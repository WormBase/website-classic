#!/usr/bin/perl

# This dumps out the table of interpolated genetic map positions for
# all of the clones.
# This query is too slow to do on the fly alas!

use Ace;
use strict;

my $path = shift || 'sace://brie3.cshl.org:2005';

# connect to database
my $db = Ace->connect($path) || die "Couldn't open database";
my $query = <<END;
select g,g->Interpolated_gmap,g->Interpolated_gmap[2] 
  from g in class "Genome_sequence" 
  where exists_tag g->Interpolated_gmap 
  order by :2 asc, :3 asc
END
;
$query =~ s/\n/ /g;
my @rows = $db->aql($query);

foreach (@rows) {
  print join("\t",@$_),"\n";
}

exit 0;
