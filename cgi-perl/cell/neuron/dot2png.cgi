#!/usr/bin/perl

use CGI;
use strict;
use GD;

my $query = new CGI;
my $fname = $query->param('fname');
my $cell  = $query->param('cell');

open (IN, "/tmp/$cell.$fname.plain");

$_ = <IN>;

my $W = 314;
my $H = 314;
my (undef, undef, $OLD_W, $OLD_H) = split /\s+/;

my $plot = new GD::Image($W,$H);
my %palette = palette($plot);
my $W_SCALE = $W / 10;
my $H_SCALE = $H / 10;
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

print $query->header('image/png');
print $plot->png;

close(IN);

sub palette() {
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
