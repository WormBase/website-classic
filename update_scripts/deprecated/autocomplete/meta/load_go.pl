#!/usr/bin/perl

use strict;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;
use Ace;

my $CLASS = 'GO_term';

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

my $i = $ace->fetch_many(-class => $CLASS,
			 -name  => '*'    ,
			 -fill  => 1
			) or die $ace->error;

while (my $term = $i->next) {
  print STDERR "loaded $count $CLASS objects $delim" if ++$count % 100 == 0;

  my %unique;
  my @definition = $term->Definition;
  my @aliases   = grep {!$unique{$_}++} ($term,$term->Term,$term->Name);

  my @meta;
  push @meta,grep { !$unique{$_}++ } $term->Reference;
  push @meta,grep { !$unique{$_}++ } $term->Motif;

  # Genes
  my @genes = $term->Gene;
  push @meta,@genes;
  push @meta,grep { ! $unique{$_}++ } map {$_->Public_name} @genes;

  push @meta,grep { !$unique{$_}++ } $term->CDS;
  push @meta,grep { !$unique{$_}++ } $term->Sequence;
  push @meta,grep { !$unique{$_}++ } $term->Phenotype;
  push @meta,grep { !$unique{$_}++ } map { $_->Primary_name || $_->Short_name } $term->Phenotype;
  push @meta,grep { !$unique{$_}++ } $term->Anatomy_term;
  push @meta,grep { !$unique{$_}++ } map { $_->Term } $term->Anatomy_term;
  push @meta,grep { !$unique{$_}++ } $term->Expr_pattern;

  $a->insert_entity($CLASS,$term,undef,\@aliases,\@definition,\@meta);
}


warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;
