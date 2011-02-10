#!/usr/bin/perl

use CGI qw(:standard *table *TR *td escape);
use strict;


my $cgi = new CGI;
my $form_type = param('form_type');


print $cgi->header;
print $cgi->start_html('Form Development');

print_search_form($cgi,$form_type);

print $cgi->end_html;


### subroutines ###

sub print_search_form {
    
    my $cgi = shift @_;
    my $form_type = shift @_;
    
    print $cgi->startform(-method=>'GET', 
			  -action=>'search');   

	print "<table>";

	if ($form_type=~ m/multi/) {
	
		print "<tr><td>";
		print_ontology_choices($cgi,$form_type);
		print "</td></tr>";
		
		print "<tr><td>";
		print_entry_items($cgi,$form_type);
		print "</td></tr>";		
		

	}

	else {
	
		print "<tr><td>";
		print_entry_items($cgi,$form_type);
		print "</td></tr>";	

		print "<tr><td>";
		print_ontology_choices($cgi,$form_type);
		print "</td></tr>";		
	}
	
	print "<tr><td>";
	print_return_choices($cgi,$form_type);
	print "</td></tr>";
	
	print "</table>";

	print "<br><br>\n";

    print $cgi->submit('Submit');
    print "\&nbsp\;\&nbsp\;";
    print $cgi->defaults('  Reset  ');

	print $cgi->endform;
}

sub print_ontology_choices {

	my $cgi = shift;
	my $form_type = shift;
	

    my %ontologies = ('biological_process'=>'GO:Biological Process',
                      'cellular_component'=>'GO:Cellular Component',
                      'molecular_function'=>'GO:Molecular Function',
		      			'anatomy'=>'Anatomy',
		      			'phenotype'=>'Phenotype'
		      			);

	if ($form_type=~ m/multi/) {
	
		print "<h3>Select ontologies you wish to search.</h3>"; 
    	print $cgi->checkbox_group({
    				-name=>'ontologies',  -values=>['biological_process','cellular_component','molecular_function',
    				'anatomy','phenotype'], 
			       	-multiple=>'true', 
			       	-labels=>\%ontologies,
			       	-linebreak=>1
			       	});	
	}
	elsif ($form_type=~ m/go/) {
	
	print $cgi->hidden(
				
				-name=>'ontologies', 
				-default=>['biological_process','cellular_component','molecular_function']
				);
	}
	
	elsif ($form_type=~ m/phenotype/) {
				       	
	print $cgi->hidden(
				
				-name=>'ontologies', 
				-default=>['phenotype']
				);  	
	}
	elsif ($form_type=~ m/anatomy/) {
	
	print $cgi->hidden(
				
				-name=>'ontologies', 
				-default=>['anatomy']
				);
	}
	else {
			print $cgi->checkbox_group({
    				-name=>'ontologies',       -values=>['biological_process','cellular_component','molecular_function',
    				'anatomy','phenotype'], 
			       	-multiple=>'true', 
			       	-labels=>\%ontologies,
			       	-linebreak=>1
			       	});	
	}			       	
}

sub print_return_choices {

	my $cgi = shift;
	my $form_type = shift;
	
	print "<br>";
	
	if ($form_type=~ /multi/) {
	
	print start_table({-border=>1, -cell_spacing=>1, -cellpadding=>1});
	
	print TR({},
			th({},'Ontology'),
			th({},'Annotated objects that can be entered into search (<i>example</i>).')
	);
	print TR({},
			td({},'GO'),
			td({},'genes(<i>unc-26</i>)')
	);
	print TR({},
			td({},'Anatomy'),
			td({},'genes(<i>unc-26</i>)')
	);
		print TR({},
			td({},'Phenotype'),
			td({},'genes(<i>unc-26</i>), transgenes(<i>bcEx757</i>), rnais(<i>WBRNAi00077478</i>), variations(<i>n422</i>)')
	);
	
	print end_table();
	
	}
	
	print "<br><br>";
	
	print $cgi->checkbox(-name=>'string_modifications', 
			 #-checked=>'checked', 
			 -value=>'ON', 
			 -label=>'Query Stands Alone');
	
	print "<br>";
    print $cgi->checkbox(-name=>'with_annotations_only', 
			 #-checked=>'checked', 
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

    print "Include the following areas in the search\:<br><br>\n";

 my %filter_choices = (
 				'd'=>'definition',
			   	's'=>'synonyms'
			   	);

    print $cgi->scrolling_list(-name=>'filters',
                           -values=>[
                                     'd',
                                     's'],
						   -default=>[
						         'd',
                                 's'],
		      				-multiple=>'true',
		      				-labels=>\%filter_choices);
}

sub print_entry_items {

	my $cgi = shift;
	my $form_type = shift;

    my %string_choices = (#'before'=>'Starts with', 
			  #'after'=>'Followed by', 
			  'middle'=>'Contains',
			  'stand_alone'=>'Stands Alone'
			  );

	if ($form_type=~ m/multi/) {

		print "<h3>Enter a term (<i>egg</i>), phrase (<i>larval development</i>), term ID, or annotated object. See table below for available information</h3>";
		#print "Annotated objects can also be used to look up terms. .<br><br>";
	}
	elsif($form_type=~ m/go/) {
	
		print "<h3>Enter a term (<i>egg</i>), phrase(<i>larval development</i>), term ID (<i>GO:0009790</i>), or gene(<i>unc-26</i>) </h3>";
	}
	elsif($form_type=~ m/anatomy/) {
	
		print "<h3>Enter a term(<i>egg</i>), phrase(<i>germ line</i>), term ID(<i>WBbt:0005784</i>), or gene(<i>unc-26</i>) </h3>";
	}
	elsif($form_type=~ m/phenotype/) {
	
		print "<h3>Enter a term(<i>egg</i>), phrase(<i>embryonic lethal</i>), term ID, gene(<i>unc-26</i>), variation(<i>n422</i>), transgene(<i>bcEx757</i>), or rnai(<i>WBRNAi00077478</i>)</h3>";
	}
	else {
	
	print "<h3>Enter a term, phrase, or term ID</h3>";
	}
	
    print $cgi->textfield(-name=>'query', 
			  -size=>50, 
			  -maxlength=>80);
 
 	 print "<br>\n";
 

}




