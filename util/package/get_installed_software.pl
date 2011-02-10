#!/usr/bin/perl

# Get the currently installed software version
use Getopt::Long;
use strict;

use constant PATH => '/usr/local/wormbase';

my ($path);
GetOptions('acedb=s' => \$path) || die <<USAGE;

Usage: get_installed_software_version.pl [optional path to acedb data dir]

  Check for the version of the currently installed software.

Unless supplied, this script will read the CVS tag of /usr/local/wormbase

Returns the WSXXX CVS tag version.

USAGE
;

$path = PATH unless defined $path;


my $version;;
if (-e $path) {
  if (-e "$path/CVS/TAG") {
    my $version = `tail -1 $path/CVS/TAG`;
  } else {
    # No CVS tag present? Must be using the live development version...
    $version = 'development release';
  }
} else {
  $version = 'none installed';
}

print STDERR $version;

1;
