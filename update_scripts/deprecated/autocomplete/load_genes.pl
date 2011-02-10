#!/usr/bin/perl

use strict;
use lib '../../cgi-perl/lib';
use WormBase::Autocomplete;
use Ace;

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

my $i = $ace->fetch_many(-class=>'Gene',-name => '*',-filled=>1) or die $ace->error;
while (my $gene = $i->next) {
  print STDERR "loaded $count genes$delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases   = grep {!$unique{$_}++} ($gene->name,
					 $gene->CGC_name,
					 $gene->Sequence_name,
					 $gene->Other_name,
					 $gene->Public_name,
					 $gene->Molecular_name,
					 $gene->Allele);

  # Alias Anatomy_terms via Anatomy_function
  # as of 4/2007, these are not yet populated.
  my %seen;
  push @aliases,grep { !$seen{$_}++ } map { $_->Involved } $gene->Anatomy_function;

  # Clones
  push @aliases,grep { !$seen{$_}++ } map { $_->Sequence } $gene->Corresponding_CDS;
  
  # Expression patterns via Anatomy_term descriptions
  my @AO_terms = grep { !$seen{$_}++ } map { $_->Anatomy_term } $gene->Expr_pattern;
  push @aliases,grep { !$seen{$_}++ } map { $_->Term } @AO_terms;
  
  my @GO_terms = $gene->GO_term;
  push @aliases,grep { !$seen{$_}++ } map { $_->Term } @GO_terms;;
  push @aliases,@GO_terms;

  push @aliases,$gene->Gene_class;

  # Gene_regulation
  push @aliases,$gene->Trans_regulator,$gene->Trans_target;

  # Laboratory
  push @aliases,$gene->Laboratory;

  # Papers
  push @aliases,$gene->Reference;

  # Phenotype
  push @aliases,$gene->Phenotype;

  # Operon
  push @aliases,$gene->Contained_in_operon;

  # RNAi
  push @aliases,$gene->RNAi_result;

  # Strains
  push @aliases,$gene->Strain;

  my $short = $gene->Concise_description;
  my $long  = $gene->Provisional_description;
  $a->insert_entity('Gene',$gene,\@aliases,[$short,$long]);
}

warn "Indexing...\n";
$a->enable_keys;

exit 0;
