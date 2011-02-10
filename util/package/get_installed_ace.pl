#!/usr/bin/perl

# Author: T. Harris, 3/2004
# Check for the currently installed version of the database

use strict;
use Getopt::Long;

use constant ACEDB => '/usr/local/acedb/elegans';

my ($acedb);
GetOptions('acedb=s'       => \$acedb,
	  ) || die <<USAGE;
Usage: get_installed_ace.pl [optional path to acedb data dir]

  Check for the version of the currently installed database.

Unless supplied, script will read the target of the elegans symlink
at /usr/local/acedb/elegans.

Returns the WSXXX version.

USAGE
;

$acedb    = ACEDB     unless defined $acedb;

my $current_installed = get_current($acedb);
#return $current_installed;

sub get_current {
  my $dir = shift;
  my $installed;
  my $realdir = -l $dir ? readlink $dir : $dir;
  ($installed) = $realdir =~ /(WS\d+)$/;

  $installed = ($installed) ? $installed : 'None installed',"\n";
  print STDERR $installed;
  return $installed;
}
