#!/usr/bin/perl
#Neuron Viewer 0.1, allenday
#shows a pretty plot of neural connections

use strict;
use CGI;
use Ace;
use Ace::Browser::AceSubs;
use ElegansSubs;
use GD;
use vars qw/$db/;

#open (DEBUG, '>./debug.log');

#print DEBUG "started up...\n";

my $query = new CGI;
$db = OpenDatabase() || AceError("Couldn't open database.");

my $q_cell    = $query->param('cell');
my $LAYER_MAX = $query->param('depth');
my $PIXELS    = $query->param('pix');
my $fname     = $query->param('fname');

my $INCH  = 10;
my $SCALE = $PIXELS / $INCH;

my %neurons;	# for storing neurodata
my %cell;	# for follow_neuron
my $layer = 0;	# for follow_neuron

unless($q_cell){
  print $query->header;
  print $query->start_html('Neuron Viewer 0.1');
  print "http://brie2:8081/perl/ace/elegans/cell/neuron/neuron.cgi?cell=ADAL";
  print $query->end_html;
} else {
  &load_neurons;
  &make_dot ($q_cell);
  &make_png;
}

#close(DEBUG);

sub make_png() {
  my $plot = new GD::Image($PIXELS,$PIXELS);
  my %palette = palette($plot);
  
  my (@body) =  split /\n/, `neato -Tplain /tmp/neuron.$fname.dot`;
  
  my (%widths, %heights);
  
  foreach (@body){
    chomp;
    my ($edgenode, @piece) = split /\s+/;
    my ($node1 , $node2, 
	$old_h1, $old_w1, 
	$old_h2, $old_w2, 
	$old_h3, $old_w3, 
	$old_h4, $old_w4) = undef;
    
    if($edgenode eq 'node'){
      ($node1, $old_w1, $old_h1) = @piece;
      $widths{$node1}  = $old_w1 * $SCALE;
      $heights{$node1} = $PIXELS - ($old_h1 * $SCALE);
    }
    elsif($edgenode eq 'edge'){
      ($node1, $node2, undef, $old_w1, $old_h1, $old_w2, $old_h2, $old_w3, $old_h4, $old_w4) = @piece;
      #print $widths{'IL2L'}, "\n";
      $plot->line(
		  $widths{$node1},$heights{$node1},
		  $widths{$node2},$heights{$node2},
		  $palette{'black'}
		 );
      #print "$widths{$node1}\t$widths{$node2}\n";
      $plot->arc($widths{$node1},$heights{$node1},4,4,0,360,$palette{'red'});
      $plot->arc($widths{$node2},$heights{$node2},4,4,0,360,$palette{'red'});
    }
  }
  
  #print $widths{'IL2L'}, "\n";
  
  print $query->header("image/png");
  open (OUT, ">/tmp/neuron" . "$q_cell.$fname.png");
  print OUT $plot->png;
  print $plot->png;
  close(OUT);
  
}

sub make_dot {
  my ($q_cell) = @_;
  
  open (OUT, ">/tmp/neuron.$fname.dot");
  print OUT 'graph elegans_nnet {' , "\n";
  print OUT '   ratio=fill;', "\n";
  print OUT "   size=\"$INCH,$INCH\";\n";	
  print OUT '   clusterrank=global;', "\n";
  print OUT '   concentrate=TRUE;', "\n";
  print OUT '   node [color=lightblue2, style=filled];', "\n";
  
  follow_axon($q_cell);
  
  print OUT '}' , "\n";
  close(OUT);
}

sub load_neurons {
  my @cells = $db->fetch(-query=>'find Cell neurodata',-filltag=>'Neurodata');
  
  for my $cell (@cells) {
    my @neighbors = $cell->Neurodata;
    for my $neighbor (@neighbors) {
      my @connections = $neighbor->col;
      foreach (@connections) {
	$neurons{$cell}{$neighbor} = $_;
      }
    }
  }
}

sub follow_axon {
  my ($kernel) = @_;
  
  unless(exists($cell{$kernel})){
    print OUT "\t$kernel;\n";
    $cell{$kernel} = $kernel;
  }
  if($layer < $LAYER_MAX){
    foreach my $friend ( keys( %{$neurons{$kernel}} ) ){
      $layer++;
      
      unless(exists($cell{$friend})){
	print OUT "\t$friend;\n";
	$cell{$friend} = $friend;
      }
      print OUT "\t$kernel -- $friend;\n";
      follow_axon($friend);
      $layer--;
    }
  }
}

sub palette {
  my $img = shift;
  
  my %palette = (
		 'white'   => $img->colorAllocate(255,255,255),
		 'black'   => $img->colorAllocate(0,0,0),
		 'gray'    => $img->colorAllocate(208,208,208),
		 'ltgray'  => $img->colorAllocate(233,233,233),
		 'violet'  => $img->colorAllocate(128,0,255),
		 'red'     => $img->colorAllocate(255,0,0),
		 'pink'    => $img->colorAllocate(255,192,192),
		 'yellow'  => $img->colorAllocate(255,255,0),
		 'green'   => $img->colorAllocate(0,255,0),
		 'cyan'    => $img->colorAllocate(0,255,255),
		 'blue'    => $img->colorAllocate(0,0,255),
		 'ltblue'  => $img->colorAllocate(64,128,255),
		);
  
  return %palette;
}
