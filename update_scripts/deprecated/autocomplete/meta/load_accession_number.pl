#!/usr/bin/perl

use strict;
use Ace;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

my $CLASS = 'Accession_number';

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

my $i = $ace->fetch_many(-class=>$CLASS,-name => '*') or die $ace->error;
while (my $ac = $i->next) {
    print STDERR "loaded $count $CLASS objects$delim" if ++$count % 100 == 0;
    warn $ac;
    my %unique;
    my @aliases   = $ac;    
    my @meta;

    # Sequences
    push @meta,grep { !$unique{$_}++ } $ac->Sequence;
    push @meta,grep { !$unique{$_}++ } $ac->CDS;
    push @meta,grep { !$unique{$_}++ } $ac->Protein;
    push @meta,grep { !$unique{$_}++ } $ac->Motif;
    push @meta,grep { !$unique{$_}++ } $ac->Clone;
    $a->insert_entity($CLASS,$ac,undef,\@aliases,undef,\@meta);
}

exit 0;

