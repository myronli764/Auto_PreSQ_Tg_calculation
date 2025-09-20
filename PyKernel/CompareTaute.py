import argparse
from sys import argv
import numpy as np

parser = argparse.ArgumentParser(description='Compared the tau to the te equilibrium time')
parser.add_argument('-tau',dest='tau',type=float,help='The relaxation time tau of the molecule')
parser.add_argument('-w',dest='w',type=float,help='The id of windows')
args = parser.parse_args()
tau = args.tau
w = args.w
te = 10**w
if tau <= te:
    print(1)
else :
    print(0)

