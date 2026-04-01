import numpy as np
import MDAnalysis as mda
import time
import math
import pickle
from scipy.stats import circmean
from numba import jit
import tqdm

@jit(nopython=True)
def pbc(pos,boxl):
        return pos - boxl*np.rint(pos/boxl)

def MassCenter(mass_weight,pos,boxl):
        return np.sum(mass_weight*pbc(pos,boxl),axis = 0)/np.sum(mass_weight)

def cmean(x,box):
        return np.arctan2(np.mean(np.sin(x/box*np.pi),axis=-2), np.mean(np.cos(x/box*np.pi),axis=-2))*box/np.pi

#@jit()
def MassCenter_trj_(gro,traj,boxl):
        start = time.time()
        f = open(gro,'r')
        lines = f.readlines()
        f.close()
        n_frames = len(traj)
        N_MC = 1200
        mass_at = {'C':12,'O':16,'H':1,'N':14}
        mass_weight = np.zeros((47,1))
        traj_MC = np.zeros((n_frames,N_MC,3))
        for n,i in enumerate(lines[2:49]):
                info = i.split()
                at = info[1][0]
                mass_weight[n-2] = mass_at[at]
        for frame in range(n_frames):
                for n in range(60):
                        for i in range(20):
                                gobal_id = i + n*20
                                MC_pos = MassCenter(mass_weight,traj[frame][n*282+gobal_id*47:n*282+(gobal_id+1)*47],boxl)
                                traj_MC[frame][gobal_id] = MC_pos
        #print('Generating trajectory of MC in {}s'.format(time.time()-start))
        return traj_MC
def MassCenter_trj(traj,boxl,Nidpath):
        Nid = pickle.load(open(Nidpath,'rb'))
        cl = Nid['cl']
        Ns = Nid['N_per_mono']
        #print(Ns)
        num_monomer = int(Nid['bool'].sum()/Ns)
        n_frames = len(traj) 
        traj_N = np.zeros((n_frames,np.sum(Nid['bool']),3))
        for i,f in enumerate(traj):
                #print(np.asarray(f).shape,Nid['bool'].shape)
                traj_N[i] = f[Nid['bool']]
        traj_MC = cmean(traj_N.reshape(n_frames,-1,cl,Ns,3),boxl)
        traj_MC = traj_N.reshape(n_frames,-1,3)
        return traj_MC


def MC_trajectory(xtc,tpr):
        u = mda.Universe(xtc,tpr)
        ags = u.atoms.split('residue')
        ag_nh = []
        for ag in ags:
                if ag.atoms[0].mass < 2:
                        continue
                ag_nh.append(ag)
        N = len(ag_nh)
        ag_nh_mono = []
        for i in range(int(N/2)):
                ag_nh_mono.append(ag_nh[i*2]+ag_nh[i*2+1])
        ag_nh = ag_nh_mono
        N = len(ag_nh)
        trajectory = u.trajectory
        n_frames = trajectory.n_frames
        traj_MC = np.zeros((n_frames,N,3))
        for i,f in tqdm.tqdm(enumerate(trajectory),total=n_frames):
                boxl = u.dimensions[:3]
                for j,ag in enumerate(ag_nh):
                        #traj_MC[i][j] = ag.center_of_mass(unwrap=True)
                        traj_MC[i][j] = cmean(ag.positions,boxl)
        #print(traj_MC)
        return traj_MC








