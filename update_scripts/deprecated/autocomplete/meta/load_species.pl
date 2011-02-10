#!/usr/bin/perl

use strict;
use Ace;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

my $CLASS = 'Species';

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
  my @aliases   = grep {!$unique{$_}++} ($o->name,$o->Genus,$o->Species,$o->Common_name);

  my @meta;
  push @meta,grep { !$unique{$_}++ } $o->Kingdom;
  push @meta,grep { !$unique{$_}++ } $o->Phylum;
  push @meta,grep { !$unique{$_}++ } $o->Class;
  push @meta,grep { !$unique{$_}++ } $o->Order;
  push @meta,grep { !$unique{$_}++ } $o->Family;

  my $display = ($o->Genus && $o->Species) ? join(' ',$o->Genus,$o->Species) : $o;
  $a->insert_entity($CLASS,$o,$display,\@aliases,undef,\@meta);
}

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;



exit 0;
