#!/usr/bin/perl -w

=pod

=head2 fetch_aggregated_UTRs.pl [options...]

This script demonstrates how to fetch the aggregated UTRs for a set of genes.

=head2 INFORMATION

This section provides identification information used to autogenerate
indexes of example scripts.

FILENAME=fetch_aggregated_UTRs.pl
PURPOSE=Demonstrate how to use aggregators to fetch all UTRs
CONCEPTS=Bio::DB::GFF;using the WormBase public datamining server (aceserver.cshl.org)
AUTHOR=Todd Harris
AUTHOR_EMAIL=harris@cshl.org
LAST_MODIFIED= $Id: fetch_aggregated_UTRs.pl,v 1.1.1.1 2010-01-25 15:47:17 tharris Exp $

=cut

use Bio::DB::GFF;
use Getopt::Long;
use strict;

my (@genes,$dna,$dsn,$user,$pass,$help);
GetOptions('gene=s'   => \@genes,
	   'dna'      => \$dna,
	   'dsn=s'    => \$dsn,
           'user=s'   => \$user,
           'pass=s'   => \$pass,
	   'help=s'   => \$help,);

$help && die <<USAGE;
Usage: fetch_any_feature.pl [options...]

  Fetch any specific feature across the entire genome

 Options:
  -genes      [optional] list of WBGene IDs to fetch, space seperated
  -dna        [optional] fetch the dna of the UTRs in fasta format
  -dsn        [optional] the database to use - defaults to aceserver
  -user       [optional] username
  -pass       [optional] password

 example:
  fetch_aggregated_UTRs.pl -dna

 If the -genes option is not provided, all genes will be fetched.

 Note:  This script is not strand sensitive.  All features will be
 reported on the plus strand.

USAGE
;

# Establish a connection to the C. elegans database on aceserver.
my $aggregator = Bio::DB::GFF::Aggregator->new(-method       => 'full_transcript',
					       -main_method  => 'Coding_transcript:Transcript',
					       -sub_parts    => ['five_prime_UTR','three_prime_UTR']
					      );

$user ||= 'anonymous';
$dsn  ||= 'dbi:mysql:elegans:aceserver.cshl.org';

my $db = Bio::DB::GFF->new(-dsn  => $dsn,
                           -user => $user,
                           -pass => $pass,
			   -aggregator => [$aggregator])
  || die "Couldn't establish a connection to $dsn";

for (qw/I II III IV V X MtDNA/) {
  # Fetch a new segment for the chromosome
  my $segment = $db->segment($_);

  # Iterate over all features
  my $feature_iterator = $segment->get_feature_stream('full_transcript');
  while (my $gene = $feature_iterator->next_seq) {
    for my $feature (qw/five_prime_UTR three_prime_UTR/) {
      my @utrs = grep { $_->name eq $gene->name } $gene->features($feature);
      foreach my $utr (@utrs) {
	# Create a more informative header
	my $name   = $utr->name;
	my $type   = $utr->type;
	my $start  = $utr->start;
	my $stop   = $utr->stop;
	my $strand = $utr->strand;
	my $refseq = $utr->sourceseq; # This is the name of the chromosome
	my $header = ">$name ($type; strand: $strand; $refseq: $start..$stop)";
	
	# If requested, fetch the sequence of the feature and convert it to fasta
	if ($dna) {
	  my $seq  = to_fasta($utr->dna);
	  print "$header\n",$seq,"\n";
	} else {
	  print $header,"\n";
	}
      }
    }
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
