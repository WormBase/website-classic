#!/usr/bin/perl

use lib '../lib';
use strict;

use File::stat;
use CGI qw/:standard Map Area *blockquote *ul *table/;
use CGI::Carp qw/fatalsToBrowser/;
use Ace;
use Ace::Sequence;
use Ace::Browser::AceSubs qw(:DEFAULT Toggle !TypeSelector ResolveUrl
			     AceMultipleChoices);
use ElegansSubs qw(:DEFAULT FetchGene MultipleChoices DisplayMoreLink StartCache Bestname);
use WormBase;
use lib '/usr/local/wormbase/website-classic/cgi-perl/cell';
use Pedigree;

use vars qw/$WORMBASE $DB $cell $results $query/;

use constant DISPLAY_LIMIT => 10;
use constant ITEM_DISPLAY_LIMIT => 100; # This is for total number of entries retrieved

END {
  undef $WORMBASE;
  undef $query;
  undef $results;
  undef $cell;
  undef $query;
}

$DB = OpenDatabase() || AceError("Couldn't open database.");
$WORMBASE = WormBase->new($DB);

$query = param('name') || param('cell') || '';

if ($query) {

    my @results = $DB->fetch(Cell => $query);
    # Query but no results
    if (@results == 0) {
	PrintTop($query,'Cell');
	PrintWarning($query,'Cell');
	print_prompt();
	PrintBottom();
	exit 0;
    }
    
    # Multiple results
    if (@results > 1) {
	PrintTop($query,'Cell');
	AceMultipleChoices($query, 'Cell' => \@results);
	PrintBottom();
	exit 0;
    }
    
    $cell = $results[0];
}

param(name=>$cell);

PrintTop($cell,'Cell');
print_prompt();

if (param('details')) {
  print_expanded_view($cell);
} else {
  print_report($cell) if $cell;
}


PrintBottom();
exit 0;


sub print_report {
  my $cell = shift;
  
  ####################
  ## FORMAT THE REPORT
  ####################

  # PRINT A SKETCH OF THE NEURONAL ARCHITECTURE
  #my $link_diagram = $results->fetch('Link_diagram'=>1);
  my $con_img = $cell->Link_diagram;
  diagram($con_img) if $con_img;
  
  # PRINT AN IMAGE AND IMAGE MAP OF THE PEDIGREE
  my ($mom,$sibling,$daughters,$nieces);
  ($mom,$sibling,$daughters,$nieces) = Pedigree->walk($cell);
  pedigree_image_and_map($results,$mom,$sibling,$daughters,$nieces);

  ## START THE OUTER UL FOR THE MAIN TOPICS
  print start_ul;

  ## OVERVIEW OF THE NEURON
  my $remark = $cell->get('Remark'=>1);
  if (defined ($cell)) {
    print li(b('OVERVIEW ')),$cell,p;
  } else {
    ## Uncomment next line to print indication that there is no additional info  
    ## print li(b('OVERVIEW: '),"No information currently available."),p;  
  }

  ## CELL GROUP INFORMATION
  if (my @cell_group = $cell->Cell_group) {
    print_cell_group_data(@cell_group);
  }

  ## CELL FATE INFORMATION
  if (!$cell->get('Daughter')) {  # no daughters, so terminal
    print li(b('FATE ')),
      'Terminally differentiated',p;
  } else {
    my $fate    = $cell->Cell_type;
    my $program = $cell->Program;
    if (defined ($fate)) {
      my $program = " ($program program)" if $program;
      print li(b('FATE')),
	ucfirst($fate)," cells$program.",p;
    } else {
      ## UNCOMMENT TO PRINT A NOTIFICATION OF NO ADDITIONAL INFO
      ## print li(b('FATE: '),"No information currently available."),p;
    }
  }

  print_pedigree_data($cell,$mom,$daughters);

  ## EMBRYO DIVISION TIME
  my $embryo_division_time= $cell->get('Embryo_division_time'=>1);
  if (defined ($embryo_division_time)) {
    print li(b('TEMPORAL INFORMATION'),
	     br,b($cell),' appears ',
	     $embryo_division_time,' minutes after the formation of the zygote.'),p;
  } else {
    ## Uncomment to print an indication that there is no info 
    ## print li(b('TEMPORAL INFORMATION: '),"None currently available."),p;
  }

  # EXPRESSION PATTERN
  my @expr_pattern = $cell->get('Expr_pattern'=>1);
  my %seen = map {$_=>1} @expr_pattern;
  
  my %associated;
  unless (@expr_pattern) {
      for my $group ($cell->Cell_group) {
	  my @patterns = grep {!$seen{$_}} $group->Expr_pattern;
	  next unless @patterns;
	  $associated{$group} = \@patterns;
      }
  }

  print li(b('EXPRESSION PATTERNS ')) if (@expr_pattern || %associated);

  my (@linked_patterns);
  if (@expr_pattern) {
    foreach (@expr_pattern) {
      my $label = eval { $_->Gene->CGC_name } || eval {$_->Gene->Public_name} || $_->CDS || $_;
      push @linked_patterns,[$_,$label];
    }
    print "$query has been directly associated with the following gene expression pattern(s): ",
      blockquote({class=>'databody'},map { ObjectLink($_->[0],$_->[1]) } sort { $a->[1] cmp $b->[1] } @linked_patterns);
  }

  if (%associated) {
    my @associated_patterns;
    print 'Similar or overlapping expression patterns:';
    for my $group (keys %associated) {
      my $pattern = $associated{$group};
      foreach (@{$pattern}) {
	my $label = eval { $_->Gene->CGC_name } || eval {$_->Gene->Public_name} || $_->CDS || $_;
	push @associated_patterns,[$_,$label];
      }
    }
    print blockquote({class=>'databody'},map { ObjectLink($_->[0],$_->[1]) } sort { $a->[1] cmp $b->[1] } 
@associated_patterns);
  } else {
    ## Uncomment to print a indication that there is no info	 
    ## print li(b('EXPRESSION PATTERNS: '),"No information currently available"),p;
  }


  my $url = url(-query=>1,-absolute=>1);
  print i(a({-href=>$url . ';details=Gene'},'View expanded details on these associated expression patterns.'));
  print p;

  # The extended table is now a separate display
  # display_expression_patterns($results);


  ## CITATIONS
  my @references = $cell->get('Reference'=>1);
  if (@references) {
    print_citations(@references) ;
    print p();
  } else {
    ## Uncomment to print a indication that there is no info 
    ## print li(b('CITATIONS: '),"No citations yet reported."),p;
  }


  ## SYNAPTIC INFORMATION
  print_synaptic_data($cell, $query) if $cell->Neurodata;

  ## END THE MAIN UL
  print end_ul;
}

#####################################
##        SUBROUTINES BEGIN
#####################################

sub diagram {
  my ($link_diagram) = @_;
  my $diagram = Configuration->Neuron_diagrams;
  print p();
  print p({-align=>'CENTER'},
	  img({-src=>"$diagram/$link_diagram"}),
	  br,b(font({-size=>2},'Source:',a({-href=>'/db/get?class=Paper;name=[cgc938]'},'The structure of the nervous system of the nematode C. elegans.')))
	 );
}


sub pedigree_image_and_map {
  my ($primary_cell,$mom,$sibling,$daughters,$nieces) = @_;

  my $pic_link= "make_pedigree.cgi?cell=" . param('name');
  print img({-src=>$pic_link,
	     -border=>'0',
	     -align=>'right',
	     -usemap=>'#make_pedigree'});
  # Boxes should be 25 x 20
  my @mapping;
  # Mom exists: build a three-layered tree
  if ($mom) {
    # The PO
    push (@mapping,Area({-shape=>'rect',
			 -coords=>'140,30,165,50',
			 -href=>Object2URL($mom),
			 -alt=>"Additional information: $mom"})
	 );
    
    # F1: sibling
    if ($sibling) {
      push (@mapping,Area({-shape=>'rect',
			   -coords=>'55,90,80,110',
				  -href=>Object2URL($sibling),
				  -alt=>"Additional information: $sibling"})
	   );
    }
    
    # F1: the primary cell
    push (@mapping,Area({-shape=>'rect',
			 -coords=>'210,90,235,110',
			 -href=>Object2URL($primary_cell),
			 -alt=>"Additional information: $primary_cell"})
	 );

    # F2: daughters
    if ($daughters) {
      if ($daughters->[0]){
	push (@mapping,Area({-shape=>'rect',
			     -coords=>'165,157,190,177',
			     -href=>Object2URL($daughters->[0]),
			     -alt=>"Additional information: " .  $daughters->[0]})
	     );
      }

      if ($daughters->[1]) {
	push (@mapping,Area({-shape=>'rect',
			     -coords=>'236,157,261,177',
			     -href=>Object2URL($daughters->[1]),
			     -alt=>"Additional information: " . $daughters->[1]})
	     );
      }
    }
    
    # F2: nieces
    if ($nieces) {
      if ($nieces->[0]){
	push (@mapping,Area({-shape=>'rect',
			     -coords=>'17,157,142,177',
			     -href=>Object2URL($nieces->[0]),
			     -alt=>"Addditional information: " . $nieces->[0]})
	     );
      }

      if ($nieces->[1]){
	push (@mapping,Area({-shape=>'rect',
			     -coords=>'90,157,115,177',
			     -href=>Object2URL($nieces->[1]),
			     -alt=>"Additional information: " . $nieces->[1]})
	     );
      }
    }
  } else {
    # The primary_cell is the root
    push (@mapping,Area({-shape=>'rect',
			 -coords=>'140,30,165,50',
			 -href=>Object2URL($primary_cell),
			 -alt=>"Additional information: $primary_cell"}),
	 );
    
    # F1: daughers
    if ($daughters) {
      if ($daughters->[0] ne '') {
	push (@mapping,Area({-shape=>'rect',
			     -coords=>'55,90,80,110',
			     -href=>Object2URL($daughters->[0]),
			     -alt=>"Additional information: " .  $daughters->[0]})
	     );
    }
      
      if ($daughters->[0]) {
	push (@mapping,Area({-shape=>'rect',
			     -coords=>'210,90,235,110',
			     -href=>Object2URL($daughters->[1]),
			     -alt=>"Additional information: " .  $daughters->[1]})
	     );
      }
    }
  }
  print Map({-name=>'make_pedigree'},@mapping);
  return;
}




sub print_prompt_hunter {
  print
    start_form,
    p({-class=>'caption'},"Type in a cell name, such as ",cite('AB:')),
    p("Symbol: ",
      textfield(-name=>'name')),
    end_form;
}



sub print_pedigree_data {
  my ($cell,$mom,$daughters) = @_;

  print li(b("PEDIGREE "));
  print
    "$query is derived from the cell named ",
      ObjectLink($mom),
	'.',p if ($mom);

  if ($daughters) {
    print 'It is the precursor of ',
    ObjectLink($daughters->[0]),' and ',
    ObjectLink($daughters->[1]),'.',p;
  }
  
  if (!$daughters) {
    print "$query represents the end of this lineage.",p;
  }

  print a({-href=>"/db/searches/pedigree?name=$cell"},"Browse this cell's pedigree."),p;

}


sub print_cell_group_data {
  my @cell_groups = @_;
 print li(b('GROUP '));
  #  my $results  = $DB->fetch(-class=>'Cell_group',
  #	  		       -name=>$cell_group);
  #  my $cell_type = $results->Remark;
  
  # Create a prettified string
  if (0) {
    my $string;
    if (@cell_groups == 1) {
      my $obj = $cell_groups[0];
      my $text = $obj;
      $text =~ s/_/ /g;
      $string .= a({-href=>Object2URL($obj)},$text);
      $string .= ' cell group.';
    } else {
      for (my $i=0;$i<@cell_groups;$i++) {
	my $obj = $cell_groups[$i];
	my $text = $obj;
	$text =~ s/_/ /g;
	if ($i == @cell_groups - 1) {
	  $string .= ' and ' . a({-href=>Object2URL($obj)},$text);
	} else {
	  $string .= a({-href=>Object2URL($obj)},$text)
	}
      }
      $string .= ' cell groups.';
    }
    print "Part of the $string",p;
  }
  foreach (@cell_groups) {
    my $obj  = $_;
    my $text = $_;
    $text =~ s/_/ /g;
    print 'Part of the ' . a({-href=>Object2URL($obj)},$text) . ' cell group.',br;
  }
  print p;
}

sub print_citations {
  
  # FOR THE OL
  #print li(b('CITATIONS'));
  
  my @references = @_;
  my @formatted_references;
  my $citation_count = @references;
  
  ## $href should be the formatted reference
  # VISIT EACH REFERENCE, EXTRACING FIELDS
  foreach my $reference (@references) {
    my $acedb_paper = $reference->fetch;
    my $paper= $acedb_paper->get('Title'=>1);
    my $author= $acedb_paper->get('Author'=>1);
    my $year= $acedb_paper->get('Year'=>1);
    my $journal= $acedb_paper->get('Journal'=>1);
    
    # FORMAT THE CITATION
    my $formatted_reference = 
      b($author,' et al. ') . 
	br . 
	  a({-href=>Object2URL($reference)},$paper) . 
	    '. ' . 
	      br . 
		$journal .
		  '. ' . 
		    $year . '.';
    push (@formatted_references,$formatted_reference);
  }  
  
  my $label = b("CITATIONS");
  
  # Toggle syntax
  # (url tag, PAGE LABEL, starting value?, 2, 3)
  ## Last 3 values
  ##
  ##2:  0 = plural; 1 = singular
  ##3:  1 = toggle glyph is closed;  0 = toggle glyph is open 
  ##    Setting it starts the initial value
  
  param(name => $query);
  my ($href,$open_citations) = Toggle('citation',$label,$citation_count,0,1);
  
  print $href;
  
  if ($open_citations) {
    print ol(li(\@formatted_references));
    print p;
  } else {
    print br;
  }
  
}

sub print_synaptic_data {
  my ($cell, $query) = @_;
  
  print li(b('SYNAPSE DATA '),br,
	   "<b>JSH: </b>Name of a <i>C. elegans</i> described in White <i>et al</i> (1986).",br,
	   "<b>N2U: </b>Name of a <i>C. elegans</i> described in White <i>et al</i> (1986).", br,
	   "The number of specified connections are indicated in <b>boldface</b>",br,
	   "The number of uncertain connections are shown <i><font color = \"999999\">italicized and in gray.</font></i>",
	   br,br,
	   "<b>Note: </b>  all data shown in the table at the moment are from the White <i>et al</i> (1986). ",br,br);
  
  # TWO DATABASE CALLS - ONE TO RETRIEVE ALL CONNECTING CELLS, 
  # ONE FOR TYPES OF CONNECTIONS
  my @connected_cells = $cell->Neurodata;  

  ############################################################
  # block of code for enhancing display capability:          #
  ############################################################
  
  # SETUP THE TABLE HEADERS

  my @headings = (	'Neuron Name',
		  	'Gap(JSH)',
		  	'Gap(N2U)',
		  	'Receives from(JSH)',
		  	'Receives from(N2U)',
		  	'Synapses on(JSH)',
		  	"Synapses on(N2U)");
			
			#Note: the new table contains three more columns
		  
  	my @rows = th({-class=>'resultstitle'},
		\@headings);
    
  	# VISIT EACH CONNECTED CELL, DETERMINE ITS TYPE OF CONNECTION
  	# AND FORMAT A LINK TO IT
  	my $hilite;
	
	for my $connected_cell (sort @connected_cells) {   
    		# FORMAT A LINK TO THE CONNECTING CELL
    		my $link = ObjectLink($connected_cell,"$connected_cell");
    		
		# RETRIEVE ALL CONNECTION CLASSES FOR A GIVEN CELL
    		my @connection_types = $connected_cell->col;

		# variables for retrieving values in table
    		my ($gap_JSH, $pre_JSH, $post_JSH) = undef;
		my ($gap_N2U, $pre_N2U, $post_N2U) = undef;
    		
		# tempporary variables for processing
		my ($pre_J_temp1, $pre_J_temp2, $post_J_temp1, $post_J_temp2) = undef;
		my ($pre_N_temp1, $pre_N_temp2, $post_N_temp1, $post_N_temp2) = undef;

		# assign values to the above variables 
		for my $connection_type ( @connection_types) {	
			
			#check type of animals used for experiment
			my @animalTypes = $connected_cell
				->at($connection_type)
				->col;

			#number of each type of connections for corresponding animal
			my @connectionNumbers = $connected_cell
				->at($connection_type)
				->col(2);

      			# TALLY UP THE TYPES OF CONNECTIONS
      			# IF A CERTAIN TYPE IS OBSERVED, SUBSTITUTE IN THE BULLET CODE
			# assign values to column variables
			
			for (my $m =0; $m<=$#animalTypes; $m++){
				if($animalTypes[$m]=~/^JSH/i){
      	                		$gap_JSH  = "<b>$connectionNumbers[$m]</b>"
						if ($connection_type =~ /^Gap/i);
      					$gap_JSH  = $connectionNumbers[$m]
						if ($connection_type =~ /^Gap.*_joint/i);
      					$pre_J_temp1  ="<b>$connectionNumbers[$m]</b>"
						if  ($connection_type =~ /^Receive$/i);
      		        		$pre_J_temp2  = "<i><font color =\"999999\">
						$connectionNumbers[$m]</font></i>"
						if (($connection_type 
							=~ /^Receive_joint$/i));
   					$post_J_temp1 = "<b>$connectionNumbers[$m]</b>"
						if  ($connection_type =~ /^Send$/i);
  					$post_J_temp2 = "<i><font color = \"999999\">
						$connectionNumbers[$m]</font></i>"
						if (($connection_type =~ /^Send_joint$/i) 
						);
				}
			}

			for (my $m =0; $m<=$#animalTypes; $m++){
				if($animalTypes[$m]=~/^N2U/i){
      	                		$gap_N2U  = "<b>$connectionNumbers[$m]</b>"
						if ($connection_type =~ /^Gap/i);
      					$gap_N2U  = $connectionNumbers[$m]
						if ($connection_type =~ /^Gap.*_joint/i);
      					$pre_N_temp1  ="<b>$connectionNumbers[$m]</b>"
						if  ($connection_type =~ /^Receive$/i);
      		        		$pre_N_temp2  = "<i><font color=\"999999\">
						$connectionNumbers[$m]</font></i>"
						if (($connection_type 
							=~ /^Receive_joint$/i));
   					$post_N_temp1 = "<b>$connectionNumbers[$m]</b>"
						if  ($connection_type =~ /^Send$/i);
  					$post_N_temp2 = "<i><font color=\"999999\">
						$connectionNumbers[$m]</font></i>"
						if (($connection_type =~ /^Send_joint$/i) 
						);
				}
			}

			# This section generates lots of innocous warnings under -w
			# as unit variable used in concatenation
			{
			  local $^W=0;
			  #summarizing		
			  $pre_JSH = $pre_J_temp1.$pre_J_temp2;
			  $post_JSH = $post_J_temp1.$post_J_temp2;
			  
			  $pre_N2U = $pre_N_temp1.$pre_N_temp2;
			  $post_N2U = $post_N_temp1.$post_N_temp2;
			  
			  #assign default value
			  $gap_JSH =  "&nbsp;" unless $gap_JSH;
			  $pre_JSH =  "&nbsp;" unless $pre_JSH;
			  $post_JSH = "&nbsp;" unless $post_JSH;
			  $gap_N2U = "&nbsp;" unless $gap_N2U;
			  $pre_N2U = "&nbsp;" unless $pre_N2U;
			  $post_N2U = "&nbsp;" unless $post_N2U;
			}
		      }
		# SWITCH THE HILIGHT COLOR AND MAKE A ROW
		$hilite = ($hilite && $hilite eq 'resultsbodyalt') ? 
		  'resultsbody' : 'resultsbodyalt';
		push (@rows,td({-align=>'LEFT', -class=>"$hilite"},
			       [$link,$gap_JSH, $gap_N2U ,$pre_JSH, $pre_N2U,
				$post_JSH, $post_N2U]));
  		
	      }
  #printing table
  print table({-border=>'0'},Tr(\@rows));
} #closing the subroutine statement



sub print_prompt {
  $WORMBASE->print_prompt(-message  => 'Specify a cell such as',
			  -class    => 'Cell',
			  -examples => [ {'no_message' => 'AB'},
					 {'no_message' => 'VD1'},
					 {'no_message' => 'M1'},
				       ]);
}




sub display_expression_patterns {
    my $cell = shift;
    my @expression_patterns = fetch_expression_patterns($cell);
    my @associated_patterns = fetch_associated_patterns($cell) unless @expression_patterns;
    
    if (@expression_patterns || @associated_patterns) {
#    print h3("Expression patterns for " . param('name'));

	print a({-href=>'#expression'},'Directly associated patterns') . ' | '
	    . a({-href=>'#linked'},'Genes with similar expression patterns'),p;
	print hr;
	if (@expression_patterns) {
	    print a({-name=>'expression'},'');
	    print "$cell has been directly associated with the following gene expression pattern(s): ";
	    print p;
	    print generate_patterns_table(\@expression_patterns);
	}

	if (@associated_patterns) {
	    print a({-name=>'linked'},'');
	    print 'Similar or overlapping expression patterns:';
	    print p;
	    print generate_patterns_table(\@associated_patterns);
	}
    } else {
	## Uncomment to print an indication that there is no info
	#print li(b('EXPRESSION PATTERNS: '),"No information currently available"),p;
    }
}



sub generate_patterns_table {
  my ($patterns,$show_all) = @_;
  $show_all ||= param('details');
  my ($link,$limit);
  if (!$show_all && @$patterns > DISPLAY_LIMIT) {
    my $link_text = scalar @$patterns . " genes found, " . DISPLAY_LIMIT . " displayed; view all";
    $link = DisplayMoreLink(\@$patterns,'Gene',undef,$link_text,1);
    $limit = DISPLAY_LIMIT;
  }
  $limit ||= @$patterns;
  my $text = start_table({-border=>1,-class=>'databody'}) . TR(th({-width=>'10%'},'CGC name'),th('Sequence'),
							     th('From expression pattern'),th('Description'));
  my @rows;
  foreach (@$patterns) {
    push @rows,[eval { $_->Gene->CGC_name } ? $_->Gene->CGC_name : '',
		eval { $_->Gene->Sequence_name} ? $_->Gene->Sequence_name : '',
		$_,
		join("<br><br>",$_->Pattern)];
  }

  my $count;
  foreach (sort { $a->[0] cmp $b->[0] } @rows) {
    last if $count++ == $limit;
    $text .= TR(
		td($_->[0] ? ObjectLink($_->[0]) : ''),
		td($_->[1] ? ObjectLink($_->[1]) : ''),
		td(ObjectLink($_->[2])),
		td($_->[3]));
  }

  $text .= end_table;
  $text .= $link if $link;
  $text .= p;
  return $text;
}


sub print_expanded_view {
  my $cell = shift;
  print h3("Displaying all associated expression patterns for $cell");
  print start_form(),button(-onClick=>'window.close()',-label=>'Close Window'),end_form();
  display_expression_patterns($cell);
}


sub fetch_expression_patterns {
  my $cell = shift;
  my @expr_patterns = $cell->get('Expr_pattern'=>1);
  return @expr_patterns;
}



sub fetch_associated_patterns {
  my $cell = shift;
  my @associated_patterns;
  my %seen;
  for my $group ($cell->Cell_group) {
    my @patterns = grep {!$seen{$_}} $group->Expr_pattern;
    next unless @patterns;
    push @associated_patterns,@patterns;
  }
  return @associated_patterns;
}
