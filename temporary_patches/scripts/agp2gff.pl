#!/usr/bin/perl -w
use strict;

my ($src,$met) = (shift, shift);
$src && $met || die "Usage: agp2gff.pl source method\n";

while (<>) {
  chomp;
  my ($chr,$ss,$se,undef,undef,$contig,$ts,$te,$strand) = split;
  $chr && $strand or next;
  print join("\t",$chr,$src,$met,$ss,$se,'.',$strand,'.',"Sequence \"$contig\""), "\n";
}



