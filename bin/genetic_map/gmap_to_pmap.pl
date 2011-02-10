#!/usr/bin/perl

# Interpolate the genetic map onto the physical map

use Ace;
use Bio::DB::GFF;
use lib '.';
use GMap;

use strict;

my @chromosomes = qw/I II III IV V X/;


my $db  = Ace->connect(-host=>'localhost',-port=>2005) or die "Couldn't connect to localhost: $!";
my $gff = Bio::DB::GFF->new(-dsn=>'dbi:mysql:elegans',-user=>'root',-pass=>'kentwashere');

my $parser = GMap->new();
my $genes = $parser->parse();

foreach (@chromosomes) {
  # Find the low and high markers by physical position on the chromosome
  my ($low,$high) = $parser->find_maximal_markers_pmap($genes->{$_});
  print "$_ PMAP limits: ",join(' ',$low->{wbgene},$low->{start},$high->{wbgene},$high->{start}),"\n";

  # Find the low and high markers by genetic map position on the chromosome
  # Exclude those that only have an interpolated map position
  my ($low,$high) = $parser->find_maximal_markers_gmap($genes->{$_},'mapped');
  print "$_ GMAP limits: ",join(' ',$low->{wbgene},$low->{map_position},$high->{wbgene},$high->{map_position}),"\n";
}
