#!/usr/bin/perl -w

use strict;
use File::Find;
use Storable 'thaw';
my %TALLY;

my $base = shift || 0;

my $wanted = sub {
  return unless -f $_;
  return unless -r _;
  open F,$_ or die "$_: $!";
  my $data = '';
  do {1} while read(F,$data,1024,length($data));
  close F;
  my $array = thaw($data) or return;
  my $obj   = $array->[1]->{_Data};
  my @keys = sort keys %$obj;
  my $key  = "@keys";
  $TALLY{$key}++;
  if ($TALLY{$key} < 20 && $key eq '.dirty .right .root class db name') {
    warn "fully populated: $obj   $File::Find::name\n";
  }
  if ($TALLY{$key} < 20 && $key eq '.root class db name') {
    warn "unpopulated: $obj   $File::Find::name\n";
  }
  if ($TALLY{$key} < 20 && $key eq '.PATHS .dirty .right .root class db name') {
    warn "partially populated: $obj   $File::Find::name\n";
  }
  if ($TALLY{$key} < 20 && $key eq 'name raw submodels') {
    warn "what's this?: $obj   $File::Find::name\n";
  }
};

find($wanted,$base);
for my $key (sort {$TALLY{$b}<=>$TALLY{$a}} keys %TALLY) {
  printf ("%-60s %-10d\n",$key,$TALLY{$key});
}

1;
