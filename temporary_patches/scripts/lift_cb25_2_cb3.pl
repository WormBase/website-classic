#!/usr/bin/perl -w
use strict;
use Data::Dumper;

# filtered.agp has split contigs and gaps removed
# split_contigs.agp has all of the split contigs mapped by BLAT
open CONTIGS, "cat cb3_agp/filtered.agp cb3_agp/split_contigs.agp |" or die $!;
my %contig;

while (<CONTIGS>) {
  chomp;
  my ($chr,$s,$e,undef,undef,$contig,$cstart,$cend,$str) = split;
  print join ("\t",$chr,qw/Genomic_canonical Sequence/,$s,$e,'.',$str,'.',qq(Sequence "$contig")), "\n";
  #$contig =~ s/[a-z]$//;
  my $offset = $str eq '+' ? $s : $e;
  $contig{"$contig $cstart $cend"} = [$chr,$offset,$str];
}

while (<>) {
  s/Sequence:([IVX]+)/Sequence:elegans_$1/;
  my ($contig,$source,$method,$start,$end,$score,$strand,$phase,$group) = split /\t/;
  
  my $map = is_within($contig,$start,$end);
  
  unless ($map) {
    warn "NO MAP: $contig\n";
    next;
  }

  my ($contig_offset,$chrom,$offset,$direction) = @$map;

  # adjust coords if this is a split contig
  ($start,$end) = map {$_ -= $contig_offset} ($start,$end);

  if ($direction ne '-') {
    $start += $offset - 1;
    $end   += $offset - 1;
  }
  else {
    my $bend = $end;
    $end = $offset - $start;
    $start = $offset - $bend;
  }
  $strand = $strand eq $direction ? '+' : '-';

  # some SO compliance (I think)
  $method =~ s/component/Sequence/;

  print join("\t",$chrom,$source,$method,$start,$end,$score,$strand,$phase,$group);
}

sub is_within {
  my ($contig,$start,$end) = @_;
  my @choices = grep /^$contig[a-z]?\s+/, keys %contig;
  
  for (@choices) {
    my ($cname,$cstart,$cend) = split;
    next unless $start >= $cstart;
    next unless $end <= $cend;
    $cstart-- if $cstart == 1;
    return [$cstart, @{$contig{$_}}];
  }
}

