f = open('em.mdp','w')
txts = '''
integrator = steep
nsteps            = 50000
emtol         = 800  ;
emstep            = 0.01 ; 100ns
nstcomm         = 100
comm-grps  = system
energygrps =
;
nstxout = 10000
nstvout = 10000
nstfout = 10000
nstlog  = 10000
nstenergy = 1000000
nstxout-compressed = 100000
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
rcoulomb      = 1.0
fourierspacing= 0.12
pme-order     = 4
vdwtype       = cut-off
rvdw          = 1.0
DispCorr      = EnerPres

constraints = none

'''
f.write(txts)
f.close()
