import argparse
from sys import argv

parser = argparse.ArgumentParser(description='Turn bash script int value to float value')
parser.add_argument('-T',dest='T',nargs='+',type=float,help='Int data to convert')
args = parser.parse_args()
T = args.T
string=''
for i in T:
    string += f' {i:.1f}'
print(string)
