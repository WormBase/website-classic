package WormBase;

=pod

=head1 WormBase.pm

=head1 Synposis

=head1 Description

=cut

use strict;
use lib '.';
use WormBase::Formatting;
use WormBase::FetchData;
use WormBase::Util::Rearrange;

use vars qw/$VERSION @ISA/;
@ISA = qw/WormBase::Formatting WormBase::FetchData/;

sub new {
  my ($class,$db) = @_;
  my $this = bless {},$class;
  $this->{db} = $db if ($db);
  return $this;
}


1;
