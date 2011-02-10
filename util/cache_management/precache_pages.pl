#!/usr/bin/perl

# Precache specific WormBase pages

use strict;
use Ace;
use WWW::Mechanize;
#use Storable;
$|++;

use constant URL => 'http://fe.wormbase.org/db/gene/gene?class=Gene;name=';
my $start = time();

my $previous = shift;
my %previous = parse() if $previous;

#my $db    = Ace->connect(-path=>'/usr/local/acedb/elegans');
my $db    = Ace->connect(-host=>'localhost',-port=>2005);
#my $i     = $db->fetch_many(-query=>qq{find Gene Species="Caenorhabditis elegans"});
#my $i     = $db->fetch_many(-query=>qq{find Gene Species="Caenorhabditis elegans" AND CGC_name AND Molecular_name});
my @i      = $db->fetch(Gene => '*');
open OUT,">genes.out";
foreach (@i) {
   print OUT $_,"\n";
}
close OUT;

my %status;
#while (my $gene = $i->next) {
open IN,"genes.out";
#foreach my $gene (@i) {
while (my $id = <IN>) {
  chomp $id;
  $db ||= Ace->connect(-host=>'localhost',-port=>2005);
  my $gene = $db->fetch(Gene=>$id);
  next if $gene->Species =~ /briggsae/i;
  next if (defined $previous{$gene});
  my $url = URL . $gene;
  sleep 2;

  # No need to watch state - create a new agent for each gene to keep memory usage low.
  my $mech = WWW::Mechanize->new(-agent => 'WormBase-PreCacher/1.0');
  $mech->get($url);
  my $success = ($mech->success) ? 'success' : 'failed';
  $status{$gene} = $success;
  print "$gene " . $gene->Public_name . ": $success","\n";
}

my $end = time();
my $seconds = $end - $start;
print "\nTime required to cache " . (scalar keys %status) . "genes: ";
printf "%d days, %d hours, %d minutes and %d seconds\n",(gmtime $seconds)[7,2,1,0];


sub parse {
  open IN,"$previous";
  my %previous;
  while (<IN>) {
	chomp;
        my ($gene,$name,$status) = split(" ");
        $previous{$gene}++;
  }        
  return %previous;
}
