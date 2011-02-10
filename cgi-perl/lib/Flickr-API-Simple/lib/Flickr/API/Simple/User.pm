package Flickr::API::Simple::User;

use strict;
use base qw/Flickr::API::Simple/;
use Data::Dumper;

=head1 Flickr photo data struct in Perl

'name' => 'photo',
'children' => [],
'type' => 'tag',
'attributes' => {
		   'owner' => '26871026@N02',
		   'isfriend' => '0',
		   'ispublic' => '1',
		   'title' => 'ZK177.3: Reporter_gene',
		   'server' => '3057',
		   'secret' => '2a9d044ae7',
		   'id' => '2736654313',
		   'farm' => '4',
		   'isfamily' => '0'
		  }

=cut

# Semi-done. What if I've retrieved the user in some other way
# than via a photo?
sub realname { 
  my $self = shift;
  return $self->{attributes}->{realname} if $self->{attributes}->{realname};
  my $element = $self->_get_element('realname');
  my $realname = eval { $element->{children}->[0]->{content} }; 
  return $realname || undef;
}

sub location { 
  my $self = shift;
  return $self->{attributes}->{location} if $self->{attributes}->{location};
  my $element = $self->_get_element('location');
  my $location = $element->{children}->[0]->{content}; 
  return $location || undef;
}

sub username { 
  my $self = shift;
  return $self->{attributes}->{username} if $self->{attributes}->{username};
  my $element = $self->_get_element('username');
  my $username = $element->{children}->[0]->{content}; 
  return $username || undef;
}


sub photosurl { 
  my $self = shift;
  return $self->{attributes}->{photosurl} if $self->{attributes}->{photosurl};
  my $element = $self->_get_element('photosurl');
  my $photosurl = $element->{children}->[0]->{content}; 
  return $photosurl || undef;
}

sub profileurl { 
  my $self = shift;
  return $self->{attributes}->{profileurl} if $self->{attributes}->{profileurl};
  my $element = $self->_get_element('profileurl');
  my $profileurl = $element->{children}->[0]->{content}; 
  return $profileurl || undef;
}

sub mobileurl { 
  my $self = shift;
  return $self->{attributes}->{mobileurl} if $self->{attributes}->{mobileurl};
  my $element = $self->_get_element('mobileurl');
  my $mobileurl = $element->{children}->[0]->{content}; 
  return $mobileurl || undef;
}

sub first_photo_date { 
  my $self = shift;
  my $element = $self->_get_element('photos');
  my $date = $element->{children}->[1]->{children}->[0]->{content}; 
  return $date || undef;
}

sub photo_count {
  my $self = shift;
  my $element = $self->_get_element('photos');
  my $count = $element->{children}->[1]->{children}->[0]->{content}; 
  return $count || undef;
}


sub nsid     {
  my $self = shift;
  my $id = $self->{attributes}->{nsid} || $self->{nsid};
}

sub id { 
  return shift->nsid;
}

=head2 $user->photos(\%params);

Get a user's photos.

Params
 page        Optional.  The page to begin the retrieve 
                from. Defaults to one if not specified.
 per_page    Optional. Number of photos to retrieve per page.
                Defaults to 100.

Returns
   Array reference of Flickr::API::Simple::Photo objects.
   undef if the request failed (see "Debugging" for information)

Note that your script should establish an iterator if
you want to retrieve more than the 500 most recent
photos from a user.

for (my $i=1;$i<=5;$i++) {
   @photos = $user->photos(page     => $i);

   ... do things
}

=cut

sub photos {
  my ($self,$params) = @_;
  $params->{userid} = $self->nsid;
  my $objects = $self->get_user_photos($params);
  return $objects;
}


=head2 $user->get_untagged_photos;

Get all untagged photos for a user.

Params
 None

Returns
 An array reference of F::A::S::Photo objects of photos
 lacking tags.

=cut

sub get_untagged_photos {
  my $self = shift;


=head1 

min_upload_date (Optional)
    Minimum upload date. Photos with an upload date greater than or equal to this value will be returned. The date should be in the form of a unix timestamp.
max_upload_date (Optional)
    Maximum upload date. Photos with an upload date less than or equal to this value will be returned. The date should be in the form of a unix timestamp.
min_taken_date (Optional)
    Minimum taken date. Photos with an taken date greater than or equal to this value will be returned. The date should be in the form of a mysql datetime.
max_taken_date (Optional)
    Maximum taken date. Photos with an taken date less than or equal to this value will be returned. The date should be in the form of a mysql datetime.
privacy_filter (Optional)
    Return photos only matching a certain privacy level. Valid values are:

        * 1 public photos
        * 2 private photos visible to friends
        * 3 private photos visible to family
        * 4 private photos visible to friends & family
        * 5 completely private photos

media (Optional)
    Filter results by media type. Possible values are all (default), photos or videos
extras (Optional)
    A comma-delimited list of extra information to fetch for each returned record. Currently supported fields are: license, date_upload, date_taken, owner_name, icon_server, original_format, last_update, geo, tags, machine_tags, o_dims, views, media.
per_page (Optional)
    Number of photos to return per page. If this argument is omitted, it defaults to 100. The maximum allowed value is 500.
page (Optional)
    The page of results to return. If this argument is omitted, it defaults to 1.


=cut

}

## Accesssors / Private methods

=head2 $photo->get_info()

You will not typically need access to this method.
It's called internally when required. Instead, use
the accessor methods described below.

Params
 None.

Returns
 True on success (and a populated object for use with accessors)

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub get_info {
  my $self = shift;
  my $api      = $self->api;
  my $response = $api->execute_method('flickr.people.getInfo',
				      {
				       user_id => $self->nsid || $self->{nsid},
				      });
  
  my $info = $self->parse_tree(@{$response->{tree}->{children}->[1]->{children}});
  $self->{user_info} = $info;
#  print Dumper($info);
  return $info;
}

sub user_info { return shift->{user_info}; }


1;

