#!/usr/bin/perl

use strict;
use Ace;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

my $CLASS = 'Expr_pattern';

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
    print STDERR "loaded $count expression patterns$delim" if ++$count % 100 == 0;
    my %unique;
    my @aliases   = grep {!$unique{$_}++} $obj;;

    my @meta;

    # Expression of
    my @genes = $obj->Gene;
    push @meta,grep { !$unique{$_}++ } @genes;
    push @meta,grep { !$unique{$_}++ } map { $_->Public_name || $_->Sequence_name } @genes;
    push @meta,grep { !$unique{$_}++ } $obj->CDS;
    push @meta,grep { !$unique{$_}++ } $obj->Sequence;
    push @meta,grep { !$unique{$_}++ } $obj->Pseudogene;
    push @meta,grep { !$unique{$_}++ } $obj->Protein;

    # AO Term
    my @ao = $obj->Anatomy_term;
    push @meta,grep { !$unique{$_}++ } @ao;
    push @meta,grep { !$unique{$_}++ } map { $_->Term } @ao;
    push @meta,grep { !$unique{$_}++ } map { $_->Definition } @ao;

    # GO Term
    my @go = $obj->GO_term;
    push @meta,grep { !$unique{$_}++ } @go;
    push @meta,grep { !$unique{$_}++ } map { $_->Term } @go;
    push @meta,grep { !$unique{$_}++ } map { $_->Definition } @go;

    # Subcellular localization
    push @meta,grep { !$unique{$_}++ } $obj->Subcellular_localization;

    # Papers
    my @papers = $obj->Reference;
    push @meta,grep { !$unique{$_}++ } @papers;
    push @meta,grep { !$unique{$_}++ } map { $_->Author } @papers;

    foreach (@papers) {
	push @meta,grep { ! $unique{$_}++ } $_->Last_name,$_->Standard_name,$_->Full_name;
    }

    # Pattern
    push @meta,grep { !$unique{$_}++ } $obj->Pattern;

    # Laboratory
    push @meta,grep { !$unique{$_}++ } $obj->Laboratory;

    push @meta,grep { !$unique{$_}++ } $obj->Author;
    push @meta,grep { !$unique{$_}++ } $obj->Strain;
    push @meta,grep { !$unique{$_}++ } $obj->Transgene;
    push @meta,grep { !$unique{$_}++ } $obj->Antibody_info;


    my $short_note = $obj->Remark;
    $a->insert_entity($CLASS,$obj,undef,\@aliases,[$short_note],\@meta);
}

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;
