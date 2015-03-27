#!/usr/bin/python

# Created on: 2015.03.26 
# Author: Carlo Artieri

##############################
# HISTORY AND THINGS TO FIX  #
##############################
#2015.03.26 - Initial script
#			- Wrote script and tested it.

###########
# MODULES #
###########
import sys			#Access to simple command-line arguments
sys.path.append('/Users/carloartieri/bin/python') #Set python path for common functions
import argparse		#Access to long command-line parsing	
import datetime		#Access to calendar/clock functions
import re			#Access to REGEX splitting
import math			#Access to math functions
import subprocess	#Access to external command-line
import os			#Access to external command-line
import textwrap		#Add text block wrapping properties
from time import sleep	#Allow system pausing

##########################
# COMMAND-LINE ARGUMENTS #
##########################

parser = argparse.ArgumentParser(description='Counts the number of each nucleotide in a FASTA file and prints the result.', add_help=False)
req = parser.add_argument_group('Required arguments:')
req.add_argument('-i','--infile', action="store", dest="infile", help='FASTA file', required=True, metavar='')
opt = parser.add_argument_group('Optional arguments:')
opt.add_argument('-e','--each', action="store_true", dest="each", help='Print count for each entry in FASTA')
opt.add_argument("-h", "--help", action="help", help="show this help message and exit")
args = parser.parse_args()

#############
# FUNCTIONS #
#############


##########
# SCRIPT #
##########

counts_dict = {}
each_counts_dict = {}

infile = open(args.infile, 'r')
for line in infile:

	line = line.rstrip('\n')
	if re.match('^>', line):
		line_split = line.split(' ')	#By default keeps only first word of the header.
		header = line_split[0].translate(None, '>')
		each_counts_dict[header] = {}
	else:
		for i in line:
			if i not in counts_dict:
				counts_dict[i] = 0
				counts_dict[i] += 1
			else:
				counts_dict[i] += 1

			if i not in each_counts_dict[header]:
				each_counts_dict[header][i] = 0
				each_counts_dict[header][i] += 1
			else:
				each_counts_dict[header][i] += 1

infile.close()

if args.each is True:
	keys_e = sorted(each_counts_dict.keys())
	for key_e in keys_e:
		keys = sorted(each_counts_dict[key_e].keys())
		for key in keys:
			print str(key_e) + '\t' + str(key) + '\t' + str(each_counts_dict[key_e][key])
	print '\ntotal:\n'

keys = sorted(counts_dict.keys())
for key in keys:
	print str(key) + '\t' + str(counts_dict[key])