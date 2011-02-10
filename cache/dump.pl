#!/usr/bin/perl

use strict;
use Data::Dumper;
use Storable 'thaw';

do_dump($_) while $_ = shift;

sub do_dump {
  my $file = shift;
  open F,$file or die "$file: $!";
  my $data = '';
  do {1} while read(F,$data,1024,length($data));
  close F;
  my $array = thaw($data) or return;
  my $obj   = $array->[1]->{_Data};
  print Data::Dumper->Dump([$obj],['obj']);
}
