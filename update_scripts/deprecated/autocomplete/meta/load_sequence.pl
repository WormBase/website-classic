#!/usr/bin/perl

use strict;
use Ace;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

my $CLASS = 'Genome_sequence';

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

# dump papers
my $emacs = $ENV{EMACS};
my $delim = $emacs ? "\n" : "\r";
my $count;

my $total = $ace->count($CLASS => '*');
print STDERR "Loading $total $CLASS...\n";

my $i = $ace->fetch_many($CLASS => '*') or die $ace->error;
while (my $o = $i->next) {
  print STDERR "loaded $count $CLASS objects $delim" if ++$count % 100 == 0;
#	warn "$count: $o";
  my %unique;
  my @aliases  = grep {!$unique{$_}++} ($o->name,
					$o->at('DB_info.Database.EMBL[2]'),
					$o->at('DB_info.Database.GenBank[2]'));
  my @meta;
  push @meta,grep { !$unique{$_}++ } $o->From_laboratory;
  push @meta,grep { !$unique{$_}++ } $o->Species;
  push @meta,grep { !$unique{$_}++ } ($o->Matching_CDS,$o->CDS_child);
  push @meta,grep { !$unique{$_}++ } $o->Clone;
  push @meta,grep { !$unique{$_}++ } $o->GO_term;
  push @meta,grep { !$unique{$_}++ } map { $_->Term } $o->GO_term;

  push @meta,grep { !$unique{$_}++ } ($o->Gene,$o->Gene_child);
  push @meta,grep { !$unique{$_}++ } map { $_->Public_name } $o->Gene;

  push @meta,grep { !$unique{$_}++ } $o->Reference;
  push @meta,grep { !$unique{$_}++ } $o->Expr_pattern;
  push @meta,grep { !$unique{$_}++ } $o->RNAi;
  push @meta,grep { !$unique{$_}++ } $o->Keyword;


  my $short    = $o->Title;
  my $long     = $o->Remark;
  $a->insert_entity('Sequence',$o,undef,\@aliases,[$short,$long],\@meta);
}

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;
