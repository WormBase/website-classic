#!/usr/bin/perl -w
use strict;
use Ace;

my $DB = Ace->connect(-host => 'aceserver.cshl.org',
		      -port => '2005')
  or die "Couldn't connect to aceserver: $!";

my @genes = $DB->fetch(-query=>
		       qq{find Gene where Species="Caenorhabditis elegans"});

foreach my $gene (@genes) {
  my $name = $gene->Public_name || $gene;
  my @alleles = $gene->Allele;
  print join("\t",$name,@alleles),"\n";
}
