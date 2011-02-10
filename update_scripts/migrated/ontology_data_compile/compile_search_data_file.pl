#!/usr/bin/perl

#########################################################################################################
#
#  takes obo and association files and creates a table of annotations for terms in a given ontology
#  syntax make_sample_file <obo_file_name> <namespace> <association_file_name>
#
##########################################################################################################

my $obo_file_name = $ARGV[0];
my $entered_namespace = $ARGV[1];
my $association_file_name = $ARGV[2];

open HTML, "<./$obo_file_name" or die "Cannot open the protein file: $obo_file_name\n";

my $id;
my $term;
my $def;
my $syn;
my $namespace = $entered_namespace;
my $discard;
my $annotation_count;
my @synonyms;

foreach my $obo_file_line (<HTML>) {
    chomp $obo_file_line;
    $annotation_count = 0;

    if($obo_file_line =~ m/^id\:/){
	#print "$obo_file_line\n";
	($discard, $id) = split '\: ', $obo_file_line;
	#print "$discard\n";
	chomp $id;
	#print "$id\n";
    }

    elsif($obo_file_line =~ m/^name\:/){
        ($discard, $term) = split '\: ', $obo_file_line;
        chomp $term;
    }

    elsif($obo_file_line =~ m/^namespace\:/){
	($discard, $namespace) = split '\: ', $obo_file_line;
	chomp $namespace;

    }
    elsif($obo_file_line =~ m/^def\:/){
        ($discard, $def) = split '\: ', $obo_file_line;
	$def =~ s/\[.*\]//g;
	$def=~ s/\"//g;
        chomp $def;
    }
	elsif($obo_file_line =~ m/^synonym\:/){
        ($discard, $syn) = split '\"', $obo_file_line;
		$syn =~ s/lineage name\: //;
		chomp($syn);
		push @synonyms,$syn;
    }

    elsif($obo_file_line =~ m/\[Term\]/){
	$annotation_count = `grep -c \'$id\' $association_file_name`;
		my $synonym_list = join '-&-',@synonyms;
		print "$id\|$term\|$def\|$namespace\|$synonym_list\|$annotation_count\n";
		@synonyms = ();
        #print "$id\|$term\|$def\|$namespace\|$annotation_count\n";
    }

    else {
	next;
    }


	   
}
