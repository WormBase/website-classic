#!/usr/bin/perl

use strict;
use lib '../../cgi-perl/lib';
use WormBase::Autocomplete;
use Ace;

use constant CLASS =>'Person';

my $version    = shift;
my $acedb_path = shift;
$version or die <<END;
 Usage: load_people.pl [WSVERSION] [ACEDB PATH (optional)]
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

my $i = $ace->fetch_many(-class=>CLASS,-name => '*',-filled=>1) or die $ace->error;
while (my $o = $i->next) {
  print STDERR "loaded $count people$delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases   = grep {!$unique{$_}++} ($o->Full_name,$o->Last_name,$o->First_name);
  my $description = $o->Standard_name;
  $a->insert_entity(CLASS,$o,\@aliases,[$description]);
}

warn "Indexing...\n";
$a->enable_keys;

exit 0;
