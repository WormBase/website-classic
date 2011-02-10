#!/usr/bin/perl

# $Id: dump_swissprot.pl,v 1.1.1.1 2010-01-25 15:36:09 tharris Exp $

use strict;
use Bio::DB::GFF;
use Getopt::Long;
use Ace;

$SIG{CHLD} = sub {exit 0};

use constant ACEDB   => 'sace://www.wormbase.org:2005';

my ($acedb,$gffdsn,$user,$pass);
GetOptions('acedb=s'  => \$acedb,
	  ) || die <<USAGE;
Usage dump_names.pl [options...]

 Options:
    -acedb    Path to local acedb
USAGE
;

$acedb  = ACEDB   unless defined $acedb;
my $db1  = Ace->connect($acedb) || die "Couldn't open database";
my $db2  = Ace->connect($acedb) || die "Couldn't open database";

print join "\t",qw(#WormPep CDS  SwissProtAc  SwissProtID Description),"\n";
my $iterator = $db1->fetch_many(-query=>'find Protein WormPep AND Live',-filltag=>'Database');
while (my $p = $iterator->next) {
   my $wormpep       = "$p";
   my $swissprot_id  = $p->Database(0)->at('SwissProt.SwissProt_ID[1]');
   my $swissprot_acc = $p->Database(0)->at('SwissProt.SwissProt_AC[1]');
   my($seq,$desc);
   eval {
     $seq           = $db2->fetch(CDS => $p->Corresponding_CDS);
     $desc          = $seq->Brief_identification;
   };
   next unless $seq && $wormpep;
   print join("\t",$wormpep,$seq,$swissprot_id,$swissprot_acc,$desc),"\n";
}
