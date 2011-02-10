#!/usr/bin/perl

use strict;
use Ace;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

my $CLASS = 'Laboratory';

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
    print STDERR "loaded $count $CLASS$delim" if ++$count % 100 == 0;
    my %unique;
    my @aliases   = grep {!$unique{$_}++} $obj;

    my @meta;

    push @meta,grep { !$unique{$_}++ } $obj->Strain_designation;
    push @meta,grep { !$unique{$_}++ } $obj->Allele_designation;
    
    my @people = $obj->Representative;
    push @people,$obj->Registered_lab_members;
    push @people,$obj->Past_lab_members;
    push @meta,grep { !$unique{$_}++ } @people;
    push @meta,grep { !$unique{$_}++ } map { $_->Full_name } @people;
    push @meta,grep { !$unique{$_}++ } map { $_->Last_name } @people;
    push @meta,grep { !$unique{$_}++ } map { $_->Standard_name } @people;

    push @meta,grep { !$unique{$_}++ } $obj->Alleles;
    push @meta,grep { !$unique{$_}++ } $obj->Gene_classes;
    
    my $short_note = $obj->Remark;
    $a->insert_entity($CLASS,$obj,undef,\@aliases,[$short_note],\@meta);
}

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;
