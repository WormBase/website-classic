package SKMAP::Search;
use strict;
use SKMAP::Config;
use SKMAP::Data::Extract;
use vars qw(@ISA);

@ISA	= qw(SKMAP::Data::Extract SKMAP::Config);

sub new{
	my $class	= shift;
	$class		= ref($class) if ref($class);
	my %self	= ();
	$self{'A'}	= $class->getA();
	$self{'config'}	= SKMAP::Config->new()->{'Config'};

	bless \%self, $class;
}


sub searchOnRadius{
        my $self        = shift;
        my ($nFrame, $X, $Y, $radius, $size) = @_;

        my $results     = [];
	my $scale_x	= $size / ($nFrame->{'x_max'} - $nFrame->{'x_min'});
	my $e_radius	= sprintf("%.2f", $radius / $scale_x);

	$self->{'X_start'}	= $X - $e_radius;
	$self->{'X_stop'}	= $X + $e_radius;
	$self->{'Y_start'}	= $Y - $e_radius;
	$self->{'Y_stop'}	= $Y + $e_radius;

#       get the position in the tied array for the given x_start value
	my $line_key    = $self->bsearch($self->{'A'}, $self->{'X_start'});

	for (my $i=$line_key; (split(/[\s]+/, $self->{'A'}->[$i]))[0] < $self->{'X_stop'}; $i++) {
          my ($x,$y) = split(/[\s]+/, $self->{'A'}->[$i]);
	  if($e_radius > 1){
		my $difX 	= $x - $self->{'X_start'};
		my $difY 	= $y - $self->{'Y_start'};
		next unless $difX**2 + $difY**2 < $e_radius**2;
	  }else{
	  	next unless $self->{'X_start'} < $x && $x < $self->{'X_stop'} &&
				$self->{'Y_start'} < $y && $y < $self->{'Y_stop'};
	  }

          push @{$results}, $self->{'A'}->[$i];
        }

        $self->{'count'}        = $#{$results};

        return $results;
}



1;
