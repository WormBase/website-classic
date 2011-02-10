#!/usr/bin/perl -w
use strict;
use Ace;
my $host = shift;
my $port = shift;

$host ||= 'aceserver.cshl.org';
$port ||= 2005;

my $DB = Ace->connect(-host => $host,
		      -port => $port)
  or die "Couldn't connect to $host: $!";

my @genes = $DB->fetch(-query=>
		       qq{find Gene where Species="Caenorhabditis elegans"});

foreach my $gene (@genes) {
  my $name = $gene->Public_name || $gene;
  my @allele = $gene->Allele;
  print join("\t",$name,@allele),"\n";
}
