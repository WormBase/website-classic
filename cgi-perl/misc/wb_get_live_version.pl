#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use Bio::WormBase::Util::CheckVersions;

my $agent   = Bio::WormBase::Util::CheckVersions->new() or die "$!";

my $version = $agent->live_version;
print $version;

exit 0;
