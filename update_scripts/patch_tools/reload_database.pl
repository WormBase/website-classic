#!/usr/bin/perl -w
# a srcipt for re-loading databases for patching errors, etc.
# $Id: reload_database.pl,v 1.1.1.1 2010-01-25 15:36:09 tharris Exp $

use strict;

use constant BASE  => '/usr/local/ftp/pub/wormbase/genomes/';
use constant PATCH => '/usr/local/wormbase/temporary_patches/';


my $species  = shift || die "provide a species name\n";
my $release  = shift || die "release number WSXXXX\n";

my $gff       = BASE . "$species/genome_feature_tables/GFF2/$species${release}.gff.gz";
my @other_files;

my $patch_gff = '';

if (@ARGV) {
  die "File $_ does not exist\n" unless -e $_;
}

$gff .= join ' ', @ARGV;

my $dna = BASE . "$species/sequences/dna/$species.${release}.dna.fa.gz";

my $display_list = $gff .' '.$dna;
$display_list =~ s/\s+/\n/g;

print "The following files will be loaded into the database:\n$display_list\n";
print "Proceed ? [Y] ";
my $go_ahead = <STDIN> || 'Y';
exit unless $go_ahead =~ /^Y|^$/i;
print "OK\n" and exit;  

system "bp_fast_load_gff.pl -u root -p kentwashere -d ${species}_$release -c $gff $patch_gff";
exec "bp_fast_load_gff.pl -u root -p kentwashere -d ${species}_$release $dna";

