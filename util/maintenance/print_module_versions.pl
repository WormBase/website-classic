#!/usr/bin/perl
# Author: T. Harris

=pod

=head1 print_module_versions.pl

Track and display the versions of modules required for a WormBase
installation.

=head2 Purpose

This little script serves two purposes:

 1. Track all modules required for a WormBase installation
 2. Provide a convenient way of determining module versions for the
    INSTALL.pod

We will assume that the version of modules installed on the live site
should be the minimum required.

If you add a new module requirement to WormBase, please add it to the
list here.

=head1 Author

Todd Harris (harris@cshl.org)

=cut

use strict;

my @required = qw/
  Ace
  Bio::Das
  CGI
  CGI::Cache
  Cache::FileCache
  DBD::mysql
  DBI
  Digest::MD5
  GD
  IO::Scalar
  IO::String
  LWP
  Net::FTP
  Statistics::OLS
  Storable
  Text::Shellwords
  /;

my @optional = qw/
  GD::SVG
  SVG
  XML::Dom
  XML::Parser
  XML::Twig
  XML::Writer
/;

my $time = localtime;
print "WormBase Module Versions, generated $time\n\n";
print "Required modules\n";
print "----------------\n";
fetch_versions(@required);

print "\nOptional modules\n";
print "----------------\n";
fetch_versions(@optional);


sub fetch_versions {
 my @modules = @_;
 foreach (sort {$a cmp $b } @modules) {
   my $string = "'" . 'print $'  . "$_" . "::VERSION'";
  my $test =  eval "use $_; 1" ? 1 : undef;
  my $version;
  if ($test) {
    $version = `perl -M$_ -e $string`;
    $version = ($version eq '') ? 'no version provided' : $version;
  } else {
    $version = 'not installed';
  }
  printf "%-20s %-20s\n",$_,$version;
}
}
