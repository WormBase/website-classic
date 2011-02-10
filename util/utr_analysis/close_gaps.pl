#!/usr/bin/perl

use strict;

# this program merges small gaps (less than 5 bp) in exons that are
# likely due to EST misalignments
use constant MINIMUM_GAP => 4;  # gaps to ignore
use constant MAX_UTR => 50_000;  # proposed utrs to ignore

push @ARGV,'proposed_utrs.txt' unless @ARGV;

my @previous;
while (<>) {
  chomp;
  my($gene,$type,$ref,$start,$end) = split "\t";
  if (!@previous or $gene eq $previous[0][0]) {
    push @previous,[$gene,$type,$ref,$start,$end];
    next;
  } else {
    emit(\@previous);
    @previous = [$gene,$type,$ref,$start,$end];
  }
}
emit(\@previous);

sub emit {
  my $p = shift;
  my ($cds_ref,$cds_low,$cds_hi);
  my %merge;

  foreach (@$p) {
    # sanity check - remove misassigned ESTs
    if ($_->[1] eq 'CDS') {
      $cds_ref = $_->[2];
      ($cds_low,$cds_hi) = $_->[3] < $_->[4] ? (@{$_}[3,4]) : (@{$_}[4,3]);
    }
    next unless $cds_ref eq $_->[2];
    next unless abs($cds_low  - $_->[3]) < MAX_UTR;
    next unless abs($cds_hi   - $_->[4]) < MAX_UTR;
    push @{$merge{$_->[1]}},$_;
  }

  foreach (keys %merge) {
    my @positions = sort {$a->[3]<=>$b->[3]} @{$merge{$_}};
    my @non_overlapping;
    foreach (@positions) {
      if (!@non_overlapping) {
	push @non_overlapping,$_;
      }
      elsif ($non_overlapping[-1][4]+MINIMUM_GAP >= $_->[3]) {
	$non_overlapping[-1][4] = $_->[4] if $_->[4] > $non_overlapping[-1][4];
      }
      else {
	push @non_overlapping,$_;
      }
    }
    print join("\n",map {join("\t",@$_)} @non_overlapping),"\n";
  }
}
