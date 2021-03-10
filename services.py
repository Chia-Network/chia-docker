import argparse, subprocess

parser = argparse.ArgumentParser()

parser.add_argument("-p", "--plots", help="path to plot directory")
parser.add_argument("-k", "--keys", help="24 word key")
parser.add_argument("-harv", "--harvester", help="start harvester, boolean")
parser.add_argument("-f", "--farmer", help="farmer address")
args = parser.parse_args()


chiaCommand = subprocess.run(["chia start", args.plots, args.keys, args.harvester, args.farmer])
print("The exit code was: %d" % chiaCommand.returncode)
