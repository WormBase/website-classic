#!/usr/bin/perl

use strict;
use Ace;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

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

do_load('WormPep');
do_load('BrigPep');

$a->enable_keys;

exit 0;



sub do_load {
    my $class = shift;

    my $emacs = $ENV{EMACS};
    my $delim = $emacs ? "\n" : "\r";
    my $count;

    my $total = $ace->count($class => '*');
    print STDERR "Loading $total $class...\n";
    
    my $i = $ace->fetch_many(-class=>$class,-name => '*',-filled=>1) or die $ace->error;
    while (my $protein = $i->next) {
	print STDERR "loaded $count proteins$delim" if ++$count % 100 == 0;
	
	my %unique;
	my @aliases   = grep {!$unique{$_}++} ($protein->name,
					       $protein->Corresponding_CDS);

	push @aliases,$protein->at('DB_info.Database[3]');

	my @meta;
	# Expression patterns via Anatomy_term descriptions
	my @AO_terms = grep { !$unique{$_}++ } map { $_->Anatomy_term } $protein->Expr_pattern;
	push @meta,grep { !$unique{$_}++ } map { $_->Term } @AO_terms;
	push @meta,$protein->Expr_pattern;
	
	# Genes:
	my @CDS = $protein->Corresponding_CDS;
	my @genes = map { $_->Gene } @CDS;
	push @meta,grep { !$unique{$_}++ } map { $_->Public_name } @genes;
	push @meta,grep { !$unique{$_}++ } @genes;

	# Gene_class
	push @meta,grep { !$unique{$_}++ } map { $_->Gene_class } @genes;

	# Motifs
	push @meta,grep { !$unique{$_}++ } $protein->Motif_homol;
	push @meta,grep { !$unique{$_}++ } map { $_->Title } $protein->Motif_homol;

	# Papers
	push @meta,grep { !$unique{$_}++ } $protein->Reference;
	
	# Variations
	push @meta,grep { !$unique{$_}++ } map { $_->Allele } @genes;

	# Species
	push @meta,grep { !$unique{$_}++ } $protein->Species;
	
	my $short = $protein->Description;
	$a->insert_entity('Protein',$protein,undef,\@aliases,[$short],\@meta);

    }

   warn "\nDone loading: loaded $count $class objects...\n";
   warn "Indexing...\n";
}

