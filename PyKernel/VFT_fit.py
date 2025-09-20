import numpy as np
import matplotlib.pyplot as plt
import scipy.optimize as op
import math
from sys import argv
import os
import argparse 

parser = argparse.ArgumentParser(description='fuckkkkkk')
parser.add_argument('-T',dest='T',type=float,nargs='+',help='T global')
parser.add_argument('-tau',dest='tau',type=float,nargs='+',help='tau global')
parser.add_argument('-n',dest='n',type=float,help='n_window')
args = parser.parse_args()
# read data

x=args.T
y=args.tau
n_window=args.n

def VFT(T,tau,D,T0):
    return tau*np.exp(D*T0/(T-T0))
#print(x,'\n',y)
x3 = np.array(x)
y3 = np.array(y)

sigma_3 = np.ones(len(x3))*1
tau3,D3,T03 = op.curve_fit(VFT,x3,y3,sigma=sigma_3, absolute_sigma=True,  bounds=([1,1, 100], [10, 10, 400]))[0]
x_ = np.arange(-1050,-450,1)*-1
y_ = VFT(x_,tau3,D3,T03)
for i,t in enumerate(y_):
    if t>= 1e14:
        Tg=x_[i]
        break

#f=open('Tg.txt','a')
#f.write(f'{Tg}\n')
#f.close()
np.savetxt(f'T_tau_{n_window}.txt',np.vstack((x_,y_)).T)

if n_window!=2.5:
    t_=10**(n_window)
    t_next=t_*10
else :
    t_=10**(n_window)
    t_next=10**3

T_next=[]
for n,i in enumerate(y_):
    if i >= t_ and i <= t_next:
        T_next.append(x_[n])
np.savetxt('check_T_next.txt',np.array(T_next))
delta_T = T_next[-1] - x3[-1]
if n_window <=2.5:
    n_points_next = 8
else :
    n_points_next = 4
SF_T = delta_T/n_points_next
if SF_T < -30:
    SF_T = -15
T_ini=x[-1]
T_next = f''
for i in range(n_points_next+1):
    T_next += f' {T_ini + i*SF_T:.1f}'
print(T_next)
f=open('Tg.txt','a')
f.write(f'{Tg}\n')
f.close()




