#!/usr/bin/perl

use strict;
use lib '../../cgi-perl/lib';
use WormBase::AutocompleteLoad;

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

my $i = $ace->fetch_many(-class=>'Variation',-name => '*',-filled=>1) or die $ace->error;
while (my $variation = $i->next) {
  print STDERR "loaded $count variations$delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases   = grep {!$unique{$_}++} ($variation->name,$variation->CGC_name,$variation->Other_name,
					 $variation->Public_name);
  my $short_note = $variation->Remark;
  $a->insert_entity('Variation',$variation,\@aliases,[$short_note]);
}

$a->enable_keys;

exit 0;
