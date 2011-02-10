package CSS::Adaptor::AceGraphics;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = 'CSS::Adaptor';

sub convert {
  my $self = shift;
  my $tag  = shift;

  #we need to strip off any leading - characters to be safe.
  #how conversion is handled isn't stable yet...
  $tag =~ s/^\-*(.+)$/$1/;


  my %mapped = ('color'            => '-fgcolor',
                'background-color' => '-fillcolor',
               );

  return "-$tag" unless $mapped{$tag};
  return $mapped{$tag};
}

1;
