import numpy as np
import time
import math
import pickle
from scipy.stats import circmean

def pbc(pos,boxl):
        return pos - boxl*np.rint(pos/boxl)

def MassCenter(mass_weight,pos,boxl):
        return np.sum(mass_weight*pbc(pos,boxl),axis = 0)/np.sum(mass_weight)

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
        n_frames = len(traj)
        traj_N = np.zeros((n_frames,np.sum(Nid['bool']),3))
        for i,f in enumerate(traj):
                traj_N[i] = f[Nid['bool']]
        traj_MC = circmean(traj_N.reshape(n_frames,-1,2,3),high = boxl,low=0,axis = -2)
        return traj_MC







