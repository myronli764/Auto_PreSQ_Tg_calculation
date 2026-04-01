import MDAnalysis as mda
from sys import argv
import argparse

parser = argparse.ArgumentParser(description='create the info of the system.')
parser.add_argument('-gro',dest='gro',type=str,help='gro file')

args = parser.parse_args()

gro = args.gro

u = mda.Universe(gro,gro)

atoms = u.atoms
ags = atoms.split('residue')
ag_nh = []
for ag in ags:
    if ag.atoms[0].type == 'H':
        continue
    ag_nh.append(ag)

num_monomers = int(len(ag_nh)/2)
cl = 8
A = ag_nh[0]
B = ag_nh[1]
c = 0
for a in A.atoms:
    if a.type == 'N':
        c +=1
for a in B.atoms:
    if a.type == 'N':
        c += 1
f = open('sys.info','w')
f.write(f'N_per_monomer {c}\ncl  {cl}')
