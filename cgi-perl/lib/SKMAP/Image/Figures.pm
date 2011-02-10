package SKMAP::Image::Figures;
use strict;
use GD;


sub triangle{
	my $self	= shift;
	my ($gd, $x, $y, $a, $color)	= @_;

	my $h     = int(($a/2) * sqrt(3));
	my ($x1, $y1) = ($x, $y + ($h*2/3));
	my ($x2, $y2) = ($x - $a/2, $y - ($h/3));
	my ($x3, $y3) = ($x + $a/2, $y - ($h/3));
	my $triP      = new GD::Polygon;
	$triP->addPt($x1, $y1);
	$triP->addPt($x2, $y2);
	$triP->addPt($x3, $y3);
	$gd->filledPolygon($triP, $color);
}



sub point{
	my $self		= shift;
	my($gd, $x, $y, $color)	= @_;
	$gd->setPixel($x, $y, $color);
}



sub circle{
	my $self		= shift;
	my($gd, $x, $y, $w, $h, $color)	= @_;
	$gd->arc($x, $y, $w, $h, 0, 360, $color);
}


sub text{
	my $self		= shift;
	my($gd, $x, $y, $text, $color, $textCoords)	= @_;
	my($w, $h)	= (gdSmallFont->width, gdSmallFont->height);
	my($x_txt, $y_txt)	= ($x+3, $y-$h/2);
	my $txtW		= $w * (scalar (split("", $text)));
	my($x_max, $y_max)	= ($x_txt + $txtW, $y_txt + $h);
	
	my ($imgW, $imgH) = $gd->getBounds();

	$x_txt	= $x-3-$txtW	if $x+3+$txtW > $imgW;
	$y_txt	= $y + $h/2	if $y-$h/2 < 0;
	$y_txt	= $y - $h	if $y+$h/2 > $imgH;


	if(scalar @$textCoords == 0){
		push @$textCoords, [$x_txt, $y_txt, $x_max, $y_max, 0];
		$gd->string(gdSmallFont, $x_txt, $y_txt, $text, $color);
	}else{
		my $stat	= 1;
		while($stat == 1){
			foreach my $pointSet (@$textCoords){
				next if $x_txt > $pointSet->[2];
				next if $x_max < $pointSet->[0];
				next if $y_txt > $pointSet->[3];
				next if $y_max < $pointSet->[1];
				$stat = 0;
			};
			push @$textCoords, [$x_txt, $y_txt, $x_max, $y_max, 0] if $stat == 1;
			$gd->string(gdSmallFont, $x_txt, $y_txt, $text, $color) if $stat == 1;
			last;
		};
	}

	
#	$gd->string(gdSmallFont, $x_txt, $y_txt, $text, $color);
}

sub square{
	my $self	= shift;
	my ($gd, $x, $y, $a, $color)	= @_;

	my ($x1, $y1) = ($x - $a/2, $y - $a/2);
	my ($x2, $y2) = ($x + $a/2, $y - $a/2);
	my ($x3, $y3) = ($x + $a/2, $y + $a/2);
	my ($x4, $y4) = ($x - $a/2, $y + $a/2);
	
	my $sqP      = new GD::Polygon;
	$sqP->addPt($x1, $y1);
	$sqP->addPt($x2, $y2);
	$sqP->addPt($x3, $y3);
	$sqP->addPt($x4, $y4);

	$gd->filledPolygon($sqP, $color);
}



sub diamond{
	my $self	= shift;
	my ($gd, $x, $y, $H, $color)	= @_;

	my $ratio	= 2/3;
	my $h		= int($H*2/3);

	my ($x1, $y1) = ($x, $y + $H);
	my ($x2, $y2) = ($x + $h, $y);
	my ($x3, $y3) = ($x, $y - $H);
	my ($x4, $y4) = ($x - $h, $y);
	
	my $dmP      = new GD::Polygon;
	$dmP->addPt($x1, $y1);
	$dmP->addPt($x2, $y2);
	$dmP->addPt($x3, $y3);
	$dmP->addPt($x4, $y4);

	$gd->filledPolygon($dmP, $color);
}


1;
