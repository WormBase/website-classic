#!/usr/bin/perl
#Neuron Viewer 0.1, allenday
#shows a pretty plot of neural connections

use strict;
use Ace;
use GD;

my $db = Ace->connect(-host=>'brie',-port=>2005) or die;
my @cells = $db->fetch(-query=>'find Cell neurodata',-filltag=>'Neurodata');

my $LAYER_MAX = 2;

my %neurons;	#for storing neurodata
my %cell;		#for follow_neuron
my $layer = 0;	#for follow_neuron

	load_neurons();

foreach my $cell (@cells) {

	open (OUT, '>./neuron_png.dot');
	print OUT 'graph elegans_nnet {' , "\n";
	print OUT '   ratio=fill;', "\n";
	print OUT '   clusterrank=global;', "\n";
	print OUT '   concentrate=TRUE;', "\n";
	print OUT '   node [color=lightblue2, style=filled];', "\n";

	follow_axon($cell);

	print OUT '}' , "\n";
	close(OUT);

	system('neato -Tplain neuron_png.dot -o neuron_png.plain');

	send_png($cell);
}

sub load_neurons() {
	print "loading neurons...\n";
	for my $cell (@cells) {
		my @neighbors = $cell->Neurodata;
		for my $neighbor (@neighbors) {
			my @connections = $neighbor->col;
			foreach (@connections) {
				#print join "\t",$cell,$_,$neighbor,"\n";
				$neurons{$cell}{$neighbor} = $_;
			}
		}
	}
}

sub follow_axon() {
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

sub send_png() {
	my ($cell) = @_;
	open(IN, './neuron_png.plain');
	$_ = <IN>;

	my $W = 800;
	my $H = 800;
	my (undef, undef, $OLD_W, $OLD_H) = split /\s+/;

	my $plot = new GD::Image($W,$H);
	my %palette = palette($plot);
	my $W_SCALE = $W / $OLD_W;
	my $H_SCALE = $H / $OLD_H;
	my (%widths, %heights);

	while(<IN>){
		chomp;
		my ($edgenode, @piece) = split /\s+/;
		my ($node1, $node2, $old_h1, $old_w1, $old_h2, $old_w2, $old_h3, $old_w3, $old_h4, $old_w4) = undef;

		if($edgenode eq 'node'){
			($node1, $old_w1, $old_h1) = @piece;
			$widths{$node1}  = $old_w1 * $W_SCALE;
			$heights{$node1} = $H - ($old_h1 * $H_SCALE);
		}
		elsif($edgenode eq 'edge'){
			($node1, $node2, undef, $old_w1, $old_h1, $old_w2, $old_h2, $old_w3, $old_h4, $old_w4) = @piece;
	
			my $w1 = $widths{$node1};
			my $w2 = $widths{$node2};
			my $h1 = $heights{$node1};
			my $h2 = $heights{$node2};

			$plot->line($w1,$h1,$w2,$h2,$palette{'black'});
			$plot->arc($widths{$node1},$heights{$node1},4,4,0,360,$palette{'red'});
			$plot->arc($widths{$node2},$heights{$node2},4,4,0,360,$palette{'red'});
	
		}
	}

	print "$cell 2.800...\n";
	open (OUT, ">./$cell.2.800.png");
	print OUT $plot->png;
	close(OUT);
}

sub palette () {
	print "making palette...\n";
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
