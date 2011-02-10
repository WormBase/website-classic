#!/usr/bin/perl

use strict;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;
use Ace;

my $CLASS = 'Paper';

my $version    = shift;
my $acedb_path = shift;
$version or die <<END;
   load_papers.pl [WSVERSION] [ACEDB PATH (optional)]
END

my $a = WormBase::Autocomplete->new("autocomplete_$version");

my $ace;
if ($acedb_path) {
    $ace = Ace->connect(-path => $acedb_path);
} else {
    $ace = Ace->connect(-port=>2005,-host=>'localhost');
}

$a->disable_keys;

# dump papers
my $emacs = $ENV{EMACS};
my $delim = $emacs ? "\n" : "\r";
my $count;

my $total = $ace->count($CLASS => '*');
print STDERR "Loading $total $CLASS objects...\n";

my $i = $ace->fetch_many($CLASS => '*') or die $ace->error;
while (my $paper = $i->next) {
  print STDERR "loaded $count $CLASS objects $delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases  = grep {!$unique{$_}++} ($paper->name,$paper->PMID);
  my @meta;

  # Refers to
  my @genes = $paper->Gene;
  push @meta,grep { ! $unique{$_}++ } map { $_->Public_name } @genes;
  push @meta,grep { ! $unique{$_}++ } map { $_->Sequence_name } @genes;
  push @meta,grep { ! $unique{$_}++ } @genes;
  push @meta,grep { ! $unique{$_}++ } $paper->Allele;
  push @meta,grep { ! $unique{$_}++ } $paper->CDS;
  push @meta,grep { ! $unique{$_}++ } $paper->Sequence;
  push @meta,grep { ! $unique{$_}++ } $paper->Strain;
  push @meta,grep { ! $unique{$_}++ } $paper->Clone;
  push @meta,grep { ! $unique{$_}++ } $paper->Protein;
  push @meta,grep { ! $unique{$_}++ } $paper->Expr_pattern;
  push @meta,grep { ! $unique{$_}++ } $paper->RNAi unless $paper eq 'WBPaper00005655' or $paper eq 'WBPaper00005654' or 'WBPaper00025054';
  push @meta,grep { ! $unique{$_}++ } $paper->GO_term;
  push @meta,grep { ! $unique{$_}++ } map { $_->Term } $paper->GO_term;

  push @meta,grep { ! $unique{$_}++ } $paper->Gene_regulation;
  push @meta,grep { ! $unique{$_}++ } $paper->Anatomy_term;
  push @meta,grep { ! $unique{$_}++ } map { $_->Term } $paper->Anatomy_term;

  push @meta,grep { ! $unique{$_}++ } $paper->Keyword;

  foreach ($paper->Person) {
    push @meta,grep { ! $unique{$_}++ } $_->Last_name,$_->Standard_name,$_->Full_name;
  }

  my $short    = $paper->Brief_citation || $paper->Title;
  my $abstract = eval{$paper->Abstract->right};
  $a->insert_entity($CLASS,$paper,undef,\@aliases,[$short,$abstract],\@meta);
}


warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;

