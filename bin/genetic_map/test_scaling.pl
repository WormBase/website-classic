#!/usr/bin/perl

my $val = '28.765526';
my $float = 0;

$val = $val * 1000000;

my $scaled = sprintf("%8.0f",$val);
warn "$val $scaled\n";
