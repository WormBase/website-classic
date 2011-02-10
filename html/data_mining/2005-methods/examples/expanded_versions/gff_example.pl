#!/usr/bin/perl -w

use strict;
use Bio::DB::GFF;
use Getopt::Long;

my ($feature,$dna,$dsn,$user,$pass);
GetOptions('feature=s'=> \$feature,
	   'dna'      => \$dna,
   	   'dsn=s'    => \$dsn,
	   'user=s'   => \$user,
	   'pass=s'   => \$pass);

$dsn  ||= 'elegans:aceserver.cshl.org';
$user ||= 'anonymous';

$feature || die <<USAGE;
Usage: gff_example.pl [options...]

 Fetch any specific feature across the entire genome

 Options:
  -feature    A GFF feature to fetch in the format method:source
  -dna        [optional] Fetch the dna of the feature in fasta
  -dsn        The database to use (defaults to aceserver)
  -user       [optional] username
  -pass       [optional] password

 example:
   gff_example.pl Ğfeature exon:curated -dna

 Note:  This script is not strand sensitive.  All features will be
  reported on the (+) strand.
USAGE
  ;
# Establish a connection to the appropriate data source
my $db = Bio::DB::GFF->new(-dsn  => 'dbi:mysql:' . $dsn,
			   -user => $user,
			   -pass => $pass,)
  || die "Couldn't establish a connection to $dsn";

# Fetch an iterator of the requested feature
my $iterator = $db->get_seq_stream(-type => $feature);
while (my $feature = $iterator->next_seq) {

  # Create an informative header
  my $name   = $feature->name;
  my $type   = $feature->type;
  my $start  = $feature->start;
  my $stop   = $feature->stop;
  my $strand = $feature->strand;
  my $refseq = $feature->sourceseq;
  my $header = "$name ($type; strand: $strand; $refseq:$start..$stop)";

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

  # Return if we are already in fasta format.
  return if ($sequence=~/^>(.+)$/m);

  # Place a carriage return after every 80 characters
  $sequence =~ s/(.{80})/$1\n/g;
  return $sequence;
}
