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

my $load = WormBase::AutocompleteLoad->new(-auto_dsn => "autocomplete_$version",
					   -ace_path => $acedb_path);

$load->load_class(
		  -class=>'Strain',
		  -name_call=>\&get_genotype,
		  -fill=>1,
		  -short_note=>'Remark',
		 );

exit 0;

sub get_genotype {
  my $object     = shift;
  my $geno       = $object->Genotype;

  # Ace.pm causes a segfault for some very large objects
  return ($geno) if $object eq 'AF16';
  return ($geno) if $object eq 'HK104';

  my @genes      = $object->Gene;
  my @variations = $object->Variation;
  my @result = $geno;
  push @result,@genes      if @genes      < 10;  # to avoid killers like C. elegans WT
  push @result,@variations if @variations < 10;
  return @result;
}

