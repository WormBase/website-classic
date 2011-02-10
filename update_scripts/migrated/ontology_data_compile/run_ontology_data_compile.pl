#!/usr/bin/perl

##################################################
# compiles ontology tree data and association data ontology related functions
# syntax > run_ontology_data_compile.pl <name_of_directory_containing_files> <wormbase_db_version>
###################

use strict;
use FindBin qw/$Bin/;

my $datadir = $ARGV[0];
my $version = $ARGV[1];
($datadir && $version) or die "Usage: $0 [/path/to/datadir] [WSVERSION]";

my $search_data_file = $datadir."/search_data.txt";
my $go_obo_file = $datadir."/gene_ontology.".$version.".obo";
my $go_assoc_file = $datadir."/gene_association.".$version.".wb.ce";
my $ao_obo_file = $datadir."/anatomy_ontology.".$version.".obo";
my $ao_assoc_file = $datadir."/anatomy_association.".$version.".wb";
my $po_obo_file = $datadir."/phenotype_ontology.".$version.".obo";
my $po_assoc_file = $datadir."/phenotype_association.".$version.".wb";
my $id2parents_file = $datadir."/id2parents.txt";
my $parent2ids_file = $datadir."/parent2ids.txt";
my $id2name_file = $datadir."/id2name.txt";
my $name2id_file = $datadir."/name2id.txt";
my $id2association_counts_file = $datadir."/id2association_counts.txt";

### compile search_data.txt
system("$Bin/compile_search_data_file.pl $go_obo_file gene $go_assoc_file >> $search_data_file &");
system("$Bin/compile_search_data_file.pl $ao_obo_file anatomy $ao_assoc_file >> $search_data_file &");
system("$Bin/compile_search_data_file.pl $po_obo_file phenotype $po_assoc_file >> $search_data_file &");

### compile id2parents relationships
system("$Bin/compile_ontology_relations.pl $go_obo_file 1 >> $id2parents_file &");
system("$Bin/compile_ontology_relations.pl $ao_obo_file 1 >> $id2parents_file &");
system("$Bin/compile_ontology_relations.pl $po_obo_file 1 >> $id2parents_file &");

### compile parent2ids relationships
system("$Bin/compile_ontology_relations.pl $go_obo_file 2 >> $parent2ids_file &");
system("$Bin/compile_ontology_relations.pl $ao_obo_file 2 >> $parent2ids_file &");
system("$Bin/compile_ontology_relations.pl $po_obo_file 2 >> $parent2ids_file &");

my $compile_search_data_running; 
do {
	sleep 30;
	undef $compile_search_data_running;
	$compile_search_data_running = `ps ax | grep compile_search_data_file.pl`;
} while ($compile_search_data_running =~ m/perl/);

# sleep 1800;

#### compile id2name
system("$Bin/parse_search_data.pl $search_data_file 0 1 > $id2name_file &");

#### compile id2name                                                                                                                             
system("$Bin/parse_search_data.pl $search_data_file 1 0 > $name2id_file &");


#### compile id2association_counts
system("./parse_search_data.pl $search_data_file 0 5 > $id2association_counts_file &");	


print "OK\n";
