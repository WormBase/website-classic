package Splicer;
# draws splice structures for genes and keeps track of image maps

use GD;
use Ace;
use Ace::Graphics::Panel;
use strict;

# make a new Transcript object
sub new {
  my ($package,$sequence) = @_;
  return bless {
		sequence   => $sequence,  # ace::sequence object
		width      => 200,
		height     => 50,
		linecolor  => 'black',
		fillcolor  => 'darkcyan',
		clonecolor => 'darkred',
		boxheight  => 20,
		label      => undef,
	       },$package;
}

sub sequence {
  my $self = shift;
  my $v = $self->{sequence};
  $self->{sequence} = shift if @_;
  return $v;
}

sub height {
  my $self = shift;
  my $v = $self->{height};
  $self->{height} = shift if @_;
  return $v;
}

sub width {
  my $self = shift;
  my $v = $self->{width};
  if (@_) {
    $self->{width} = shift;
    delete $self->{scale};
  }
  return $v;
}

sub label {
  my $self = shift;
  my $v = $self->{label};
  $self->{label} = shift if @_;
  return $v;
}

sub dimensions {
  my $self = shift;
  my ($w,$h) = @{$self}{qw(width height)};
  $self->width(shift)  if defined $_[0];
  $self->height(shift) if defined $_[0];
  return ($w,$h);
}

sub linecolor {
  my $self = shift;
  my $v = $self->{linecolor};
  $self->{linecolor} = shift if @_;
  $v;
}

sub fillcolor {
  my $self = shift;
  my $v = $self->{fillcolor};
  $self->{fillcolor} = shift if @_;
  $v;
}

sub clonecolor {
  my $self = shift;
  my $v = $self->{clonecolor};
  $self->{clonecolor} = shift if @_;
  $v;
}


sub boxheight {
  my $self = shift;
  my $v = $self->{boxheight};
  $self->{boxheight} = shift if @_;
  return $v;
}

sub image {
  my $self = shift;
  $self->{panel} ||= $self->create_panel;
  return unless $self->{panel};
  my $gd = $self->{panel}->gd;
  my $label = join (' ',
		    $self->sequence->source,
		    $self->sequence->start.
		    '-'.
		    $self->sequence->end,
		    $self->sequence->strand < 0 ? '(- strand)' : '(+ strand)'
		   );
  my $x = ($self->width - length($label) * gdMediumBoldFont->width)/2;
  $gd->string(gdMediumBoldFont,$x,0,$label,1);
  $gd;
}

# a little bit of postprocessing
sub boxes {
  my $self = shift;
  $self->{panel} ||= $self->create_panel;
  return unless $self->{panel};
  my $boxes = $self->{panel}->boxes;
  my @boxes;
  foreach (@$boxes) {
    my ($feature,@rect) = @$_;
    my $f = $feature->info;
    push @boxes,{
		 object  => $f,
		 feature => $feature,
		 box     => \@rect};
  }
  return \@boxes;
}

sub layout {
  my $self = shift;
  $self->{panel} ||= $self->create_panel;
  return ($self->{panel}->width,$self->{panel}->height);
}

sub create_panel {
  my $self = shift;
  my $segment = $self->sequence;
  my @list = ('structural:GenePair','Transcript','Clone','experimental:RNAi');
  push @list,'similarity:^(BLASTN_)?EST_(genome|elegans)' if $segment->length <= 40_000;

  my @features    = $segment->features(@list);

  my (@forward,@reverse,@clones,@primers,@RNAi,@cDNA);
  foreach (@features) {
    if ($_->type eq 'Transcript') {
      push @forward,$_ if $_->strand >= 0;
      push @reverse,$_ if $_->strand < 0;
    }
    push @clones,$_  if $_->subtype eq 'Clone';
    push @primers,$_ if $_->subtype eq 'GenePair STS';
    push @RNAi,$_    if $_->subtype eq 'RNAi';
    push @cDNA,$_    if $_->type eq 'GappedAlignment';
  }

  # sort the cDNAs into 5' and 3' groups
  my %cDNA_pairs;
  for my $a (@cDNA) {
    (my $base = $a) =~ s/\.[35]$//;
    push @{$cDNA_pairs{$base}},$a;
  }

  my $panel = Ace::Graphics::Panel->new(-segment => $segment,
					-width   => $self->width,
					-pad_top => gdMediumBoldFont->height,
				       ) || return undef;
  my $labelf = @forward <= 10;
  my $labelr = @reverse <= 10;
  my $labelp = @primers <= 10;

  $panel->add_track(\@forward=>'transcript',
		    -fillcolor =>  $self->fillcolor,
		    -fgcolor   =>  $self->linecolor,
		    -bump      =>  -1,
		    -height    => $self->boxheight,
		    -label     => $labelf);
  # the cDNAs are a bit tricky
  my $track = $panel->add_track('segments',
				-fillcolor => 'paleturquoise',
				-fgcolor   => $self->linecolor,
				-height    => 4,
				-label     => 0,  # no labels right now
				-connectgroups   => 1,
				-bump      => -1);
  $track->add_group($_) foreach values %cDNA_pairs;


  $panel->add_track(\@primers => 'primers',
		    -fillcolor => $self->fillcolor,
		    -fgcolor   => $self->linecolor,
		    -label     => $labelp,
		    -connect   => 1,
		    -connect_color => 'wheat',
		    -bump      => -1);
  $panel->add_track($segment   => 'arrow',
		    -bump      => 0,
		    -tick      => 2);
  $panel->add_track(\@RNAi,
		    -fillcolor => 'wheat',
		    -fgcolor   => $self->linecolor,
		    -height    => 4,
		    -label     => 1,
		    -bump      => +1);
  $panel->add_track(\@reverse  => 'transcript',
		    -fillcolor => $self->fillcolor,
		    -fgcolor   => $self->linecolor,
		    -height    => $self->boxheight,
		    -label     => $labelr,
		    -bump      => +1);

  $panel->add_track(\@clones   => 'anchored_arrow',
		    -bump      => '+1',
		    -label     => 1,
		    -fgcolor   => $self->clonecolor);
  $panel;
}

1;
