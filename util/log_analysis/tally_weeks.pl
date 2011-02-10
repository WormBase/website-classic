#!/usr/bin/perl -w

# print out per-week histogram
use strict;
use Date::Format;
use Date::Parse;

@ARGV = qw(access_log.old.gz access_log_brie.gz access_log.gz);
foreach (@ARGV) {
  $_ = "zcat /usr/local/wormbase/logs/$_ |";
}
my %hits;

while (<>) {
  chomp;
  my ($who,$when,$what) = /^(\S+).+?\[([^\]]+)\].+\"(?:GET|POST) (.+) HTTP\/.+\"/ or next;
  my $time = str2time($when);
  my @date = localtime($time);
  my $year = $date[5]+1900;
  my $week = sprintf "%02d",time2str('%U',$time);
  my $wkyr = "$year-$week";
  $hits{$wkyr}++;
}

foreach (sort keys %hits) {
  print $_,"\t",$hits{$_},"\n";
}
