#!/usr/bin/perl

use strict;


my $data_file = $ARGV[0];
my $index_1 = $ARGV[1];
my $index_2 = $ARGV[2];

open FILE, "<./$data_file" or die "Cannot open $data_file\n";

foreach my $line (<FILE>){
	if($line =~ m/./){
		chomp $line;
		# print "$line\n";
		my @line_elements = split /\|/,$line;
		print "$line_elements[$index_1]\=\>$line_elements[$index_2]\n"; 	
	}
	else{
		next;
	}
} 
