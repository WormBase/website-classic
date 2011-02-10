#!/usr/bin/perl

use Bio::DB::GFF;
use strict;

my $version = shift;

my $gff = Bio::DB::GFF->new(-adaptor     => 'dbi::mysqlace',
			    -dsn         => "dbi:mysql:database=elegans_$version;host=localhost",
			    -user        => 'root',
			    -pass        => 'kentwashere',
			   ) or die "$!";

my @chromosomes = qw/I II III IV V X/;
foreach (@chromosomes) {
    my @segment = $gff->segment(Sequence=>$_);
	print join "\t",@segment,"\n";
}
