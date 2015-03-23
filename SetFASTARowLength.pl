#!/usr/bin/perl

# This script makes sure that the sequence of a FASTA file is in rows of defined length (or less
# for the last row).

#USAGE: perl SetFASTARowLength.pl [IN FASTA FILE] [OUT FASTA FILE] [ROW LENGTH]

############################################
# UPDATE HISTORY AND LIST OF THINGS TO FIX #
############################################

#14.04.01	Wrote script.
#15.01.28	Added in removal of all blank lines to conform with 'samtools faidx'.

###############
# SUBROUTINES #
###############

$home = `echo \$HOME`;
chomp($home);
do "$home/Software/Common_Subroutines.pl";

##########
# SCRIPT #
##########

$len = $ARGV[2];

%fasta = fasta2hash($ARGV[0]);

@keys = sort(keys %fasta);

open(OUT, ">$ARGV[1]\_tmp");

$cnt = 1;
foreach $key (@keys)	{
	print OUT ">$key\n";
	@temp = ();
	@temp = split('', $fasta{$key});
	$j = 1;
	for($i = 0; $i < scalar(@temp); ++$i)	{
		if($j < $len)	{
			print OUT "$temp[$i]";
		}
		if($j == $len)	{
			print OUT "$temp[$i]\n";
			$j = 0;
		}
		++$j;
	}
	print OUT "\n";
}
close OUT;

system "sed '/^\$/d' $ARGV[1]\_tmp > $ARGV[1]";
system "rm $ARGV[1]\_tmp";