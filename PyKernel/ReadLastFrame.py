from sys import argv
f = open(argv[1],'r')
lines = f.readlines()
line = (lines[-1].split())[0]
print(float(line))
