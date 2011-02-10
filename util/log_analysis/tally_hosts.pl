#!/usr/bin/perl

use strict;
my (%HOSTS,$TOTAL);

while (<>) {
  chomp;
  next unless /^==FROM==/../^==WHAT==/;
  next if /^==/;
  next unless /[a-zA-Z]/;

  my ($host,$count) = split /\s+/;
  my ($suffix) = $host =~ /\.(\w+)$/;
  next unless $suffix;
  $HOSTS{$suffix} += $count;
  $TOTAL += $count;
}

for my $suffix (sort {$HOSTS{$b}<=>$HOSTS{$a}} keys %HOSTS) {
  printf("%6s %5.2f%%\n",$suffix,100*$HOSTS{$suffix}/$TOTAL);
}
