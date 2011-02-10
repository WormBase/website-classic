#!/usr/bin/perl

use Bio::DB::GFF;

@ARGV = qw(I II III IV V X) unless @ARGV;

my $db = Bio::DB::GFF->new(-dsn=>'elegans:host=brie3') or die;
$db->absolute(1);

# work on each chromosome
for my $chr (@ARGV) {
  inspect_chromosome($chr);
}

# just for testing a case
# inspect_chromosome('T02G5');

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

  # find exons
  my @cds  = sort {$a->start<=>$b->start} grep {$_->group eq $gene->group} $gene->features(-type=>['CDS:curated']);
  

  # find ESTs and full-length RNAs that overlap
  my @left_rnas = $cds[0]->features(-type=>['EST_match:BLAT_EST_BEST',
					    'cDNA_match:BLAT_mRNA_BEST']);
  my @right_rnas = $cds[-1]->features(-type=>['EST_match:BLAT_EST_BEST',
					      'cDNA_match:BLAT_mRNA_BEST']);
  find_left_utr($cds[0],@left_rnas);
  find_right_utr($cds[-1],@right_rnas);
}

sub find_left_utr {
  my $exon = shift;
  my @rnas = @_;
  my $ref = $exon->abs_ref;

  my %rnas = map {$_->group=>$_} @rnas;

  # find the left-most overlapping EST/mRNA
  my $left_most;
  foreach (values %rnas) {
    # get the whole thing
    my ($full_alignment) = grep { $_->abs_ref eq $ref &&
				    $_->type =~ /BEST/ && 
				    $exon->overlaps($_) } $db->get_feature_by_name($_->class,$_->name);
    next unless $full_alignment;
    $left_most = $full_alignment 
      if !defined($left_most) || $full_alignment->low < $left_most->low;
  }
  return unless $left_most;

  my @segments       = sort {$a->low <=> $b->low} $left_most->segments;
  my $side = $exon->strand > 0 ? "5'" : "3'";
  my $right_most;
  foreach (@segments) {
    last if $_->low > $exon->low;  # done
    $right_most = $_;
    my $noncoding = $_->high < $exon->low;
    print join("\t",
	       $exon->name,
	       ($noncoding ? "noncoding $side UTR" : "partially coding $side UTR" ),
	       $_->abs_ref,$_->abs_low,$_->abs_high),"\n";
  }

  # handle case of rightmost not overlapping CDS
  if ($right_most && $right_most->high < $exon->low) {
    print join ("\t",
		$exon->name,
		"implied coding $side UTR",
		$right_most->abs_ref,$right_most->abs_low,$exon->low
	       ),"\n";
		
  }
}

sub find_right_utr {
  my $exon = shift;
  my @rnas = @_;

  # find the right-most overlapping EST/mRNA
  my $ref = $exon->abs_ref;
  my %rnas = map {$_->group=>$_} @rnas;

  my $right_most;
  foreach (values %rnas) {
    # get the whole thing
    my ($full_alignment) = 
      grep {  $_->type =~ /BEST/ &&
		$_->abs_ref eq $ref &&
		$exon->overlaps($_) } $db->get_feature_by_name($_->class,$_->name);
    next unless $full_alignment;
    $right_most = $full_alignment 
      if !defined($right_most) || $full_alignment->high > $right_most->high;
  }
  return unless $right_most;

  my @segments       = sort {$b->high <=> $a->high} $right_most->segments;

  my $side = $exon->strand > 0 ? "3'" : "5'";

  my $left_most;
  foreach (@segments) {
    last if $_->high < $exon->high;  # done
    $left_most = $_;
    my $noncoding = $_->low > $exon->high;
    print join("\t",
	       $exon->name,
	       ($noncoding ? "noncoding $side UTR" : "partially coding $side UTR" ),
	       $_->abs_ref,$_->abs_low,$_->abs_high),"\n";
  }

  # handle case of leftmost not overlapping CDS
  if ($left_most && $left_most->low > $exon->high) {
    print join ("\t",
		$exon->name,
		"implied coding $side UTR",
		$right_most->abs_ref,$exon->low,$left_most->abs_high,
	       ),"\n";
		
  }
}
