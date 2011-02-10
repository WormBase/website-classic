#!/usr/bin/perl -w

#file: graf.cgi
#author: Jack Chen
#data: Sep-Dec 2001

use strict;
use lib '../lib';
#the following line is added to locate GraphViz.pm module
use lib '/usr/lib/perl5/site_perl/5.6.0';
use File::stat;
use CGI qw/:standard :html3 escape Map *table *TR *td *pre area *dl *blockquote *ul/;
use CGI::Carp qw/fatalsToBrowser/;
use Ace 1.51;
use Ace::Sequence;
use Ace::Browser::AceSubs;
use Ace::Browser::SearchSubs;
use Ace::Browser::TreeSubs qw(AceImageHackURL);
use ElegansSubs;

use vars qw(%COLOR_EDGE %SHAPE_NODE %COLOR_NODE %LINE %ANIMAL %neurons_hash);
use GraphViz;

%COLOR_EDGE = (
	1 	=>	'purple',
	2 	=>	'darkviolet',
	3 	=>	'blueviolet',
	4 	=>	'lightblue',
	5 	=>	'green',
	6 	=>	'greenyellow',
	7 	=>	'orange',
	8 	=>	'orangered',
	9 	=>	'pink',
	10	=>	'red',
);
%SHAPE_NODE = (
	'ring' 			=> 'circle',
	'ventral cord' 		=> 'box',
	'labial neuron' 	=> 'hexagon',
	'amphid' 		=> 'triangle',
	'cephalic' 		=> 'diamond',
	'others' 		=> 'house',
);
%COLOR_NODE =(
	'inter'			=> 'blue',
	'motor' 		=> 'magenta',
	'inner' 		=> 'red',
	'outer' 		=> 'blueviolet',
	'others'		=> 'red',
);
%LINE = (
	'sure' 			=> 'solid',
	'uncertain' 		=> 'dotted',
);

#use thicker line to represent JSH data
#use thinner line to represent N2U data
%ANIMAL =(
	'JSH'			=> 'bold',
	'N2U'			=> '',
);

my $neuron_graf = param ('neuron_graf');
my $animal = param('animal');

#developer's note;
#things need to taken care of
#	a. name of animal
#	b. type of connection
#	C. number of connections
#	to begin with, focus on JSH

# give each cgi instance a unique number (used to generate/track temp files)
my $fname = $$;

# START ACE AND QUERY IF THERE IS PEDIGREE INFO
my $DB = OpenDatabase() || AceError("Couldn't open database.");

#the following line get all the possible neurons from the database.
my @neurons = $DB->fetch(-query=>"query find cell neurodata");

#for checking and "casting"
foreach my $neuron(@neurons){
	$neurons_hash{$neuron}=$neuron;
}

if (exists $neurons_hash{$neuron_graf}){
	$neuron_graf = $neurons_hash{$neuron_graf};
}else{
	$neuron_graf = $neurons[0];
	print "The neuron $neuron_graf does not exist, displayed default value\n";
}

#all of the neurons connected to the "master neuron"
my @connected_cells = $neuron_graf->Neurodata;

my $WIDTH = $#connected_cells + 1;
my $g = GraphViz -> new(width=>$WIDTH / 1.8, height=>7);

#the "master neuron"
$g->add_node("$neuron_graf",fontcolor => 'white',
				shape =>get_node_shape($neuron_graf),
			   height =>1, 
			   width => 1,
                           style => 'filled',
			   fillcolor => get_node_color($neuron_graf)
);


#for each connected cell, check each connection between it and the "master" cell 
foreach my $connected_cell(sort @connected_cells){
  $g->add_node("$connected_cell",fontcolor => 'white',
  				 shape => get_node_shape($connected_cell),
				 height =>1.5,
 				 width =>0.5,
				 style => 'filled',
				 fillcolor => get_node_color($connected_cell),
				 #trying to add links, not working still
				 #URL =>"http://jarlsberg.cshl.org/db/cell/neuron_graf.cgi?each_neuron=$connected_cell",
				 URL =>"neuron_graf.cgi?each_neuron=$connected_cell",
  );

  #decide the color (number of each connections), direction (receive or send)
  #and line/broken-line of each edge
  #first, retrieve all of the connected types (a kind of connection + a number)
  my @connected_types = $connected_cell->col;
  
  if (@connected_types){
  	#assign value to each connectype (or each edge:kind+number)
	foreach my $connected_type(@connected_types){
		#check name of animals used for experiment
		my @animal_types = $connected_cell
			->at($connected_type)
			->col;
		#number of each type of connection for corresponding animal
		my @connection_numbers = $connected_cell
			->at($connected_type)
			->col(2);
  
  		#second, retrieve the value for each type of connection, and draw an edge
  		for (my $m=0; $m<=$#animal_types; $m++){
  			if (($animal eq 'JSH') && ($animal_types[$m]=~/^JSH/i)){
				if ($connected_type =~ /^Receive$/i){
					my $tmp = $connection_numbers[$m];
  					$g->add_edge("$neuron_graf" => "$connected_cell",
		 				      color => $COLOR_EDGE{$tmp},
						      style => 'bold',
						      dir   => 'back',
						      arrowsize => 3,
					);
				}
		
				if($connected_type =~ /^Receive_joint$/i){
					my $tmp = $connection_numbers[$m];
  					$g->add_edge("$neuron_graf" => "$connected_cell",
		 				      color => $COLOR_EDGE{$tmp},
						      dir   => 'back',
						      arrowsize => 3,
					);
				}
		
				if($connected_type =~ /^Gap/i){
					my $tmp = $connection_numbers[$m];
  					$g->add_edge("$neuron_graf" => "$connected_cell",
		 				      color => $COLOR_EDGE{$tmp},
						      dir   => 'both',
						      style => 'bold',
						      arrowhead => 'dot',
						      arrowtail => 'dot',
						      arrowsize => 5,
					);
				}
				if($connected_type =~ /^Send/i){
					my $tmp = $connection_numbers[$m];
  					$g->add_edge("$neuron_graf" => "$connected_cell",
		 				      color => $COLOR_EDGE{$tmp},
						      style => 'bold',
						      dir   => 'forward',
						      arrowsize => 3,
					);
				}
				if($connected_type =~ /^Send_joint/i){
					my $tmp = $connection_numbers[$m];
  					$g->add_edge("$neuron_graf" => "$connected_cell",
		 				      color => $COLOR_EDGE{$tmp},
						      dir   => 'forward',
						      arrowsize => 3,
					);
				}

			}elsif(($animal eq 'N2U') && ($animal_types[$m] =~ /^N2U/i)){
	
				if ($connected_type =~ /^Receive$/i){
					my $tmp = $connection_numbers[$m];
  					$g->add_edge("$neuron_graf" => "$connected_cell",
		 				      color => $COLOR_EDGE{$tmp},
						      style => 'bold',
						      dir   => 'back',
						      arrowsize => 3,
					);
				}
		
				if($connected_type =~ /^Receive_joint$/i){
					my $tmp = $connection_numbers[$m];
  					$g->add_edge("$neuron_graf" => "$connected_cell",
						      color => $COLOR_EDGE{$tmp},
						      dir   => 'back',
						      arrowsize => 3,
					);
				}
		
				if($connected_type =~ /^Gap/i){
					my $tmp = $connection_numbers[$m];
  					$g->add_edge("$neuron_graf" => "$connected_cell",
		 				      color => $COLOR_EDGE{$tmp},
						      style => 'bold',
						      dir   => 'both',
						      arrowhead => 'dot',
						      arrowtail => 'dot',
						      arrowsize => 5,
					);
				}
				if($connected_type =~ /^Send/i){
					my $tmp = $connection_numbers[$m];
  					$g->add_edge("$neuron_graf" => "$connected_cell",
		 				      color => $COLOR_EDGE{$tmp},
						      style => 'bold',
						      dir   => 'forward',
						      arrowsize => 3,
					);
				}
				if($connected_type =~ /^Send_joint/i){
					my $tmp = $connection_numbers[$m];
  					$g->add_edge("$neuron_graf" => "$connected_cell",
		 				      color => $COLOR_EDGE{$tmp},
						      dir   => 'forward',
						      arrowsize => 3,
					);
				}
			}
  		}
  	}
  }
  $g->add_edge("$neuron_graf" =>
  		"$connected_cell",
  		style => 'invis',
		);

}

print $g->as_png;

#+++++++++++++++++++
#subroutines start here

sub get_node_shape{
	my $selected_neuron = shift;
  	if (exists $neurons_hash{$selected_neuron}){
  		$selected_neuron = $neurons_hash{$selected_neuron};
  	}
	my $briefid = $selected_neuron->get('Brief_id'=>1); 
	my $shape;

	#traversing the hash
	#foreach my $key (keys %SHAPE_NODE){
	#	if ($briefid =~m/$key/){
	#		$shape = $SHAPE_NODE{$key};		
	#	}else{
	#		$shape = $SHAPE_NODE{others};
	#	}
	#}
	
	if ($briefid =~/ring/i){
		$shape="circle";
	}elsif($briefid=~/ventral cord/i){
		$shape="box";
	}elsif($briefid=~/labial/i){
		$shape="hexagon";
	}elsif($briefid=~/amphid/i){
		$shape="triangle";
	}elsif($briefid=~/cephalic/i){
		$shape="diamond";
	}else{
		$shape="house";
	}

	return $shape;
}
########
sub get_node_test{
	my $selected_neuron = shift;
  	if (exists $neurons_hash{$selected_neuron}){
  		$selected_neuron = $neurons_hash{$selected_neuron};
  	}
	my $briefid = $selected_neuron->get('Brief_id'=>1); 
	my $shape;
	#traversing the hash
	foreach my $key (keys %SHAPE_NODE){
		if ($briefid =~/^$key/i){
			$shape = $SHAPE_NODE{$key};		
		}else{
			$shape = $SHAPE_NODE{others};
		}
	}
	#return $shape;
	#just for testing
	return $briefid;
}
########
sub get_node_color{
	my $selected_neuron = shift;
  	if (exists $neurons_hash{$selected_neuron}){
  		$selected_neuron = $neurons_hash{$selected_neuron};
  	}
	my $briefid = $selected_neuron->get('Brief_id'=>1); 
	my $color;
	#traversing the hash
	#foreach my $key (keys %COLOR_NODE){
	#	if ($briefid =~/^$key/i){
	#		$color = $COLOR_NODE{$key};		
	#	}else{
	#		$color = $COLOR_NODE{others};
	#	}
	#}
	
	if ($briefid =~/inter/i){
		$color="blue";
	}elsif($briefid=~/motor/i){
		$color="magenta";
	}elsif($briefid=~/inner/i){
		$color="red";
	}elsif($briefid=~/outer/i){
		$color="blueviolet";
	}else{
		$color="brown";
	}
	return $color;
}

