#!/usr/bin/perl
# Author: Lincoln Stein
# Date: May 22, 2002
# see README file

use strict;

push @ARGV,'consolidated_utrs.txt' unless @ARGV;
while (<>) {
  chomp;
  my($gene,$type,$ref,$start,$end) = split "\t";
  next if $type eq 'CDS';  # unwanted
  my $source = $type =~ /5\'/       ? "5'UTR" : "3'UTR";
  my $method = $type =~ /noncoding/ ? 'noncoding'
              :$type =~ /partially/ ? 'partially-coding'
	      :$type =~ /implied/   ? 'inferred-partially-coding'
	      : die "breakdown in logic";
  my $strand = '+';
  if ($start > $end) {
    ($start,$end) = ($end,$start);
    $strand = '-';
  }
  my $phase = '.';
  my $score = '.';
  my $group = qq(Sequence "$gene");
  print join("\t",
	     $ref,
	     $method,
	     $source,
	     $start,
	     $end,
	     $score,
	     $strand,
	     $phase,
	     $group),"\n";
}
