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







##function GMX_EM_SLURM_WRITE: < .mdp .gro .top .tpr .out
GMX_EM_SLURM_WRITE(){
    mdp=$1
    gro=$2
    top=$3
    tpr=$4
    out=$5
    GMX2022=/public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/gmx_mpi
#########           gmx.slurm            #########
    cat>gmx.slurm<<EOF
#!/bin/bash

#SBATCH -p ty_normal
#SBATCH -N 1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=8
#SBATCH --gres=dcu:4
#SBATCH --gres-flags=disable-binding
#SBATCH --exclusive

module purge
module load compiler/devtoolset/7.3.1
module load mpi/hpcx/2.4.1/gcc-7.3.1
module load  compiler/dtk/22.10
# 请按用户手册处理DTK22.10环境并加载
source /public/software/compiler/dtk-22.10/env.sh
source /public/software/compiler/dtk-22.10/cuda/env.sh



GMX2022=/public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/gmx_mpi
source /public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/GMXRC


export GMX_USE_GPU_BUFFER_OPS=1
export GMX_GPU_DD_COMMS=true
export GMX_GPU_PME_PP_COMMS=true
export GMX_FORCE_UPDATE_DEFAULT_GPU=true

${GMX2022} grompp -f $mdp -c $gro -p $top -o $tpr -maxwarn 100
mpirun --bind-to numa -np 4 ${GMX2022}  mdrun -v -deffnm ${tpr} -c ${out}
EOF

}



##function GMX_SLURM_WRITE: < .mdp .gro .top .tpr .out
GMX_SLURM_WRITE(){
    mdp=$1
    gro=$2
    top=$3
    tpr=$4
    out=$5
    GMX2022=/public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/gmx_mpi
#########           gmx.slurm            #########
    cat>gmx.slurm<<EOF
#!/bin/bash

#SBATCH -p ty_normal
#SBATCH -N 1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=8
#SBATCH --gres=dcu:4
#SBATCH --gres-flags=disable-binding
#SBATCH --exclusive

module purge
module load compiler/devtoolset/7.3.1
module load mpi/hpcx/2.4.1/gcc-7.3.1
module load  compiler/dtk/22.10
# 请按用户手册处理DTK22.10环境并加载
source /public/software/compiler/dtk-22.10/env.sh
source /public/software/compiler/dtk-22.10/cuda/env.sh



GMX2022=/public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/gmx_mpi
source /public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/GMXRC


export GMX_USE_GPU_BUFFER_OPS=1
export GMX_GPU_DD_COMMS=true
export GMX_GPU_PME_PP_COMMS=true
export GMX_FORCE_UPDATE_DEFAULT_GPU=true

${GMX2022} grompp -f $mdp -c $gro -p $top -o $tpr -maxwarn 100
mpirun --bind-to numa -np 4 ${GMX2022}  mdrun -v -deffnm ${tpr} -c ${out} -pin on -nb gpu  -ntomp 8 -npme 1 -pme gpu  -bonded gpu
EOF

}

##function GMX_TRJ_SLURM_WRITE: < $flag .xtc .tpr .gro dump
GMX_TRJ_SLURM_WRITE(){
    flag=$1
    xtc=$2
    tpr=$3
    gro=$4
    dump=$5
    GMX2022=/public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/gmx_mpi
    if [ ${flag} == 1 ]
    then
        cat>trj.slurm<<EOFF
#!/bin/bash

#SBATCH -p ty_normal
#SBATCH -N 1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=8
#SBATCH --gres=dcu:4
#SBATCH --gres-flags=disable-binding
#SBATCH --exclusive

module purge
module load compiler/devtoolset/7.3.1
module load mpi/hpcx/2.4.1/gcc-7.3.1
module load  compiler/dtk/22.10
# 请按用户手册处理DTK22.10环境并加载
source /public/software/compiler/dtk-22.10/env.sh
source /public/software/compiler/dtk-22.10/cuda/env.sh



GMX2022=/public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/gmx_mpi
source /public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/GMXRC


export GMX_USE_GPU_BUFFER_OPS=1
export GMX_GPU_DD_COMMS=true
export GMX_GPU_PME_PP_COMMS=true
export GMX_FORCE_UPDATE_DEFAULT_GPU=true
${GMX2022} trjconv -f ${xtc} -s ${tpr} -o ${gro} -dump ${dump} <<EOF
0
EOF
EOFF
    fi
}

#SBATCH -x b07r2n14,b07r4n06,b06r4n01,b07r2n00,b08r4n17
##function GMX_ENER_SLURM: < .edr
GMX_ENER_SLURM(){
    edr=$1
    GMX2022=/public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/gmx_mpi
    cat>energy.slurm<<EOFF
#!/bin/bash

#SBATCH -p ty_normal
#SBATCH -N 1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=8
#SBATCH --gres=dcu:4
#SBATCH --gres-flags=disable-binding
#SBATCH --exclusive

module purge
module load compiler/devtoolset/7.3.1
module load mpi/hpcx/2.4.1/gcc-7.3.1
module load  compiler/dtk/22.10
# 请按用户手册处理DTK22.10环境并加载
source /public/software/compiler/dtk-22.10/env.sh
source /public/software/compiler/dtk-22.10/cuda/env.sh



GMX2022=/public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/gmx_mpi
source /public/home/limingyang/software/Gromacs_2022.1_nfs3.2_DTK22.10_hpcxs2.4.1_11Nov2022/gromacs-2022.1-mpi/bin/GMXRC


export GMX_USE_GPU_BUFFER_OPS=1
export GMX_GPU_DD_COMMS=true
export GMX_GPU_PME_PP_COMMS=true
export GMX_FORCE_UPDATE_DEFAULT_GPU=true
${GMX2022} energy -f ${edr} -o den<<EOF
22
EOF
EOFF
}



##function CONFI: < $n_points $Tini $Tend $n_window $T_list
## work path : test/
CONFI(){
    n_points=$1
    Tini=$2
    Tend=$3
    n_window=$4
    cd Run_Data
    windir=$(python ../PyKernel/GetLinearAnneal.py ${Tini} ${Tend} ${n_window}) #mkdir /window and mv output anneal.mdp to /window
    cd $windir
    echo "***   Knowledge can change your fate.   ***"
    GMX_SLURM_WRITE anneal.mdp ../ini_.gro ../topol.top anneal anneal.gro
    sbatch gmx.slurm
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
    for T in ${T_list[@]}
    do
        aa=`expr $a + 1`
        dump=`expr $a \* 20`
        #srun -p ty_normal -n 1 -N 1 -c 8 --gres=dcu:1 
        GMX_TRJ_SLURM_WRITE 1 ../anneal.xtc ../anneal.tpr ../${T}/${T}.gro ${dump}
        sbatch trj.slurm
        until [ -e ../${T}/${T}.gro ]
        do
        sleep 3
        done
        #cp ${T}.gro ../${T}
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
        GMX_SLURM_WRITE npt.mdp ${T}_.gro ../../topol.top ${T}_pre ${T}_pre.gro
        OLD_IFS=$IFS
        IFS=' ' read -r -a JID <<<$(sbatch gmx.slurm)
        IFS=$OLD_IFS
        jid=${JID[3]}
        flag=0
        file="${T}_pre.gro"
        until [[ $flag  == 1 || -e $file ]]
        do
            sleep 300
            echo "*********************************************************************************"
            srun -p ty_normal -n 1 -N 1 -c 8 --gres=dcu:1 python ../../../PyKernel/StrexpJudge.py ${T}_pre.xtc ${T}_.gro $dt ${SYSdir} >flag.dat
            flag=$(cat flag.dat) 
            echo $flag
        done
        if [ $flag == 1 ]; then scancel $jid; fi
        GMX_ENER_SLURM ${T}_pre.edr
        sbatch energy.slurm
        until [ -e den.xvg ]
        do
        sleep 3
        done
        IFS=' '
        www=($(wc -l den.xvg))
        dump=($(sed "${www}q;d" den.xvg))
        GMX_TRJ_SLURM_WRITE 1 ${T}_pre.xtc ${T}_pre.tpr ${T}.gro ${dump}
        sbatch trj.slurm
        until [ -e ${T}.gro ]
        do
        sleep 3
        done
####
        rm -f den.xvg
        sleep 5
        a=`expr $a + 1`
        cd ..
    done
}

##function SAM: < n_points T_list dt n_window
## product, monitoring the process use python, while the run time exceeds twice the relaxation time, kill the process.
SAM() {
    n_points=$1
    dt=$2
    n_window=$3
    a=0
    for T in ${T_list[@]}
    do
        cd ${T}
        GMX_SLURM_WRITE nvt.mdp ${T}.gro ../../topol.top ${T} ${T}.gro
        IFS=' ' read -r -a JID <<< $(sbatch gmx.slurm)
        flag=0
        run_time=0
        until [[ $flag != 0 ]]
        do
            sleep 300
            run_time=`expr $run_time + 300`
            echo "****************************************************************************"
            srun -p ty_normal -n 1 -N 1 -c 8 --gres=dcu:1 python ../../../PyKernel/FqJudge.py ${T}.xtc ${T}.gro $dt ${SYSdir} >flag.dat
            flag=$(cat flag.dat)
            echo $flag
            echo "****************************************************************************"
        done
        echo 
        sleep $run_time
        scancel ${JID[3]}
        srun -p ty_normal -n 1 -N 1 -c 8 --gres=dcu:1 python ../../../PyKernel/FqJudge.py ${T}.xtc ${T}.gro $dt ${SYSdir}
        GMX_ENER_SLURM ${T}_pre.edr
        sbatch energy.slurm
        until [ -e den.xvg ]
        do
        sleep 3
        done
        www=($(wc -l den.xvg))
        dump=($(sed "${www}q;d" den.xvg))
        GMX_TRJ_SLURM_WRITE 1 ${T}.xtc ${T}.tpr ${T}.gro ${dump}
        sbatch trj.slurm
        until [ -e ${T}.gro ]
        do
        sleep 3
        done
        rm -f den.xvg
        cp ${T}.gro ..
        mv ../${T}.gro ../../ini_.gro 
        cd ..
        a=`expr $a + 1`
    done
}

## function PRE_SAM_CHECKED: #< T_eq T_addi
PRE_SAM_CHECKED(){
    echo "**********************  PRE_SAM_CHECKED  ************************"
    echo "*******************  generate configuration  ********************"
    n_T_eq=${#T_eq[*]}
    python ../../PyKernel/CleanNonEq.py -n $n_T_eq -Teq ${T_eq[@]}
    for T in ${T_addi[@]}
    do
        python ../../PyKernel/GetRunMdp.py $T $n_window
    done
    for T in ${T_addi[@]}
    do
        cd $T
        python ../../../PyKernel/QuickAnneal.py ${T_eq[0]} $T
        GMX_SLURM_WRITE quickanneal.mdp ../anneal.gro ../../topol.top quick ${T}_.gro
        sbatch gmx.slurm
        until [[ -e ${T}_.gro ]]
        do
            a=1
        done
        echo "*****************  PRE_EQU for Tempreture ${T}  ******************"
        GMX_SLURM_WRITE npt.mdp ${T}_.gro ../../topol.top ${T}_pre ${T}_pre.gro
        IFS=' ' read -r -a JID <<< $(sbatch gmx.slurm)
        jid=${JID[3]}
        flag=0
        file="${T}_pre.gro"
        until [[ $flag  == 1 || -e $file ]]
        do
            sleep 300
            echo "*********************************************************************************"
            srun -p ty_normal -n 1 -N 1 -c 8 --gres=dcu:1 python ../../../PyKernel/StrexpJudge.py ${T}_pre.xtc ${T}_.gro $dt ${SYSdir} >flag.dat
            flag=$(cat flag.dat)
            echo $flag
            echo "*********************************************************************************"
        done
        if [ flag != 0 ];then scancel $jid;fi
        GMX_ENER_SLURM ${T}_pre.edr
        sbatch energy.slurm
        until [ -e den.xvg ]
        do
        sleep 3
        done
        www=($(wc -l den.xvg))
        dump=($(sed "${www}q;d" den.xvg))
        GMX_TRJ_SLURM_WRITE 1 ${T}_pre.xtc ${T}_pre.tpr ${T}.gro ${dump}
        sbatch trj.slurm
        until [ -e ${T}.gro ]
        do 
        sleep 3
        done
        rm -f den.xvg
        ###
        ###SAM
        ###
        echo "********************  SAM for Tempreture ${T}  ********************"
        GMX_SLURM_WRITE nvt.mdp ${T}.gro ../../topol.top ${T} ${T}.gro
        IFS=' ' read -r -a JID <<< $(sbatch gmx.slurm)
        flag=0
        run_time=0
        until [ $flag != 0 ]
        do
            sleep 300
            run_time=`expr $run_time + 300`
            echo "****************************************************************************"
            srun -p ty_normal -n 1 -N 1 -c 8 --gres=dcu:1 python ../../../PyKernel/FqJudge.py ${T}.xtc ${T}.gro $dt ${SYSdir} >flag.dat
            flag=$(cat flag.dat)
            echo "The segment relaxation time at ${T}K is ${flag}ps."
            echo "****************************************************************************"
        done
        echo 
        sleep $run_time
        scancel ${JID[3]}
        srun -p ty_normal -n 1 -N 1 -c 8 --gres=dcu:1 python ../../../PyKernel/FqJudge.py ${T}.xtc ${T}.gro $dt ${SYSdir}
        GMX_ENER_SLURM ${T}_pre.edr
        sbatch energy.slurm
        until [ -e den.xvg ]
        do
            sleep 3
        done
        www=($(wc -l den.xvg))
        dump=($(sed "${www}q;d" den.xvg))
        GMX_TRJ_SLURM_WRITE 1 ${T}.xtc ${T}.tpr ${T}.gro ${dump} 
        sbatch trj.slurm
        until [ -e ${T}.gro ]
        do
            sleep 3
        done
        rm -f den.xvg
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
    checkresult=$(python ../../PyKernel/CheckComplete.py ${T_list_l[@]} ${tau_l[@]} $n_window)
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
        echo "T_eq: ${T_eq[@]} ,  T_addi: ${T_addi[@]} " > log.log
        ISF=$OLD_ISF
        PRE_SAM_CHECKED
        return 1
    fi
}

# function VFT: < n_window  T_list_l tau_l
VFT() {
    n_window=$1
    tau_g=(${tau_g[@]} ${tau_l[@]})
    T_list_g=(${T_list_g[@]} ${T_list_l[@]})
    cd ../VFT
    echo "************************ T_g tau_g *****************************"
    echo ${T_list_g[@]}
    echo ${tau_g[@]}
    echo "************************ T_g tau_g *****************************"
    OLD_IFS=$IFS
    IFS=' ' read -r -a T_next <<< $(python ../../PyKernel/VFT_fit.py -n $n_window -T ${T_list_g[@]} -tau ${tau_g[@]})
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
    T=1000
    flag=0
    n=1
    dt=0.5
    count=1
    python ../../PyKernel/GetEmMdp.py
    GMX_EM_SLURM_WRITE em.mdp ../ini.gro ../topol.top em em.gro
    sbatch gmx.slurm
    file='em.gro'
    until [[ -e $file ]]
    do
        a=0
    done
    python ../../PyKernel/GetIniMdp_.py $T
    GMX_SLURM_WRITE trial_.mdp em.gro ../topol.top ini ini_.gro
    sbatch gmx.slurm
    file='ini_.gro'
    until [[ -e $file ]]
    do
        a=0
    done
    mv ini_.gro ../ini.gro
    while [ $flag == 0 ]
    do
        python ../../PyKernel/GetIniMdp.py $T
####
        # nohup gmx grompp -f trial.mdp -c ../ini.gro  -p ../topol.top -o ini
        # nohup gmx mdrun -deffnm ini -v -c ini_.gro -ntmpi 1 -ntomp 30 -gpu_id 0 -pin on 
        GMX_SLURM_WRITE trial.mdp ../ini.gro ../topol.top ini ini_.gro
        sbatch gmx.slurm
        file='ini_.gro'
        until [[ -e $file ]]
        do
            a=0
        done
####
        python ../../PyKernel/GetIniSamMdp.py $T
####
        # nohup gmx grompp -f trial_sam.mdp -c ini_.gro  -p ../topol.top -o ini
        # nohup gmx mdrun -deffnm ini -v -c ini_.gro -ntmpi 1 -ntomp 30 -gpu_id 0 -pin on
        GMX_SLURM_WRITE trial_sam.mdp ini_.gro ../topol.top ini ini_.gro
        sbatch gmx.slurm
        rm ini_.gro
        file='ini_.gro'
        until [[ -e $file ]]
        do
            a=0
        done

####
        srun -p ty_normal -n 1 -N 1 -c 8 --gres=dcu:1 python ../../PyKernel/FqJudge.py ini.xtc ini_.gro $dt ${SYSdir} >tau.dat
        tau=$(cat tau.dat)
        if [ $tau != 0 ]
        then
            #srun -p ty_normal -n 1 -N 1 -c 8 --gres=dcu:1 python ../../PyKernel/CompareTaute.py -tau $tau -w 1.5 >flag.dat
            #flag=$(cat flag.dat)
            flag=$(python ../../PyKernel/CompareTaute.py -tau $tau -w 1.5)
        else
            flag=0
        fi
        if [ $flag != 1 ]
        then 
            T=`expr ${T} + 200`
            count=`expr $count + 1`
            rm -f $file
        fi
    done
    de=`expr $count \* 10`
    T1=`expr ${T} - 1 \* $de`
    T2=`expr ${T} - 2 \* $de`
    T3=`expr ${T} - 3 \* $de`
    T4=`expr ${T} - 4 \* $de`
    T5=`expr ${T} - 5 \* $de`
    T6=`expr ${T} - 6 \* $de`
    T7=`expr ${T} - 7 \* $de`
    T8=`expr ${T} - 8 \* $de`
    srun -p ty_normal -n 1 -N 1 -c 8 --gres=dcu:1 python ../../PyKernel/Int2Float.py -T $T $T1 $T2 $T3 $T4 $T5 $T6 $T7 $T8 >T_next.dat
    IFS=' ' read -r -a T_next <<< $(cat T_next.dat)
    T_list_g[0]=$T
    tau_g[0]=$tau
    mv ini_.gro ../ini_.gro
    cd ../../
}


## function main: < gro MC_traj.py top 
main() {
    cd Run_Data
    srun -p ty_normal -n 1 -N 1 -c 8 --gres=dcu:1 python ../PyKernel/FindNid.py -gro ini.gro -info sys.info >SYSdir.dat
    SYSdir=$(cat SYSdir.dat)
    mkdir trial
    mkdir VFT
    cd ..
    T_list_g=()
    T_next=()
    tau_g=()
    echo "---------------------------------------  Here we go!  -----------------------------------"
    INI_TRIAL  ## >> T_next T_list_g tau_g
    #ws=(1.5 2.5 3 4)
    for n_window in {1..4}
    do
        if [ $n_window -lt 4 ]
        then
            n_points=8
        else
            n_points=4
        fi
        if [ $n_window -lt 3 ]
        then
            dt=0.5
        else
            dt=50
        fi
        if [ $n_window == 1 ]
        then
            n_window=1.5
        fi
        if [ $n_window == 2 ]
        then
            n_window=2.5
            dt=5
        fi
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
        VFT $n_window
        echo "*****************************   VFT fitting is done!   ***************************"
        echo ${T_next[@]}
        T_list=()
        echo "---------------------------------  This program will go to next loop.  -------------------------------"
    done
}
main
