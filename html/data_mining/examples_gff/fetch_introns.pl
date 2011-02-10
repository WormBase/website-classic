#!/usr/bin/perl -w

=begin metadata

This metadata is used to autogenerate indices of example scripts.

<metadata>
  <filename>fetch_introns.pl</filename>
  <purpose>Demonstrate how to fetch a single feature across the whole genome from a Bio::DB::GFF database.</purpose>
  <concepts>Bio::DB::GFF;using the WormBase public datamining server (aceserver.cshl.org)</concepts>
  <date>6 July 2004</date>
  <author>Todd Harris</author>
  <author_email>harris@cshl.org</author_email>
</metadata>

=end metadata

=pod

=head1 DESCRIPTION

Fetch all C. elegans introns from the open data mining server at
WormBase (aceserver.cshl.org), using Bio::DB::GFF.

=head2 Step-by-step explanation

This script uses the Bio::DB::GFF module.  We also "use strict;" to
ensure that we properly scope all variables.

=cut

#!/usr/bin/perl -w
use Bio::DB::GFF;
use strict;

=pod

Create a new Bio::DB::GFF object, connecting to the open Bio::DB::GFF
database at aceserver.cshl.org.  No password is required.

=cut

my $db = Bio::DB::GFF->new(#-dsn => 'dbi:mysql:elegans:aceserver.cshl.org',
			    -dsn => 'dbi:mysql:elegans',
	 		    -user => 'anonymous');

=pod

Iterate over the six C. elegans chromosomes, in turn iterating over
all CDSes on each chromosome.

=cut

#for (qw/I II III IV V X/) {
for (qw/I/) {

  # Fetch a new segment corresponding to the chromosome
  my $segment = $db->segment($_);
  
  # Iterate over all CDSes on the chromosome
  my $feature_iterator = $segment->get_feature_stream('CDS:curated');
  while (my $cds = $feature_iterator->next_seq) {
    
    # Set the refseq to the CDS, not the chromosome
    $cds->refseq($cds);
    
    # Iterate over all introns of the CDS
    my @introns = sort { $a->start <=> $b->start } $cds->features('intron:Coding_transcript');
    my $intron_count;
    foreach my $intron (@introns) {
      $intron_count++;

      # Fetch the sequence of the intron and convert it to fasta format
      my $seq  = to_fasta($intron->dna);

      # Create a more informative header
      my $name   = $intron->name;
      my $start  = $intron->start;
      my $stop   = $intron->stop;

      # Fetch some values related to absolute coordinates
      $intron->refseq($segment);
      my $abs_ref   = $intron->sourceseq;  # This is the chromosome
      my $abs_start = $intron->abs_start;
      my $abs_stop  = $intron->abs_stop;
      my $strand    = $intron->strand;

      my $header = ">$name ($intron_count/"
	. scalar @introns 
	  . ") ($strand; $start-$stop) ($abs_ref: $abs_start-$abs_stop)";
      print "$header\n",$seq,"\n";
    }
  }
}

=pod

=head2 to_fasta();

This subroutine converts a dna string into fasta format.

=cut

sub to_fasta {
  my $sequence = shift;

  # Return if we are already in fasta format.
  return if ($sequence=~/^>(.+)$/m);

  # This is the business part of the subroutine.
  # Place a carriage return after every 80 characters
  $sequence =~ s/(.{80})/$1\n/g;
  return $sequence;
}
