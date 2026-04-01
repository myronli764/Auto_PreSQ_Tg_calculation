from sys import argv
import argparse

parser = argparse.ArgumentParser(description='Get mdrun mdp file.')

parser.add_argument('-inte',dest='inte',type=str)
parser.add_argument('-dt',dest='dt',type=float)
parser.add_argument('-iter',dest='i',type=int)
parser.add_argument('-nsteps',dest='n',type=int)

args = parser.parse_args()

integrator = args.inte
dt = args.dt
i = args.i
n = args.n
if float(dt) < 0.0008:
    cc = 2e-5
else:
    cc = 4e-5
f = open(f'eq{i}_{integrator}.mdp','w')
sbd = f'''
integrator = bd
dt         = {dt}  ; fs
nsteps     = 100000 ; 100ns
comm-grps  = system
energygrps =
;
nstxout = 0
nstvout = 0
nstfout = 0
nstlog  = 1000
nstenergy = 1000
nstxout-compressed = 10000
compressed-x-grps  = system
;
annealing = no;single
annealing_npoints = 3
annealing_time = 0 2000 41000; 100000
annealing_temp = 920 900 900; 463
;
pbc = xyz
cutoff-scheme = Verlet
coulombtype   = PME
rcoulomb      = 1.0
fourierspacing= 0.12
pme-order     = 4
vdwtype       = cut-off
rvdw          = 1.0
DispCorr      = EnerPres
;
Tcoupl  = no;Berendsen
tau_t   = 0.5
tc_grps = system
ref_t   = 1000
bd-fric = 0
ld-seed = 0
;
Pcoupl     = no;Berendsen
pcoupltype = isotropic
tau_p = 5.0
ref_p = 1.0
compressibility = 4.5e-4
;
gen_vel  = no
gen_temp = 1000
gen_seed = -1
;
freezegrps  =
freezedim   =
constraints = none

'''

smd = f'''
define =
integrator = md
dt         = {dt}  ; fs
nsteps     = {n} ; 100ns
comm-grps  = system
energygrps =
;
nstxout = 0
nstvout = 0
nstfout = 0
nstlog  = 1000
nstenergy = 1000
nstxout-compressed = 10000
compressed-x-grps  = system
;
annealing = no;single
annealing_npoints = 3
annealing_time = 0 2000 41000; 100000
annealing_temp = 920 900 900; 463
;
pbc = xyz
cutoff-scheme = Verlet
coulombtype   = PME
rcoulomb      = 1.0
fourierspacing= 0.12
pme-order     = 4
vdwtype       = cut-off
rvdw          = 1.0
DispCorr      = EnerPres
;
Tcoupl  = Berendsen
tau_t   = 0.5
tc_grps = system
ref_t   = 1000

Pcoupl     = Berendsen
pcoupltype = isotropic
tau_p = 3.0
ref_p = 1.0
compressibility = {cc}
;
gen_vel  = yes
gen_temp = 0
gen_seed = -1
;
freezegrps  =
freezedim   =
constraints = none

'''
if integrator == 'bd':
    f.write(sbd)
    f.close()
    #print(sbd)
elif integrator == 'md':
    f.write(smd)
    f.close()
    #print(smd)


