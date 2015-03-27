#!/usr/bin/perl

# This script makes sure that the sequence of a FASTA file is in rows of defined length (or less
# for the last row).

#USAGE: perl SetFASTARowLength.pl [IN FASTA FILE] [OUT FASTA FILE] [ROW LENGTH]

############################################
# UPDATE HISTORY AND LIST OF THINGS TO FIX #
############################################

#14.04.01	Wrote script.
#
#15.01.28	Added in removal of all blank lines to conform with 'samtools faidx'.
#
#15.03.26	Added subroutines to script so it no longer needs a common subroutine file.

###############
# SUBROUTINES #
###############

sub fasta2hash	{
	my($file) = @_; 
	my @FASTA;
	my $line;
	my @line2;
	my @line3;
	my %fastahash;
	my $curhead;
	my $seq = "";
	my $tmp;

	#Open the FASTA file and store it in an array.

	open (LIST, "$file");
	@FASTA = <LIST>;
	close LIST;

	#Now go through the FASTA an store '>' lines as KEYS and sequence as VALUES.

	foreach $line (@FASTA)	{
		chomp($line);	
	
		if(($line =~ />/) && ($seq eq ""))	{	#Here's what we do with the first header.
			@line2 = split(/>/, $line);
			@line3 = split(/ /, $line2[1]);
			$curhead = $line3[0];
		}

		if($line !~ />/)	{	#Here's what we do with sequence lines.
			@line2 = split(/>/, $line); 
			$seq .= $line;
		}
		
		if(($line =~ />/) && ($seq ne ""))	{	#Here's what we do with the subsequent headers.
			$fastahash{$curhead} = $seq;
			$seq = "";
			@line2 = split(/>/, $line);
			@line3 = split(/ /, $line2[1]);
			$curhead = $line3[0];
		}
	}
	
	$fastahash{$curhead} = $seq;	#The final FASTA seq will be put in here.
	
	return %fastahash;
}

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