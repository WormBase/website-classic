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

$load->load_class(-autocomplete_class=>'Genome_sequence',
		  -query             =>'find Genome_sequence',
		  -aliases           =>[
					'DB_info.Database.EMBL[2]',
					'DB_info.Database.GenBank[2]',
					],
		  -fill              => 'DB_info',
		  );

$load->load_object_names('Sequence');
exit 0;

