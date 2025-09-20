import numpy as np
import pickle
from sys import argv
import argparse

parser = argparse.ArgumentParser(description='find Nid of the polymer')

parser.add_argument('-gro',dest='gro',help='GRO File')
parser.add_argument('-info',dest='info',help='INFO File, system information')

args = parser.parse_args()

gro = args.gro
info = args.info

f = open(info,'r')
info_ = f.readlines()
N_per_mono = int(info_[0].split()[-1])
Num_mono_per_Chain = int(info_[0].split()[-1])
f.close()
f = open(gro,'r')
lines = f.readlines()[2:-1]
num = len(lines)
Nid = {}
Nid_bool = np.zeros((num,)) == 1
Nid['N_per_mono'] = N_per_mono
for i,l in enumerate(lines):
    data=l.split()
    if data[1][0] == 'N':
        Nid_bool[i] = True
Nid ['bool'] = Nid_bool
Nid['cl'] = Num_mono_per_Chain
import os
print(os.path.join(os.getcwd(),'Nid.pkl'))
pickle.dump(Nid,open('Nid.pkl','wb'))
