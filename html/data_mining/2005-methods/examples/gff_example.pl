#!/usr/bin/perl -w

use strict;
use Bio::DB::GFF;

my $feature = shift;
my $dna     = shift;
$feature || die "You must specify a feature to fetch\n";;

# Establish a connection to the appropriate data source
my $db = Bio::DB::GFF->new(-dsn  => 'dbi:mysql:elegans:aceserver.cshl.org',
			   -user => 'anonymous')
  || die "Couldn't establish a connection to DSN: $!";

# Fetch an iterator of the requested feature
my $iterator = $db->get_seq_stream(-type => $feature);
while (my $feature = $iterator->next_seq) {

  # Create an informative header
  my $name   = $feature->name;
  my $type   = $feature->type;
  my ($start,$stop) = ($feature->start,$feature->stop);
  my $refseq = $feature->sourceseq;
  my $header = "$name ($type; $refseq:$start..$stop)";

  # If requested, fetch sequence of the feature in FASTA
  if ($dna) {
    my $seq  = to_fasta($feature->dna);
    print ">$header\n",$seq,"\n";
  } else {
    print "$header\n";
   }
 }

# This subroutine converts a dna string into fasta format
sub to_fasta {
  my $sequence = shift;
  return if ($sequence=~/^>(.+)$/m); # Return if already in FASTA
  $sequence =~ s/(.{80})/$1\n/g; # Carriage return every 80 characters
  return $sequence;
}
