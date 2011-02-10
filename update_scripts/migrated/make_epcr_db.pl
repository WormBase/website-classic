#!/usr/bin/perl

# this simply concatenates the CHROMOSOME files into one long .fa
# file for the purposes of ePCR program.
use strict;

use constant CHUNKSIZE  => 1_000; # size of each line
use constant OVERLAP    => 50;     # oligos can't be larger than this

my ($fasta_dir, $epcr_dest, $oligo_dest) = @ARGV;

my $files = "$fasta_dir/CHROMOSOME_*.dna.gz";

my $generating_epcr;
unless (-e $epcr_dest && -M $epcr_dest <= -M "$fasta_dir/CHROMOSOME_I.dna.gz") { 
    open (EPCR,">$epcr_dest")   or die "Couldn't open $epcr_dest: $!";
    $generating_epcr++;
}
open (OLIGO,">$oligo_dest") or die "Couldn't open $oligo_dest: $!";

my ($sequence,$offset,$id);
@ARGV = map {"gunzip -c $_ |"} glob($files);

while (<>) {
    next if /^\s/; # Ignore empty lines
  s/^>CHROMOSOME_/>/;
  if ($generating_epcr) {
    print EPCR;
  }
  chomp;
 if (/>(\S+)/) {
    do_dump($id,\$offset,\$sequence) if $id;
    $id = $1;
    $id =~ s/^CHROMOSOME_//;
    $sequence = '';
    $offset   = 0;
    next;
  }
  $sequence .= $_;
  do_dump($id,\$offset,\$sequence) if $id;
}
do_dump($id,\$offset,\$sequence,1) if $id;

sub do_dump {
  my ($id,$offset,$seqref,$finish) = @_;
  my $limit  = $finish ? 0 : CHUNKSIZE;
  while (length $$seqref > $limit ) {
    my $seg = substr($$seqref,0,CHUNKSIZE);
    print OLIGO "$id:$$offset:$seg\n";
    substr($$seqref,0,CHUNKSIZE - OVERLAP) = '';
    $$offset += CHUNKSIZE - OVERLAP;
  }
}

