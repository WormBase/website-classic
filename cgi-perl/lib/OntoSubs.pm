#!/usr/local/perl

sub print_ao_annotations {

    my ($gene_obj,$page_type) = @_;
    my @expr_patterns = $gene_obj->Expr_pattern;
    my @unique_ao_terms;
    my %ao_terms_seen;

    foreach my $expr_pattern (@expr_patterns){
        push @unique_ao_terms, grep {!$ao_terms_seen{$_}++ } $expr_pattern->Anatomy_term;
    }

    print start_table({border => 0,-width=>'100%'});
    if ($page_type eq 'ont_gene'){
	print TR({},th({-align=>'left',-colspan=>2,-class=>'databody'},'Anatomy Ontology Associations via Expression'));
	my $term_width = '30%';
	my $def_width = '70%';
    }
    else {
	$my_termwidth = '20%';
        $my_defwidth = '80%';
    }
    print TR({},
	     th({-align=>'left',-width=>$term_width,-class=>'databody'},'Term'),
	     th({-align=>'left',-width=>$def_width,-class=>'databody'},'Definition')
             );
    foreach my $unique_ao_term (@unique_ao_terms) {

        $AO_TERM = $DB->fetch('Anatomy_term',$unique_ao_term);

        my $actual_term =  $AO_TERM->Term;
        my $definition = $AO_TERM->Definition;
	#my $id = $AO_TERM->Name;
        my $link = ObjectLink($AO_TERM,$actual_term);
        
        print TR({},td({-align=>'left',-width=>$term_width,-class=>'databody'},$link),td({-align=>'left',-width=>$def_width,-class=>'databody'},$definition,br));
    }
    #print end_table();

}

#### search form

sub print_search_form {
    
    my $cgi = shift @_;
    my $form_type = shift @_;
    
    print $cgi->startform(-method=>'GET', 
			  -action=>'search');   
			  
	my %instructions = (
						'multi' => 'Multi form instructions'
						,'go'=>'GO instructions'
						,'phenotype'=>'Phenotype instructions'
						,'anatomy'=>'Anatomy instructions'
						);
	
	my $intruction = $instructions{$form_type};

	print "<br>$intruction<br>";

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

	###


	### 

	if ($form_type=~ m/multi/) {

		print "<h3>Enter a term (egg), phrase (larval development), term ID, or annotated object. See table below for available information</h3>";
		
	}
	elsif($form_type=~ m/go/) {
	
		print "<h3>Enter a term (egg), phrase (larval development), term ID (GO:0009790), or gene (unc-26) </h3>";
	}
	elsif($form_type=~ m/anatomy/) {
	
		print "<h3>Enter a term (egg), phrase (germ line), term ID (WBbt:0005784), or gene (unc-26) </h3>";
	}
	elsif($form_type=~ m/phenotype/) {
	
		print "<h3>Enter a term (egg), phrase (embryonic lethal), term ID, gene (unc-26), variation (n422), transgene (bcEx757), or rnai (WBRNAi00077478)</h3>";
	}
	else {
	
		print "<h3>Enter a term, phrase, or term ID</h3>";
	}
	
    print $cgi->textfield(-name=>'query', 
			  -size=>50, 
			  -maxlength=>80);
	
	print "<br>\n";
 

}

#### end search form

1;

