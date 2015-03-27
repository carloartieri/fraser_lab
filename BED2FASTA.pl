#!/usr/bin/perl

# The purpose of this script is to extract FASTA sequences of all of the transcripts within a GTF
# file.

#USAGE: perl GTF2FASTA.pl [GENOME FASTA FILE] [GTF FILE] [OUTFILE]


############################################
# UPDATE HISTORY AND LIST OF THINGS TO FIX #
############################################

#11.03.15
#	- Charted out the initial concept and finished script.
#12.11.09
#	- Modified script to use options and all user to specify reverse transcribe genes on the neg.
#	  strand.
#15.03.12
#	- Cleaned up and put in shared script directory
#
#15.03.27
#	- Added ANSIColor module

###############
# SUBROUTINES #
###############
use Getopt::Long;
use Term::ANSIColor;

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

	#Now go through the FASTA an store '>' lines as KEYS and sequence as VALUES.

	foreach $line (@FASTA)	{
		chomp($line);	
	
		if(($line =~ />/) && ($seq eq ""))	{	#Here's what we do with the first header.
			@line2 = split(/>/, $line);
			$curhead = $line2[1];
		}

		if($line !~ />/)	{	#Here's what we do with sequence lines.
			@line2 = split(/>/, $line); 
			$seq .= $line;
		}
		
		if(($line =~ />/) && ($seq ne ""))	{	#Here's what we do with the subsequent headers.
			$fastahash{$curhead} = $seq;
			$seq = "";
			@line2 = split(/>/, $line);
			$curhead = $line2[1];
		}
	}
	
	$fastahash{$curhead} = $seq;	#The final FASTA seq will be put in here.
	
	return %fastahash;
}


$rev = 0;

GetOptions (	"genome=s" => \$genome,
				"bed=s" => \$bed,
				"out=s" => \$out, 	
				'rev' => \$rev,
				'help' => \$help,
				'h' => \$help,				
			);

if(($help == 1) || ($genome eq "") || ($bed eq "") || ($out eq ""))	{
	print colored['bright_red'], '
	This script takes an annotation file in BED format as well as a genome in FASTA format and
	outputs a new FASTA file containing the sequences of the annotations (e.g., spliced genes).

	USAGE: perl BED2FASTA.pl --genome <genome.fa> --bed <annotation.bed> --out <annotation.fa> --rev

	Options and formatting are as follows:

	--rev
		If this option is specified, reverse transcribe genes on the negative strand so that their
		sequence is 5\' - 3\'. 
	
	--help or --h
		Print this text.
		
';
	exit;
}


##########
# SCRIPT #
##########

#Read in the genome
%genomefasta = fasta2hash($genome);

open(OUT, ">$out");

#Open the BED file.
open (BED, "$bed");
while(<BED>) 	{
	chomp($_);
	@line = split(/\t/, $_);
	
	$chr = $line[0];
	$start = $line[1];
	$gene = $line[3];
	$or = $line[5];
	@lengths = split(/\,/, $line[10]);
	@starts = split(/\,/, $line[11]);

	$seq = "";
	for($i = 0; $i < scalar(@lengths); ++$i)	{
		$seq .= substr($genomefasta{$chr},($start+$starts[$i]),$lengths[$i]);
	}
	
	if(($rev == 1) && ($or eq "-"))	{
		$seq = reverse($seq);
		$seq =~ tr/actgACTG/tgacTGAC/;
	}
	
	print OUT ">$gene\n$seq\n";
	
}
close BED;
close OUT;