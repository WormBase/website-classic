#!/usr/bin/perl

# Calculate the most popular genes for a given set of logs

use strict;
use Getopt::Long;
use CGI qw/:standard *table *TR *div *td/;
use Ace;

my (@logs,$not_accessed,$output,$format,$release);
GetOptions('logs=s'         => \@logs,
	   'not_accessed=s' => \$not_accessed,
	   'output=s'       => \$output,
	   'format=s'       => \$format,
	   'release=s'      => \$release);

unless (@logs) {
  print STDERR <<END;
 Usage: most_popular_genes.pl [options]

  Options:
    -logs    list of access_logs to include, seperated by spaces
    -not_accessed  print a list of genes not accessed
    -output  full path to the output directory
    -release WSXXX release
    -format  one of HTML,TAB,TEXT
END
  die;
}

my (%WBGENES,%GENES_SEEN,%genes_hit,%all_stats,@cloned_loci,@unknown);
my $DB = Ace->connect(-host=>'localhost',-port=>'2005') or die "Couldn't open local database: $!";
get_genes();

@ARGV = @logs;
foreach (@ARGV) {
  $_ = "gunzip -c $_ |" if /\.gz$/;
}

while (<>) {
  chomp;
  # Does this look like a gene request?
  #  if (my ($request) = /http:\/\/\w\w\w\.wormbase\.org\/db\/gene\/gene\?name=(.+)[;|&|\s]?.*\s\".*\"\s\".*\".*/) {
  #  if (my ($request) = /\"GET\s\/db\/gene\/gene\?name=(.+)[;?.*|&?.*|\s]\sHTTP\/1\.1\".*/) {
  if (my ($request) = /\"GET\s\/db\/gene\/gene\?name=(.+?)[;&%\s].*\s?HTTP.*/) {
    # Ignore internal requests on the gene page for images
    my $pubmed = "GET /images/pubmed_button.gif HTTP/1.1";
    next if (/$pubmed/);

    # Fetch the WBGeneID for this request
    my $id = $GENES_SEEN{$request};
    unless ($id) {
      $id = fetch_gene($request);
      unless ($id) {
	push @unknown,$request;
	next;
      }
      $GENES_SEEN{$request} = $id;
      $GENES_SEEN{$id}      = $id;
    }
    $genes_hit{$id}->{total_accessions}++;  # Total of times the gene was accessed

    # track all the different identifiers that were used to access this gene
    $genes_hit{$id}->{accessors}->{$request}++;
  }
}

$all_stats{unique_accessions} = scalar keys %genes_hit;

my $suffix = ($format eq 'TAB' || $format eq 'TEXT') ? 'txt' : 'html';

# Print out genes hit in descending order of total accessions
open OUT,">$output/gene_stats-most_popular.$suffix";

if ($format eq 'TEXT') {
  printf OUT "%-15s %-15s %-15s %-8s %-40s\n",
    qw/WBGeneID Locus MolecularID Total_accesses(Total_accessors) Accessors(Accesses)/;
} elsif ($format eq 'TAB') {
  print OUT join("\t",'#WBGeneID','Locus','MolecularID','Total_accesses (Total accessors)','Accessors (Accesses)'),"\n";
} else {
  start_page("Most Popular Genes: $release");
  print OUT
    start_div({-class=>'container'}),
      div({-class=>'category'},'Most popular genes, in order of number of accessions'),
	start_table({-class=>'incontainer',-cellpadding=>10}),
	  TR({-class=>'pageentry'},
	     td('WBGeneID'),
	     td('Locus'),
	     td('Molecular ID'),
	     td('Total accesses (total accessors)'),
	     td('Accessors (accesses'));
}

foreach my $gene (sort {$genes_hit{$b}->{total_accessions} <=> $genes_hit{$a}->{total_accessions} }
		  keys %genes_hit) {

  # Delete this gene from the total genes list
  # so that I can track genes which were not hit.
  my $wbgene = $WBGENES{$gene};
  my $name   = $wbgene->Public_name   || '-';  # may or may not be locus
  my $mol    = $wbgene->Sequence_name || '-';
  my $total_accesses = $genes_hit{$gene}->{total_accessions};

  # Examine all the different IDs that were used to access this gene
  my %seen;
  my @accessed_by;
  foreach my $accessed_by (grep {!$seen{$_}++} keys %{$genes_hit{$wbgene}->{accessors}}) {
    my $accesses = $genes_hit{$wbgene}->{accessors}->{$accessed_by};
    push (@accessed_by,"$accessed_by ($accesses)");
  }

  # Track cloned genes that were accessed
  $name = ($name eq $mol) ? '-' : $name;
  if ($name ne '-' && $mol ne '-') {
    push @cloned_loci,$gene;
  }

  ## Track the number that are cloned, not cloned, predicted only
  $all_stats{genetically_defined}++ if ($name ne '-' && $mol eq '-');
  $all_stats{cloned}++              if ($name ne '-' && $mol ne '-');
  $all_stats{predicted}++           if ($name eq '-' && $mol ne '-');

  if ($format eq 'TEXT') {
    printf OUT "%-15s %-15s %-15s %-8s %-40s\n",
      $wbgene,$name,$mol,
	$total_accesses . '(' . (scalar @accessed_by) . ')',
	  join("; ",@accessed_by);
  } elsif ($format eq 'TAB') {
    print OUT join("\t",
		   $wbgene,$name,$mol,
		   $total_accesses . '(' . (scalar @accessed_by) . ')',
		   join("; ",@accessed_by)),"\n";
  } else {
    print TR({-class=>'pageentry'},
	     td($wbgene),
	     td($name),
	     td($mol),
	     td($total_accesses . '(' . (scalar @accessed_by) . ')'),
	     td(join("; ",@accessed_by)));
  }
}

if ($format eq 'HTML') {
  print OUT end_table,end_div,end_html;
}
close OUT;





# Genes not accessed in the month
# Will not print this report for the html page
if ($suffix eq 'txt') {
  open OUT,">$output/gene_stats-not_accessed.out";
  print OUT "\n\n-----------------------\n";
  print OUT scalar (keys %WBGENES) . " GENES NOT ACCESSED\n";
  print OUT "\n\n-----------------------\n";
  foreach (sort keys %WBGENES) {
    my $gene = $WBGENES{$_};
    next if (defined $GENES_SEEN{$_});
    print OUT join("\t",$_,$gene->CGC_name || '-',$gene->Sequence_name || '-'),"\n";
  }
  close OUT;
}



# line 1000
# If a locus is cloned is it more likely to be accessed by its locus, gene id, or sequence ID?
my %stats;
foreach my $gene (@cloned_loci) {
  my $accessed_by_locus;
  my $accessed_by_geneid;
  my $accessed_by_seq;
  foreach my $accessor (keys %{$genes_hit{$gene}->{accessors}}) {
    my $accessions = $genes_hit{$gene}->{accessors}->{$accessor};
    # Is the accessor a locus or a molecular ID?
    my $gene = $GENES_SEEN{$accessor};
    my $locus  = $gene->CGC_name || $gene->Other_name;
    my $seq    = $gene->Sequence_name;

    $stats{total_accessions}    += $accessions;
    $stats{accessed_by_locus}   += $accessions  if ($accessor =~ /$locus/i);
    $stats{accessed_by_geneid}  += $accessions  if ($accessor =~ /$gene/i);
    $stats{accessed_by_seq}     += $accessions  if ($accessor =~ /$seq/i);
    $accessed_by_locus++   if ($accessor =~ /$locus/i);
    $accessed_by_geneid++  if ($accessor =~ /$gene/i);
    $accessed_by_seq++     if ($accessor =~ /$seq/i);
  }
  push (@{$stats{accessed_only_by_locus}},$gene) if ($accessed_by_locus && !$accessed_by_seq && !$accessed_by_seq);
  push (@{$stats{accessed_only_by_seq}},$gene)   if (!$accessed_by_locus && $accessed_by_seq && !$accessed_by_geneid);
  push (@{$stats{accessed_only_by_id}},$gene)   if (!$accessed_by_locus && !$accessed_by_seq && $accessed_by_geneid);
  push (@{$stats{accessed_by_both}},$gene)       if ($accessed_by_locus && $accessed_by_seq);
}



open OUT,">$output/gene_stats-summary.txt";
print OUT "Gene access stats (summary): $release\n";
print OUT "Cloned loci accessed     : " . $all_stats{cloned} . "\n";
print OUT "Accessed only by locus   : " . (scalar @{$stats{accessed_only_by_locus}})
  . mean((scalar @{$stats{accessed_only_by_locus}}),$all_stats{cloned}),"\n" if $all_stats{accessed_only_by_locus};
print OUT "Accessed only by gene    : " . (scalar @{$stats{accessed_only_by_seq}})
  . mean((scalar @{$stats{accessed_only_by_seq}}),$all_stats{cloned}),"\n" if $all_stats{accessed_only_by_seq};
print OUT "Accessed by both        : " . (scalar @{$stats{accessed_by_both}})
  . mean((scalar @{$stats{accessed_by_both}}),$all_stats{cloned}),"\n" if $all_stats{accessed_by_both};

print OUT "Total accessions         : " . $stats{total_accessions} . "\n";
print OUT "Accessed by locus        : " . $stats{accessed_by_locus}
  . mean($stats{accessed_by_locus},$stats{total_accessions}) . "\n";
print OUT "Accessed by seq          : " . $stats{accessed_by_seq}
  . mean($stats{accessed_by_seq},$stats{total_accessions}) . "\n";
print OUT "Accessed by gene id      : " . $stats{accessed_by_geneid}
  . mean($stats{accessed_by_geneid},$stats{total_accessions}) . "\n";

# OVERALL STATS
print OUT "\n\n-----------------------\n";
print OUT "Total unique genes accessed        : " . $all_stats{unique_accessions} . "\n";
print OUT "Genetically defined but not cloned : " . $all_stats{genetically_defined}
  . mean($all_stats{genetically_defined},$all_stats{unique_accessions}) . "\n";
print OUT "Genetically defined and cloned     : " . $all_stats{cloned}
  . mean($all_stats{cloned},$all_stats{unique_accessions}) . "\n";
print OUT "Predicted genes only               : " . $all_stats{predicted}
  . mean($all_stats{predicted},$all_stats{unique_accessions}) . "\n";
close OUT;







sub mean {
  my ($num,$denom) = @_;
  my $mean = (($num || 0) / $denom) * 100;
  return (' ' . sprintf("%2.2f%",$mean));
}


# Create a hash lookup table keyed by WBGene IDs
sub get_genes {
  %WBGENES    = map { $_ => $_ } $DB->fetch('Gene' => '*');
}

sub fetch_gene {
  my $query = shift;
  my $gene = $DB->fetch('Gene'=>$query);
  return $gene if $gene;

  my $gene_name = $DB->fetch('Gene_name'=>$query);
  return unless $gene_name;
  my $gene =
    $gene_name->Public_name_for || $gene_name->CGC_name_for ||
      $gene_name->Sequence_name_for ||
	$gene_name->Other_name_for || $gene_name->Molecular_name_for;
}





sub start_page {
  my $title = shift;
  print header;
  print start_html(-title=>$title);
}
