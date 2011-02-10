#!/usr/bin/perl

use strict;

my (%REFERERS,$TOTAL);

while (<>) {
  next unless /^==REFERER==/..eof;
  chomp;
  my ($referer,$count) = split /\s+/;
  next unless $count =~ /^\d+$/;
  last if $count < 100;
  next if $referer eq '-';
  $referer = lc($referer);
  my ($domain) = $referer =~ m!^(?:\w+://)?([^/]+)!;
  $domain =~ s/:\d+$//;
  $domain ||= $referer;
  warn $_ if $domain =~ /^http/;
  next if $domain =~ /wormbase\.org/;
  next if $domain =~ /cshl\.org/;
  $REFERERS{$domain} += $count;
  $TOTAL             += $count;
}

for my $referer (sort {$REFERERS{$b}<=>$REFERERS{$a}} keys %REFERERS) {
  my $percent = 100*$REFERERS{$referer}/$TOTAL;
  last if $percent < 0.1;
  printf("%30s %5.2f%%\n",$referer,$percent);
}

print "TOTAL=$TOTAL\n";
