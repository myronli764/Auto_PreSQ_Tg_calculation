import os
import numpy as np

path = os.path.abspath('.')
Rpath = os.path.join(path,'Run_Data')
dirs_ = os.listdir(Rpath)
wdirs = []
for d in dirs_:
    d = os.path.join(Rpath,d)
    if os.path.isdir(d):
        if 'windows' in d:
            wdirs.append(d)
T_tau = {}
T_g = []
for d in wdirs:
    dirs = os.listdir(d)
    for dd in dirs:
        dd_ = os.path.join(d,dd)
        if os.path.isdir(dd_):
            if 'confi' not in dd:
                T = float(dd)
                dT = dd_
                dtau = os.path.join(dT,'tau.txt')
                tau = open(dtau,'r').read().split('\n')[0]
                T_g.append(T)
                T_tau[T] = tau
T_g.sort(reverse=True)
tau_g = [T_tau[T] for T in T_g]
T_g = [str(T) for T in T_g]
sT_g = ' '.join(T_g)
stau_g = ' '.join(tau_g)
print(sT_g+', '+stau_g)



