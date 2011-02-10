#!/usr/bin/perl
# $Id: invert_waba.pl,v 1.1.1.1 2010-01-25 15:36:09 tharris Exp $
# invert a waba file so that query becomes target

# IMPORTANT: This script must be run intermittently on the C. elegans
# GFF dumps in order to create a compatible WABA alignment file for
# loading into the briggsae database.  Otherwise the synteny browser
# will no longer work properly.
#
# to clean out the database first, do this
# % mysql briggsae
# mysql> select * from ftype where fsource LIKE 'waba%';
# +---------+------------+-------------+
# | ftypeid | fmethod    | fsource     |
# +---------+------------+-------------+
# |       4 | similarity | waba_coding |
# |       6 | similarity | waba_strong |
# |       5 | similarity | waba_weak   |
# +---------+------------+-------------+
# mysql> delete from fdata where ftypeid in (4,5,6);
# invert_waba.pl > ~/briggsae.waba.gff
# bp_fast_load_gff.pl -d briggsae ~/briggsae.waba.gff

use strict;
unless (@ARGV) {
  my @gff_files = <~ftp/pub/wormbase/GENE_DUMPS/elegansWS*.gff.gz>;
  my ($most_recent) = map {$_->[0]} sort {$b->[1] <=> $a->[1]} map { /(\d+)/ && [$_,$1] } @gff_files;
  @ARGV = "gunzip -c $most_recent |";
}

while (<>) {
  chomp;
  my ($ref,$source,$method,$start,$end,$score,$strand,$phase,$target) = split "\t";
  next unless $method eq 'similarity' && $source =~ /waba/;
  $ref =~ s/^CHROMOSOME_//;
  my ($targ,$t_start,$t_end) = $target =~ /Target "Sequence:(\S+)" (\d+) (\d+)/;
  if ($t_start > $t_end) {
    ($start,$end)     = ($end,$start);
    ($t_start,$t_end) = ($t_end,$t_start);
  }

  print join("\t",($targ,$source,$method,$t_start,$t_end,$score,'.',$phase,
		   qq(Target "Sequence:$ref" $start $end)
		  )),"\n";
}
