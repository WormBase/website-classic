#!/usr/bin/perl
# Author: Lincoln Stein
# Date: May 22, 2002
# see README file

use strict;

push @ARGV,'consolidated_utrs.txt' unless @ARGV;

my ($oldgene,@data);

while (<>) {
  chomp;
  my($gene,$type,$ref,$start,$end) = split "\t";
  if (@data and $gene ne $oldgene) {
    emit(\@data);
    @data = ();
  }
  push @data,[$gene,$type,$ref,$start,$end];
  $oldgene = $gene;
}
emit(\@data) if @data;

sub emit {
  my $data = shift;
  my $strand;

  # sort so that CDS appears first.  This ensures
  # that we pick the strand up from the CDS.
  foreach (sort {$a->[1] cmp $b->[1]} @$data) {  
    my($gene,$type,$ref,$start,$end) = @$_;
    $strand ||= $start < $end ? '+' : '-';
    next if $type eq 'CDS';  # unwanted
    my $source = $type =~ /5\'/       ? "5'UTR" : "3'UTR";
    my $method = $type =~ /noncoding/ ? 'noncoding'
              :$type =~ /partially/ ? 'partially-coding'
	      :$type =~ /implied/   ? 'inferred-partially-coding'
	      : die "breakdown in logic";
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
}
