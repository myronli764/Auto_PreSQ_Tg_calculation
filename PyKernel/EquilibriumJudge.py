import scipy.optimize as op
import numpy as np
import mdtraj as md
from scipy import interpolate

def f(x,tau,beta):
    return np.exp(-(x/tau)**beta)
def Stretchexp(xtc,gro,tpr,dt,Nidpath,pre_):
    import MC_trj as mct
    import in_sca
    pre_para = np.loadtxt(pre_)
    dt=float(dt)
    traj = md.load(xtc,top=gro)
    trj = np.array(traj.xyz)
    box = traj.unitcell_lengths
    boxl = box[-1]
    #traj_MC = mct.MC_trajectory(tpr,xtc)
    #traj_MC = mct.MassCenter_trj(trj,boxl,Nidpath)
    traj_MC = trj
    n_frames = len(traj_MC)
    n_par = len(traj_MC[0])
    beta = []
    #we set q equal to 7 default
    #def f(x,A,tau,beta):
    #    return A*np.exp(-(x/tau)**beta)
    #for bframe in range(11,16):
    if 1:
        bframe = 10
        if bframe >= n_frames:
            bframe = None
        ret = in_sca.incoherrent_scattering(traj_MC[bframe:],12,[2*np.pi/boxl[0],2*np.pi/boxl[1],2*np.pi/boxl[2]],rtol=1e-2)
        Fq = np.abs(np.sum(ret[0],axis=-1) / n_par)
        t = np.arange(Fq.shape[0])*dt
        sigma=np.ones(len(t))
        tau,beta = op.curve_fit(f,Fq,t,sigma=sigma, absolute_sigma=True,  bounds=([0, 100], [100, 400]))[0]
    np.savetxt('Fq__.txt',np.vstack((t,Fq)).T)
    np.savetxt('curve_para.dat',np.array([tau,beta]))
    if ( (pre_para[0] - tau)**2 <=0.05 and (pre_para[1] - beta)**2 <=0.05 and Fq[-1] <= 0.368) or t[-1] >= 1e4:
        return 0
    else :
        return 0

def Fq_tau_calc(xtc,gro,tpr,dt,Nidpath):
    import MC_trj as mct
    import in_sca
    dt=float(dt)
    traj = md.load(xtc,top=gro)
    trj = np.array(traj.xyz)
    box = traj.unitcell_lengths
    boxl = box[-1]
    #traj_MC = mct.MC_trajectory(tpr,xtc)
    #traj_MC = mct.MassCenter_trj(trj,boxl,Nidpath)
    traj_MC = trj
    n_frames = len(traj_MC)
    n_par = len(traj_MC[0])
    ret= in_sca.incoherrent_scattering(traj_MC,12,[2*np.pi/boxl[0],2*np.pi/boxl[1],2*np.pi/boxl[2]],rtol=1e-2)
    Fq = np.abs(np.sum(ret[0],axis=-1) / n_par)
    t = np.arange(Fq.shape[0])*dt
    fi = interpolate.interp1d(t,Fq)
    t_ = np.arange(t[0],t[-1],0.1)
    Fq_ = fi(t_)
    np.savetxt('Fq.txt',np.vstack([t_,Fq_]).T)
    for n,Fqi in enumerate(Fq_):
        if (Fqi <= 0.368 and n != 0) or t_[n] >= 1e4+2:
             tau = t_[n]
             np.savetxt('tau.txt',np.array([tau]),fmt='%6.6f')
             #return 0
             return tau
    return 0





