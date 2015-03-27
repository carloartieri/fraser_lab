#!/usr/bin/perl

############################################
# UPDATE HISTORY AND LIST OF THINGS TO FIX #
############################################

#11.03.15 - Charted out the initial concept and finished script.
#
#12.11.09	- Modified script to use options and all user to specify reverse transcribe genes 
#			  on the neg. strand.
#
#15.03.27	- Added help text and removed link to common subroutines file. Added ANSIColor 
#			  module

###############
# SUBROUTINES #
###############

use Getopt::Long;
use Term::ANSIColor;

$rev = 0;

GetOptions (	"genome=s" => \$genome,
				"gtf=s" => \$gtf,
				"out=s" => \$out, 	
				'rev' => \$rev,
				'h' => \$help,
				'help' => \$help,								
			);

if(($help == 1) || ($genome eq "") || ($gtf eq "") || ($out eq ""))	{
	print colored['bright_red'], '
	This script takes an annotation file in GTF format as well as a genome in FASTA format and
	outputs a new FASTA file containing the sequences of the annotations (e.g., spliced genes).

	USAGE: perl GTF2FASTA.pl --genome <genome.fa> --bed <annotation.bed> --out <annotation.fa> --rev

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

$down = 0; 	#This is the number of additional nucleotides to extract beyond the 5'UTR.

#First we'll use the GTF file in order to determine all of the chromosomes that we should store
#in the genome FASTA. We're also going to determine all of the unique transcripts in the file as
#well as well as their positions.

open (GTF, "$gtf");
while(<GTF>) 	{
	@line = tab_parse($_);
	$genomehash{$line[0]} = "";
	@temp1 = split(/\"/, $line[8]);
	$geneid = $temp1[3];
	$locushash{$geneid} .= "$line[3]-$line[4]\t"; 	#So the %locushash will have all of the
													#positions overlapped by that locus.
	$chrloclist{$line[0]} .= "$geneid\t";	#Want to store all of the particular transcripts on a
											#chromosome.
	$locor{$geneid}	= "$line[6]";	#$locor will contain the orientation of the genes.
}
close GTF;

@chromosomes = keys %genomehash;

#The next step is to parse the genome FASTA file into a hash format for easy reference.

open (GENOME, "$genome");
$currchr = "";
while(<GENOME>) 	{
	chomp($_);
	if ($_ =~ />/)	{	#Deal with header lines differently.
		@headb = split(/>/, $_);
		$head = "$headb[1] "; #We're doing this to try deal with odd headers.
		$found = 0;
		foreach $chr (@chromosomes)	{
			if ($head eq "$chr ")	{	#We're adding a space because of subset chromosomes (chr2L, 
									#chr2Lhet), etc.
					$currchr = $chr;		
					$found = 1;
			}
		}
		if($found == 0)	{
			$currchr = "";		
		}
	}
	else	{
		$genomehash{$currchr} .= $_;
	}
}
close GENOME;

open(OUT, ">$out");

#In order to generalize this script to any genome, we need to do this chromosome by chromosome.

foreach $chr (@chromosomes)	{

	print "Current Chr: $chr\n";	#Provide feedback so we know where we are.

	#The first thing to do will be to bust up the chromosome sequence into a hash.
	%chrhash = ();
	@seq = split (//, $genomehash{$chr});
	for ($i = 1; $i <= scalar(@seq); ++$i)	{
		$j = $i + 1;
		$chrhash{$j} = $seq[$i];
	}
	@seq = ();
	
	#Next we identify all of the transcripts that are on the chromosome of interest.
	%lochash = ();
	@poloc = split (/\t/, $chrloclist{$chr});
	foreach $tmp (@poloc)	{
		$lochash{$tmp} = "";
	}
	@loci = keys %lochash;
	
	#Finally, we start writing out the data for each locus.
	foreach $locus (@loci)	{
		@pos1 = split(/\t/, $locushash{$locus});

		foreach $tmp (@pos1)	{
			@pos2 = split(/-/, $tmp); 
			if($locor{$locus} eq "+")	{
				for ($i = $pos2[0]; $i <= $pos2[1]+$down; ++$i)	{
					$sequence .= $chrhash{$i}
				}
			}
			elsif($locor{$locus} eq "-")	{
				for ($i = $pos2[0]-$down; $i <= $pos2[1]; ++$i)	{
					$sequence .= $chrhash{$i}
				}
			}
		}
	
		#If we want sequences reverse transcribed.
		if(($rev == 1) && ($locor{$locus} eq "-"))	{
			$sequence =~ tr/actgACTG/tgacTGAC/;
			$sequence = reverse($sequence);
		}
	
		print ">$locus\n$sequence\n\n";
		print OUT ">$locus\n$sequence\n\n";
		$sequence = "";

	}
}

close OUT;
