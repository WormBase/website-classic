package SKMAP::Coordinates;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
require Exporter;
use SKMAP::Config;

@ISA = qw(Exporter);

@EXPORT		= qw( getXYPixelCoordinates getXYGeneCoordinates);
@EXPORT_OK	= qw();

{
	my $Config      = SKMAP::Config->new()->{'Config'};
	my $mountains   = &{$Config->Mountains_coords};

	sub _getMountainsCoords{
		return $mountains;
	}
}

sub getXYPixelCoordinates{
#       given the absolute coordinates and based on the image width
#       compute the X_px and the Y_px on the image for this gene

	my ($nFrame, $X, $Y, $imgSize) = @_;

	my $scale_x = $imgSize/($nFrame->{'x_max'} - $nFrame->{'x_min'});
	my $scale_y = $imgSize/($nFrame->{'y_max'} - $nFrame->{'y_min'});

	my $X_px = ($X - $nFrame->{'x_min'}) * $scale_x;
	my $Y_px = $imgSize - ($Y - $nFrame->{'y_min'}) * $scale_y;

	return ($X_px, $Y_px);
}

sub getXYGeneCoordinates{
#      given the (X_px, Y_px) values and the Frame return the X and Y

	my ($Frame, $X_px, $Y_px, $imgSize) = @_;

        my $scale_x = $imgSize/($Frame->{'x_max'} - $Frame->{'x_min'});
        my $scale_y = $imgSize/($Frame->{'y_max'} - $Frame->{'y_min'});

	my $X	= $Frame->{'x_min'} + ($X_px / $scale_x); 
	my $Y	= $Frame->{'y_min'} + ($imgSize - $Y_px)/$scale_y;

	return ($X, $Y);
}


1;
