#!/usr/bin/perl

use strict;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;
use Ace;

my $CLASS = 'Person';

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

my $emacs = $ENV{EMACS};
my $delim = $emacs ? "\n" : "\r";
my $count;

my $total = $ace->count($CLASS => '*');
print STDERR "Loading $total $CLASS...\n";

my $i = $ace->fetch_many(-class=>$CLASS,-name => '*',-filled=>1) or die $ace->error;
while (my $o = $i->next) {
  print STDERR "loaded $count $CLASS objects$delim" if ++$count % 100 == 0;
  next if $o->Merged_into || $o->Status eq 'Invalid';

  my %unique;
  my @aliases;
  push @aliases,grep {!$unique{$_}++} ($o,$o->Full_name,$o->Last_name,$o->First_name);

  my $description = $o->Standard_name;

  my @meta;
  push @meta,grep { !$unique{$_}++ } $o->Laboratory,$o->CGC_representative_for;

  my $display = $o->Full_name || $o->Standard_name || undef;
  $a->insert_entity($CLASS,$o,$display,\@aliases,[$description],\@meta);
}

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;
