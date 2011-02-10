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

# dump anatomy terms
my $i = $ace->fetch_many(-class=>'Anatomy_term',-name => '*',-fill=>1) or die $ace->error;
while (my $term = $i->next) {
  my %unique;
  my @definition = $term->Definition;
  my @aliases   = grep {!$unique{$_}++} ($term->Term,$term->Synonym);
  $a->insert_entity('Anatomy_term',$term,\@aliases,\@definition);
}

$a->enable_keys;

exit 0;
