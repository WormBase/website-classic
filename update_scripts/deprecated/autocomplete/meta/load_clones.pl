#!/usr/bin/perl

use strict;
use Ace;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

my $CLASS = 'Clone';

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
while (my $obj = $i->next) {
    print STDERR "loaded $count clones$delim" if ++$count % 100 == 0;
    my %unique;
    my @aliases   = grep {!$unique{$_}++} $obj;;

    my @meta;

    # PCR
    push @meta,grep { !$unique{$_}++ } $obj->PCR_product;

    # Papers
    push @meta,grep { !$unique{$_}++ } $obj->Reference;

    # Sequences
    push @meta,grep { !$unique{$_}++ } $obj->Sequence;

    # Accessions
    push @meta,grep { !$unique{$_}++ } $obj->at('DB_info.Databases[3]');

    # Strains
    push @meta,grep { !$unique{$_}++ } $obj->In_strain;

    my @exp = $obj->Expr_pattern;
    push @meta,grep { !$unique{$_}++ } @exp;
    push @meta,grep { !$unique{$_}++ } map { $_->Anatomy_term } @exp;
    push @meta,grep { !$unique{$_}++ } map { eval { $_->Anatomy_term->Term } } @exp;

    my $short_note = $obj->Remark;
    $a->insert_entity($CLASS,$obj,undef,\@aliases,[$short_note],\@meta);
}

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;
