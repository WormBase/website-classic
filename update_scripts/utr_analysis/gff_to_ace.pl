#!/usr/bin/perl

use strict;
use Bio::DB::GFF;

use constant DSN=> 'elegans:host=brie3';

my $UTR = "UTR000000";
my $db = Bio::DB::GFF->new(-dsn=>DSN) or die;

# map everything into cosmid or link coordinates
@ARGV = 'utrs.gff' unless @ARGV;
while (<>) {
  chomp;
  my($chrom,$source,$method,$start,$stop,undef,$strand,undef,$gene) = split "\t";
  my $segment  = $db->segment($chrom,$start=>$stop);
  my @links    = $segment->features('region:Genomic_canonical','region:Link');

  # find either a genomic canonical or a link that covers the region entirely
  my $shortest_canonical;
  for my $c (@links) {
    next unless $c->contains($segment);  # must contain segment completely
    $shortest_canonical = $c if !defined($shortest_canonical) || $c->length < $shortest_canonical->length;
  }

  my $ref;
  if ($shortest_canonical) {
    $segment->ref($shortest_canonical);
    $ref = $shortest_canonical->name;
  } else {
    warn "Couldn't find shortest canonical for $chrom:$start,$stop\n";
    $ref = $chrom;
  }

  my $start = $segment->start;
  my $end   = $segment->end;
  ($start,$end) = ($end,$start) if $strand eq '-';
  my ($cds) = $gene =~ /\"([^\"]+)\"/;

  $ref = "CHROMOSOME_$ref" if $ref =~ /^[IVX]+$/;  # special case for chromosomes
  my $method = join '-',$method,$source;

  $UTR++;
  print <<END;
Sequence : "$ref"
UTR $UTR $start $end

UTR : "$UTR"
Species "Caenorhabditis elegans"
Matching_CDS "$cds"
Method "$method"

END
;
}

print <<END;
Method : "5'UTR-noncoding"
GFF_source noncoding
GFF_feature "5'UTR"

Method : "5'UTR-partially-coding"
GFF_source "partially-coding"
GFF_feature "5'UTR"

Method : "5'UTR-inferred-partially-coding"
GFF_source "inferred-partially-coding"
GFF_feature "5'UTR"

Method : "3'UTR-noncoding"
GFF_source noncoding
GFF_feature "3'UTR"

Method : "3'UTR-partially-coding"
GFF_source "partially-coding"
GFF_feature "3'UTR"

Method : "3'UTR-inferred-partially-coding"
GFF_source "inferred-partially-coding"
GFF_feature "3'UTR"

END
