#!/usr/bin/perl -w

=pod

=head2 fetch_any_feature.pl [options...]

This script demonstrates how to generically fetch any feature across
the entire genome using a Bio::DB::GFF database.

=head2 INFORMATION

This section provides identification information used to autogenerate
indexes of example scripts.

FILENAME=fetch_any_feature.pl
PURPOSE=Demonstrate how to fetch any feature across the whole genome using a Bio::DB::GFF database
CONCEPTS=Bio::DB::GFF;using the WormBase public datamining server (aceserver.cshl.org)
AUTHOR=Todd Harris
AUTHOR_EMAIL=harris@cshl.org
LAST_MODIFIED= $Id: fetch_any_feature.pl,v 1.1.1.1 2010-01-25 15:47:17 tharris Exp $

=cut

use Bio::DB::GFF;
use Getopt::Long;
use strict;

my ($feature,$dna,$dsn,$user,$pass);
GetOptions('feature=s'=> \$feature,
	   'dna=i'    => \$dna,
	   'dsn=s'    => \$dsn,
           'user=s'   => \$user,
           'pass=s'   => \$pass,);

$feature || die <<USAGE;
Usage: fetch_any_feature.pl [options...]

  Fetch any specific feature across the entire genome

 Options:
  -feature    A GFF feature to fetch in the format method:source
  -dna        [optional] Fetch the dna of the feature in fasta format
  -dsn        The database to use
  -user       [optional] username
  -pass       [optional] password

 example:
  fetch_any_feature.pl -feature exon:curated -dna 1 -dsn elegans:aceserver.cshl.org

 Note:  This script is not strand sensitive.  All features will be 
 reported on the plus strand.

USAGE
;

# Establish a connection to the C. elegans database on aceserver.
#my $db = Bio::DB::GFF->new(-dsn => 'dbi:mysql:elegans:aceserver.cshl.org',
my $db = Bio::DB::GFF->new(-dsn  => 'dbi:mysql:' . $dsn,
                           -user => $user,
                           -pass => $pass,)
  || die "Couldn't establish a connection to $dsn";


# Iterate over all of the requested features
my $iterator = $db->get_seq_stream(-type => $feature);
while (my $feature = $iterator->next_seq) {
    
    # Create a more informative header
    my $name   = $feature->name;
    my $type   = $feature->type;
    my $start  = $feature->start;
    my $stop   = $feature->stop;
    my $strand = $feature->strand;
    my $refseq = $feature->sourceseq; # This is the name of the chromosome
    my $header = ">$name ($type; strand: $strand; $refseq: $start..$stop)";

    # If requested, fetch the sequence of the feature and convert it to fasta
    if ($dna) {
      my $seq  = to_fasta($feature->dna);
      print ">$header\n",$seq,"\n";
    } else {
      print $header,"\n";
    }
}



# This subroutine converts a dna string into fasta format
sub to_fasta {
  my $sequence = shift;

  # Return if we are already in fasta format.
  return if ($sequence=~/^>(.+)$/m);

  # This is the business part of the subroutine.
  # Place a carriage return after every 80 characters
  $sequence =~ s/(.{80})/$1\n/g;
  return $sequence;
}
