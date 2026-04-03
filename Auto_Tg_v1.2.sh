#!/bin/bash
#
# Copyright (c) 2023, Myron
# Refactored for Production
# unit: time (ps)  distance (nm)  tempreture (K)

# ==========================================================
# 全局硬件与环境配置 (通过 main 函数传入)
# ==========================================================
GPU_ID=""
NTOMP=""
PINOFFSET=""
CHECKPOINT_FILE="presq_checkpoint.env"

# ==========================================================
# 工具函数层 (Infrastructure)
# ==========================================================

# 统一封装 GROMACS 运行命令 (前台阻塞)
run_gmx() {
    local deffnm=$1
    shift
    # "$@" 接收传入的其他参数
    gmx mdrun -deffnm "$deffnm" -v -c "${deffnm}.gro" \
        -ntmpi 1 -ntomp "$NTOMP" -gpu_id "$GPU_ID" -pin off \
        -nb gpu -bonded gpu -pme gpu -pmefft gpu -pinoffset "$PINOFFSET" "$@" > gmx_run.log 2>&1
}

# 统一封装 GROMACS 运行命令 (后台非阻塞，返回 PID)
run_gmx_bg() {
    local deffnm=$1
    shift
    nohup gmx mdrun -deffnm "$deffnm" -v -c "${deffnm}.gro" \
        -ntmpi 1 -ntomp "$NTOMP" -gpu_id "$GPU_ID" -pin off \
        -nb gpu -bonded gpu -pme gpu -pmefft gpu -pinoffset "$PINOFFSET" "$@" > gmx_bg_run.log 2>&1 &
    # 输出后台进程的真实 PID
    echo $!
}

# 断点续算模块
save_checkpoint() {
    local step_idx=$1
    echo "CURRENT_STEP=$step_idx" > "$CHECKPOINT_FILE"
    declare -p T_next T_list_g tau_g wslist nplist dtlist nw >> "$CHECKPOINT_FILE"
    echo ">>> Checkpoint saved at window index $step_idx <<<"
}

load_checkpoint() {
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        source "$CHECKPOINT_FILE"
        echo ">>> Found checkpoint! Resuming from window index $CURRENT_STEP <<<"
    else
        CURRENT_STEP=0
    fi
}

# ==========================================================
# 物理流程控制层 (Scientific Workflow)
# ==========================================================

## function CONFI: < $n_points $Tini $Tend $n_window
CONFI(){
    local n_points=$1 Tini=$2 Tend=$3 n_window=$4
    cd Run_Data || exit 1
    
    local windir
    windir=$(python ../PyKernel/GetLinearAnneal.py "${Tini}" "${Tend}" "${n_window}")
    cd "$windir" || exit 1
    
    echo "*** Knowledge can change your fate.   ***"
    gmx grompp -f anneal.mdp -c ../ini_.gro -p ../topol.top -o anneal -maxwarn 100 >/dev/null 2>&1
    
    # 后台运行退火
    run_gmx_bg anneal
    
    local file="anneal.gro"
    until [[ -e "$file" ]]; do
        sleep 5
    done
    echo "*** Linear anneal at this windows has done!   ***"
    
    for T in "${T_list[@]}"; do
        python ../../PyKernel/GetRunMdp.py "$T" "$n_window"
    done
    
    mkdir -p confi
    cd confi || exit 1
    
    local delta=$((5000 / n_points))
    local a=1
    
    for T in "${T_list[@]}"; do
        local dumpt=$((a * delta))
        gmx trjconv -f ../anneal.xtc -s ../anneal.tpr -o "${T}.gro" -dump "$dumpt" <<< 0 >/dev/null 2>&1
        cp "${T}.gro" "../${T}"
        ((a++))
    done 
    cd ..
}

## function PRE_EQU: < n_points dt n_window
PRE_EQU(){
    local n_points=$1 dt=$2 n_window=$3
    
    for T in "${T_list[@]}"; do
        cd "${T}" || exit 1
        mv "${T}.gro" "${T}_.gro"
        
        gmx grompp -f npt.mdp -c "${T}_.gro" -o "${T}_pre" -p ../../topol.top -maxwarn 100 >/dev/null 2>&1
        
        # 精确获取真正的 PID
        local pid=$(run_gmx_bg "${T}_pre")
        
        local flag=0
        local file="${T}_pre.gro"
        echo -e "0.0  0.0" > curve_para.dat
        
        until [[ "$flag" == 1 || -e "$file" ]]; do
            sleep 300
            echo "*********************************************************************************"
            flag=$(python ../../../PyKernel/StrexpJudge.py "${T}_pre.xtc" "${T}_.gro" "${T}_pre.tpr" "$dt" "${SYSdir}" curve_para.dat)
            echo "StrexpJudge Status: $flag"
        done
        
        # 稳妥地杀掉后台进程
        if [[ "$flag" == 1 ]]; then 
            kill "$pid" 2>/dev/null || true
        fi
        
        gmx energy -f "${T}_pre.edr" -o den <<< 22 >/dev/null 2>&1
        local dumpt=$(python ../../../PyKernel/ReadLastFrame.py den.xvg)
        gmx trjconv -f "${T}_pre.xtc" -s "${T}_pre.tpr" -o "${T}.gro" -dump "$dumpt" <<< 0 >/dev/null 2>&1
        
        sleep 2
        cd ..
    done
}

## function SAM: < n_points dt n_window
SAM() {
    local n_points=$1 dt=$2 n_window=$3
    
    for T in "${T_list[@]}"; do
        cd "${T}" || exit 1
        gmx grompp -f nvt.mdp -c "${T}.gro" -p ../../topol -o "${T}" -maxwarn 100 >/dev/null 2>&1
        
        local pid=$(run_gmx_bg "${T}")
        echo "Sampling PID: $pid"
        
        local flag=0
        local run_time=0
        
        until [[ "$flag" != 0 ]]; do
            sleep 300
            ((run_time += 300))
            echo "****************************************************************************"
            flag=$(python ../../../PyKernel/FqJudge.py "${T}.xtc" "${T}.gro" "${T}.tpr" "$dt" "${SYSdir}")
            echo "FqJudge Status: $flag"
            echo "****************************************************************************"
        done
        
        sleep "$run_time" # 按照原逻辑双倍松弛时间
        kill "$pid" 2>/dev/null || true
        
        python ../../../PyKernel/FqJudge.py "${T}.xtc" "${T}.gro" "${T}.tpr" "$dt" "${SYSdir}"
        
        gmx energy -f "${T}_pre.edr" -o den <<< 22 >/dev/null 2>&1
        local dumpt=$(python ../../../PyKernel/ReadLastFrame.py den.xvg)
        gmx trjconv -f "${T}.xtc" -s "${T}.tpr" -o "${T}.gro" -dump "$dumpt" <<< 0 >/dev/null 2>&1
        
        cp "${T}.gro" ..
        mv "../${T}.gro" ../../ini_.gro 
        cd ..
    done
}

## function PRE_SAM_CHECKED
PRE_SAM_CHECKED() {
    echo "********************** PRE_SAM_CHECKED  ************************"
    python ../../PyKernel/CleanNonEq.py -Teq "${T_eq[@]}"
    gmx trjconv -f anneal.xtc -s anneal.tpr -dump 0 -o anneal_ini.gro <<< 0 >/dev/null 2>&1
    
    for T in "${T_addi[@]}"; do
        echo "***************** generate configuration for ${T}  ******************"
        python ../../PyKernel/GetRunMdp.py "$T" "$n_window"
        cd "$T" || exit 1
        python ../../../PyKernel/QuickAnneal.py "${T_eq[0]}" "$T"
        gmx grompp -f quickanneal.mdp -c ../anneal_ini.gro -p ../../topol.top -o quick -maxwarn 100 >/dev/null 2>&1
        
        run_gmx quick -c "${T}_.gro"
        gmx trjconv -f quick.xtc -s quick.tpr -o "${T}_.gro" -dump 5000 <<< 0 >/dev/null 2>&1
        
        # PRE_EQU 部分
        echo "***************** PRE_EQU for Temperature ${T}  ******************"
        gmx grompp -f npt.mdp -c "${T}_.gro" -o "${T}_pre" -p ../../topol.top -maxwarn 100 >/dev/null 2>&1
        
        local pid=$(run_gmx_bg "${T}_pre")
        local flag=0
        local file="${T}_pre.gro"
        echo -e "0.0  0.0" > curve_para.dat
        
        until [[ "$flag" == 1 || -e "$file" ]]; do
            sleep 300
            flag=$(python ../../../PyKernel/StrexpJudge.py "${T}_pre.xtc" "${T}_.gro" "${T}_pre.tpr" "$dt" "${SYSdir}" curve_para.dat)
        done
        
        if [[ "$flag" != 0 ]]; then kill "$pid" 2>/dev/null || true; fi
        
        gmx energy -f "${T}_pre.edr" -o den <<< 22 >/dev/null 2>&1
        local dumpt=$(python ../../../PyKernel/ReadLastFrame.py den.xvg)
        gmx trjconv -f "${T}_pre.xtc" -s "${T}_pre.tpr" -o "${T}.gro" -dump "$dumpt" <<< 0 >/dev/null 2>&1
        cd ..
    done
    
    for T in "${T_addi[@]}"; do
        cd "$T" || exit 1
        echo "***************** SAM for Temperature ${T}  ******************"
        gmx grompp -f nvt.mdp -c "${T}.gro" -p ../../topol.top -o "${T}" -maxwarn 100 >/dev/null 2>&1
        
        local pid=$(run_gmx_bg "${T}")
        local flag=0
        local run_time=0
        
        until [[ "$flag" != 0 ]]; do
            sleep 300
            ((run_time += 300))
            flag=$(python ../../../PyKernel/FqJudge.py "${T}.xtc" "${T}.gro" "${T}.tpr" "$dt" "${SYSdir}")
        done
        
        sleep "$run_time"
        kill "$pid" 2>/dev/null || true
        
        python ../../../PyKernel/FqJudge.py "${T}.xtc" "${T}.gro" "${T}.tpr" "$dt" "${SYSdir}"
        gmx energy -f "${T}_pre.edr" -o den <<< 22 >/dev/null 2>&1
        local dumpt=$(python ../../../PyKernel/ReadLastFrame.py den.xvg)
        gmx trjconv -f "${T}.xtc" -s "${T}.tpr" -o "${T}.gro" -dump "$dumpt" <<< 0 >/dev/null 2>&1
        cp "${T}.gro" ..
        mv "../${T}.gro" ../../ini_.gro
        cd ..
    done
}

# function CHECK: < n_window dt
CHECK() {
    local n_window=$1 dt=$2
    local checkresult=$(python ../../PyKernel/CheckComplete.py -T "${T_list_l[@]}" -tau "${tau_l[@]}" -nwin "$n_window")
    
    if [[ "$checkresult" == 1 ]]; then
        echo "********************************************************"
        echo "* This window has completed!              *"
        echo "********************************************************"
        return 1
    else
        local arr=(${checkresult//,/ }) # 用纯 Bash 替换 IFS 拆分，更安全
        # 重新分配到全局变量
        T_eq=(${arr[0]})
        T_addi=(${arr[1]})
        echo "T_eq: ${T_eq[@]} ,  T_addi: ${T_addi[@]} " | tee -a log.log
        PRE_SAM_CHECKED
        return 1
    fi
}

# function VFT: < n_window  n_window_next n_points_next
VFT() {
    local n_window=$1 n_window_next=$2 n_points_next=$3
    tau_g=("${tau_g[@]}" "${tau_l[@]}")
    T_list_g=("${T_list_g[@]}" "${T_list_l[@]}")
    
    cd ../VFT || exit 1
    echo "************************ T_g tau_g *****************************"
    echo "${T_list_g[@]}"
    echo "${tau_g[@]}"
    
    # 安全获取 Python 输出到数组
    read -r -a T_next <<< "$(python ../../PyKernel/VFT_fit.py -n "$n_window" -T "${T_list_g[@]}" -tau "${tau_g[@]}" -n_next "$n_window_next" -np_next "$n_points_next")"
    cd ../../
}

## function CAT_INFO: < n_window
CAT_INFO() {
    local arr=($(python ../../PyKernel/CatInfo.py | tr ',' ' '))
    T_list_l=(${arr[0]})
    tau_l=(${arr[1]})
}

INI_TRIAL() {
    cd Run_Data/trial || exit 1
    local Ts=$1 
    local T=1000      # 初始猜测温度
    local delta_T=200 # 初始搜索步长
    local min_delta=50 
    local flag=0 n=$2 dt=$3 count=1
    
    while [[ "$flag" == 0 ]]; do
        echo ">>> INI_TRIAL: Testing Temperature = ${T}K (Step = ${delta_T}K)..."
        python ../../PyKernel/GetIniMdp.py "$T"
        gmx grompp -f trial.mdp -c ../ini.gro -p ../topol.top -o ini -maxwarn 100 >/dev/null 2>&1
        
        run_gmx_bg ini
        local file='ini_.gro'
        until [[ -e "$file" ]]; do sleep 5; done
        
        gmx trjconv -f ini.xtc -s ini.tpr -dump 1000 -o ini_.gro <<< 0 >/dev/null 2>&1
        
        python ../../PyKernel/GetIniSamMdp.py "$T"
        gmx grompp -f trial_sam.mdp -c ini_.gro -p ../topol.top -o ini -maxwarn 100 >/dev/null 2>&1
        
        run_gmx ini # 这里使用阻塞运行
        gmx trjconv -f ini.xtc -s ini.tpr -dump 1000 -o ini_.gro <<< 0 >/dev/null 2>&1
        
        local tau=$(python ../../PyKernel/FqJudge.py ini.xtc ini_.gro ini.tpr "$dt" "${SYSdir}")
        local status=$(python ../../PyKernel/CompareTaute.py -tau "$tau" -w 2)
        
        if [[ "$status" == "1" ]]; then 
            flag=1
            echo ">>> INI_TRIAL: Target temperature ${T}K is acceptable!"
        elif [[ "$status" == "0" ]]; then 
            ((T += delta_T))
            ((count++))
            rm -f "$file"
        elif [[ "$status" == "2" ]]; then
            ((T -= delta_T))
            ((count++))
            rm -f "$file"
            if [[ $delta_T -gt $min_delta ]]; then delta_T=$((delta_T / 2)); fi
        else
            echo ">>> Error: Unrecognized status '$status' from CompareTaute.py"
            exit 1
        fi
    done
    
    local de=$((count * 10))
    local list=("$T")
    for (( i=1 ; i<=Ts ; i++ )); do
        list+=($((T - i * de)))
    done
    
    read -r -a T_next <<< "$(python ../../PyKernel/Int2Float.py -T "${list[@]}")"
    T_list_g[0]=$T
    tau_g[0]=$tau
    mv ini_.gro ../ini_.gro
    cd ../../
}

# ==========================================================
# Main 函数入口
# ==========================================================
main() {
    GPU_ID=$1
    NTOMP=$2
    PINOFFSET=$3
    
    # 确保在预期的顶级工作目录下执行
    if [[ ! -d "Run_Data/trial" ]]; then
        cd Run_Data || exit 1
        python ../PyKernel/CreateInfo.py -gro ini.gro
        # 声明全局变量供 Python 脚本和其他函数使用
        export SYSdir=$(python ../PyKernel/FindNid.py -gro ini.gro -info sys.info)
        mkdir -p trial VFT confi
        cd ..
    else
        export SYSdir=$(python PyKernel/FindNid.py -gro Run_Data/ini.gro -info Run_Data/sys.info)
    fi

    # 声明全局数组，避免子 shell 作用域丢失
    declare -g -a T_list_g T_next tau_g T_list_l tau_l T_eq T_addi

    wslist=(1.5 2.5 3 3.5 4)
    nplist=(8 8 8 8 4)
    dtlist=(0.5 5 50 50 50)
    nw=${#wslist[@]}
    
    echo "---------------------------------------  Here we go!  -----------------------------------"
    
    load_checkpoint
    
    if [[ "$CURRENT_STEP" -eq 0 ]]; then
        INI_TRIAL "${nplist[0]}" "${wslist[0]}" "${dtlist[0]}"
    fi

    for (( i=CURRENT_STEP ; i<nw ; i++ )); do
        local n_window=${wslist[$i]}
        local n_points=${nplist[$i]}
        local dt=${dtlist[$i]}
        
        echo "---------------------------------------  This window is $n_window  -----------------------------------"
        
        # 截取数组片段
        T_list=("${T_next[@]:1:$n_points}")
        local Tini=${T_next[0]}
        local Tend=${T_next[$n_points]} 
        
        CONFI "$n_points" "$Tini" "$Tend" "$n_window"
        echo "************************* CONFI preparation is done!   *************************"
        
        PRE_EQU "$n_points" "$dt" "$n_window"
        echo "************************** PRE_Equilibrium is done!   **************************"
        
        SAM "$n_points" "$dt" "$n_window"
        echo "******************************* Sample is done!   ******************************"
        
        CAT_INFO "$n_window"
        CHECK "$n_window" "$dt"
        echo "******************************* CHECK is done!   *******************************"
        
        CAT_INFO "$n_window"
        
        local i_next=$((i + 1))
        if [[ $i_next -lt $nw ]]; then
            VFT "$n_window" "${wslist[$i_next]}" "${nplist[$i_next]}"
            echo "***************************** VFT fitting is done!   ***************************"
            echo "Next Temperatures: ${T_next[*]}"
        fi
        
        echo "---------------------------------  This program will go to next loop.  -------------------------------"
        save_checkpoint $((i + 1))
    done
    
    echo "---------------------------------  This PreSQ program is done.  -------------------------------"
}

# 脚本入口点：捕获命令行参数
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <GPU_ID> <NTOMP> <PINOFFSET>"
    exit 1
fi
main "$1" "$2" "$3"
