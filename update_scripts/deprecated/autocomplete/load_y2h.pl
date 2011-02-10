#!/usr/bin/perl

use strict;
use lib '../../cgi-perl/lib';
use WormBase::AutocompleteLoad;

my $script = $0 =~ /([^\/]+)$/ ? $1 : '';

my $version    = shift;
my $acedb_path = shift;
$version or die <<END;
Usage: $script [WSVERSION] [ACEDB PATH (optional)]
END

my $load = WormBase::AutocompleteLoad->new(-auto_dsn => "autocomplete_$version",
					   -ace_path => $acedb_path);

$load->load_class(
		  -class=>'YH',
		  -fill=>1,
		  -aliases => ['Interactor.Bait[2]',
			       'Interactor.Target[2]'
			       ]
		  );

exit 0;
