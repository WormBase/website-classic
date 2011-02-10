#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use Bio::WormBase::Mirror;
use Getopt::Long;
use Sys::Hostname;

my ($CONFIG,$VERSION,$COMPONENT,$HELP,$FORCE);
GetOptions('config=s'       => \$CONFIG,
	   'version=s'      => \$VERSION,
	   'component=s'    => \$COMPONENT,
	   'help'           => \$HELP,
	   'force'          => \$FORCE,
	  );

my $USAGE = <<END;
Usage: install_component.pl --component [component] [options]

Install or upgrade a specific component of WormBase.

 Options:
 --config /path/to/configuration/file  see WormBase.pm for examples
 --version WSXXX  Install a certain version (if available)
 --force          Force installation, even if already up-to-date
END

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
die $USAGE if $HELP || !$COMPONENT;


my $agent = Bio::WormBase::Mirror->new(-config=>$CONFIG);

my $desired_version = $VERSION if $VERSION;
my $local_version = $agent->local_version;
my $live_version  = $agent->live_version;
$desired_version ||= $live_version;
my @components = split(",",$COMPONENT);

my $uptodate;
if ($local_version eq $desired_version) {
  $uptodate++;
}

foreach (@components) {
  $agent->install(-component=>$_,-version=>$desired_version) unless ($uptodate && !$FORCE);
}

if ($uptodate) {
  $agent->start_log_section(-msg => "Your WormBase installation is up-to-date (currently running $desired_version)");
}

exit 0;
