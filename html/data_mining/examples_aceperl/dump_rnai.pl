#!/usr/bin/perl

# Dump all RNAi experiments
# Author: T. Harris, 12/1/2004
# harris@cshl.org

use Ace;
my $DB = Ace->connect(-host=>'localhost',
		      -port=>2005) or die;

my $file = shift;
my $genes = get_genes($file);

foreach (@$genes) {
  my @rnai = $_->RNAi_result;
  print join("\t",$_,@rnai),"\n";
}

sub get_genes {
  my $file = shift;
  my @genes;
  if ($file) {
    open IN,$file;
    while (<IN>) {
      chomp;
      my $gene = $DB->fetch(-class=>'Gene',-name=>$_);
      push(@genes,$gene);
    }
  } else {
    @genes = $DB->fetch(-query=>qq{find Gene where Species="Caenorhabditis elegans"});
  }
  return \@genes;
}
