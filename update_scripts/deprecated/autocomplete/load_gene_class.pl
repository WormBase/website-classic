#!/usr/bin/perl

use strict;
use lib '../../cgi-perl/lib';
use WormBase::AutocompleteLoad;

my $script = $0 =~ /([^\/]+)$/ ? $1 : '';

my $version    = shift;
my $acedb_path = shift;
$version or die <<END;
Usage: $script [WSVERSION] [ACEDB PATH (optional)]
END


$a->disable_keys;

# dump genes
my $emacs = $ENV{EMACS};
my $delim = $emacs ? "\n" : "\r";
my $count;

my $i = $ace->fetch_many(-class=>'Gene_class',-name => '*',-filled=>1) or die $ace->error;
while (my $gc = $i->next) {
  print STDERR "loaded $count genes$delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases   = grep {!$unique{$_}++} ($gc->name,
					 $gc->Old_member,
					 $gc->Main_name,
					 $gc->Other_name,
					 $gc->Variation,
					 $gc->Designating_laboratory,
					 );
  
  my @genes = $gc->Genes;
  push @aliases,grep { !$seen{$_}++ } map { $_->Public_name } @genes;
  push @aliases,@genes;

  my $short = $gc->Description;
  my $long  = $gc->Phenotype;
  $a->insert_entity('Gene_class',$gc,\@aliases,[$short,$long]);
}

$a->enable_keys;

exit 0;

