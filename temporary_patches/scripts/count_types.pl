#!/usr/bin/perl -w
use strict;

my %type;
while (<>) {
  next if /\#/;
  $_ = join("\t",(split)[1,2]);
  chomp;
  $type{$_}++;
}

for my $k (sort { $type{$b}<=>$type{$a} } keys %type) {
  print "$k\t$type{$k}\n";
}
