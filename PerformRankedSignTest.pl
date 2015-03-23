#!/usr/bin/perl

###########################
# SUBROUTINES AND MODULES #
###########################

#Use the module that allows for long command line option parsing. 
use Getopt::Long;
use List::Util qw(first);
use Term::ANSIColor;

sub fisher_yates_shuffle {
        my $array = shift;
        my $i;
        for ($i = @$array; --$i; ) {
                my $j = int rand ($i+1);
                next if $i == $j;
                @$array[$i,$j] = @$array[$j,$i];
        }
}

sub tab_parse {
	my($string) = @_;
	my @line;
	my $j;
	@line = split(/\t/, $string);
	$j = 0;
	while($j < scalar(@line))	{		
		$line[$j] =~ s/\s+//g;
		++$j;
	}
	return @line;
}

sub sum_array {
    my(@vals) = @_;        # put parameters in array @vals
    my($sum) = 0;       # initialize the sum to 0
    foreach $i (@vals) {
	$sum = $sum + $i;
    }
    return($sum);
}

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


######################################
# DEFAULT AND COMMAND LINE VARIABLES #
######################################

#Define options.
$min = 10; #Default minimum number of genes in a category..
$frac = 1; #Default fraction will be to use all genes.
$perms = 1000; #Default permutations will be 1000.

GetOptions (	
		"funcats=s" => \$funcats,
		"asetable=s" => \$asetable,		
		"output=s" => \$out,
		"fraction=s" => \$frac,
		"min=s" => \$min,
		"perms=s" => \$perms,
		'help' => \$help,
		'h' => \$help,
);

if(($help == 1) || ($funcats eq "") || ($asetable eq "") || ($out eq ""))	{
	print colored['bright_red'], '
	This script takes a list of genes with ASE values as well as a group of functional categories 
	and determines whether any of the functional categories shows significant parental bias in 
	directionality by way of a chi-square test. It then permutes gen-category assignments to 
	determine how often such a degree of bias would be observed by chance, producing a category-
	specific false-discovery rate.

	USAGE: perl PerformRankedSignTest.pl --asetable [GENE ASE VALUES] --funcats [FUNCTIONAL CATEGORIES] --output [OUTPUT FILE] --fraction [#] --min [#] --perms [#]

	Options and formatting are as follows:

	--asetable 
		A tab-delimited file with two columns, the first of which is the gene name and the 
		second is the log2(species 1 allele/species 2 allele) ASE value. i.e.:

		[GENE]	[LOG2 ASE]

	--funcats
		A tab-delimited list of genes and the functional categories in which they belong. The genes 
		must be in the first column and the functional categories in the second. Genes that belong
		to multiple categories should separate categories by |. i.e.:

		[GENE]	[FUNCAT 1]|[FUNCAT 2]|[FUNCAT 3]

	--output
		The tab-delimited file where test values are written with the following columns:
		
		CATEGORY		The functional category
		SP1_BIASED		Number of genes showing species 1 bias (i.e., positive Log2(ASE) values)
		SP2_BIASED		Number of genes showing species 1 bias (i.e., negative Log2(ASE) values)
		SP1_EXPECTED		Number of expected genes showing sp1 bias given the proportion of sp1 biased genes among all genes
		SP2_EXPECTED		Number of expected genes showing sp2 bias given the proportion of sp2 biased genes among all genes
		CHI_SQ			Chi-square value
		FDR			How often (1/#perms) is an equal or higher chi-square value observed among permuted data	
		SP1_GENES		Species 1 biased genes, seperated by |
		SP2_GENES		Species 2 biased genes, seperated by |

	--fraction [Default 1]
		Analyze only the top X fraction (e.g., 0.25) most biased genes from each species. Allows you to
		look for enrichment of direction bias in tails of the ASE distribution. By default, the script 
		uses all genes.

	--min	[Default 10]
		The minimum number of genes that a functional category must posess to attempt the test. Due to multiple
		testing, categories with fewer than ~10 genes typically can\'t acheive significance.
		
	--perms [Default 1000]
		The number of permutations to run for the purpose of determining the category-specific FDR.
	
	--help or --h
		Print this text.
		
';
	exit;
}



##########
# SCRIPT #
##########

#Get genes and funcats
open(FILE, "$funcats");
while(<FILE>)	{
		chomp($_);
		@line = split(/\t/, $_);
		$genes{$line[0]} = "$line[1]";
		
		#Create a reciprocal funcat hash.
		@line2 = split(/\|/, $line[1]);
		foreach $cat (@line2)	{
			$funcat{$cat} .= "$line[0]\t"; 
		}
}
close FILE;

#Get ASE table and determine gene lists.

open(FILE, "$asetable");
$sp1genes = 0;
$sp2genes = 0;
while(<FILE>)	{
		chomp($_);
		@line = split(/\t/, $_);
		unless($line[1] eq "NA")	{
			$ase{$line[0]} .= $line[1];
			if(($_ ne "") && ($line[1] > 0))	{
				++$sp1genes;
			}
			elsif(($_ ne "") && ($line[1] < 0))	{
				++$sp2genes;
			}
		}
}
close FILE;

$sp1num = int(($sp1genes*$frac) + 0.5);
$sp2num = int(($sp2genes*$frac) + 0.5);

#Get sp1 genes and number.
my @keys = sort { $ase{$a} <=> $ase{$b} } keys(%ase);
@keys = reverse(@keys);
@sp1list = ();
for($i = 0; $i < $sp1num; ++$i)	{
	push(@sp1list, $keys[$i]);
	$sp1genes{$keys[$i]} = 1;
}
#Get sp2 genes and number.

my @keys = sort { $ase{$a} <=> $ase{$b} } keys(%ase);
@sp2list = ();
for($i = 0; $i < $sp2num; ++$i)	{
	push(@sp2list, $keys[$i]);
	$sp2genes{$keys[$i]} = 1;
}

$sp1bias = $sp1num/($sp1num+$sp2num);

@combolist = (@sp1list,@sp2list);
%combogenes = map { $_ => 1 } @combolist;

print "AT THRESHOLD FRACTION $frac, THERE ARE $sp1num SP1 BIASED GENES AND $sp2num SP2 BIASED GENES. SP1BIAS = $sp1bias\n";

#Now determine the categories passing threshold.
@keys = sort (keys %funcat);
foreach $key (@keys)	{
	$good = 0;
	$count = 0;
	@tempgenes = split(/\t/, $funcat{$key});
	$temp = scalar(@tempgenes);
	if(scalar(@tempgenes) >= $min) {
		foreach $tmp (@tempgenes)	{	
			$count += $combogenes{$tmp};
		}
		if($count >= $min)	{
			$good = 1;
		}
	}

	if($good == 1)	{
		$goodfuncat{$key} = $funcat{$key};
	}
}

@keys = sort (keys %goodfuncat);
$goodcats = scalar(@keys);

print "$goodcats FUNCTIONAL CATEGORIES PASS THE MINIMUM THRESHOLD OF $min GENES FOR CHI-SQUARE.\n";

#Now perform category-specific permutations.

print "BEGINNING CATEGORY-SPECIFIC PERMUTATIONS...\n";

@chisqperms = ();

for($perm = 0; $perm < $perms; ++$perm)	{

	#STEP 1, PERMUTE ASE ASSIGNMENT AMONG SPECIES.
	%sp1perm = ();
	%sp2perm = ();
	@chip = ();
	
	fisher_yates_shuffle( \@combolist );

	$sp1pnum = 0;
	$sp2pnum = 0;
	
	for($i = 0; $i < scalar(@combolist); ++$i)	{
		if($i < $sp1num)	{
			$sp1perm{$combolist[$i]} = 1;
			$sp2perm{$combolist[$i]} = 0;
			++$sp1pnum;
		}
		else	{
			$sp1perm{$combolist[$i]} = 0;
			$sp2perm{$combolist[$i]} = 1;
			++$sp2pnum;
		}
	}
	#STEP 2, GO THROUGH EACH CATEGORY AND RETAIN THE HIGHEST CHI-SQUARE VALUE.
	
	foreach $cat (@keys)	{
		@genestemp = split(/\t/, $goodfuncat{$cat});
		$sp1permcount = 0;
		$sp2permcount = 0;
		$totpermcount = 0;
		foreach $gene (@genestemp)	{
			$sp1permcount += $sp1perm{$gene};
			$sp2permcount += $sp2perm{$gene};
			$totpermcount += $sp1perm{$gene};
			$totpermcount += $sp2perm{$gene};
			#print "$gene\t$sp1permcount\t$sp2permcount\t$totpermcount\n";
		}
		$esp1 = int(($totpermcount*$sp1bias) + 0.5);
		$esp2 = $totpermcount-$esp1;
		$chi = ((($sp1permcount - $esp1)**2)/$esp1) + ((($sp2permcount - $esp2)**2)/$esp2);
		push(@chip, $chi);
	}
	@chip = sort { $a <=> $b } @chip;
	push(@chisqperms, $chip[-1]);

	$k = $perm;
	$j = $perm/100;
	if (($j !~ /\D/) && ($k > 0)) {
		print "COMPLETED $k PERMUTATIONS\n";
	}	
}	

#Now test observed cis ratios against the permuted ones.

open(OUT,">$out");
print OUT "CATEGORY\tSP1_BIASED\tSP2_BIASED\tSP1_EXPECTED\tSP2_EXPECTED\tCHI_SQ\tFDR\tSP1_GENES\tSP2_GENES\n";	
foreach $cat (@keys)	{
	@genestemp = split(/\t/, $goodfuncat{$cat});
	$sp1count = 0;
	$sp2count = 0;
	$totcount = 0;
	$sp1names = "";
	$sp2names = "";
	foreach $gene (@genestemp)	{
		$sp1count += $sp1genes{$gene};
		$sp2count += $sp2genes{$gene};
		$totcount += $sp1genes{$gene};
		$totcount += $sp2genes{$gene};
		if($sp1genes{$gene} == 1)	{
			$sp1names .= "$gene|";	
		}
		if($sp2genes{$gene} == 1)	{
			$sp2names .= "$gene|";	
		}
	}
	$esp1 = int(($totcount*$sp1bias) + 0.5);
	$esp2 = $totcount-$esp1;
	$chi = ((($sp1count - $esp1)**2)/$esp1) + ((($sp2count - $esp2)**2)/$esp2);
	#Now estimate the category-specific FDR.
	$large = 0;
	foreach $tmp (@chisqperms)	{
		if($tmp > $chi)	{
			++$large;	
		}
	}
	$p = $large/$perms;
	if($p == 0)	{
		$p = 1/$perms;
	}
		
	#Write the output.
	print OUT "$cat\t$sp1count\t$sp2count\t$esp1\t$esp2\t$chi\t$p\t$sp1names\t$sp2names\n";	
}
close OUT;

