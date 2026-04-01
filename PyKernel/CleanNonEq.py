from sys import argv
import os
import shutil
import argparse

parser = argparse.ArgumentParser(description='fuck')

parser.add_argument('-Teq',dest='Teq',type=str,nargs='+')

args = parser.parse_args()

T_eq = args.Teq

#n_T_eq=int(argv[1])
#T_eq=[]
#for i in range(2,n_T_eq+2):
#    T_eq.append(str(argv[i]))

for i in os.listdir('.'):
    if os.path.isdir(i):
        if i not in T_eq and i != 'confi':
            shutil.rmtree(i,ignore_errors=True)

