from sys import argv
import argparse

parser = argparse.ArgumentParser(description='Get energy minimization mdp file.')

parser.add_argument('-emtol',dest='emtol',type=int)
parser.add_argument('-iter',dest='i',type=int)
parser.add_argument('-dt',dest='dt',type=float)

args = parser.parse_args()

emtol = args.emtol
i = args.i
dt = args.dt
if dt is None:
    dt = 0.01
smdp = f'''
integrator = steep
nsteps            = 50000
emtol         = {emtol}  ;
emstep            = {dt} ; 100ns

nstcomm         = 100
comm-grps  = system
energygrps =
;
nstxout = 10000
;nstvout = 10000
;nstfout = 10000
nstlog  = 10000
nstenergy = 1000000
nstxout-compressed = 1000
compressed-x-grps  = system
;
annealing = no
annealing_npoints = 4
annealing_time = 0 1000 90000 100000
annealing_temp = 300 1000 500 463
;
pbc = xyz
cutoff-scheme = Verlet
coulombtype   = PME
rcoulomb      = 0.5
fourierspacing= 0.12
pme-order     = 4
vdwtype       = cut-off
rvdw          = 0.5
DispCorr      = EnerPres

constraints = none
'''
f = open(f'em{i}.mdp','w')
f.write(smdp)
f.close()
