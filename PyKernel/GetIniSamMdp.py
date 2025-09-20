from sys import argv

def write_mdp(T):
    f = open('../model.mdp', 'r')
    lines = f.readlines()
    f.close()
    f1 = open('trial_sam.mdp', 'w')
    for line in lines:
        l = line.split()
        if l[0] == 'nsteps':
            f1.write('nsteps     = 100000\n')
            #f1.write('nsteps     = 10000\n')
        elif l[0] == 'annealing':
            f1.write("annealing = no\n")
        elif l[0] == 'ref_t':
            f1.write(f'ref_t    =   {T}\n')
        elif l[0] == 'Pcoupl':
            f1.write('Pcoupl    = no')
        else:
            f1.write(line)
    return 0
write_mdp(argv[1])
