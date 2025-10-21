#!/bin/bash
#
#Copyright (c) 2023, Myron
#
#unit: time (ps)  distance (nm)  tempreture (K)
#
# ______________________
#|                      |
#|      INI_TRIAL       |
#|______________________|
#          ||
#          || get into the "for" loop of window(1.5 2.5 3 4)
#          \/			     
# ______________________	     
#|                      | /___________ 
#|        CONFI         | \	     |
#|______________________|            |
#          |			     |
#          |			     |
#          V			     |
# ______________________             |
#|                      |            |
#|       PRE_QUE        |            |
#|______________________|	     |
#          |			     |
#          |			     |
#          V			     |
# ______________________             |
#|                      |            |
#|         SAM          |	     |
#|______________________|	     |
#          | 			     |
#          |			     |
#          V			     |
# ______________________	     |
#|                      |	     |
#|      CAT_INFO        |	     |
#|______________________|	     |
#          |			     |
#          |			     |
#          V			     |
# ______________________ 	     |
#|                      |	     |
#|        CHECK         |	     |
#|______________________|	     |
#          | 			     |
#          |			     |
#          V			     |
# ______________________	     |
#|                      |	     |
#|      CAT_INFO        |	     |
#|______________________|	     |
#          |                         |
#          |                         |
#          V                         |
# ______________________             |
#|                      |____________|
#|         VFT          |
#|______________________|













##function CONFI: < $n_points $Tini $Tend $n_window $T_list
## work path : test/
CONFI(){
    n_points=$1
    Tini=$2
    Tend=$3
    n_window=$4
    cd Run_Data
    windir=$(python ../PyKernel/GetLinearAnneal.py ${Tini} ${Tend} ${n_window} ) #mkdir /window and mv output anneal.mdp to /window
    cd $windir
    echo "***   Knowledge can change your fate.   ***"
    nohup gmx grompp -f anneal.mdp -c ../ini_.gro -p ../topol.top -o anneal -maxwarn 1000 
    nohup gmx mdrun -deffnm anneal -v -c anneal.gro -ntmpi 1 -ntomp $ntomp -gpu_id $gpuid -pin off -nb gpu -bonded gpu -pme gpu -pmefft gpu -pinoffset $pinoffset 1>stdin 2>stdout & 
    file="anneal.gro"
    until [[ -e $file ]]
    do
        a=1
    done
    echo "***   Linear anneal at this windows has done!   ***"
    for T in ${T_list[*]}
    do
        python ../../PyKernel/GetRunMdp.py $T $n_window
    done
    mkdir confi
    cd confi
    delta=$((5000/$n_points))
    for T in ${T_list[@]}
    do
        aa=`expr $a + 1`
        dumpt=`expr $a \* $delta`
        #dumpt=`expr $a \* 1`
        nohup gmx trjconv -f ../anneal.xtc -s ../anneal.tpr -o ${T}.gro -dump $dumpt<<EOF
0
EOF
        cp ${T}.gro ../${T}
        a=`expr $a + 1`
    done 
    cd ..
}


##function PRE_EQU: < n_points T_list dt n_window
## run the pre equilibrium of every states with different tempreture, at the same time, use the stretching exponential to monitor the simulation process. 
## work dir : test/Run_Data/windows{}
PRE_EQU(){
    n_points=$1
    #T_list=$2
    dt=$2
    n_window=$3
    a=0
    for T in ${T_list[@]}
    do
        cd ${T}
        mv ${T}.gro ${T}_.gro
        nohup gmx grompp -f npt.mdp -c ${T}_.gro -o ${T}_pre -p ../../topol.top -maxwarn 1000
        nohup gmx mdrun -deffnm ${T}_pre -v -c ${T}_pre.gro -ntmpi 1 -ntomp $ntomp -gpu_id $gpuid -pin off -nb gpu -bonded gpu -pme gpu -pmefft gpu -pinoffset $pinoffset 1>stdin 2>stdout &
        pid=$(ps -ef | grep "${T}_pre" | grep -v grep | awk '{print $2}' )
        flag=0
        file="${T}_pre.gro"
        cat > curve_para.dat<<EOF
0.0  0.0
EOF
        until [[ $flag  == 1 || -e $file ]]
        do
            sleep 300
            echo "*********************************************************************************"
            flag=$(python ../../../PyKernel/StrexpJudge.py ${T}_pre.xtc ${T}_.gro ${T}_pre.tpr $dt ${SYSdir} curve_para.dat)
            echo $flag
        done
        if [ $flag == 1 ]; then kill $pid; fi
        nohup gmx energy -f ${T}_pre.edr -o den<<EOF
22
EOF
        #SUCH A SON OF BITCH!!!!!!!!!!
        dumpt=$(python ../../../PyKernel/ReadLastFrame.py den.xvg)
        nohup gmx trjconv -f ${T}_pre.xtc -s ${T}_pre.tpr -o ${T}.gro -dump $dumpt<<EOF
0
EOF
        sleep 5
        a=`expr $a + 1`
        cd ..
    done
}

##function SAM: < n_points T_list dt n_window
## product, monitoring the process use python, while the run time exceeds twice the relaxation time, kill the process.
SAM() {
    n_points=$1
    #T_list=$2
    dt=$2
    n_window=$3
    a=0
    for T in ${T_list[@]}
    do
        cd ${T}
        nohup gmx grompp -f nvt.mdp -c ${T}.gro -p ../../topol -o ${T} -maxwarn 1000
        nohup gmx mdrun -deffnm ${T} -v -c ${T}.gro -ntmpi 1 -ntomp $ntomp -gpu_id $gpuid -pin off -nb gpu -bonded gpu -pme gpu -pmefft gpu -pinoffset $pinoffset 1>stdin 2>stdout &
        pid=$(ps -ef | grep "gmx mdrun -deffnm ${T} -v -c ${T}.gro" | grep -v grep | awk '{print $2}' )
        echo $pid
        flag=0
        run_time=0
        until [[ $flag != 0 ]]
        do
            sleep 300
            run_time=`expr $run_time + 300`
            echo "****************************************************************************"
            flag=$(python ../../../PyKernel/FqJudge.py ${T}.xtc ${T}.gro ${T}.tpr $dt ${SYSdir})
            echo $flag
            echo "****************************************************************************"
        done
        echo 
        sleep $run_time
        kill $pid
        python ../../../PyKernel/FqJudge.py ${T}.xtc ${T}.gro ${T}.tpr $dt ${SYSdir}
        nohup gmx energy -f ${T}_pre.edr -o den<<EOF
22
EOF
        dumpt=$(python ../../../PyKernel/ReadLastFrame.py den.xvg)
        nohup gmx trjconv -f ${T}.xtc -s ${T}.tpr -o ${T}.gro -dump $dumpt<<EOF
0
EOF
        cp ${T}.gro ..
        #w_next=`expr ${n_window} + 1`
        mv ../${T}.gro ../../ini_.gro 
        cd ..
        a=`expr $a + 1`
    done
}

## function PRE_SAM_CHECKED: #< T_eq T_addi
PRE_SAM_CHECKED() {
    echo "**********************  PRE_SAM_CHECKED  ************************"
    #echo "*******************  generate configuration  ********************"
    n_T_eq=${#T_eq[*]}
    python ../../PyKernel/CleanNonEq.py -Teq ${T_eq[@]}
    nohup gmx trjconv -f anneal.xtc -s anneal.tpr -dump 0 -o anneal_ini.gro <<< 0
    for T in ${T_addi[@]}
    do
        echo "*****************  generate configuration for ${T}  ******************"
        python ../../PyKernel/GetRunMdp.py $T $n_window
        cd $T
        python ../../../PyKernel/QuickAnneal.py ${T_eq[0]} $T
        nohup gmx grompp -f quickanneal.mdp -c ../anneal_ini.gro -p ../../topol.top -o quick -maxwarn 1000
        nohup gmx mdrun -deffnm quick -v -c ${T}_.gro -ntmpi 1 -ntomp $ntomp -gpu_id $gpuid -pin off -nb gpu -bonded gpu -pme gpu -pmefft gpu -pinoffset $pinoffset 1>stdin 2>stdout
        nohup gmx trjconv -f quick.xtc -s quick.tpr -o ${T}_.gro -dump 5000 <<< 0
        ###
        ###PRE_EQU
        ###
        echo "*****************  PRE_EQU for Tempreture ${T}  ******************"
        nohup gmx grompp -f npt.mdp -c ${T}_.gro -o ${T}_pre -p ../../topol.top -maxwarn 1000
        nohup gmx mdrun -deffnm ${T}_pre -v -c ${T}_pre.gro -ntmpi 1 -ntomp $ntomp -gpu_id $gpuid -pin off -nb gpu -bonded gpu -pme gpu -pmefft gpu -pinoffset $pinoffset 1>stdin 2>stdout &
        pid=$(ps -ef | grep "gmx mdrun -deffnm ${T}_pre" | grep -v grep | awk '{print $2}' )
        flag=0
        file="${T}_pre.gro"
        cat > curve_para.dat<<EOF
0.0  0.0
EOF
        until [[ $flag  == 1 || -e $file ]]
        do
            sleep 300
            echo "*********************************************************************************"
            flag=$(python ../../../PyKernel/StrexpJudge.py ${T}_pre.xtc ${T}_.gro ${T}_pre.tpr $dt ${SYSdir} curve_para.dat)
            echo $flag
        done
        if [ $flag != 0 ];then kill $pid;fi
        echo "*****************  PRE_EQU for Tempreture ${T} is done  ******************"
        nohup gmx energy -f ${T}_pre.edr -o den <<EOF
22
EOF
        #SUCH A SON OF BITCH!!!!!!!!!!
        dumpt=$(python ../../../PyKernel/ReadLastFrame.py den.xvg)
        nohup gmx trjconv -f ${T}_pre.xtc -s ${T}_pre.tpr -o ${T}.gro -dump $dumpt <<EOF
0
EOF
        cd ..
    done
    for T in ${T_addi[@]}
    do
        cd $T
        ###
        ###SAM
        ###
        echo "*****************  SAM for Tempreture ${T}  ******************"
        nohup gmx grompp -f nvt.mdp -c ${T}.gro -p ../../topol.top -o ${T} -maxwarn 1000
        nohup gmx mdrun -deffnm ${T} -v -c ${T}.gro -ntmpi 1 -ntomp $ntomp -gpu_id $gpuid -pin off -nb gpu -bonded gpu -pme gpu -pmefft gpu -pinoffset $pinoffset 1>stdin 2>stdout &
        pid=$(ps -ef | grep "gmx mdrun -deffnm ${T} -v -c ${T}.gro" | grep -v grep | awk '{print $2}' )
        flag=0
        run_time=0
        until [ $flag != 0 ]
        do
            sleep 300
            run_time=`expr $run_time + 300`
            echo "****************************************************************************"
            flag=$(python ../../../PyKernel/FqJudge.py ${T}.xtc ${T}.gro ${T}.tpr $dt ${SYSdir})
            echo "The segment relaxation time at ${T}K is ${flag}ps."
            echo "****************************************************************************"
        done
        echo 
        sleep $run_time
        kill $pid
        echo "*****************  SAM for Tempreture ${T} is done  ******************"
        python ../../../PyKernel/FqJudge.py ${T}.xtc ${T}.gro ${T}.tpr $dt ${SYSdir}
        nohup gmx energy -f ${T}_pre.edr -o den<<EOF
22
EOF
        dumpt=$(python ../../../PyKernel/ReadLastFrame.py den.xvg)
        nohup gmx trjconv -f ${T}.xtc -s ${T}.tpr -o ${T}.gro -dump $dumpt <<EOF
0
EOF
        cp ${T}.gro ..
        mv ../${T}.gro ../../ini_.gro
        cd ..
    done

}

# function CHECK: < n_window T_list_l tau_l dt
CHECK() {
    n_window=$1
    dt=$2
    #te=$[10*10**$1]
    checkresult=$(python ../../PyKernel/CheckComplete.py -T ${T_list_l[@]} -tau ${tau_l[@]} -nwin $n_window)
    if [ $checkresult == 1 ]
    then
        echo "********************************************************"
        echo "*                                                      *"
        echo "*             This window has completed!               *"
        echo "*                                                      *"
        echo "********************************************************"
        return 1
    else
        OLD_ISF=$IFS
        IFS=',' read -r -a arr <<< $checkresult
        IFS=' ' read -r -a T_eq <<< ${arr[0]}
        IFS=' ' read -r -a T_addi <<< ${arr[1]}
        echo "T_eq: ${T_eq[@]} ,  T_addi: ${T_addi[@]} "
        echo "T_eq: ${T_eq[@]} ,  T_addi: ${T_addi[@]} " > log.log
        ISF=$OLD_ISF
        PRE_SAM_CHECKED
        return 1
    fi
}

# function VFT: < n_window  n_window_next n_points_next
VFT() {
    n_window=$1
    n_points_next=$3
    n_window_next=$2
    tau_g=(${tau_g[@]} ${tau_l[@]})
    T_list_g=(${T_list_g[@]} ${T_list_l[@]})
    cd ../VFT
    echo "************************ T_g tau_g *****************************"
    echo ${T_list_g[@]}
    echo ${tau_g[@]}
    echo "************************ T_g tau_g *****************************"
    OLD_IFS=$IFS
    IFS=' ' read -r -a T_next <<< $(python ../../PyKernel/VFT_fit.py -n $n_window -T ${T_list_g[@]} -tau ${tau_g[@]} -n_next $n_window_next -np_next $n_points_next )
    IFS=$OLD_IFS 
    cd ../../
}

## function CAT_INFO: < n_window
CAT_INFO() {
    n_window=$1
    OLD_IFS=$IFS
    IFS=',' read -r -a arr <<< $(python ../../PyKernel/CatInfo.py)
    IFS=' ' read -r -a T_list_l <<< ${arr[0]}
    IFS=' ' read -r -a tau_l <<< ${arr[1]}
    IFS=$OLD_IFS
}

INI_TRIAL() {
    cd Run_Data/trial
    Ts=$1 
    T=1000
    flag=0
    n=$2
    dt=$3
    count=1
    while [ $flag == 0 ]
    do
        python ../../PyKernel/GetIniMdp.py $T
        nohup gmx grompp -f trial.mdp -c ../ini.gro  -p ../topol.top -o ini -maxwarn 100
        nohup gmx mdrun -deffnm ini -v -c ini_.gro -ntmpi 1 -ntomp $ntomp -gpu_id $gpuid -pin off -nb gpu -bonded gpu -pme gpu -pmefft gpu -pinoffset $pinoffset 1>stdin 2>stdout &
        file='ini_.gro'
        until [ -e $file ]
        do
            a=0
        done
        nohup gmx trjconv -f ini.xtc -s ini.tpr -dump 1000 -o ini_.gro <<< 0
        python ../../PyKernel/GetIniSamMdp.py $T
        nohup gmx grompp -f trial_sam.mdp -c ini_.gro  -p ../topol.top -o ini -maxwarn 100
        nohup gmx mdrun -deffnm ini -v -c ini_.gro -ntmpi 1 -ntomp $ntomp -gpu_id $gpuid -pin off -nb gpu -bonded gpu -pme gpu -pmefft gpu -pinoffset $pinoffset 1>stdin 2>stdout
        nohup gmx trjconv -f ini.xtc -s ini.tpr -dump 1000 -o ini_.gro <<< 0
        tau=$(python ../../PyKernel/FqJudge.py ini.xtc ini_.gro ini.tpr $dt ${SYSdir})
        flag=$(python ../../PyKernel/CompareTaute.py -tau $tau -w 2)
        if [ $flag != 1 ]
        then 
            T=`expr ${T} + 200`
            count=`expr $count + 1`
            rm -f $file
        fi
    done
    de=`expr $count \* 10`
    list=($T)
    for (( i=1 ; i<=$Ts ; i++))
    do
        T1=`expr ${T} - $i \* $de`
        list+=($T1)
    done
    IFS=' ' read -r -a T_next <<< $(python ../../PyKernel/Int2Float.py -T ${list[@]})
    T_list_g[0]=$T
    tau_g[0]=$tau
    mv ini_.gro ../ini_.gro
    cd ../../
}


## function main: < gro MC_traj.py top 
main() {
    gpuid=$1
    ntomp=$2
    pinoffset=$3
    cd Run_Data
    python ../PyKernel/CreateInfo.py -gro ini.gro
    SYSdir=$(python ../PyKernel/FindNid.py -gro ini.gro -info sys.info)
    mkdir trial
    mkdir VFT
    cd ..
    T_list_g=()
    T_next=()
    tau_g=()
    wslist=(1.5 2.5 3 3.5 4)
    nplist=(8 8 8 8 4)
    dtlist=(0.5 5 50 50 50)
    nw=${#wslist[@]}
    echo "---------------------------------------  Here we go!  -----------------------------------"
    INI_TRIAL ${nplist[0]} ${wslist[0]} ${dtlist[0]} ## >> T_next T_list_g tau_g
    for (( i=0 ; i<$nw ; i++))
    do
        n_window=${wslist[$i]}
        n_points=${nplist[$i]}
        dt=${dtlist[$i]}
        echo $n_window $n_points $dt
        echo "---------------------------------------  this window is $n_window  -----------------------------------"
        T_list=(${T_next[@]:1:$n_points})
        Tini=${T_next[0]}
        Tend=${T_next[$n_points]} 
        echo $Tini $Tend
        CONFI $n_points $Tini $Tend $n_window
        echo "*************************   CONFI preparation is done!   *************************"
        PRE_EQU $n_points $dt $n_window
        echo "**************************   PRE_Equilibrium is done!   **************************"
        SAM $n_points $dt $n_window
        echo "*******************************   Sample is done!   ******************************"
        T_next=()
        T_list_l=()
        tau_l=()
        CAT_INFO $n_window
        echo "****************   Catching information for the CHECK is done!   *****************"
        CHECK $n_window $dt
        echo "*******************************   CHECK is done!   *******************************"
        T_next=()
        T_list_l=()
        tau_l=()
        CAT_INFO $n_window
        echo "***************   Catching information after the CHECK is done!   ****************"
        i_=$(($i + 1))
        VFT $n_window ${wslist[$i_]} ${nplist[$i_]}
        echo "*****************************   VFT fitting is done!   ***************************"
        echo ${T_next[@]}
        T_list=()
        echo "---------------------------------  This program will go to next loop.  -------------------------------"
    done
    echo "---------------------------------  This PreSQ program is done.  -------------------------------"
}
## main get parameter to control gmx mdrun: gpuid ntomp pinoffset
main $1 $2 $3
