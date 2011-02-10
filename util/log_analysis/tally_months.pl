#!/usr/bin/perl -w

# print out per-week histogram
use strict;
use Date::Format;
use Date::Parse;

@ARGV = qw(access_log_old.gz access_log.gz);
foreach (@ARGV) {
  $_ = "zcat /usr/local/wormbase/logs/$_ |";
}
my %mon = (Jan=>1,Feb=>2,Mar=>3,Apr=>4,May=>5,
	   Jun=>6,Jul=>7,Aug=>8,Sep=>9,Oct=>10,
	   Nov=>11,Dec=>12);
my %hits;
my $oldmo;

while (<>) {
  chomp;
  my ($who,$when,$what) = /^(\S+).+?\[([^\]]+)\].+\"(?:GET|POST) (.+) HTTP\/.+\"/ or next;
  my ($mon,$yr) = $when =~ m!\d+/(\w{3})/(\d{4})!;
  my $moyr = sprintf("%04d-%02d",$yr,$mon{$mon});
  if ($moyr ne $oldmo) {
    print STDERR $moyr,"\n";
    $oldmo = $moyr;
  }
  $hits{$moyr}++;
}

foreach (sort keys %hits) {
  print $_,"\t",$hits{$_},"\n";
}
