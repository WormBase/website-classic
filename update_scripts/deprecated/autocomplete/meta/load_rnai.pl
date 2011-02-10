#!/usr/bin/perl

use strict;
use Ace;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

my $CLASS = 'RNAi';

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
while (my $o = $i->next) {
  print STDERR "loaded $count $CLASS objects $delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases   = grep {!$unique{$_}++} ($o->name,$o->History_name);

  my @meta;

  push @meta,grep { !$unique{$_}++ } $o->Predicted_gene;
  push @meta,grep { !$unique{$_}++ } $o->Gene;
  push @meta,grep { !$unique{$_}++ } map { $_->Public_name} $o->Gene;
  push @meta,grep { !$unique{$_}++ } $o->at('DB_info.Database[3]');

  push @meta,grep { !$unique{$_}++ } $o->Gene_regulation;
  push @meta,grep { !$unique{$_}++ } $o->Reference;
  push @meta,grep { !$unique{$_}++ } $o->PCR_product;
  push @meta,grep { !$unique{$_}++ } $o->Phenotype;
  push @meta,grep { !$unique{$_}++ } $o->Strain;
  push @meta,grep { !$unique{$_}++ } $o->Laboratory;
  push @meta,grep { !$unique{$_}++ } $o->Genotype;
  push @meta,grep { !$unique{$_}++ } $o->Sequence;

  my $short = $o->Remark;
  $a->insert_entity($CLASS,$o,undef,\@aliases,[$short],\@meta);
}

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;
