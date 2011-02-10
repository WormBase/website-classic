#!/usr/lab/perl

###############################################################################
# Name: find_genes_no_hits.pl
# Purpose: compares the original wormpepXX file and a .ace file 
#          outputs list of genes and their sequence that aren't in .ace file
# Usage:  $0 [wormpepXX or fa file] [.ace file]
# Requires: -
#
# Written by: Fiona Cunningham
# Date: 2nd July 2002
# Version: 1.0.0.0 
###############################################################################

use strict;


# Files
if (not($ARGV[1]))
  {die "\n Usage: $0 [fasta_file(wormpepXX)] [.ace file]\n";}

my $fasta_file = $ARGV[0];     # pslReps_output
my $ace = $ARGV[1];

# Get Gene ids from .ace file
my $genes_in_ace = parse_ace($ace);

# Get Gene ids from fasta file
get_gene_seq($fasta_file, $genes_in_ace);

exit;

#------------------ End of Main PROGRAM --------------------------------------#





###############################################################################
# SUBROUTINE: Get Gene ids from fasta file
# make a hash %$genes_in_ace
###############################################################################
sub parse_ace {

  my $ace_file = shift;
  my $genes_in_ace;
  open (ACE, $ace) or die "Error: Can't open $ace file\n";
  
  while (<ACE>){
    if (/Corresponding_DNA/)
      {
	my $ace_gene;
	if ($_ =~s/Corresponding_DNA //)	
	  {
	    $_ =~s/ //g;
	    chomp $_;
	    $ace_gene = $_;
	    $genes_in_ace->{$ace_gene}="in_ace";
	    # print "ace$ace_gene,\n";
	  }
      } # end of if
  }# end of while
  
  close ACE;
  return ($genes_in_ace);
} # end sub
#------------------------------------------------------------------------------



###############################################################################
# Foreach gene that is not in %$genes_in_ace, get the fa sequence from .fa file
# print these out
###############################################################################
sub get_gene_seq{
  my ($fasta_file, $genes_in_ace) = @_;
  my $print_prot;                       # flag when should print out $_

  open (FA, $fasta_file) or die "Error: Can't open $fasta_file file\n";
  
  while (<FA>){
    if (/>/)
      {
	if (/>(\w+\.?\w+)             # $1 wb_orf
	    \s+
	    (CE\d{5})                # $2 $protein
	    \s+.*/x)
	  {
	    $print_prot =0;
	    my $gene = $1;
	    if (!($genes_in_ace->{$1}))
	      {print $_; $print_prot=1;}
	  } # end of if 
      } # end of if (/>/)
    
    elsif ($print_prot ==1){print $_;}
  }# end of while
  close FA;
} # end of sub
#------------------------------------------------------------------------------
