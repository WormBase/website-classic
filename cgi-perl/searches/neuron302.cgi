#!/usr/bin/perl

#file: neuron302.cgi
#Author: Jack chen
#Date: Sep-Dec 2001

#last modified: Dec 13, 2001, Thursday
#created: Oct 11, 2001, Thursday.
#This file creates a big table by default;
#show all neurons in C. elegans and all aspects of a neuron
#Note: the number of total neurons connected is still not right!!

use lib '../lib';
use strict;
use File::stat;
use CGI qw/:standard :html3 escape Map area *dl *blockquote *ul/;
use CGI::Carp qw/fatalsToBrowser/;
use Ace 1.51;
use Ace::Sequence;
use Ace::Browser::AceSubs qw(:DEFAULT Toggle !TypeSelector);
use Ace::Browser::AceSubs;
use ElegansSubs;
use vars qw($DB @NEURONS);

END {
  undef @NEURONS;
}

# START ACE AND QUERY IF THERE IS PEDIGREE INFO
$DB = OpenDatabase() || AceError ("Couldn't open database"); 
my $query = qq(query find cell Neurodata AND cell_type ="JW-Designated Neuron");
#just for testing
#my $query = qq(query find cell Neurodata);
@NEURONS = $DB->fetch(-query => $query, -fill=>1); 

# give each cgi instance a unique number (used to generate/track temp files)
my $fname = $$;

PrintTop (undef, undef, undef, '-Title'=>"All neurons in C. elegans");

my $time = localtime;
 
#print notes:
print start_ul;
print h1('Summary of All Neurons in <i>C. elegans</i> (Adult Hermaphrodite)');
print li(b('Note:')),br,
	'To see more details about each neuron, click on the name.', br,
	'Num: serial number in alphabetical order.',br,
	'Neuron: name of neurons.',br,
	'Brief ID: brief identification.',br,
	'Num total connections: number of all connections including 
		gap junctions and synapses',br,
	'--: data not available in database at time being', br, br;
print li(b('Time this table generated: ')),br,"$time", br,br;
print li(b('Reference: ')),br, '(White et al., 1986) unless otherwise specified',br,br;
print end_ul;

# SETUP THE TABLE HEADERS
  my @headings = (	'Num',
		  	'Neuron',
			'Brief ID',
			'Num neurons connected',
			'Num total connections',
			'Go to summary page',
			#'Go to graph page'
  );
		  
  my @rows = th({-class=>'resultstitle'},
		\@headings);
    
  # VISIT EACH CONNECTED CELL, DETERMINE ITS TYPE OF CONNECTION
  # AND FORMAT A LINK TO IT
  my $number = 0;
  my ($link, $pic_link, $hilite, $briefid, $total_neurons, $total_connects);

  for my $each_neuron (@NEURONS) {

	if ($DB->fetch(cell=>$each_neuron)){
		$each_neuron = $DB->fetch(cell => $each_neuron);

  		$link = ObjectLink(
				$each_neuron,
				"Summary"
				#"$each_neuron"
				);
        
		# link to neuron_graf.cgi page
		#$pic_link = qq{<a href="neuron_graf.cgi?each_neuron
		#	=${each_neuron}">
		#	Graph
		#	</a>
		#	}; 

		# get value for Brief_ID
		$briefid = $each_neuron->get ('Brief_id'=>1);
	
		# get value for total number of neurons connected
		my @con_neurons = $each_neuron->Neurodata;
		$total_neurons = scalar(@con_neurons);

		# get value for total number of connections 
		# (how matter if its gap junction, or synapses)
		$total_connects = 0;
		
		foreach my $totalN (@con_neurons){
			my @con_types = $totalN->col;

			foreach my $con_type(@con_types){
				my @connectionNumbers = $totalN->at($con_type)->col(2);
			
				foreach my $connectionNumber(@connectionNumbers){
					$total_connects += $connectionNumber;
				}
			}
		}	
	
		# assign default values
		$briefid  	= "--" unless $briefid;
		$total_connects = "--" unless $total_connects;
		#$pic_link = '--' unless $total_neurons;
		$link = '--' unless $link;
		$total_neurons	= "--" unless $total_neurons;

	}

	# SWITCH THE HILIGHT COLOR AND MAKE A ROW
    	$hilite = ($hilite eq 'resultsbodyalt') ? 
			'resultsbody' : 'resultsbodyalt';
	$number ++;

    	push (@rows,td({-align=>'LEFT', -class=>"$hilite"},
			[$number, $each_neuron, $briefid, 
			 $total_neurons, $total_connects, $link,
		#	$pic_link
			]));
  }
  print table({-border=>'0'}, Tr(\@rows));
 
PrintBottom();
