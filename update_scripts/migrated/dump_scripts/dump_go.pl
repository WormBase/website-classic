#!/usr/bin/perl

# Fetch the GO terms for a list of genes
# Author: T. Harris, 4/14/2004
# harris@cshl.org
# early morning pre-coffee hack

use Ace;

# Added acedb_dir/acedb_host option - Payan

my $usage = "$0 (<acedb_dir> | <acedb_host>:<port>) [gene_list_file]";

my ($database, $file) = @ARGV;
$database or die "Usage: $usage\n";

my $DB;
if ($database =~ /:/) {
	my ($host, $port) = split(":", $database);
	$DB = Ace->connect( -host => $host, -port => $port) 
		or die "Cannot connect to host: $host, port: $port\n";
	} else {	
		$DB = Ace->connect( -path => $database) 
		or die "Cannot connect to database (directory): $database\n";
	}	

my $genes = get_genes($file);

foreach (@$genes) {
  next unless ($_->Species eq 'Caenorhabditis elegans');
  next if ($_->Method eq 'history');
  my $id = $_->Public_name;
  $id .= ' (' . $_->Molecular_name . ')' if $_->Molecular_name;
  print "$_ $id\n";
  my @go = $_->GO_term;
  next unless @go;

  # Consolidate all the GO terms by their type
  my $types = {};
  foreach (@go) {
    my $term = $_->Term;
    my $type = $_->Type;
    push (@{$types->{$type}},"$term ($_)");
  }
  
  foreach my $type (qw/Molecular_function Cellular_component Biological_process/) {
    foreach (sort { $a cmp $b } @{$types->{$type}}) {
      print "\t$type: $_\n";
    }
  }
}

sub get_genes {
  my $file = shift;
  my @genes;
  if ($file) {
    open IN,$file;
    while (<IN>) {
      chomp;
      my $gene = $DB->fetch(-class=>'Gene',-name=>$_);
      push(@genes,$gene);
    }
  } else {
    @genes = $DB->fetch(-class=>'Gene',-name=>'*');
  }
  return \@genes;
}
