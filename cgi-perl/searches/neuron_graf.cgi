#!/usr/bin/perl -w

#file: neuron_graf.cgi
#author: Jack Chen
#date: Sep-Dec 2001

use strict;
use lib '../lib';
use File::stat;
use CGI qw/:standard :html3 escape Map *table *TR *td *pre area *dl *blockquote *ul/;
use CGI::Carp qw/fatalsToBrowser/;
use Ace 1.51;
use Ace::Sequence;
use Ace::Browser::AceSubs qw(:DEFAULT Configuration ResolveUrl Style Toggle !TypeSelector);
use Ace::Browser::AceSubs;
use Ace::Browser::SearchSubs;
use Ace::Browser::TreeSubs qw(AceImageHackURL);
use ElegansSubs;
use vars qw(%COLOR_EDGE %SHAPE_NODE %COLOR_NODE %LINE);

my $neuron_graf = param('each_neuron');
my @animals = ('JSH', 'N2U');
print header();

#testing
PrintTop(undef, undef, undef,
	'-Title' =>"Wormbase Neuronal Connection Display: $neuron_graf",
	'-Style'=>Style(),
	'-Target'=>'_top',
	'-Class'=>'search'
);

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

print h1("Detailed wiring data for neuron $neuron_graf");
print h3("Scroll down to view captions");
# to print out images for both JSH and N2U on a same page
for my $animal (@animals){
	# note: call graf.cgi
	my $pic_link = 'graf.cgi?neuron_graf='.$neuron_graf.'&animal='.$animal;
	
	print h3("$animal");
	#print image
	print img(
		{
			-src =>$pic_link,
			-border =>'0'
			#-usemap =>'hmap'
		}
	);
	print hr;
}

#use thicker line to represent JSH data
#use thinner line to represent N2U data
#%ANIMAL =(
#	'JSH'			=> 'bold',
#	'N2U'			=> '',
#);

my $caption_link1 = 'neuron_shape?node_shape='.'house'.'&node_color='.'blue';
my $caption_link2 = 'neuron_shape?node_shape='.'circle'.'&node_color='.'red';
my $caption_link3 = 'neuron_shape?node_shape='.'circle'.'&node_color='.'blue';
my $caption_link4 = 'neuron_shape?node_shape='.'triangle'.'&node_color='.'red';
my $caption_link5 = 'neuron_shape?node_shape='.'triangle'.'&node_color='.'blue';
my $caption_link6 = 'neuron_shape?node_shape='.'house'.'&node_color='.'magenta';
my $caption_link7 = 'neuron_shape?node_shape='.'hexagon'.'&node_color='.'red';
my $caption_link8 = 'neuron_shape?node_shape='.'hexagon'.'&node_color='.'blueviolet';
my $caption_link9 = 'neuron_shape?node_shape='.'diamond'.'&node_color='.'red';
my $caption_link10 = 'neuron_shape?node_shape='.'box'.'&node_color='.'red';
my $caption_link11 = 'neuron_shape?node_shape='.'box'.'&node_color='.'magenta';
my $caption_link12 = 'neuron_shape?node_shape='.'box'.'&node_color='.'blue';
my $caption_link13 = 'neuron_shape?node_shape='.'house'.'&node_color='.'red';


print 
	table({-width=>'50%', -cellpadding=>'5', cellspacing=>'1'},
	TR(th({-class=>'datatitle', colspan=>3}, 'Caption')),
	TR(th({-class=>'datatitle', -width=>"40%"},'Neuron-type'),
		th({-class=>'datatitle',-width=>"30%"}, 'Representation')),
	TR(td({-class=>'databody'},'interneuron, dorsal cord motor neuron, pharyngeal motorneuron/interneuron'),
		td({-class=>'databody'}, img({-src=>$caption_link1, -border=>'0'})
	)),	
	TR(td({-class=>'databody'},'ring neuron'),
		td({-class=>'databody'}, img({-src=>$caption_link2, -border=>'0'})
	)),	
	TR(td({-class=>'databody'},'ring motor neuron/interneuron, ring/ventral cord interneuron, ring/lateral cord interneuron'),
		td({-class=>'databody'}, img({-src=>$caption_link3, -border=>'0'})
	)),	
	TR(td({-class=>'databody'},'amphid neuron'),
		td({-class=>'databody'}, img({-src=>$caption_link4, -border=>'0'})
	)),	
	TR(td({-class=>'databody'},'amphid interneuron'),
		td({-class=>'databody'}, img({-src=>$caption_link5, -border=>'0'})
	)),	
	TR(td({-class=>'databody'},'pharyngeal motor neuron, pharyngeal neurosecretory motorneuron'),
		td({-class=>'databody'}, img({-src=>$caption_link6, -border=>'0'})
	)),	
	TR(td({-class=>'databody'},'inner labial neuron'),
		td({-class=>'databody'}, img({-src=>$caption_link7, -border=>'0'})
	)),	
	TR(td({-class=>'databody'},'outer labial neuron'),
		td({-class=>'databody'}, img({-src=>$caption_link8, -border=>'0'})
	)),	
	TR(td({-class=>'databody'},'cephalic neuron'),
		td({-class=>'databody'}, img({-src=>$caption_link9, -border=>'0'})
	)),
	TR(td({-class=>'databody'},'hermaphrodite specific ventral cord neuron'),
		td({-class=>'databody'}, img({-src=>$caption_link10, -border=>'0'})
	)),
	TR(td({-class=>'databody'},'ventral cord motor neuron'),
		td({-class=>'databody'}, img({-src=>$caption_link11, -border=>'0'})
	)),
	TR(td({-class=>'databody'},'ventral cord interneruon'),
		td({-class=>'databody'}, img({-src=>$caption_link12, -border=>'0'})
	)),
	TR(td({-class=>'databody'},'deirid sensory neuron, sensory touch neuron, neuron along exrectory canal, hermaphrodite specific neuron, phasmid neuron, neuron'),
		td({-class=>'databody'}, img({-src=>$caption_link13, -border=>'0'})
	))
);

PrintBottom;
