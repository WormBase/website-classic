
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

print STDERR "Loading all Protein IDs...\n";
$load->load_object_names('Protein');  # all proteins

print STDERR "Loading WormPep IDs and aliases...\n";
$load->load_class(-autocomplete_class => 'WormPep',
		  -query              => 'find Protein WormPep',
		  -aliases            => ['DB_info.Database[3]','Corresponding_CDS'],		  
		  -fill               => 'DB_info');

print STDERR "Loading BrigPep IDs and aliases...\n";
$load->load_class(-autocomplete_class => 'BrigPep',
		  -query              => 'find Protein BrigPep',
		  -aliases            => ['DB_info.Database[3]','Corresponding_CDS'],
		  -fill               => 'DB_info');

exit 0;

