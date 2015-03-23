#!/usr/bin/perl


############################################
# UPDATE HISTORY AND LIST OF THINGS TO FIX #
############################################

#12.10.15	- Began writing the script.

###############
# SUBROUTINES #
###############

#This is the location of the common subroutines file.
$home = `echo \$HOME`;
chomp($home);
do "$home/Software/Common_Subroutines.pl";


#READ IN THE FASTA
%fasta = fasta2hash($ARGV[0]);

$a = 0;
$c = 0;
$g = 0;
$t = 0;
$n = 0;
$x = 0;
@keys = sort(keys %fasta);

foreach $key (@keys)	{
	#Bust up the Coding sequence into codons.
	@nucs = split(//, $fasta{$key});
	for($i = 0; $i < scalar(@nucs); ++$i)	{
		if (($nucs[$i] eq "A") || ($nucs[$i] eq "a"))	{
			++$a;
		}
		if (($nucs[$i] eq "C") || ($nucs[$i] eq "c"))	{
			++$c;
		}
		if (($nucs[$i] eq "G") || ($nucs[$i] eq "g"))	{
			++$g;
		}
		if (($nucs[$i] eq "T") || ($nucs[$i] eq "t"))	{
			++$t;
		}
		if (($nucs[$i] eq "N") || ($nucs[$i] eq "n"))	{
			++$n;
		}
		if (($nucs[$i] eq "X") || ($nucs[$i] eq "x"))	{
			++$x;
		}
	} 
}

#open(OUT, ">$ARGV[1]");
print "NUC\tTOT\n";
print "A\t$a\n";
print "C\t$c\n";
print "G\t$g\n";
print "T\t$t\n";
print "N\t$n\n";
print "X\t$x\n";
#close OUT;
