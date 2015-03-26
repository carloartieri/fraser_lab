###############################
# NOTES ON FRASER LAB SCRIPTS #
###############################

Last updated 2015.03.26 by Carlo


BED2FASTA.pl
------------

	This script takes an annotation file in BED format as well as a genome in FASTA format and
	outputs a new FASTA file containing the sequences of the annotations (e.g., spliced genes).

	USAGE: perl BED2FASTA.pl --genome <genome.fa> --bed <annotation.bed> --out <annotation.fa> --rev

	Options and formatting are as follows:

	--rev
		If this option is specified, reverse transcribe genes on the negative strand so that their
		sequence is 5\' - 3\'. 
	
	--help or --h
		Print this text.
		

ConcatenateTables.pl
--------------------

	This script will concatenate any number of tab-delimited tables based on a list of common 
	identifiers. Tables that do not contain the identifier will have \'NA\'s in place of the
	missing cells. 

	USAGE: perl ConcatenateTables.pl <LIST> <0-based search column> <OUTFILE> <TABLE 1> <TABLE 2> ... <TABLE N>

	The <LIST> should contain the identifiers, each on a separate line. The <0-based search column> 
	tells the script in which column in each table to look for the identifiers (usually the first,
	or 0). After specifying the <OUTFILE>, each table should be separated by a space. They will be 
	concatenated in the order specified.
	
	--help or --h
		Print this text.