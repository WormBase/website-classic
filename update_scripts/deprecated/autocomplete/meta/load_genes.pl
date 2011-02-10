#!/usr/bin/perl

use strict;
use Ace;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

my $CLASS = 'Gene';

my $script = $0 =~ /([^\/]+)$/ ? $1 : '';

my $version    = shift;
my $acedb_path = shift;
$version or die <<END;
 Usage: $script [WSVERSION] [ACEDB PATH (optional)]
END

my $a = WormBase::Autocomplete->new("autocomplete_$version");

my $ace;
if ($acedb_path) {
    $ace = Ace->connect(-path => $acedb_path);
} else {
    $ace = Ace->connect(-port=>2005,-host=>'localhost');
}

$a->disable_keys;

# dump genes
my $emacs = $ENV{EMACS};
my $delim = $emacs ? "\n" : "\r";
my $count;

my $total = $ace->count($CLASS => '*');
print STDERR "Loading $total $CLASS...\n";

my $i = $ace->fetch_many(-class=>$CLASS,-name => '*',-fill => 1) or die $ace->error;
while (my $gene = $i->next) {
  #  next unless $gene->CGC_name =~ /unc/;
  print STDERR "loaded $count $CLASS objects $delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases   = grep {!$unique{$_}++} ($gene->name,
					 $gene->CGC_name,
					 $gene->Sequence_name,
					 $gene->Other_name,
					 $gene->Public_name,
					 $gene->Molecular_name);
  
  my @meta;
  push @meta,grep { !$unique{$_}++ } $gene->Allele;
  
  # Alias Anatomy_terms via Anatomy_function. As of 4/2007, these are not yet populated.
  push @meta,grep { !$unique{$_}++ } map { $_->Involved } $gene->Anatomy_function;

  # Clones and sequences
  my @cds = $gene->Corresponding_CDS;
  push @meta,grep { !$unique{$_}++ } @cds;
  push @meta,grep { !$unique{$_}++ } map { $_->Sequence } @cds;
  
  # Expression patterns via Anatomy_term descriptions
  my @AO_terms = grep { !$unique{$_}++ } map { $_->Anatomy_term } $gene->Expr_pattern;
  push @meta,grep { !$unique{$_}++ } map { $_->Term } @AO_terms;
  push @meta,$gene->Expr_pattern;
  
  my @GO_terms = $gene->GO_term;
  push @meta,grep { !$unique{$_}++ } map { $_->Term } @GO_terms;
  push @meta,@GO_terms;

  push @meta,$gene->Gene_class;

  # Gene_regulation
  my @gr = ($gene->Trans_regulator,$gene->Trans_target);
  push @meta,grep { ! $unique{$_}++ } @gr;

  # Should also probably step into the GR class and fetch Genes, seqs, CDSs...

  # Laboratory
  push @meta,grep { ! $unique{$_}++ } $gene->Laboratory;

  # Papers
  push @meta,grep { ! $unique{$_}++ } $gene->Reference;

  # Phenotype
  push @meta,grep { ! $unique{$_}++ } $gene->Phenotype;

  # Operon
  push @meta,grep { ! $unique{$_}++ } $gene->Contained_in_operon;

  # RNAi
  push @meta,grep { ! $unique{$_}++ } $gene->RNAi_result;

  # Strains
  push @meta,grep { ! $unique{$_}++ } $gene->Strain;

  # Species
  push @meta,grep { !$unique{$_}++ } $gene->Species;

  my $short = $gene->Concise_description;
  my $long  = $gene->Provisional_description;

  my $display_name = $gene->Public_name
      || $gene->CGC_name
      || $gene->Molecular_name
      || $gene->Sequence_name;

  $a->insert_entity($CLASS,$gene,$display_name,\@aliases,[$short,$long],\@meta);
}

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;
