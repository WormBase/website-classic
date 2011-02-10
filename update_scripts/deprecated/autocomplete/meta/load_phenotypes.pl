#!/usr/bin/perl

use strict;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;
use Ace;

my $CLASS = 'Phenotype';

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

my $total = $ace->count($CLASS => '*');
print STDERR "Loading $total $CLASS...\n";

my $i = $ace->fetch_many(-class=>$CLASS,-name => '*') or die $ace->error;
while (my $o = $i->next) {
    print STDERR "loaded $count $CLASS objects$delim" if ++$count % 100 == 0;
    my %unique;
    my @aliases   = grep {!$unique{$_}++} ($o->name,
					   $o->Primary_name,$o->Short_name,$o->Synonym);
    
    # segfault protection with select objects
    my %avoid = map { $_ => 1 } (qw/
				 WBPhenotype0000031
				 WBPhenotype0000032
				 WBPhenotype0000049
				 WBPhenotype0000050
				 WBPhenotype0000051
				 WBPhenotype0000054
				 WBPhenotype0000055
				 WBPhenotype0000059
				 WBPhenotype0000060
				 WBPhenotype0000535
				 WBPhenotype0000886
				 /);
    my @meta;
    warn "forbidden: $o" if defined $avoid{$o};
#    warn $o;
    
    unless (defined $avoid{$o}) {
	push @meta,grep { ! $unique{$_}++ } $o->Variation;
	
	# GO_terms
	push @meta,grep { ! $unique{$_}++ } $o->GO_term;
	push @meta,grep { ! $unique{$_}++ } map { $_->Term } $o->GO_term;
	
	# AO_Terms
	my @ao_function = $o->Anatomy_function;
	push @meta,grep { ! $unique{$_}++ } map { $_->Involved } @ao_function;
	push @meta,grep { ! $unique{$_}++ } map { eval { $_->Involved->Term }  } @ao_function;
	
	# RNAi
	push @meta,grep { ! $unique{$_}++ } $o->RNAi;
	
	my $description = $o->Description;
	my $display = $o->Primary_name || $o->Short_name;
  $a->insert_entity($CLASS,$o,$display,\@aliases,[$description],\@meta);
    }
}
    
warn "\nDone loading: loaded $count $CLASS objects\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;
