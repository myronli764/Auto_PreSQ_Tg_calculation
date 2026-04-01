import numpy as np
from sys import argv
import argparse

#parser = argparse.ArgumentParser(description='check the T point')
#
#parser.add_argument('-T',dest='T',type=float)
#parser.add_argument('-tau',dest='tau',type=float)

#args = parser.parse_args()


T=[]
tau=[]
for i in range(1,9):
    T.append(float(argv[i]))
    tau.append(float(argv[i+8]))
te=10*10**float(argv[17])

def WinCheck(T,tau):
    if T[4] == 0:
        T=T[:4]
        tau=tau[:4]
        n_points=4
    else:
        n_points=8
    flag=[]
    for n,i in enumerate(tau):
        if 10*i > te :
            flag.append(n)
    if flag == []:
        return 1
    N_noneq=len(flag)
    N_eq=len(T)-N_noneq
    Tini=T[0]
    Tend=T[N_eq - 1]
    if N_eq == 0:
        Tend = T[N_eq]
    delta_T=(Tini-Tend)/(N_noneq+1)
    if delta_T > 15:
        delta_T = 5
    T_eq=""
    T_addi=""
    shift = 2.5
    for i in range(n_points):
        if i in flag:
            T_addi += f'{-delta_T*(i-N_eq+1)+Tini+shift:.1f} '
        else :
            T_eq += str(T[i]) + ' '
    return T_eq[:-1] + ',' + T_addi[:-1]

print(WinCheck(T,tau))
