#!/usr/bin/perl
# $Id: dump_names.pl,v 1.1.1.1 2010-01-25 15:36:09 tharris Exp $

# This is broken for Gene objects due to split nature of loci/genes
# Should simply look at genes and ignore polymorphisms

use strict;
use Bio::DB::GFF;
use Getopt::Long;
use Ace;

$SIG{CHLD} = sub {exit 0};

use constant ACEDB   => 'sace://www.wormbase.org:2005';
use constant GFFDSN => 'database=elegans;host=localhost';

my ($acedb,$gffdsn,$user,$pass);
GetOptions('acedb=s'  => \$acedb,
	   'gffdsn=s' => \$gffdsn,
	   'user=s'   => \$user,
	   'pass=s'   => \$pass,
	  ) || die <<USAGE;
Usage dump_names.pl [options...]

 Options:
    -acedb    Path to local acedb (for getting genes and other things
                     that aren't in the gff)
    -gffdsn   The GFF DSN (database=elegans;host=local)
    -user     Username for mysql access
    -pass     Password for mysql access
'
USAGE
;

$acedb  = ACEDB   unless defined $acedb;
$gffdsn = GFFDSN  unless defined $gffdsn;

my @auth;
push @auth,(-user=>$user) if $user;
push @auth,(-pass=>$pass) if $pass;

my $db  = Ace->connect($acedb) || die "Couldn't open database";
my $gff = Bio::DB::GFF->new(-dsn=>$gffdsn,@auth);
$gff->absolute(1);

my @loci = $db->fetch(Gene => '*');

for my $locus (@loci) {
  #  next if $locus->New_name; # no longer a valid test
  my $species = $locus->Species || "Caenorhabditis elegans";
#  my $type    = $locus->Type or next;
  my $genomic = join ',',$locus->Corresponding_CDS;
  my $other   = join ',',$locus->Other_sequence;
  my (undef,$chrom,undef,$position,undef,$error) = eval{$locus->Map(0)->row};
  my $genetic_map    = $chrom ? "$chrom:$position cM" : '';
  my ($sequence_map) = $gff->segment(($type eq 'Polymorphism' ? 'Allele' : 'Locus') => $locus->name);
  if ($sequence_map) {
    my $strand =  $sequence_map->length == 1 ? '.' 
                : $sequence_map->strand > 0  ? '+' 
                : '-';
    $sequence_map .= " bp ($strand)";
    $sequence_map  =~ s/,/../;
  }
  print join("\t",$locus,$species,$type,$genomic,$other,$genetic_map,$sequence_map),"\n";
}

exit 0;
