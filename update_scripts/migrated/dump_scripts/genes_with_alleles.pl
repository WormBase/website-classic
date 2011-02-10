#!/usr/bin/perl

use strict;
use Getopt::Long;
use Ace;

$|++;

my ($acedb,$help,$file,$exclude);
GetOptions ('acedb=s'       => \$acedb,
            'help'          => \$help,
	    'exclude_loci'  => \$exclude,
            'file=s'        => \$file,
           );

if ($help) {
  die <<END;


This script generates a list of genes displaying and whether or not
those genes contain alleles.  For the sake of loading into
spreadsheets, I've split the output into two tab-delimited files.  The
first is a list of genes which contains the number of alleles and
their IDs.  The second file lists alleles with some additional
information concerning each allele.

 Usage: genes_with_alleles.pl [options]

  Options:
  -acedb    Full path to acedb database to use (/usr/local/acedb/elegans)
            If not provided, defaults to using the remote data mining
            server at WormBase, aceserver.cshl.org.
  -exclude_loci  Exclude those genes that only currently exist as genetic loci
  -file     A list of genes specified by sequence or CGC names
  -help     Display this help

END
}

# Connect to ace and fetch the database version
print STDERR "\nConnecting to acedb: " . (($acedb) ? $acedb : "aceserver.cshl.org\n");

my $db = (($acedb)
	  ? Ace->connect(-path=>$acedb)
	  : Ace->connect(-host=>'aceserver.cshl.org',-port=>2005)) or die "Couldn't connect to Acedb: $!";

my $version = $db->status->{database}{version};

open GENES,  ">$version-genes_and_alleles.txt";
open ALLELES,">$version-alleles.txt";

my $genes = get_genes($file);


my @allele_columns = (qw/allele variation_type mutation_type is_KOC_allele sequence_status affects_gene affects_cds phenotype/);
print ALLELES join("\t",@allele_columns),"\n";

# What script isn't complete without REDUNDANT DATA STRUCTURES!
my %genes2data;     # Store the contents of the original file, if provided
my %genes2alleles; # Collect some statistics on the number of genes with alleles and how many alleles/gene

foreach my $gene (@$genes) {
  # Are there mutations in this gene
  my @alleles = $gene->Allele;
  my $string = join('; ',@alleles);
  foreach (@alleles) {
    # Dump out information on this allele for a separate spreadsheet
    dump_allele($_);
  }

  # Track number of alleles per gene
  $genes2alleles{$gene . ': ' . $gene->Sequence_name . '; ' . $gene->CGC_name} = @alleles ? scalar @alleles : 0;

  # If we were provided with a file, simply append the allele data
  # Kind of a hack so that I can easily generate a new spreadsheet for DM
  if ($file) {
    print GENES join("\t",$genes2data{$gene},(@alleles ? scalar @alleles : 0),$string),"\n";
  } else {
    print GENES join("\t",$gene,$gene->Public_name,(@alleles ? scalar @alleles : 0),$string),"\n";
  }
}


# Generate a simple report that lists all genes and the number of
# alleles they contain, dumped to STDERR
foreach (sort { $genes2alleles{$a} <=> $genes2alleles{$b} } keys %genes2alleles) {
  print "$_\t$genes2alleles{$_}\n";
}


sub dump_allele {
  my $allele     = shift;

  my %data;
  $data{allele} = $allele;
  # What type of variation is this? If an allele, what type?
  $data{variation_type}  = $allele->Variation_type;
  $data{mutation_type}   = $allele->Type_of_mutation;

  # Is this a KO allele?
  $data{is_KOC_allele} = 'true' if $allele->KO_consortium_allele(0);
  $data{is_KOC_allele} = 'true' if $allele->NBP_allele(0);

  # Sequence and status
  $data{sequence_status} = $allele->SeqStatus;

  # Affected gene / CDS
  $data{affects_gene}    = join("; ",$allele->Gene);           # possibly a list
  $data{affects_cds}     = join("; ",$allele->Predicted_CDS);  # possibly a list

  # Molecular information
  
  # Phenotypic information
  $data{phenotype} = join("; ",$allele->Phenotype);

  print ALLELES join("\t", map { $data{$_} } @allele_columns),"\n";
}



sub get_genes {
  my $file = shift;
  my @genes;
  if ($file) {
    open IN,$file or die "Couldn't open the list of genes";
    while (<IN>) {
      chomp;
      my ($sequence,@junk) = split("\t");

      # Fetch the Gene_name object for this sequence
      my $gene_name = $db->fetch(Gene_name => $sequence);

      # Now grab the gene
      my $gene = $gene_name->Public_name_for || $gene_name->Sequence_name_for || $gene_name->Other_name_for;
      $gene or die "Couldn't fetch a gene object for $sequence";

      # Exclude genes that only exist as genetic loci.
      next if ($exclude && !$gene->Sequence_name);

      # Store the entire original line so that I can simply append data
      # HACK! Excel is leaving the last column as undef if empty.  Not good.
      # So simply storing the original line does not work when reimporting data. Oh, Jesu.
      if (@junk < 6) {
	push @junk,'';
      }
      $genes2data{$gene} = join("\t",$sequence,@junk);
      push @genes,$gene;
    }
  } else {
    if ($exclude) {
      @genes = $db->fetch(-query=>qq{find Gene where Species=C*elegans AND Sequence_name});
    } else {
      @genes = $db->fetch(-query=>qq{find Gene where Species=C*elegans});
    }
  }
  return \@genes;
}
