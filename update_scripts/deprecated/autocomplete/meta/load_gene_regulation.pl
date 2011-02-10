#!/usr/bin/perl

use strict;
use lib '/usr/local/wormbase/cgi-perl/lib';
use Ace;
use WormBase::Autocomplete;

my $CLASS = 'Gene_regulation';

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
while (my $gene = $i->next) {
  print STDERR "loaded $count $CLASS objects$delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases   = grep {!$unique{$_}++} $gene;

  my @meta;
  my @genes = 
      ( $gene->Trans_regulator_gene,
	$gene->Trans_regulated_gene,
	eval { $gene->Trans_regulator_gene->Public_name },
	eval { $gene->Trans_regulated_gene->Public_name });

  push @meta,grep { ! $unique{$_}++ } @genes;
  push @meta,grep { ! $unique{$_}++ } map { $_->Public_name } @genes;
  push @meta,grep { ! $unique{$_}++ } ($gene->Cis_regulator_seq,$gene->Cis_regulated_seq);

  push @meta,grep { ! $unique{$_}++ } $gene->Reference;

  $a->insert_entity($CLASS,$gene,undef,\@aliases,[$gene->Remark,$gene->Summary].\@meta);
}

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";

$a->enable_keys;

exit 0;
