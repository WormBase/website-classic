#!/usr/bin/perl

#########################################################################################################
# ontology_relations.pl
# parses the obo files and gets parent-child relationships between terms in the the ontology
# syntax: ontology_relations.pl <obo_file_name> and creates a two DB_File files using term ids as keys and  contains two listings, one of their parents, the other of the children.
# NB: abstract to work with specificid ontologies
##########################################################################################################

my $obo_file_name = $ARGV[0];
my $output = $ARGV[1];  # 1 if id2parents; 2 if parent2ids
 
use DB_File;
use strict;

open HTML, "<./$obo_file_name" or die "Cannot open the protein file: $obo_file_name\n";

my $id;
my $parent;
my %id2parent;
my %parent2id;
my $discard;
# system ('rm ./id2parents.dat');
# system ('rm ./parent2ids.dat');

foreach my $obo_file_line (<HTML>) {
    chomp $obo_file_line;
    my $annotation_count = 0;
	
    if($obo_file_line =~ m/^id\:/){
		# print "$obo_file_line\n";
		($discard, $id) = split '\: ', $obo_file_line;
		#print "$discard\n";
		chomp $id;
		# print "inside\:$id\n";
		undef $discard;
    }
	
	# print "outside\:$id\n";

    if($obo_file_line =~ m/^is_a\:/){
		# print "$obo_file_line\n";
		my ($discard, $parent) = split '\: ', $obo_file_line;
		#print "$discard\n";
		chomp $parent;
		# print "$id\n";
		($parent, $discard) = split ' ! ', $parent;
		# print "is_a\&$parent\<\-$id\n";
		$parent = "is_a\&".$parent;
		$parent2id{$parent}{$id} = 1;
		$id2parent{$id}{$parent} = 1;
		
		
    }

 	if($obo_file_line =~ m/^relationship\:/){
		# print "$obo_file_line\n";
		my ($discard, $parent) = split '\: ',$obo_file_line;
		#print "$discard\n";
		chomp $parent;
		$parent =~ s/ /&/;
		($parent, $discard) = split ' ! ',$parent;
		# print "$parent\<\-$id\n";
		$parent2id{$parent}{$id} = 1;
		$id2parent{$id}{$parent} = 1;
    }

    elsif($obo_file_line =~ m/\[Term\]/){
		# print "\n\*TERM\*\n";
		undef $id;
		undef $parent;
    }
    else {
	next;
    }
	   
}

my %id2parents;
my %parent2ids;

# tie (%id2parents, 'DB_File', 'id2parents.dat') or die;
# tie (%parent2ids, 'DB_File', 'parent2ids.dat') or die;

if($output == 1) {
	foreach my $term (keys %id2parent){
	print "$term\=\>";
	my @term_parents = (keys %{$id2parent{$term}});
	my $term_parent_list = join '|', @term_parents;
	print "$term_parent_list";
	print "\n";
	$id2parents{$term} = $term_parent_list;
	}
}
elsif($output == 2){
	foreach my $term (keys %parent2id){
	my($discard,$parent_term) = split '&',$term;
	print "$parent_term\=\>";
	my @term_children = (keys %{$parent2id{$term}});
	my $term_children_list = join '|', @term_children;
	print "$term_children_list";
	print "\n";
	$parent2ids{$parent_term} = $term_children_list;
	}
}





