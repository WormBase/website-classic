#!/usr/bin/perl

use Ace;

$db = Ace->connect(-host=>'localhost',-port=>'2005');
@genes = $db->fetch(Gene=>'*');
foreach (@genes) {
	my $ts = $_->timestamp;
        print "$_ $ts\n";
}
