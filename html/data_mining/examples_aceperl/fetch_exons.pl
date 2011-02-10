#!/usr/bin/perl

use Ace;
use strict;

my $db = Ace->connect(-host=>'aceserver.cshl.org',
		      -port=>'2005');
my $cds = $db->fetch('CDS' => 'JC8.10a');
my $dna = $cds->asDNA;

my $c = 1;
my (@markup,$pos,$flag);
foreach ($cds->Source_exons) {
  $c++;
  my ($start,$end) = $_->row(0);
  my $length = $end - $start + 1;
  #  print ">" . $c++ . " $start $end $length\n";
  my $seq = substr($dna,$pos,$length);
  print (($c % 2 == 0) ? uc($seq) : lc($seq));
  $pos += $length;
}
