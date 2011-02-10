#!/usr/bin/perl

my %ips;
while (<>) {
    chomp;
   my ($tag,$rest) = split("=",$_);
   $ips{$rest}++;
}

foreach (sort {$ips{$b} <=> $ips{$a} } keys %ips) {
   print "$_ : $ips{$_}\n"
}

print "Total: " . (scalar keys %ips) . "\n";
