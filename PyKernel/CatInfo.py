import numpy as np
import os

aidir = os.listdir('.')
#print(aidir)
T_list_l=''
tau_l=''
T_=[]
tau_=[]
for i in aidir:
    if os.path.isdir(i):
        if i !='confi':
            T_.append(float(i))

T_.sort(reverse=True)
for T in T_:
    f=open(str(T)+'/tau.txt','r')
    tau=f.readlines()
    tau_.append(' ' + tau[0][:-1])
for n,T in enumerate(T_):
    T_list_l += ' ' + str(T)
    tau_l += tau_[n]
if len(T_)<=4:
    T_list_l += ' 0 0 0 0'
    tau_l +=  ' 0 0 0 0'

string=T_list_l + ',' + tau_l
print(string)


