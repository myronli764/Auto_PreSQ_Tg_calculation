import MC_trj as mct
import mdtraj as md
import in_sca
from sys import argv
import xml.etree.ElementTree as ET
import numba as nb
import numpy as np
tree = ET.parse(argv[3])
root = tree.getroot()


xtc = argv[1]
gro = argv[2]

def pbc(x,box):
    return x - box* np.rint(x/box)
#pre_para = np.loadtxt(pre_)
traj = md.load(xtc,top=gro)
trj = np.array(traj.xyz)*0.1
box = traj.unitcell_lengths
boxl = box[-1]*0.1
traj_MC = mct.MassCenter_trj(trj,boxl,'sq_test/Nid.pkl')
#@nb.jit(nopython=True)
def p2txt(p):
    string = '\n'
    for _ in p:
        string += f'{_[0]}  {_[1]}  {_[2]}\n'
    return string
flag = 0
import tqdm
for frame in tqdm.tqdm(traj_MC,total=trj.shape[0]):
    tree = ET.parse(argv[3])
    root = tree.getroot()
    position = root[0][1]
    frame = pbc(np.mod(frame,boxl)-boxl/2,boxl)
    box = root[0][0]
    box.attrib['lx'] = str(boxl[0])
    box.attrib['ly'] = str(boxl[0])
    box.attrib['lz'] = str(boxl[0])
    s = p2txt(frame)
    position.text = s
    tree.write(f'sq_test/{flag:0>3d}.xml')
    flag += 1
    if flag >= 400:
        break


