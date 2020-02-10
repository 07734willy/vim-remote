from argparse import ArgumentParser
import pdb
import sys
import json


def set_breaks(debugger, breakpoints):
	breakpoints = json.loads(breakpoints)
	for filepath, linenos in breakpoints.items():
		for lineno in linenos:
			debugger.set_break(filepath, lineno)

def main():
	parser = ArgumentParser()
	parser.add_argument('--file', type=str)
	parser.add_argument('--arg1', type=str)
	parser.add_argument('--arg2', type=str)
	parser.add_argument('breakpoints', type=str)
	
	args = parser.parse_args()
	
	debugger = pdb.Pdb()
	set_breaks(debugger, args.breakpoints)
	
	print(args.file, args.arg1, args.arg2)
	input("paused, press any key to continue")
	print(args.breakpoints)


if __name__ == "__main__":
	main()
