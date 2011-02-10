#!/usr/bin/perl

use strict;
use Ace;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

my $CLASS = 'Variation';

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

my $emacs = $ENV{EMACS};
my $delim = $emacs ? "\n" : "\r";
my $count;

my $total = $ace->count($CLASS => '*');
print STDERR "Loading $total $CLASS...\n";

my $i = $ace->fetch_many(-class=>$CLASS,-name => '*',-filled=>1) or die $ace->error;
while (my $variation = $i->next) {
  print STDERR "loaded $count $CLASS objects $delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases   = grep {!$unique{$_}++} ($variation->name,$variation->CGC_name,$variation->Other_name,
					 $variation->Public_name);

  my @meta;
  push @meta,$variation->Rearrangement,
  
  # Genes, GeneIDs, Gene_class
  my @genes = $variation->Gene;
  push @meta,@genes;
  push @meta,grep { !$unique{$_}++ } map { $_->Public_name } @genes;
  push @meta,grep { !$unique{$_}++ } map { $_->Gene_class } @genes;

  # Sequences
  push @meta,grep { !$unique{$_}++ } $variation->Predicted_CDS;

  # Laboratory
  push @meta,grep { !$unique{$_}++ } $variation->Laboratory;

  # Papers
  push @meta,grep { !$unique{$_}++ } $variation->Reference;

  # Phenes
  push @meta,grep { !$unique{$_}++ } $variation->Phenotype;
  push @meta,grep { !$unique{$_}++ } $variation->Phenotype_remark;

  # Proteins
  push @meta,grep { !$unique{$_}++ } map { eval { $_->Corresponding_CDS->Corresponding_protein } } @genes;

  # Strains
  push @meta,grep { !$unique{$_}++ } $variation->Strain;

  # Species
  push @meta,grep { !$unique{$_}++ } $variation->Species;

  my $short_note = $variation->Remark;
  $a->insert_entity($CLASS,$variation,undef,\@aliases,[$short_note],\@meta);
}

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;
