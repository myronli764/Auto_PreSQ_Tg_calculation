import os
import numpy as np
from math import log
def Temdown(Tini,Tend,n):
    f = open('model.mdp','r')
    lines = f.readlines()
    f.close()
    f = open('anneal.mdp','w')
    for line in lines:
        l = line.split()
        if l[0] == 'nsteps':
            f.write('nsteps     = 160000\n')
            #f.write('nsteps     = 10000\n')
        elif l[0] == 'annealing_temp':
            f.write(f"annealing_temp = {Tini} {Tend}\n")
        elif l[0] == 'ref_t':
            f.write(f"ref_t    =   {Tini}\n")
        else :
            f.write(line)
    if not os.path.exists(f'windows{n}'):
        os.system(f'mkdir windows{n}')
    os.system(f'mv anneal.mdp windows{n}')
    return f'windows{n}'

#default annealing time is 16 ps
def Run_out(T,n):
    def write_mdp(n,T):
        f = open('../model.mdp', 'r')
        lines = f.readlines()
        #os.system('cd {}'.format(T))
        f.close()
        f1 = open(f'npt.mdp', 'w')
        f2 = open(f'nvt.mdp', 'w')
        for line in lines:
            l = line.split()
            if l[0] == 'nsteps':
                f1.write(f'nsteps     = {int(10*10**n*1000)}\n')
                f2.write(f'nsteps     = 100000000\n')
                #f1.write(f'nsteps     = {10000}\n')
                #f2.write(f'nsteps     = 10000\n')
            elif l[0] == 'annealing':
                f1.write(f"annealing = no\n")
                f2.write(f"annealing = no\n")
            elif l[0] == 'ref_t':
                f1.write(f"ref_t    =   {T}\n")
                f2.write(f"ref_t    =   {T}\n")
            elif l[0] == 'Pcoupl':
                f1.write(line)
                f2.write('Pcoupl = no\n')
            elif l[0] == 'nstxout-compressed':
                if n < 2:
                    f1.write(line)
                    f2.write(line)
                elif n == 2.5 :
                    f1.write('nstxout-compressed     = 5000\n')
                    f2.write('nstxout-compressed     = 5000\n')
                elif n >= 3:
                    f1.write('nstxout-compressed     = 50000\n')
                    f2.write('nstxout-compressed     = 50000\n')
            elif l[0] == 'nstenergy':
                if n < 2:
                    f1.write(line)
                    f2.write(line)
                elif n == 2.5 :
                    f1.write('nstenergy     = 5000\n')
                    f2.write('nstenergy     = 5000\n')
                elif n >= 3:
                    f1.write('nstenergy     = 50000\n')
                    f2.write('nstenergy     = 50000\n')
            else:
                f1.write(line)
                f2.write(line)
    T=float(T)
    if not os.path.exists(f'{T}'):
        os.system(f'mkdir {float(T):.1f}')
    write_mdp(float(n),float(T))
    os.system(f'mv npt.mdp nvt.mdp {T:.1f}')
    return 0


