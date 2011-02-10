#!/usr/bin/perl

use strict;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

my $script = $0 =~ /([^\/]+)$/ ? $1 : '';

my $version = shift;
my $user    = shift;
my $pass    = shift;
$version or die <<END;
Usage: $script [WSVERSION] [MYSQLUSER] [MYSQLPASS]
END

my $a = WormBase::Autocomplete->new("autocomplete_$version",$user,$pass);
$a->init;

1;
