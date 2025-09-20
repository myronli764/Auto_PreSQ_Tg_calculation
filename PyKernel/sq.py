import numpy as np
from numba import jit
#import matplotlib.pyplot as plt

def hist_vec_by_r(x, dr, r_bin, r_max, middle=None):
    # middle is the index of array x where the corresponding
    # position is zero vector.
    ret = np.zeros(int(r_max / r_bin) + 1, dtype=x.dtype)
    r_max2 = float(ret.shape[0] * r_bin) ** 2
    cter = np.zeros(ret.shape, dtype=np.float)
    if middle is None:
        middle = np.zeros(x.ndim, dtype=np.float)

    #@jit(nopython=True)
    @jit()
    def _func(x, dr, r_bin, r_max2, ret, cter, middle):
        for idx in np.ndindex(x.shape):
            rr = 0
            for jdx, m in zip(idx, middle):
                rr += ((jdx - m) * dr) ** 2
            if rr < r_max2:
                kdx = int(rr ** 0.5 / r_bin)
                ret[kdx] += x[idx]
                cter[kdx] += 1

    _func(x, dr, r_bin, r_max2, ret, cter, middle)
    cter[cter == 0] = 1
    return ret / cter


def scatter_sq(x, x_range=None, r_cut=0.5, q_bin=0.1, q_max=20.3, zero_padding=1, expand=0):
    # Using `x_range' rather than `box' for the unknown origin of the box
    box = np.array(np.array([_[1] - _[0] for _ in x_range]))
    bins = np.asarray(box / r_cut, dtype=np.int64)
    x_range = np.asarray(x_range)
    expand = np.asarray(expand)
    n_dim = x.shape[1]
    if x_range.shape[0] != n_dim:
        raise ValueError("Dimension of coordinates is %d and"
                         "dimension of x_range is %d" % (n_dim, x_range.shape[0]))
    if bins.ndim < 1:
        bins = np.asarray([bins] * n_dim)
    rho_x, _ = np.histogramdd(x, bins=bins, range=x_range)
    if expand.ndim < 1:
        expand = np.asarray([expand] * rho_x.ndim)
    z_bins = (np.asarray(rho_x.shape) * zero_padding).astype(np.int64)
    rho_x = np.pad(rho_x, [(0, _ * __) for _, __ in zip(rho_x.shape, expand)], 'wrap')
    z_bins = np.where(
        z_bins > np.asarray(rho_x.shape[0]), z_bins, np.asarray(rho_x.shape[0])
    )
    _rft_sq_x = np.fft.rfftn(rho_x, s=z_bins)
    _rft_sq_y = _rft_sq_x
    _rft_sq_xy = _rft_sq_x.conj() * _rft_sq_y  # circular correlation.
    fslice = tuple([slice(0, _) for _ in z_bins])
    lslice = np.arange(z_bins[-1] - z_bins[-1] // 2 - 1, 0, -1)
    pad_axes = [(0, 1)] * (n_dim - 1) + [(0, 0)]
    flip_axes = tuple(range(n_dim - 1))
    _sq_xy = np.concatenate(
        [_rft_sq_xy, np.flip(
            np.pad(_rft_sq_xy.conj(), pad_axes, 'wrap'), axis=flip_axes
        )[fslice][..., lslice]], axis=-1
    )
    _d = box / bins
    q0 = np.fft.fftfreq(_sq_xy.shape[0], _d[0])
    dq = q0[1] - q0[0]
    dq = dq * 2 * np.pi
    middle = np.asarray(_sq_xy.shape, dtype=np.float64) // 2
    _sq_xy = np.fft.fftshift(_sq_xy)
    return hist_vec_by_r(_sq_xy, dq, q_bin, q_max, middle=middle)
'''
x = np.random.random((100,3))
sq = scatter_sq(x, q_bin=0.1, r_cut=0.05, x_range=((0,1),(0,1),(0,1)))
q = np.arange(sq.shape[0]) * 0.1
plt.plot(q.T,sq.T)
plt.show()
'''
#print(np.vstack([q, sq]).T)