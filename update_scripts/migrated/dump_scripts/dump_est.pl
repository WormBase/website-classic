#!/usr/bin/perl

# dump out an elegans EST file suitable for BLAST searching

use Ace;
use strict;

my $path = shift || 'rpcace://www.wormbase.org:200005';

# connect to database
my $db = Ace->connect($path) || die "Couldn't open database";
my $sock = $db->db;

$sock->query('query find cDNA_Sequence');
die "ace error: ",$sock->status,"\n"
  if $sock->status == STATUS_ERROR;
$sock->query('dna');

while ($sock->status == STATUS_PENDING) {
  my $h = $sock->read;
  $h =~ s/\0+\Z//; # get rid of nulls in data stream!
  $h =~ s!^//.*!!gm;
  print $h;
}



