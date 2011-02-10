#!/usr/bin/perl

# Author: Payan Canaran (canaran@cshl.org)
# Copyright 2007 Cold Spring Harbor Laboratory

=head1 NAME

make_thumbnails.pl

=head1 DESCRIPTION

...

=cut

use strict;
use Image::Thumbnail;
use Getopt::Long;
use Carp;
use Data::Dumper;

my $pattern;
my $out_dir;

my $usage = <<USAGE;
$0 -pattern <pattern> -out_dir <out_dir>
  pattern : Glob pattern (must be in single quotes)
  out_dir : Output directory
USAGE

my $result = GetOptions(
    'pattern=s' => \$pattern,
    'out_dir=s' => \$out_dir,
) or croak("Usage: $usage");

croak("Usage: $usage") unless ($pattern and $out_dir);

my @files = glob($pattern);

foreach my $file (@files) {
    print "Processing file ($file) ...\n";

    my ($source_file_name) = $file =~ /([^\/]+)$/;
    my $ext = $1 if $source_file_name =~ s/\.([^\.]*)$//;

    my $thumb_file = qq[$out_dir/$source_file_name-thumbnail.$ext];

    my $t = new Image::Thumbnail(
        module     => 'GD',
        size       => 70,
        input      => $file,
        outputpath => $thumb_file,
    );

    $t->create;
}
