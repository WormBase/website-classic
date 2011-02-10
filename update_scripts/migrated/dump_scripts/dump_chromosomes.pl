#!/usr/bin/perl
# file: dump_chromosomes.pl
# funtion: combine multiple chromosome files and update sequence names if necessary
# usage: dump_chromosomes.pl <chr_dir> <out_file>

use strict;
use File::Slurp qw(slurp);

my $usage = "$0 <chr_dir> <out_file>";

my ($chr_dir, $out_file) = @ARGV;
die $usage if (!$chr_dir || !$out_file);

my @files = glob("$chr_dir/CHROMOSOME*.dna.gz");

if (@files != 7) {
    die "Incorrect chr file set: " . join(', ', @files);
}

my $files = join(' ', @files);

my $cmd = qq[(zcat $files > $out_file.tmp) >& $out_file.err];

system($cmd) and die "System call ($cmd) failed: $!";

my $err = slurp("$out_file.err");
print STDERR $err;
unlink "$out_file.err";

open(OUT, ">$out_file") or die "Cannot write file: $!";

open(IN, "<$out_file.tmp") or die "Cannot read file: $!";
while (<IN>) {
    s/^>([IVX]+|MtDNA)/>CHROMOSOME_$1/;
    print OUT $_;
}

close IN;
close OUT;
unlink "$out_file.tmp";
