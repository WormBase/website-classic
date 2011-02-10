package Flickr::API::Simple::Group;

use strict;
use base qw/Flickr::API::Simple/;


=head1 $api->get_group_photos(\%params)

Get a list of photos belonging to a group.

Params
 page       page to begin with. Defaults to 1.
 per_page   Items per page. Max: 500. Default: 100.
 tag        Optional tag on which to filter.

Returns
 Array reference of F::A::S::Photo objects

   Authentication : not required
Flickr API method : flickr.groups.pools.getPhotos

=cut  

sub search_group_photos {
  my ($self,$params) = @_;
  my $gid      = $params->{group_id};
  my $tag      = $params->{tag};
  my $page     = $params->{page}     || 1;
  my $per_page = $params->{per_page} || 100;
  
  my $api = $self->api;
  my $response;
  if ($tag) {
    $response = $api->execute_method('flickr.groups.pools.getPhotos',
				     { group_id => $gid,
				       per_page => $per_page,
				       page     => $page,
				       tag      => $tag,
				     });
  } else {
    $response = $api->execute_method('flickr.groups.pools.getPhotos',
				     { group_id => $gid,
				       per_page => $per_page,
				       page     => $page,
				       tag      => $tag,
				     });
  }

  my $photos = $self->parse_tree(@{$response->{tree}->{children}->[1]->{children}});
  
  # Turn these into the appropriate Flickr::API::Simple objects
  my @objects = $self->factory("Flickr::API::Simple::Photo",$photos);
  return \@objects;
}

1;

