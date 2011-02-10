#!/usr/bin/perl

# Check for the size of the download dir
# Purge it if requested

use Getopt::Long;
use strict;

use constant TMP => '/usr/local/tmp/wormbase';

my ($check,$purge,$path);
GetOptions('check=s' => \$check,
	   'purge=s'  => \$purge,
	   'path=s'   => \$path);

$check || $purge || die <<USAGE;

Usage: purge_downloads.pl [--check || --purge]

purge_downloads.pl --check  Return the size of the tmp download dir, in MB
purge_downloads.pl --purge  Empty the current download directory

Defaults to ~/.wormbase/downloads.  This can be overridden by supplying the
--path option.

USAGE
;

$path = TMP unless defined $path;

get_size() if ($check);
do_purge() if ($purge);

sub get_size {
  my $size = `du -hs $path`;
  $size = ($size =~ /\s*(.*)\s.*\s/) ? $1 : $size;
  print STDERR $size;
}

sub do_purge {
  if (-e $path) {
    system("rm -rf $path/*");
  }
  get_size();
}

sub interpolate {
  my $path = shift;
  my ($to_expand,$homedir);
  return $path unless $path =~ m!^~([^/]*)!;
 
  if ($to_expand = $1) {
    $homedir = (getpwnam($to_expand))[7];
  } else {
    $homedir = (getpwuid($<))[7];
  }
  return $path unless $homedir;
  $path =~ s!^~[^/]*!$homedir!;
  return $path;
}


1;
