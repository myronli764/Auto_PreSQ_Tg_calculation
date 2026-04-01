import numpy as np
import mdtraj as md
import scipy
import MC_trj as mct
from sys import argv

xtc = argv[1]
gro = argv[2]
nid = argv[3]
traj = md.load(xtc,top=gro)
trj = np.array(traj.xyz)*0.1
box = traj.unitcell_lengths
boxl = box[-1]*0.1
traj_MC = mct.MassCenter_trj(trj,boxl,nid)



