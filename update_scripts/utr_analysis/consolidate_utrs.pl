#!/usr/bin/perl
# author: Lincoln Stein, May 22, 2002
# see README file.

use strict;
use constant MINIMUM_GAP => 8;  # gaps to ignore

push @ARGV,'proposed_utrs_gaps_closed.txt' unless @ARGV;

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
  my %merge;

  foreach (@$p) {
    push @{$merge{$_->[1]}},$_;
  }

  my ($cds_start,$cds_end) = @{$merge{CDS}[0]}[3,4];
  die "no damn CDS!" unless $cds_start > 0;

  if ($cds_start < $cds_end) {
    merge_forward($cds_start,$cds_end,\%merge);
  } else {
    merge_reverse($cds_start,$cds_end,\%merge);
  }
}

sub merge_forward {
  my ($cds_start,$cds_end,$merge) = @_;

  # look for a "partially coding 5' UTR" and merge with "implied coding 5' UTR" if present
  my ($utr5_start,$utr5_end);
  my $utr5 = $merge->{"partially coding 5' UTR"}[0] || $merge->{"implied coding 5' UTR"}[0];
  if ($utr5) {
    ($utr5_start,$utr5_end) = @{$utr5}[3,4];
    $utr5_end = $cds_start - 1;
  }

  # merge this with the rightmost 5' non-coding UTR if present
  if (exists $merge->{"noncoding 5' UTR"} &&
      (my @nc = sort {$a->[4]<=>$b->[4]} @{$merge->{"noncoding 5' UTR"}})) {
    if ($nc[-1][4] + MINIMUM_GAP >= $utr5_start) {
      $utr5_start = $nc[-1][3];
      pop @nc;
      $merge->{"noncoding 5' UTR"} = @nc ? \@nc : undef;
    }
  }

  # repeat with 3' UTR
  my ($utr3_start,$utr3_end);
  my $utr3 = $merge->{"partially coding 3' UTR"}[0] || $merge->{"implied coding 3' UTR"}[0];
  if ($utr3) {
    ($utr3_start,$utr3_end) = @{$utr3}[3,4];
    $utr3_start             = $cds_end + 1;
  }

  # merge this with the leftmost 3' non-coding UTR if present
  if (exists $merge->{"noncoding 3' UTR"} &&
      (my @nc = sort {$a->[3]<=>$b->[3]} @{$merge->{"noncoding 3' UTR"}})) {
    if ($nc[0][3] - MINIMUM_GAP <= $utr3_end) {
      $utr3_end = $nc[0][4];
      pop @nc;
      $merge->{"noncoding 3' UTR"} = @nc ? \@nc : undef;
    }
  }

  print join("\n",map {join("\t",@$_)} @{$merge->{"noncoding 5' UTR"}}),"\n"
    if $merge->{"noncoding 5' UTR"};

  print join("\t",@{$utr5}[0,1,2],$utr5_start,$utr5_end),"\n"
    if $utr5;

  print join("\t",@{$merge->{CDS}[0]}),"\n";

  print join("\t",@{$utr3}[0,1,2],$utr3_start,$utr3_end),"\n"
    if $utr3;

  print join("\n",map {join("\t",@$_)} @{$merge->{"noncoding 3' UTR"}}),"\n" 
    if $merge->{"noncoding 3' UTR"};
}

sub merge_reverse {
  my ($cds_start,$cds_end,$merge) = @_;

  # look for a "partially coding 3' UTR" and merge with "implied coding 3' UTR" if present
  my ($utr3_start,$utr3_end);
  my $utr3 = $merge->{"partially coding 3' UTR"}[0] || $merge->{"implied coding 3' UTR"}[0];
  if ($utr3) {
    ($utr3_start,$utr3_end) = @{$utr3}[3,4];
    $utr3_end = $cds_end - 1;
  }
  # merge this with the rightmost 3' non-coding UTR if present
  if (exists $merge->{"noncoding 3' UTR"} &&
      (my @nc = sort {$a->[4]<=>$b->[4]} @{$merge->{"noncoding 3' UTR"}})) {
    if ($nc[-1][4] + MINIMUM_GAP >= $utr3_start) {
      $utr3_start = $nc[-1][3];
      pop @nc;
      $merge->{"noncoding 3' UTR"} = @nc ? \@nc : undef;
    }
  }

  # repeat with 5' UTR
  my ($utr5_start,$utr5_end);
  my $utr5 = $merge->{"partially coding 5' UTR"}[0] || $merge->{"implied coding 5' UTR"}[0];
  if ($utr5) {
    ($utr5_start,$utr5_end) = @{$utr5}[3,4];
    $utr5_start             = $cds_start + 1;
  }

  # merge this with the leftmost 5' non-coding UTR if present
  if (exists $merge->{"noncoding 5' UTR"} 
      && (my @nc = sort {$a->[3]<=>$b->[3]} @{$merge->{"noncoding 5' UTR"}})) {
    if ($nc[0][3] - MINIMUM_GAP <= $utr5_end) {
      $utr5_end = $nc[0][4];
      pop @nc;
      $merge->{"noncoding 5' UTR"} = @nc ? \@nc : undef;
    }
  }

  print join("\n",map {join("\t",@{$_}[0,1,2,4,3])} @{$merge->{"noncoding 3' UTR"}}),"\n" 
    if $merge->{"noncoding 3' UTR"};

  print join("\t",@{$utr3}[0,1,2],$utr3_end,$utr3_start),"\n"
    if $utr3;

  print join("\t",@{$merge->{CDS}[0]}),"\n";

  print join("\t",@{$utr5}[0,1,2],$utr5_end,$utr5_start),"\n"
    if $utr5;

  print join("\n",map {join("\t",@{$_}[0,1,2,4,3])} @{$merge->{"noncoding 5' UTR"}}),"\n"
    if $merge->{"noncoding 5' UTR"};

}
