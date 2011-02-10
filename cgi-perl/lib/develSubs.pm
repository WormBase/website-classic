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



1;

