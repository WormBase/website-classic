#!/usr/bin/perl

use strict;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;
use Ace;

my $CLASS = 'Motif';

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

my $i = $ace->fetch_many(-class=>$CLASS,-name => '*',-fill => 1) or die $ace->error;
while (my $o = $i->next) {
  #  next unless $gene->CGC_name =~ /unc/;
  print STDERR "loaded $count $CLASS objects $delim" if ++$count % 100 == 0;
  my %unique;

  my @aliases;
  push @aliases,$o->name;
  
  my (@meta);
  push @meta,grep { ! $unique{$_}++ } $o->GO_term;
  push @meta,grep { ! $unique{$_}++ } map { $_->Term } $o->GO_term;
  push @meta,grep { ! $unique{$_}++ } $o->Remark;
  push @meta,grep { ! $unique{$_}++ } $o->at('Database[3]');

  my $note = $o->Title;
  $a->insert_entity($CLASS,$o,undef,\@aliases,[$note],\@meta);
}

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;

