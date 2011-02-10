#!/usr/bin/perl

use strict;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::AutocompleteLoad;

my $script = $0 =~ /([^\/]+)$/ ? $1 : '';

my $version    = shift;
my $acedb_path = shift;
$version or die <<END;
Usage: $script [WSVERSION] [ACEDB PATH (optional)]
END

my $load = WormBase::AutocompleteLoad->new(-auto_dsn   => "autocomplete_$version",
					   -acedb_path => $acedb_path);

exit 0;

sub munge_name {
  my $object = shift;
  my $name = $object->name;
  $name =~ s/^\?//;
  $name;
}

