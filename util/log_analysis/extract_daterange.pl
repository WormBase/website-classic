#!/usr/bin/perl

use strict;
my $start = shift;
my $end   = shift;

$start && $end or die <<USAGE;
 $0 <start_date> <end_date>

Extract a date range.

USAGE
;

my ($start_seen,$end_seen);
while (<>) {
  $start_seen ||= /$start/o;
  next unless $start_seen;
  $end_seen   ||= /$end/o;
  next unless $start_seen or $end_seen;
  last if $end_seen and !/$end/o;
  print;
}
