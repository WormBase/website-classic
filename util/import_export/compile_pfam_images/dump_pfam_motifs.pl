#!/usr/bin/perl

use Ace;
use strict;
use Time::Format qw(%time);
use Data::Dumper;

#
# Dump PFAM motifs
#

my $usage =
  "$0 [<host> <port> | <path>]; defaults to aceserver.cshl.org:2005";

my ($host, $port) = @ARGV;

if (!$host && !$port) {
    $host = "aceserver.cshl.org";
    $port = 2005;
}

my $dbh =
  ($host && $port)
  ? Ace->connect(-host => $host, -port => $port)
  : Ace->connect(-path => $host);
$dbh || die "Couldn't open database ($host, $port)";

my $xml_ref = {};

dump_pfam_motifs($dbh);

$dbh->close;

# [END]

sub dump_pfam_motifs {
    my ($dbh, $file) = @_;

    my $command = qq[find Motif PFAM*];

    my $iterator = $dbh->fetch_many(-query => $command)
      || die "Cannot fetch ($command)";

    my $time = $time{"yyyy-mm-dd hh:mm:ss"};

    my %ids;

    while (my $object = $iterator->next) {
        my $id = $object;

        $ids{$id} = 1;
    }

    print "# $time\n";

    foreach my $id (sort keys %ids) {
        print "$id\n";
    }

    return 1;
}
