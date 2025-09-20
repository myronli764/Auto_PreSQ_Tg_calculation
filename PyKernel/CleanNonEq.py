from sys import argv
import os
import shutil
import argparse

parser = argparse.ArgumentParser(description='Clean All None-Equlibrium Tempreture Points')
parser.add_argument('-n',dest='n',type=int)
parser.add_argument('-Teq',dest='eq',nargs='+',type=str)
args = parser.parse_args()
n_T_eq=args.n
T_eq=args.eq
#for i in range(2,n_T_eq+2):
#    T_eq.append(str(argv[i]))
for i in os.listdir('.'):
    if os.path.isdir(i):
        if i not in T_eq and i != 'confi':
            shutil.rmtree(i,ignore_errors=True)

