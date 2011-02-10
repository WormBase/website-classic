#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use Sys::Hostname;
use Bio::WormBase::Util::CheckVersions;
use Getopt::Long;
use Sys::Hostname;

my ($CONFIG,$HELP);
GetOptions('config=s'       => \$CONFIG,
	   'help'           => \$HELP,
	  );

# Dynamically discover the configuration file
# Useful when updating nodes
# These should be stored relative to the script itself (../conf/)
my $hostname = Sys::Hostname::hostname();
unless ($CONFIG) {
    if (-e "/usr/local/wormbase/update_scripts/conf/$hostname.cfg") {
	$CONFIG = "/usr/local/wormbase/update_scripts/conf/$hostname.cfg";
    } elsif (-e "/usr/local/wormbase-admin/update_scripts/conf/$hostname.cfg") {
	$CONFIG = "/usr/local/wormbase-admin/update_scripts/conf/$hostname.cfg";
    }
}

my $agent   = Bio::WormBase::Util::CheckVersions->new(-config => $CONFIG) or die "$!";
my $version = $agent->local_version;

print $version;

exit 0;
