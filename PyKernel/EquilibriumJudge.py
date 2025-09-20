import scipy.optimize as op
import numpy as np
import mdtraj as md
from scipy import interpolate

def f(x,tau,beta):
    return np.exp(-(x/tau)**beta)
def Stretchexp(xtc,gro,dt,Nidpath):
    import MC_trj as mct
    import in_sca
    dt=float(dt)
    traj = md.load(xtc,top=gro)
    trj = np.array(traj.xyz)
    box = traj.unitcell_lengths
    boxl = box[-1]
    traj_MC = mct.MassCenter_trj(trj,boxl,Nidpath)
    n_frames = len(traj_MC)
    n_par = len(traj_MC[0])
    beta = []
    #we set q equal to 7 default
    #def f(x,A,tau,beta):
    #    return A*np.exp(-(x/tau)**beta)
    for bframe in range(11,16):
        if bframe > n_frames:
            bframe = None
        ret = in_sca.incoherrent_scattering(traj_MC[bframe:],7,[2*np.pi/boxl[0],2*np.pi/boxl[1],2*np.pi/boxl[2]],rtol=1e-2)
        Fq = np.abs(np.sum(ret[0],axis=-1) / n_par)
        t = np.arange(Fq.shape[0])*dt
        sigma=np.ones(len(t))
        tau,b = op.curve_fit(f,Fq,t,sigma=sigma, absolute_sigma=True,  bounds=([0, 100], [100, 400]))[0]
        beta.append(b)
    np.savetxt('Fq__.txt',np.vstack((t,Fq)).T)
    beta = np.array(beta)
    if np.std(beta,axis=-1)<=0.05 and Fq[-1] <= 0.368:
        return 0
    else :
        return 0

def Fq_tau_calc(xtc,gro,dt,Nidpath):
    import MC_trj as mct
    import in_sca
    dt=float(dt)
    traj = md.load(xtc,top=gro)
    trj = np.array(traj.xyz)
    box = traj.unitcell_lengths
    boxl = box[-1]
    traj_MC = mct.MassCenter_trj(trj,boxl,Nidpath)
    n_frames = len(traj_MC)
    n_par = len(traj_MC[0])
    ret= in_sca.incoherrent_scattering(traj_MC,7,[2*np.pi/boxl[0],2*np.pi/boxl[1],2*np.pi/boxl[2]],rtol=1e-2)
    Fq = np.abs(np.sum(ret[0],axis=-1) / n_par)
    t = np.arange(Fq.shape[0])*dt
    fi = interpolate.interp1d(t,Fq)
    t_ = np.arange(t[0],t[-1],0.1)
    Fq_ = fi(t_)
    np.savetxt('Fq.txt',np.vstack([t_,Fq_]).T)
    for n,Fqi in enumerate(Fq_):
        if Fqi <= 0.368 and n != 0:
             tau = t_[n]
             np.savetxt('tau.txt',np.array([tau]),fmt='%6.6f')
             return tau
    return 0





