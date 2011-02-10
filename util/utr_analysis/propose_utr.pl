#!/usr/bin/perl

use Bio::DB::GFF;
my $db = Bio::DB::GFF->new(-dsn=>'elegans:host=brie3') or die;

# work on each chromosome
for my $chr (qw(I II III IV V X)) {
  inspect_chromosome($chr);
}

sub inspect_chromosome {
  my $chr = shift;
  my $segment  = $db->segment($chr);
  for my $s ($segment->features('Sequence:curated')) {
    find_utrs($s);
  }
}

sub find_utrs {
  my $gene = shift;
  print join("\t",
	     $gene->name,
	     'CDS',
	     $gene->abs_ref,$gene->abs_start,$gene->abs_end),"\n";
  # debug
  # return;

  # find ESTs and full-length RNAs that overlap
  my @rnas = $gene->features(-type=>['similarity:BLAT_EST_BEST',
				     'similarity:BLAT_mRNA_BEST']);
  find_left_utr($gene,@rnas);
  find_right_utr($gene,@rnas);
}

sub find_left_utr {
  my $gene = shift;
  my @rnas = @_;
  my $ref = $gene->abs_ref;

  my %rnas = map {$_->group=>$_} @rnas;

  # find the left-most overlapping EST/mRNA
  my $left_most;
  foreach (values %rnas) {
    # get the whole thing
    my ($full_alignment) = grep { $_->abs_ref eq $ref &&
				    $_->type =~ /BEST/ && 
				    $gene->overlaps($_) } $db->get_feature_by_name($_->class,$_->name);
    next unless $full_alignment;
    $left_most = $full_alignment 
      if !defined($left_most) || $full_alignment->low < $left_most->low;
  }
  return unless $left_most;

  my @segments       = sort {$a->low <=> $b->low} $left_most->segments;
  my $side = $gene->strand > 0 ? "5'" : "3'";
  my $right_most;
  foreach (@segments) {
    last if $_->low > $gene->low;  # done
    $right_most = $_;
    my $noncoding = $_->high < $gene->low;
    print join("\t",
	       $gene->name,
	       ($noncoding ? "noncoding $side UTR" : "partially coding $side UTR" ),
	       $_->abs_ref,$_->abs_start,$_->abs_end),"\n";
  }

  # handle case of rightmost not overlapping CDS
  if ($right_most && $right_most->high < $gene->low) {
    print join ("\t",
		$gene->name,
		"implied coding $side UTR",
		$right_most->abs_ref,$right_most->abs_start,$gene->low
	       ),"\n";
		
  }
}

sub find_right_utr {
  my $gene = shift;
  my @rnas = @_;

  # find the right-most overlapping EST/mRNA
  my $ref = $gene->abs_ref;
  my %rnas = map {$_->group=>$_} @rnas;

  my $right_most;
  foreach (values %rnas) {
    # get the whole thing
    my ($full_alignment) = 
      grep {  $_->type =~ /BEST/ &&
		$_->abs_ref eq $ref &&
		$gene->overlaps($_) } $db->get_feature_by_name($_->class,$_->name);
    next unless $full_alignment;
    $right_most = $full_alignment 
      if !defined($right_most) || $full_alignment->high > $right_most->high;
  }
  return unless $right_most;

  my @segments       = sort {$b->high <=> $a->high} $right_most->segments;

  my $side = $gene->strand > 0 ? "3'" : "5'";

  my $left_most;
  foreach (@segments) {
    last if $_->high < $gene->high;  # done
    $left_most = $_;
    my $noncoding = $_->low > $gene->high;
    print join("\t",
	       $gene->name,
	       ($noncoding ? "noncoding $side UTR" : "partially coding $side UTR" ),
	       $_->abs_ref,$_->abs_start,$_->abs_end),"\n";
  }

  # handle case of leftmost not overlapping CDS
  if ($left_most && $left_most->low > $gene->high) {
    print join ("\t",
		$gene->name,
		"implied coding $side UTR",
		$right_most->abs_ref,$gene->low,$left_most->abs_stop,
	       ),"\n";
		
  }
}
