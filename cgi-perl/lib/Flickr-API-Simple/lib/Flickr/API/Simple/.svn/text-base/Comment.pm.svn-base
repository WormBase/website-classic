package Flickr::API::Simple::Comment;

use strict;
use base qw/Flickr::API::Simple/;

sub content { return shift->{children}->[0]->{content}; } 
sub author  { 
  my $self = shift;
  my $author = $self->{attributes}->{authorname};
  my $id     = $self->{attributes}->{author};
  my $object = $self->factory("Flickr::API::Simple::User",[{nsid => $id }]);
  return $object;
}

sub id        { return shift->{attributes}->{id};         }
sub created   { return shift->{attributes}->{datecreate}; }
sub permalink { return shift->{attributes}->{permalink};  }

1;

