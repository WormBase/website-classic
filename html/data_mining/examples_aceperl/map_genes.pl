#!/usr/bin/perl

=begin metadata

This metadata is used to autogenerate indices of example scripts.

<metadata>
  <filename>map_genes.pl</filename>
  <purpose>Provided with a list of genes, proteins, or loci, retrieve their linkage group and genetic map position.</purpose>
  <concepts>AcePerl</concepts>
  <date>24 August 2004</date>
  <author>Todd Harris</author>
  <author_email>harris@cshl.org</author_email>
</metadata>

=end metadata


use Ace;

# Take a list of genes, retrieving their genetic map position and chromosome.
my $db = Ace->connect(-path=>'/usr/local/acedb/elegans');


my $map = {};
while (<>) {
  chomp;
  my $gene_name = $db->fetch('Gene_name' => $_);
  my $gene = $gene_name->Public_name_for || $gene_name->Sequence_name_for || $gene_name->CGC_name_for
    || $gene_name->Molecular_name_for || $gene_name->Other_name_for;

  my ($chromosome,$position) = get_position($gene);
  push (@{$map->{$chromosome}},[$_,$gene,$position]);
}

foreach my $chrom (qw/I II III IV V X/) {
  my @sorted = sort {$a->[2] <=> $b->[2]} @{$map->{$chrom}};
  foreach my $gene (@sorted) {
    printf "%-5s %-8s %-16s %-10s\n",$chrom,@$gene;
  }
}


sub get_position {
  my $gene = shift;
  my $chromosome = $gene->get(Map=>1);
  my $position   = $gene->get(Map=>3);
  return ($chromosome,$position) if $chromosome;
  if (my $m = $gene->get('Interpolated_map_position')) {
    ($chromosome,$position) = $m->right->row;
    return ($chromosome,$position) if $chromosome;
  }
}
