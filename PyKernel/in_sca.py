import math
import time
from cmath import exp
import matplotlib.pyplot as plt
import numba as nb
import numpy as np
import tqdm
from numba import float64, complex128, cuda


@nb.jit(nopython=True,nogil=True)
def pbc(x,l):
    return x - l*np.rint(x/l)

@nb.jit(nopython=True, nogil=True)
def _q_vec(n_q, mid, q, dq, rtol=1e-2):
    ret = []
    for q_ary in np.ndindex(n_q):
        q_tmp = 0
        i = 0
        for qi in q_ary:
            q_tmp += ((qi - mid[i]) * dq[i]) ** 2
            i += 1
        q_tmp = q_tmp ** 0.5
        if abs(q_tmp - q) / q < rtol:
            ret.append(q_ary)
    return ret


@nb.guvectorize([(float64[:, :], float64[:, :], complex128[:])],
                '(n, p),(m, p)->(n)', target='parallel')
def exp_iqr(a, b, ret):
    for i in range(a.shape[0]):
        tmp = 0
        for j in range(b.shape[0]):
            prod = 0
            for k in range(b.shape[1]):
                prod += a[i, k] * b[j, k]
            tmp += exp(-1j * prod)
        ret[i] = tmp
@nb.guvectorize([(float64[:, :], float64[:, :], complex128[:, :])],
                '(n, p),(m, p)->(n, m)', target='parallel')
def exp_iqr1(a, b, ret):
    for i in range(a.shape[0]):
        for j in range(b.shape[0]):
            prod = 0
            for k in range(b.shape[1]):
                prod += a[i, k] * b[j, k]
            ret[i, j] = exp(-1j *prod)


@cuda.jit
def exp_iqr_cuda(a, b, out):
    t = cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x
    T = a.shape[0]
    N = a.shape[1]
    # only valid threads do work
    if t >= T:
        return

    # we will accumulate a complex128 in two float64 parts
    real_acc = 0.0
    imag_acc = 0.0

    # b has shape (1,3) so element is b[0,k]
    for j in range(N):
        # dot product a[t,j,:] · b[0,:]
        prod = 0.0
        prod += a[t, j, 0] * b[0, 0]
        prod += a[t, j, 1] * b[0, 1]
        prod += a[t, j, 2] * b[0, 2]

        # exp(-i * prod) = cos(prod) - i sin(prod)
        c = math.cos(prod)
        s = math.sin(prod)
        real_acc += c
        imag_acc -= s     # minus because e^{-i x} = cos x - i sin x

    # write back a complex128
    out[t, j] = complex(real_acc, imag_acc)


# Host side code
def compute_gpu(a_host, b_host):
    # shape checks omitted for brevity
    T, N, _ = a_host.shape

    # allocate on device
    a_dev = cuda.to_device(a_host)
    b_dev = cuda.to_device(b_host)
    out_dev = cuda.device_array((T,N), dtype=np.complex128)

    # choose a block / grid size
    threads_per_block = 128
    blocks_per_grid = (T + threads_per_block - 1) // threads_per_block

    # launch
    exp_iqr_cuda[blocks_per_grid, threads_per_block](a_dev, b_dev, out_dev)

    # copy back
    return out_dev.copy_to_host()


def incoherrent_scattering(traj, q=None, dq=None, rtol=1e-3, q_vectors=None):
    n_dim = traj.shape[-1]
    s = time.time()
    q_vecs = q_vectors
    if q_vecs is None:
        if q is None or dq is None:
            raise ValueError("q, dq or q_vectors should be given!")
        if isinstance(dq, float):
            dq = np.asarray([dq,] * n_dim)
        dq = np.asarray(dq)
        n_q = np.asarray(q / dq + 0.5, dtype=np.int64) * 2 # nyquist theorem
        mid = n_q // 2
        n_q = tuple(n_q)
        last_len = 1
        while True:
            qvi = _q_vec(n_q, mid, q, dq, rtol) # f**k one more time, ignore it
            this_len = len(qvi)
            if (0 < this_len < 1000) or (this_len > 0 and last_len == 0):
                break
            if this_len > 1000:
                rtol = rtol / 1.1
            elif this_len == 0:
                rtol = rtol * 1.1
            last_len = this_len
        q_vecs = (np.asarray(qvi, dtype=np.float64) - mid) * dq
        #print("Generating q vecs in %.6fs, processing with num of q vectors: %d" % (time.time() - s, q_vecs.shape[0]))
    n_frames = traj.shape[0]
    corr = np.zeros((n_frames, traj.shape[1]), dtype=np.complex128)
    #if q_vecs.shape[0] > 1500:
    #    raise ValueError(f"Too many q vectors! {q_vecs.shape[0]} > 1500")
    i = 0
    #for q_vec in tqdm.tqdm(q_vecs, desc="Processing with Q vectors", unit=r"Q vectors", ncols=100):
    #    #print(traj.shape,q_vec.shape)
    #    #traj_tmp = compute_gpu(traj, np.array([q_vec]))
    #    #print('cuda',corr.shape, traj_tmp.shape)
    #    s = time.time()
    #    traj_tmp = exp_iqr(traj, [q_vec])
    #    print(time.time()-s)
    #    #print('guvec',corr.shape, traj_tmp.shape)
    #    s = time.time()
    #    corr = corr + np.fft.ifft(np.abs(np.fft.fft(traj_tmp, axis=0, n=2 * n_frames)) ** 2,
    #                              axis=0, n=2 * n_frames)[:n_frames]
    #    #print('1',time.time()-s)
    #    if i == 0:
    #        print(corr[0])
    #        break
    traj = exp_iqr(traj, q_vecs)
    corr = np.fft.ifft(np.abs(np.fft.fft(traj, axis=0, n=2*n_frames))**2, axis=0, n=2*n_frames)[:n_frames]
    #print(corr[0].sum(axis=1),q_vecs.shape[0])
    corr = corr / np.arange(n_frames, 0, -1)[:, None]
  
    return corr / q_vecs.shape[0], q_vecs

def DynamicStrfac_Fq(x,box,dt,qrange=(5,12),dq=1,types=[]):
    bl = box.mean()
    frames, nbeads, _ = x.shape
    #xM = pbc(x.reshape(frames,-1,2,3).mean(axis=-2).reshape(frames,-1,3),box.reshape(-1,1,3))
    #print(x.shape,box.shape)
    #x = pbc(x,box.reshape(-1,1,3))
    #xA = x[:,types=='A',:]
    #xB = x[:,types=='B',:]

    #_, nA, __ = xA.shape
    #_, nB, __ = xB.shape
    #_, nM, __ = xM.shape
    _, nM, __ = x.shape
    
    #FqA = {}
    #FqB = {}
    FqM = {}

    qr = np.arange(qrange[0],qrange[1],dq)
    #q = 3
    t = np.arange(frames)*dt
    #FqA[q] = np.vstack((t,np.abs(np.sum(incoherrent_scattering(xA,q,[2*np.pi/bl,2*np.pi/bl,2*np.pi/bl],rtol=1e-2)[0],axis=-1) / nA)))
    for q in tqdm.tqdm(qr,total=len(qr)):
        #FqA[q] = np.vstack((t,np.abs(np.sum(incoherrent_scattering(xA,q,[2*np.pi/bl,2*np.pi/bl,2*np.pi/bl],rtol=1e-2)[0],axis=-1) / nA)))
        #FqB[q] = np.vstack((t,np.abs(np.sum(incoherrent_scattering(xB,q,[2*np.pi/bl,2*np.pi/bl,2*np.pi/bl],rtol=1e-2)[0],axis=-1) / nB)))
        #print([2*np.pi/bl,2*np.pi/bl,2*np.pi/bl])
        FqM[q] = np.vstack((t,np.abs(np.sum(incoherrent_scattering(x,q,[2*np.pi/bl,2*np.pi/bl,2*np.pi/bl],rtol=1e-2)[0],axis=-1) / nM)))
        FqM[q][1] = FqM[q][1]/FqM[q][1][0]
    return FqM

