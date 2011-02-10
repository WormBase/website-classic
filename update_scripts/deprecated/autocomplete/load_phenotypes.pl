#!/usr/bin/perl

use strict;
use lib '../../cgi-perl/lib';
use WormBase::Autocomplete;
use Ace;

use constant CLASS =>'Phenotype';

my $version    = shift;
my $acedb_path = shift;
$version or die <<END;
 Usage: load_phenotypes.pl [WSVERSION] [ACEDB PATH (optional)]
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

my $i = $ace->fetch_many(-class=>CLASS,-name => '*',-filltags=>['Primary_name',
								'Short_name',
								'Synonym']) or die $ace->error;
while (my $o = $i->next) {
  print STDERR "loaded $count phenotypes$delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases   = grep {!$unique{$_}++} ($o->Primary_name,$o->Short_name,$o->Synonym);
  my $description = $o->Primary_name;
  $a->insert_entity(CLASS,$o,\@aliases,[$description]);
}

warn "Indexing...\n";
$a->enable_keys;

exit 0;
