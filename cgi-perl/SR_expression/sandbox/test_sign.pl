#!/usr/bin/perl -w
use strict;

my $str = "ADA%_";
print $str, "\n";
$str =~ s/%_//;
print $str, "\n";
