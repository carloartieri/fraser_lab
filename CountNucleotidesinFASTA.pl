#!/usr/bin/perl


############################################
# UPDATE HISTORY AND LIST OF THINGS TO FIX #
############################################

#12.10.15	- Began writing the script.

###############
# SUBROUTINES #
###############

sub fasta2hash	{
	my($file) = @_; 
	my @FASTA;
	my $line;
	my @line2;
	my %fastahash;
	my $curhead;
	my $seq = "";
	my $tmp;

	#Open the FASTA file and store it in an array.

	open (LIST, "$file");
	@FASTA = <LIST>;
	close LIST;

	#Now go through the FASTA and store '>' lines as KEYS and sequence as VALUES.

	foreach $line (@FASTA)	{
		chomp($line);	
	
		if(($line =~ />/) && ($seq eq ""))	{	#Here's what we do with the first header.
			@line2 = split(/>/, $line);
			$curhead = $line2[1];
			$curhead =~ s/\s+//g;
		}

		if($line !~ />/)	{	#Here's what we do with sequence lines.
			$seq .= $line;
		}
		
		if(($line =~ />/) && ($seq ne ""))	{	#Here's what we do with the subsequent headers.
			$fastahash{$curhead} = $seq;
			$seq = "";
			@line2 = split(/>/, $line);
			$curhead = $line2[1];
			$curhead =~ s/\s+//g;
		}
	}
	
	$fastahash{$curhead} = $seq;	#The final FASTA seq will be put in here.
	
	return %fastahash;
}

##########
# SCRIPT #
##########

if(($ARGV[0] eq '-h') || ($ARGV[0] eq '--help'))	{
	print colored['bright_red'], '
	This script counts the number of A,C,T,G,N, or Xs in a FASTA files\' sequence line and spits 
	out the result.
	
	USAGE: perl CountNucleotidesinFASTA.pl <FASTA FILE>
	
	--help or --h
		Print this text.
		
';
	exit;
}


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
