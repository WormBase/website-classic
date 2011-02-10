#!/usr/bin/perl

use strict;
use Ace;
use lib '/usr/local/wormbase/cgi-perl/lib';
use WormBase::Autocomplete;

my $CLASS = 'Strain';

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
while (my $strain = $i->next) {
    print STDERR "loaded $count $CLASS objects$delim" if ++$count % 100 == 0;
    my %unique;
    my @aliases   = grep {!$unique{$_}++} $strain->name;
    push @aliases,get_genotype($strain);

    my @meta;
    # Genes, GeneIDs, Gene_class
    #    my @genes = $strain->Gene;
    #    push @meta,@genes;
    # push @meta,grep { !$unique{$_}++ } map { $_->Public_name } @genes;

    # Variation
    # push @meta,grep { !$unique{$_}++ } $strain->Variation;

    # Laboratory
    push @meta,grep { !$unique{$_}++ } $strain->Location;
    
    # Papers
    push @meta,grep { !$unique{$_}++ } $strain->Reference;

    # Species
    push @meta,grep { !$unique{$_}++ } $strain->Species;

    my $short_note = $strain->Remark;
    $a->insert_entity($CLASS,$strain,undef,\@aliases,[$short_note],\@meta);
  }

warn "\nDone loading: loaded $count $CLASS objects...\n";
warn "Indexing...\n";
$a->enable_keys;

exit 0;


sub get_genotype {
  my $object     = shift;
  my $geno       = $object->Genotype;

  # Ace.pm causes a segfault for some very large objects
  return ($geno) if $object eq 'AF16';
  return ($geno) if $object eq 'HK104';
  return ($geno) if $object eq 'CB4856';
  return ($geno) if $object eq 'CB4857';

  my @genes  = $object->Gene;
  my @result = $geno if $geno;
  if (@genes < 50) { # to avoid killers like C. elegans WT
    push @result,@genes;
    push @result,map { $_->Public_name } @genes;
  }

  my @variations = $object->Variation;
  push @result,@variations;
  return @result;
}

