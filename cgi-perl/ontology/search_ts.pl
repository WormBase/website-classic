#!/usr/bin/perl
### ontology search

use strict;
use lib '../lib';
use ElegansSubs qw/:DEFAULT Bestname/;
use Ace::Browser::AceSubs;
use CGI qw(:standard *table escape);
use WormBase;
use vars qw/$WORMBASE $db $query $db_ar/;
# use OntSubs;
# my @sections2filter = qw(t d);


END {
  undef $WORMBASE;
  undef $db;
}

my $ontology_list;
my @ontology_list;
my $with_annotations_only = 0;
my $data_file_name;
my $return_flag;
my $string_modification;
my $annotation_flag;
my $sort_results_by;
my $special_search;
my %search_results_hash;
my @sections2filter;

my $dbx = OpenPageGetObject('Ontology Search',undef,1);
my $db = Ace->connect(-host=>'localhost',-port=>2005); 

#$db = shift @{$db_ar};
$string_modification = param('string_modifications');
$query = param('query');
@ontology_list = param('ontologies');
$annotation_flag = param('with_annotations_only');
$sort_results_by = param('sort');
$special_search = param('special_search');
@sections2filter = param('filters');
push @sections2filter, 't';
push @sections2filter, 'i';

$query=~ s/\+/ /g;

#PrintTop($query,'', $query ? "Search Result for $query" : "Ontology Search");

my $cgi = new CGI;

StartCache();

$WORMBASE = WormBase->new();





if ($annotation_flag eq 'ON'){
    $with_annotations_only = 1;
}

$ontology_list = join '&', @ontology_list;

#my $data_directory = './'; 
my $version = $db->version;
our $data_directory = '/usr/local/wormbase/databases/$version/ontology/';

$data_file_name = $data_directory . "search_data.txt";

### specialized search off URL not via form! ####

if ($special_search){
	%search_results_hash = &ontology_survey($special_search);
	$query = 1;
	# print "OK\n";
}
else{
	%search_results_hash = &run_search ($data_file_name,$query,$ontology_list,$with_annotations_only,$string_modification);
}

my %filtered_data = filter_sections(\%search_results_hash,\@sections2filter,$query);


my @fd_keys = keys %filtered_data;
#print "\<pre\>@fd_keys\<\/pre\>\n";


$return_flag = check_for_results(\%filtered_data);

#print "\<pre\>@sections2filter\<\/pre\>\n";
#print "\<pre\>$return_flag\<\/pre\>\n";


$return_flag = 2;

if(!($query)){
    # Do nothing;
}
elsif($return_flag == 0){

    print "<br><br>Your search for <i>$query</i> did not return any terms. Please check the spelling and try again<br><br>\n";
}
else{
     print_ontology_search_results(\%filtered_data,$sort_results_by);
}

print_search_form($cgi);
ClosePage;

exit 0;


#######################################
#
# Subroutines
#
#######################################



sub association_links {
	
	my ($id,$ontology,$associations_count,$association_urls_hr) = @_;
	my $assc_url;
	my $wga_url;
	
	if($associations_count == 0){
		#print "Hello Associations!\n";
		return 0;
	}
	else { 
	## get urls
	$assc_url = ${$association_urls_hr}{$ontology};
	# $wga_url = ${$wm_gene_annotation_urls_hr}{$ontology}{'gene'};
	$assc_url =~ s/\$\$\$\$/$id/;
	# $wga_url =~ s/\$\$\$\$/$id/;
	return $assc_url;
	}		
}

sub wormmart_links {
		my ($id,$ontology,$wm_object_ontology_urls_hr) = @_;
		my %ontology_wm_objects = ('biological_process' => [qw(gene)],
			       'cellular_component' => [qw(gene)],
			       'molecular_function' => [qw(gene)],
			       'anatomy' => [qw(expr_pattern gene )],
			       'phenotype' => [qw(gene rnai variation)]
	    );
		
		my $objects_ar = $ontology_wm_objects{$ontology};
		my %wm_urls;
		foreach my $object (@{$objects_ar}){
			my $wga_url = ${$wm_object_ontology_urls_hr}{$ontology}{$object};
			$wga_url =~ s/\$\$\$\$/$id/;
			$wm_urls{$object} = $wga_url;
		}
		
		return %wm_urls;
}


sub filter_sections {
	my($results_hash_ref,$sections2filter_array_ref,$query) = @_;
	my %return_hash;

	foreach my $result_key (keys %{$results_hash_ref}){
		
		my $filtered_line = "";
		my $term_lines = ${$results_hash_ref}{$result_key};
		my @term_lines = split(/\n/,$term_lines);
		
		foreach my $term_line (@term_lines){	
			#print "\n\ncheck\:$term_line";
			my $checked_line = check_section($sections2filter_array_ref,$query,$term_line);
			#print "\nchecked_line\:$checked_line";
			$filtered_line = $filtered_line.$checked_line."\n";
		}
		$return_hash{$result_key} = $filtered_line;
	}
	return %return_hash;
}

sub check_section {
	my ($sections_array_ref,$query,$line) = @_;
	## split line
	my %sections;
	($sections{'i'},$sections{'t'},$sections{'d'},$sections{'s'},$sections{'n'},$sections{'a'}) = split /\|/,$line;
	my $return_data = 0;
	foreach my $check_section (@{$sections_array_ref}){
		# print "\n$check_section => $sections{$check_section}\n";
		if($sections{$check_section} =~ m/$query/){			
			$return_data = $line;
		}
		else{
			next;
		}
	}
	return $return_data;
}

sub ontology_survey {
	my %search_results;
	my ($ontology,$data_file_name) = @_;
	my $search_data = `grep \'\|$ontology\|\' \./$data_file_name`;
	$search_results{$ontology} = $search_data;
	return %search_results;
	
}

sub print_search_form {
    
    my $cgi = shift @_;

    print $cgi->startform(-method=>'GET', 
			  -action=>'search');   

    print "<br><hr><br>Search for term, phrase, or term ID that \&nbsp\;\&nbsp;";

    my %string_choices = (#'before'=>'Starts with', 
			  #'after'=>'Followed by', 
			  'middle'=>'Contains',
			  'stand_alone'=>'Stands Alone'
			  );

    print $cgi->popup_menu(-name=>'string_modifications', 
			   -values=>[
				     #'before',
				     #'after',
				     'middle',
				     'stand_alone'], 
			   -default=>'stand_alone', 
			   -labels=>\%string_choices);
 
    
    print "<br><br>\n";

    print $cgi->textfield(-name=>'query', 
			  -size=>50, 
			  -maxlength=>80);
    
    print "<br><br>In the following ontologies\:<br><br>\n";

    my %ontologies = ('biological_process'=>'GO: Biological Process',
                      'cellular_component'=>'GO: Cellular Component',
                      'molecular_function'=>'GO: Molecular Function',
		      'anatomy'=>'Anatomy',
		      'phenotype'=>'Phenotype'
		      );

    print $cgi->scrolling_list(-name=>'ontologies', 
			       -values=>['biological_process','cellular_component','molecular_function','anatomy','phenotype'], 
			       -default=>['biological_process','cellular_component','molecular_function'], 
			       -multiple=>'true', -labels=>\%ontologies);

    print "<br><br>Include the following areas in the search\:<br><br>\n";


 my %filter_choices = ('d'=>'definition',
			   's'=>'synonyms'
			   );

    print $cgi->scrolling_list(-name=>'filters',
                           -values=>[
                                     'd',
                                     's'],
						   -multiple=>'true',
		       -labels=>\%filter_choices);

    print "<br><br>\n";

    print $cgi->checkbox(-name=>'with_annotations_only', 
			 -checked=>'checked', 
			 -value=>'ON', 
			 -label=>'Return Only Terms with Annotations');

    print "<br><br>Sort Annotations \&nbsp\;\&nbsp\;";
    
    my %sorting_choices = ('alpha'=>'Alphabetically',
			   'annotation_count'=>'By number of annotations'
			   );

    print $cgi->popup_menu(-name=>'sort',
                           -values=>[
                                     'alpha',
                                     'annotation_count'],
                           -default=>'alpha',
		       -labels=>\%sorting_choices);

    print "<br><br>";
    print $cgi->submit('Submit');
    print "\&nbsp\;\&nbsp\;";
    print $cgi->defaults('  Reset  ');

	print $cgi->endform;
}

sub run_search {

    my %search_results;
    my ($data_file_name, $query,$ontology_list,$annotations_only,$string_modification) = @_;
    my $search_data;

    my @ontologies = split '&',$ontology_list;
    sort @ontologies;

    if ($annotations_only == 1) {
	if #($string_modification eq 'before'){
	   # $search_data = `grep \'\\\<$query\.\* \.\/$data_file_name \| grep \-v \'\|0\'`;
	#}
	#elsif($string_modification eq 'after'){
	#    $search_data = `grep -w \*\'$query\\\>\' \.\/$data_file_name \| grep \-v \'\|0\'`;
	#}
	#elsif
	    ($string_modification eq 'stand_alone'){
	    $search_data = `grep -iw \'$query\' \.\/$data_file_name \| grep \-v \'\|0\'`;
	}
	else{
	    $search_data = `grep \'$query\' \.\/$data_file_name \| grep \-v \'\|0\'`;
	}
    }
    else {
	#if ($string_modification eq 'before'){
	#    $search_data = `grep  '\<$query.*>' \.\/$data_file_name`;
	#}
	#elsif($string_modification eq 'after'){
	#    $search_data = `grep -w \*\'\<$query' \.\/$data_file_name`;
	#    #$search_data = `grep -w \*\'$query\\\>\' \.\/$data_file_name`;
	#}
	if($string_modification eq 'stand_alone'){
	    #$search_data = `grep -w \'\\\<$query\\\>\' \.\/$data_file_name`;
	    $search_data = `grep -iw \'$query\' \.\/$data_file_name`;
	}
	else{
	    $search_data = `grep  \'$query\' \.\/$data_file_name`;
	}
    }

    $search_data =~ s/$query/\<font color\=\'red\'\>$query\<\/font\>/g;
    my @search_data_lines = split '\n', $search_data;
   
    foreach my $ontology (@ontologies){
        my $ontology_specific_line = '';
        foreach my $search_data_line (@search_data_lines){
            my @split_data = split(/\|/, $search_data_line);
            if($ontology eq $split_data[3]){
                $ontology_specific_line = $ontology_specific_line."$search_data_line\n";
            }
            else {
                next;
            }
        }
        if ($ontology_specific_line =~ m/\|/){
            $search_results{$ontology} = $ontology_specific_line;
        }
        else
        {
            $search_results{$ontology} = 0;
        }
    }
    return %search_results;
}

sub check_for_results {

    my $search_results_hash_ref;
    my $key;
    my $data;
    my $results_returned_flag = 0;

    ($search_results_hash_ref) = @_; 

    foreach $key (keys %{$search_results_hash_ref}){
        $data = ${$search_results_hash_ref}{$key};
	if($data =~ m/\|/) { ### 
	    $results_returned_flag = 1;
	    last;
	}
	else {
	    next;
	}
    }
    return $results_returned_flag;
}

sub print_ontology_search_results {

	my $query = param('query');
    my $search_results_hash_ref;
    my $key;
    my $data;
    my $sort_results_by;

    ($search_results_hash_ref,$sort_results_by) = @_;

    my %ontology_names = ('biological_process', 'GO Biological Process',
		       'cellular_component', 'GO Cellular Component',
		       'molecular_function', 'GO Molecular Function',
		       'anatomy', 'Anatomy Ontology',
		       'phenotype', 'Phenotype Ontology'
    );

    my @ontology_names = sort {lc($a) cmp lc($b)} keys %ontology_names;

    my %ontology_directory = ('biological_process', 'ontology/gene',
                       'cellular_component', 'ontology/gene',
                       'molecular_function', 'ontology/gene',
                       'anatomy', 'ontology/anatomy',
                       'phenotype', 'misc/phenotype'
			  );
			
			my %association_urls = ('biological_process', '/db/ontology/gene?name=$$$$#asc',
			                   'cellular_component', '/db/ontology/gene?name=$$$$#asc',
			                   'molecular_function', '/db/ontology/gene?name=$$$$#asc',
			                   'anatomy', '/db/ontology/anatomy?name=$$$$#asc',
			                   'phenotype', '/db/misc/phenotype?name=$$$$#asc'
				);

			my $server = '/'; ## kludge for localhost:9006

### wormmart links for gene data
	my %wm_gene_annotation_urls; ### vestigial declaration
			
	my %wm_object_ontology_urls;
	
	$wm_object_ontology_urls{'biological_process'}{'gene'} =  $server.'biomart/martview?VIRTUALSCHEMANAME=default&ATTRIBUTES=wormbase_gene.default.attributes.gene|wormbase_gene.default.attributes.public_name|wormbase_go_term.default.attributes.go_term|wormbase_go_term.default.attributes.term&FILTERS=wormbase_go_term.default.filters.go_term_ancestor."$$$$"';

	$wm_object_ontology_urls{'cellular_component'}{'gene'} = $server.'biomart/martview?VIRTUALSCHEMANAME=default&ATTRIBUTES=wormbase_gene.default.attributes.gene|wormbase_gene.default.attributes.public_name|wormbase_go_term.default.attributes.go_term|wormbase_go_term.default.attributes.term&FILTERS=wormbase_go_term.default.filters.go_term_ancestor."$$$$"';

	$wm_object_ontology_urls{'molecular_function'}{'gene'} = $server.'biomart/martview?VIRTUALSCHEMANAME=default&ATTRIBUTES=wormbase_gene.default.attributes.gene|wormbase_gene.default.attributes.public_name|wormbase_go_term.default.attributes.go_term|wormbase_go_term.default.attributes.term&FILTERS=wormbase_go_term.default.filters.go_term_ancestor."$$$$"';

	$wm_object_ontology_urls{'anatomy'}{'gene'} = $server.'biomart/martview?VIRTUALSCHEMANAME=default&ATTRIBUTES=wormbase_expr_pattern.default.attributes.gene|wormbase_expr_pattern.default.attributes.gene_public_name|wormbase_anatomy_term.default.attributes.anatomy_term|wormbase_anatomy_term.default.attributes.term_anatomy_name&FILTERS=wormbase_anatomy_term.default.filters.anatomy_term."$$$$"',

	$wm_object_ontology_urls{'phenotype'}{'gene'} =
$server.'biomart/martview?VIRTUALSCHEMANAME=default&ATTRIBUTES=wormbase_gene.default.attributes.gene|wormbase_gene.default.attributes.public_name|wormbase_phenotype.default.attributes.phenotype|wormbase_phenotype.default.attributes.name_primaryname_phenotypename&FILTERS=wormbase_gene.default.filters.rnai_observed_count."only"|wormbase_phenotype.default.filters.phenotype."$$$$"';
	
	$wm_object_ontology_urls{'anatomy'}{'expr_pattern'} =
	
$server.'biomart/martview?VIRTUALSCHEMANAME=default&ATTRIBUTES=wormbase_expr_pattern.default.attributes.expr_pattern|wormbase_expr_pattern.default.attributes.gene|wormbase_expr_pattern.default.attributes.gene_public_name|wormbase_anatomy_term.default.attributes.anatomy_term|wormbase_anatomy_term.default.attributes.term_anatomy_name&FILTERS=wormbase_anatomy_term.default.filters.anatomy_term."$$$$"';

	$wm_object_ontology_urls{'phenotype'}{'rnai'} = $server.'biomart/martview?VIRTUALSCHEMANAME=default&ATTRIBUTES=wormbase_rnai.default.attributes.rnai|wormbase_rnai.default.attributes.gene|wormbase_phenotype.default.attributes.phenotype|wormbase_phenotype.default.attributes.name_primaryname_phenotypename&FILTERS=wormbase_phenotype.default.filters.phenotype."$$$$"';
	
	$wm_object_ontology_urls{'phenotype'}{'variation'} = $server.'biomart/martview?VIRTUALSCHEMANAME=default&ATTRIBUTES=wormbase_variation.default.attributes.variation|wormbase_phenotype.default.attributes.phenotype|wormbase_phenotype.default.attributes.name_primaryname_phenotypename&FILTERS=wormbase_variation.default.filters.species_selection."Caenorhabditis elegans"|wormbase_phenotype.default.filters.phenotype."$$$$"';
	
	

	print "<div align=right><b>NB: * $query \(also\) found in synonym\(s\)\<\/b></div><br\>";
    ## Start table
    StartDataTable;

    ## loop through ontology data hash
    #foreach $key (keys %{$search_results_hash_ref}){
    foreach $key (@ontology_names){

	my %terms;
	my %defs;
	my %annotation_counts;
	my @sorted_ids;
	
    $data = ${$search_results_hash_ref}{$key};

	if($data =~ m/\|/){  ## data available
	    ## start row for ontology
	    StartSection($ontology_names{$key});
	    my @data = split (/\n/,$data);

	    foreach my $data_line (@data){
                if($data_line =~ 'OBSOLETE') {
                    next;
                }
                else{
                    my ($id,$term,$definition,$ontology,$synonyms,$annotation_count) = split (/\|/,$data_line);
		    $term =~ s/\_/ /g;
			if($synonyms =~ m/$query/){
				$term = "$term"."\*";
			}
		    $terms{$id} = $term;
		    $defs{$id} = $definition;
		    $annotation_counts{$id} = $annotation_count;
                }
            }

	    if ($sort_results_by eq 'annotation_count'){		
		@sorted_ids = reverse sort { $annotation_counts{$a} <=> $annotation_counts{$b} } keys %annotation_counts; 
	    }
	    else{
		@sorted_ids = sort { lc($terms{$a}) cmp lc($terms{$b}) } keys %terms;
	    }

	    print start_table({border => 0,width=> '100%'});
	    my $term_width = '20%';
	    my $def_width = '50%';
	    my $annotation_count_width = '10%';
		my $wm_link_width = '20%';

	    print TR({},
		     th({-align=>'left',-width=>$term_width,-class=>'databody'},'Term'),
		     th({-align=>'left',-width=>$def_width,-class=>'databody'},'Definition'),
		     th({-align=>'center',-width=>$annotation_count_width,-class=>'databody'},'Annotations'),
			 th({-align=>'center',-width=>$wm_link_width,-class=>'databody'},'WormMart data')
		     );

	    foreach my $sorted_id (@sorted_ids){
		
		my $anchor = a({-href=>"/db/$ontology_directory{$key}\?name=$sorted_id"},$terms{$sorted_id});

		my $association_url = &association_links($sorted_id,$key,$annotation_counts{$sorted_id},\%association_urls);
		my %wm_urls = &wormmart_links($sorted_id,$key,\%wm_object_ontology_urls);
		my @wm_links;
		# my $wm_url;
		my $association_anchor;
		my $wm_anchor;
		if($association_url){
			$association_anchor = a({-href=>$association_url},$annotation_counts{$sorted_id});
			foreach my $object (keys %wm_urls){
				
				$wm_anchor = a({-href=>$wm_urls{$object}},$object);
				push @wm_links, $wm_anchor;
			}
		}
		else {
			$association_anchor = $annotation_counts{$sorted_id};
			@wm_links = ('');
		}
		
		my $wm_link_line = join " | ", @wm_links;
		
		print TR({},
			 td({-align=>'left',-width=>$term_width,-class=>'databody'},$anchor),
			 td({-align=>'left',-width=>$def_width,-class=>'databody'},$defs{$sorted_id}),
			 td({-align=>'center',-width=>$annotation_count_width,-class=>'databody'},$association_anchor),
			 td({-align=>'center',-width=>$wm_link_width,-class=>'databody'},$wm_link_line)
			 );
# 
	    }
	} # end if($data =~ m/\|/){
	else {
	    next; ## skip creation of row
	} # end else
	print end_section;    
    } # end foreach $key (keys %{$search_results_hash_ref}){
    
    ## end table
EndDataTable;

} # end sub print_ontology_search_results

