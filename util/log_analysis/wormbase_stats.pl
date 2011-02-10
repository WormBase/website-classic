#!/usr/bin/perl

use strict;
use constant LOGS => '/usr/local/wormbase/logs/access_log*.gz';

unless (@ARGV) {
  @ARGV = <${\LOGS}>;
}

foreach (@ARGV) {
  $_ = "gunzip -c $_ |" if /\.gz$/;
}

my (%WHO,%WHEN,%WHAT,%SIGNIFICANT,%REFERER);
my %MON = (Jan=>1,Feb=>2,Mar=>3,Apr=>4,May=>5,Jun=>6,Jul=>7,Aug=>8,Sep=>9,Oct=>10,Nov=>11,Dec=>12);
my $lines = 0;

while (<>) {
  chomp;
  my ($hostname,$when,$referer,$what) = /^(\S+).+?\[([^\]]+)\] (\S+) \"[^\"]+?\".+\"(?:GET|POST) (.+) HTTP\/.+\"/ or next;
  warn "processed $lines\n" if (++$lines % 100000) == 0;
  next if $hostname =~ /cshl\.org/;
  next if $hostname eq 'localhost';

  $what =~ s/\?.*$//;
  my ($day,$mon,$yr) = split '/',$when;
  $yr =~ s/:.+$//; # get rid of time
  my $date = sprintf("1-%s-%02d",$MON{$mon},$yr,);
  $WHEN{$date}++;
  $WHO{$hostname}++;

  $REFERER{$referer}++ unless $referer =~ /wormbase\.org/;

  my $significant = $what =~ m!^/(perl|db)!;
  next unless $significant;

  $SIGNIFICANT{$date}++;
  $WHAT{$what}++;
}

print "==HITS==\n";
for my $mo (sort keys %WHEN) {
  printf("%-8s %7d %7d\n",$mo,$WHEN{$mo},$SIGNIFICANT{$mo});
}
print "\n";

print "==FROM==\n";
for my $who (sort {reverse($a) cmp reverse($b)} keys %WHO) {
  printf("%-50s %7d\n",$who,$WHO{$who});
}
print "\n";

print "==WHAT==\n";
for my $what (sort {$WHAT{$b} <=> $WHAT{$a}} keys %WHAT) {
  printf("%-50s %7d\n",$what,$WHAT{$what});
}

print "\n";
print "==REFERER==\n";
for my $r (sort {$REFERER{$b} <=> $REFERER{$a} } keys %REFERER) {
  printf("%-50s %7d\n",$r,$REFERER{$r});
}
print "\n";
