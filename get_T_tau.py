import os
import numpy as np

workdir = 'Run_Data'
dirs = os.listdir(workdir)
Ts = []
taus = []
for d in dirs:
    if not os.path.isdir(os.path.join(workdir,d)):
        continue
    if 'windows' in d:
        T_dirs = os.listdir(os.path.join(workdir,d))
        for T in T_dirs:
            if not os.path.isdir(os.path.join(workdir,d,T)):
                continue
            if T == 'confi':
                continue
            if not os.path.exists(os.path.join(workdir,d,T,'tau.txt')):
                continue
            Ts.append(float(T))
            tau = float(open(os.path.join(workdir,d,T,'tau.txt'),'r').read()[:-1])
            taus.append(tau)
data = {}
for T,tau in zip(Ts,taus):
    data[T] = tau
sorted_T = sorted(data.keys(),reverse=True)
sorted_taus = [data[T] for T in sorted_T]

print('declare -a T_list_g=('+' '.join([f'[{i}]="{T}"' for i,T in enumerate(sorted_T)])+')')
print('declare -a tau_g=('+' '.join([f'[{i}]="{tau}"' for i,tau in enumerate(sorted_taus)])+')')
