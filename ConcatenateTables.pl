#!/usr/bin/perl

#The purpose of this script is to combine any number of tab-delimited tables into a single large
#table picking a specific column as the criteria by which all rows will be arranged. Note that
#elements of said column must be UNIQUE.

#USAGE: perl ConcatenateTables.pl [ELEMENT LIST] [COLUMN {0 BASED}] [OUTFILE] [TABLE1] [TABLE2] etc...

##################
# MISC VARIABLES #
##################

$list = shift(@ARGV);	#Shift off the list file.
$col = shift(@ARGV);	#Shift off the column.
$out = shift(@ARGV);	#Shift off the name of the outfile.
@tables = @ARGV;		#The @tables array will contain the tables we're to combine.


###############
# SUBROUTINES #
###############

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

##########
# SCRIPT #
##########

#First open up the list and store it.

open (LIST, "$list");
while(<LIST>) 	{
	chomp($_);
	push (@list, $_);
	
	#Now we're going to create a hash that will store all of the lines we extract from the tables.
	#The first column on each line will be the list element.
	$listhash{$_} = "$_\t";
	
}
close LIST;

#Now open each file in turn and store all of the lines in a hash whose key will be the element from
#the corresponding column.

foreach $table (@tables)	{
	open (TABLE, "$table");
	while(<TABLE>) 	{
		chomp($_);
		@line = tab_parse($_);
		$tablehash{$line[$col]} = "$_";	
	}
	close TABLE;

	#Go through each element of the list and test to see if there's a table hash for it.
	foreach $lis (@list)	{
		unless ($tablehash{$lis} eq "")	{
			$listhash{$lis} .= "$tablehash{$lis}\t"; #Combine the table line into the list hash.
		}
		else	{
			#If that line was not in the table, then we want to add NAs for each of the table cols.
			for ($z = 0; $z < scalar(@line) ; ++$z)	{
				$listhash{$lis} .= "NA\t"
			}
		
		}
	}
	
	#Now reinitialize the table hash for the next table.
	
	%tablehash = ();
	
}

#Now we want to write our output to the outfile.

open (OUT, ">$out");
	foreach $lis (@list)	{
		print OUT "$listhash{$lis}\n";	
	}
close OUT;