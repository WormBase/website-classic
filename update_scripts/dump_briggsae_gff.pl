#!/usr/bin/perl

use strict;
use Ace;

my $ace = shift || "sace://localhost:2005";
my $db = Ace->connect($ace) or die "Couldn't connect to $ace: $!";

my @briggsae = $db->fetch(-query=>'find Sequence cb25* AGP_fragment');
for my $b (@briggsae) {
  my @frags = $b->AGP_fragment;
  foreach (@frags) {
    my ($name,$start,$stop) = $_->row(0);
    my $source = $name=~/contig/i ? 'contig' : 'clone';
    my $strand = $start < $stop ? '+' : '-';
    ($start,$stop) = ($stop,$start) if $start > $stop;
    print join("\t",$b,$source,'component',$start,$stop,'.','.','.',"Component $name"),"\n";
  }
}
