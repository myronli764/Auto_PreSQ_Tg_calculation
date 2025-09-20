import os
import numpy as np
from math import log
from sys import argv
def Temdown(Tini,Tend):
    f = open('../../model.mdp','r')
    lines = f.readlines()
    f.close()
    f = open('quickanneal.mdp','w')
    for line in lines:
        l = line.split()
        if l[0] == 'nsteps':
            f.write('nsteps     = 160000\n')
        elif l[0] == 'annealing_temp':
            f.write(f"annealing_temp = {Tini} {Tend}\n")
        elif l[0] == 'ref_t':
            f.write(f"ref_t    =   {Tend}\n")
        else :
            f.write(line)
    return 0
Temdown(argv[1],argv[2])


