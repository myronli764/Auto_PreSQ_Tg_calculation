import numpy as np
from sys import argv
import argparse

parser = argparse.ArgumentParser(description='check the T point')

parser.add_argument('-T',dest='T',type=float,nargs='+')
parser.add_argument('-tau',dest='tau',type=float,nargs='+')
parser.add_argument('-nwin',dest='nwin',type=float)

args = parser.parse_args()

T=args.T
tau=args.tau
nwin=args.nwin

#for i in range(1,9):
#    T.append(float(argv[i]))
#    tau.append(float(argv[i+8]))
te=10*10**nwin

def WinCheck(T,tau):
    #if T[4] == 0:
    #    T=T[:4]
    #    tau=tau[:4]
    #    n_points=4
    #else:
    #    n_points=8
    n_points=len(T)
    flag=[]
    for n,i in enumerate(tau):
        if 10*i > te :
            flag.append(n)
    if flag == []:
        return 1
    N_noneq=len(flag)
    N_eq=len(T)-N_noneq
    _delta = T[0] - T[1]
    Tini= T[0]+_delta
    Tend=T[N_eq - 1]
    if N_eq == 0:
        Tend = T[N_eq]
    delta_T=(Tini-Tend)/(N_noneq+1)
    delta_T_ = 0
    if delta_T > 20:
        delta_T_ = 10
        if nwin ==4:
            if delta_T > 15:
                delta_T_ = 5
    if delta_T_ == 0:
        delta_T_ = delta_T
    delta_T = delta_T_
    T_eq=""
    T_addi=""
    shift = 2.5
    for i in range(n_points):
        if i in flag:
            T_addi += f'{-delta_T*(i-N_eq+1)+Tini+shift:.1f} '
        else :
            T_eq += str(T[i]) + ' '
    if T_eq == '':
        T_eq = T_addi.split(' ')[0] + ' '
    return T_eq[:-1] + ',' + T_addi[:-1]

print(WinCheck(T,tau))
