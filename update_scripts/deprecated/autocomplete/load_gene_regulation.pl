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

my $i = $ace->fetch_many(-class=>'Gene_regulation',-name => '*',-filled=>1) or die $ace->error;
while (my $gene = $i->next) {
  print STDERR "loaded $count genes$delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases   = grep {!$unique{$_}++} ($gene->name,eval { $gene->Trans_regulator_gene->Public_name } ,eval { $gene->Trans_regulated_gene->Public_name },
					 $gene->Cis_regulator_seq,$gene->Cis_regulated_seq);

  $a->insert_entity('Gene_regulation',$gene,\@aliases,[$gene->Remark,$gene->Summary]);
}

$a->enable_keys;

exit 0;
