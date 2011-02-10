package Flickr::API::Simple::Tag;


# This package is currently a giant hack.
# Methods dip directly into the object structure
# and expect that the tag objects have been created 
# from a photo object.

use strict;
use base qw/Flickr::API::Simple/;

=head2 $tag->name;

Fetch the name of the tag.

Params
 None

Returns
 The tag name or undef.

=cut

sub name { return shift->{children}->[0]->{content}; }

=head2 $tag->machine_tag;

Check if the tag is a machine tag.

Params
 None

Returns
 True or undef.

=cut 

sub machine_tag { return shift->{attributes}->{machine_tag}; }

=head2 $tag->author;

Fetch the author of the tag.

Params
 None

Returns
 a F::A::S::User object.

=cut

sub author {
  my $self   = shift;
  my $author = $self->{attributes}->{author};
  my $object = $self->factory("Flickr::API::Simple::User",[{ nsid => $author }]);
  return $object;
}

=head2 $photo->id;

Get the ID of the tag.

Params
 None

Returns
 The ID of the tag or undef.

=cut

sub id {
  my $self = shift;
  return $self->{attributes}->{id};
}

=head2 $tag->raw;

Return the raw value of the tag.

Params
 None

Returns
 The raw tag or undef.

=cut

sub raw {
  my $self = shift;
  return $self->{attributes}->{raw};
}



=head2 $tag->get_related;

Return a list of related tags identified through clustered usage analysis.

Params
 None

Returns
 An array reference of F::A::S::Tag objects.

=cut

sub get_related {
    my $self = shift;
    my $raw = $self->raw;
    my $api = $self->api;
  
    my $response = $api->execute_method('flickr.tags.getRelated',
					{ tag => $raw,
					  });

    print Dumper($response);
#  my $users = $self->parse_tree(@{$response->{tree}->{children}->[1]->{children}});
  
#  # Turn these into the appropriate Flickr::API::Simple objects
#  my @objects = $self->factory("Flickr::API::Simple::User",$users);
#  return \@objects;
}

1;

