package Flickr::API::Simple::Photo;

use strict;
use Data::Dumper;
use base qw/Flickr::API::Simple/;


=head1 Flickr::API::Simple::Photo

Methods for working with individual photos.

=cut

=head1 PHOTO INFORMATION

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
  my $response = $api->execute_method('flickr.photos.getInfo',
				      { photo_id => $self->id,
				      });
  
  my $info = $self->parse_tree(@{$response->{tree}->{children}->[1]->{children}});
  $self->{photo_info} = $info;
#  print Dumper($info);
  return $info;
}

=head2 $photo->id;

Fetch the Flickr ID of the photo.

Params
 None

Return
 The Flickr ID of the photo or undef.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub id       {
  my $self = shift;
  return $self->{attributes}->{id};
}

########################################
#
#  Parsing results from get_info
#
########################################

## OWNER ELEMENT

=head2 $photo->owner;

Fetch the owner of a photo.

Params
 None

Returns
 A F::A::S::User object.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub owner {
  my $self = shift;
  my $element     = $self->_get_element('owner');
  my $object      = $self->factory("Flickr::API::Simple::User",[$element]);
  return $object;
}

## TITLE ELEMENT

=head2 $photo->title;

Return the title of a photo

Params
 None

Returns
 The title as a scalar or undef

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub title    {
  my $self = shift;
  return $self->{attributes}->{title} if $self->{attributes}->{title};
  my $element = $self->_get_element('title');
  my $title = $element->{children}->[0]->{content};
  return $title || undef;
}

## DESCRIPTION ELEMENT

=head2 $photo->description;

Fetch the description for a photo.

Params
 None

Returns
 The description as a scalar or undef.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub description {
  my $self = shift;
  return $self->{attributes}->{description} if $self->{attributes}->{description};
  my $element = $self->_get_element('description');
  my $description = $element->{children}->[0]->{content};
  return $description || undef;
}

## VISIBILITY ELEMENT

=head2 $photo->isfriend;

Check if the photo is restricted to friends.

Params
 None

Returns
 True if the photo is restricted to friends.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub isfriend {
  my $self = shift;
  return $self->{attributes}->{isfriend} if $self->{attributes}->{isfriend};
  my $element = $self->_get_element('visibility');
  my $data = $element->{attributes}->{isfriend};
  return $data || undef;
}

=head2 $photo->isfamily;

Check if the photo is restricted to family.

Params
 None

Returns
 True if the photo is restricted to family.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub isfamily {
  my $self = shift;
  return $self->{attributes}->{isfamily} if $self->{attributes}->{isfamily};
  my $element = $self->_get_element('visibility');
  my $data = $element->{attributes}->{isfamily};
  return $data || undef;
}

=head2 $photo->ispublic;

Check if the photo is available to the public.

Params
 None

Returns
 True if the photo is public.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub ispublic {
  my $self = shift;
  return $self->{attributes}->{ispublic} if $self->{attributes}->{ispublic};
  my $element = $self->_get_element('visibility');
  my $data = $element->{attributes}->{ispublic};
  return $data || undef;
}

## DATES ELEMENT

=head2 $photo->lastupdate;

Return the Unix timestamp of the last update.

Params
 None

Returns
 The unix timestamp of the last update or undef.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub lastupdate {
  my $self = shift;
  my $element = $self->_get_element('dates');
  my $data = $element->{attributes}->{lastupdate};
  return $data || undef;
}

=head2 $photo->date_posted;

Return the Unix timestamp of the photo's post date.

Params
 None

Returns
 The unix timestamp of the post date or undef.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub date_posted {
  my $self = shift;
  my $element = $self->_get_element('dates');
  my $data = $element->{attributes}->{posted};
  return $data || undef;
}

=head2 $photo->date_taken;

Return a date string of when the photo was taken.

Params
 None

Returns
 A date string or undef.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub date_taken {
  my $self = shift;
  my $element = $self->_get_element('dates');
  my $data = $element->{attributes}->{taken};
  return $data || undef;
}

## EDITABILITY ELEMENT

=head2 $photo->can_comment;

Check if the photo is open for comment.

Params
 None

Returns
 True or undef.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub can_comment {
  my $self = shift;
  my $element = $self->_get_element('editability');
  my $data = $element->{attributes}->{cancomment};
  return $data || undef;
}

=head2 $photo->can_add_meta;

Check if the photo accepts additonal meta data.

Params
 None

Returns
 True or undef.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub can_add_meta {
  my $self = shift;
  my $element = $self->_get_element('editability');
  my $data = $element->{attributes}->{canaddmeta};
  return $data || undef;
}

## USAGE ELEMENT

=head2 $photo->can_download;

Check if the photo can be downloaded.

Params
 None

Returns
 True or undef.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub can_download {
  my $self = shift;
  my $element = $self->_get_element('usage');
  my $data = $element->{attributes}->{candownload};
  return $data || undef;
}

=head2 $photo->can_print;

Check if the photo can be downloaded.

Params
 None

Returns
 True or undef.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub can_print {
  my $self = shift;
  my $element = $self->_get_element('usage');
  my $data = $element->{attributes}->{canprint};
  return $data || undef;
}

=head2 $photo->can_blog;

Check if the photo can be downloaded.

Params
 None

Returns
 True or undef.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub can_blog {
  my $self = shift;
  my $element = $self->_get_element('usage');
  my $data = $element->{attributes}->{canblog};
  return $data || undef;
}

## NOTES ELEMENT

=head2 no support yet for notes

=cut

## TAGS ELEMENT
  
=head2 $photo->tags;

Get all tags for a photo.

Params
 None

Returns
 An array reference of F::A::S::Tag objects.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub tags {
  my $self = shift;
  my $element = $self->_get_element('tags');
  my $split   = $self->parse_tree(@{$element->{children}});
  my @objects = $self->factory("Flickr::API::Simple::Tag",$split);
  return \@objects;
}

## URLS ELEMENT

=head2 $photo->photopage_url;

Fetch the photo page URL.

Params
 None

Returns
 A URL for the photo page or undef.

   Authentication : not required
Flickr API method : flickr.photos.getInfo

=cut

sub photopage_url {
  my $self = shift;
  my $element = $self->_get_element('urls');
  my $url     = $element->{children}->[1]->{children}->[0]->{content};
  return $url or undef;
}



## NOT DONE - HOW DO I FETCH VIEWS IN THE API?
sub views {
  my $self = shift;
  my $element = $self->_get_element('views');
  my $views     = $element->{children}->[1]->{children}->[0]->{content};
  return $views or undef;
}









=head1 MANIPULATING PHOTO TAGS

=head2 $photo->add_tags(\%params)

Add tags to a photo.

Params
 tags      array reference of tags to add

Returns
 True if success; undef if failure.

   Authentication : required
Flickr API method : flickr.photos.addTags

=cut  

sub add_tags {
  my ($self,$tags) = @_;

  my $id = $self->id;  
  my $api = $self->api;
  my $auth_token = $self->auth_token;
  
  my $response = $api->execute_method('flickr.photos.addTags',
				      { tags       => join(" ",@$tags),
					auth_token => $auth_token,
					photo_id   => $id,
				      });
  return 1 if $response;
  return; 
}

=head2 $photo->set_tags(\%params);

Set tags for a photo (note: replaces existing tags).

Params
 tags      array reference of tags to add

Returns
 True if success; undef if failure.

   Authentication : required
Flickr API method : flickr.photos.setTags

=cut  

sub set_tags {
  my ($self,$tags) = @_;

  my $id = $self->id;  
  my $api = $self->api;
  my $auth_token = $self->auth_token;
  
  my $response = $api->execute_method('flickr.photos.setTags',
				      { tags       => join(" ",@$tags),
					auth_token => $auth_token,
					photo_id   => $id,
				      });
  return 1 if $response;
  return; 
}

=head2 $photo->set_safety_level(\%params);

Set the safety level of a photo.

Params
 safety_level One of 
           1 for Safe, 2 for Moderate, and 3 for Restricted.

Returns
 True if success; undef if failure.

   Authentication : required
Flickr API method : flickr.photos.setSafetyLevel

=cut

sub setSafetyLevel {
  my ($self,$params) = @_;

  my $safety_level = $params->{safety_level};
  return "Please provide a safety level of 1, 2, or 3\n" unless $safety_level =~ /[1|2|3]/;
  
  my $id = $self->id;  
  my $api = $self->api;
  my $auth_token = $self->auth_token;
  
  my $response = $api->execute_method('flickr.photos.setSafetyLevel',
				      { safety_level => $safety_level,
					auth_token => $auth_token,
					photo_id   => $id,
				      });
  return 1 if $response;
  return; 
}

=head2 $photo->set_search_visibility(\%params);

Set the public search visibility of a photo.

Params
 visibility   One of 
              0 for hidden from public searches
              1 visibile in public searches

Returns
 True if success; undef if failure.

   Authentication : required
Flickr API method : flickr.photos.setSafetyLevel

=cut

sub set_search_visibility {
  my ($self,$params) = @_;

  my $visibility = $params->{visibility};
  return "Please provide a visibility level of 0 or 1\n" unless $visibility =~ /[0|1]/;
  
  my $id = $self->id;  
  my $api = $self->api;
  my $auth_token = $self->auth_token;
  
  my $response = $api->execute_method('flickr.photos.setSafetyLevel',
				      { hidden     => $visibility,
					auth_token => $auth_token,
					photo_id   => $id,
				      });
  return 1 if $response;
  return; 
}

=head2 $photo->set_meta_data(\%params);

Set title and description data.

Params
 title       a title for the photo (required)
 description a description for the photo (required)

Returns
 True if success; undef if failure.

   Authentication : required
Flickr API method : flickr.photos.setMeta

=cut

sub set_meta_data {
  my ($self,$params) = @_;

  my $title = $params->{title};
  my $desc  = $params->{desc};
  return "Please provide a title and description" unless $title && $desc;
  
  my $id = $self->id;  
  my $api = $self->api;
  my $auth_token = $self->auth_token;
  
  my $response = $api->execute_method('flickr.photos.setMeta',
				      { auth_token => $auth_token,
					photo_id   => $id,
					title      => $title,
					descripiton => $desc,
				      });
  return 1 if $response;
  return; 
}

=head2 $photo->set_dates(\%params);

NOTE: The set_dates method is not supported in v 0.01 of Flickr::API::Simple. Sorry.

Set dates associated with the photo.

Params
date_posted (Optional)
    The date the photo was uploaded to flickr (see the dates documentation)
date_taken (Optional)
    The date the photo was taken (see the dates documentation)
date_taken_granularity (Optional)
    The granularity of the date the photo was taken (see the dates documentation)

Returns
 True if success; undef if failure.

   Authentication : required
Flickr API method : flickr.photos.setDates

=cut

sub set_dates {
  my ($self,$params) = @_;

  return "The set_dates method is not supported in v 0.01 of Flickr::API::Simple. Sorry.";
  
  my $id = $self->id;  
  my $api = $self->api;
  my $auth_token = $self->auth_token;
  
  my $response = $api->execute_method('flickr.photos.setDates',
				      { auth_token => $auth_token,
					photo_id   => $id,
				      });
  return 1 if $response;
  return; 
}

=head2 $photo->set_permissions(%params);

Set permissions on a photo.

Params
 photo_id (Required)
    The id of the photo to set permissions for.
 is_public (Required)
    1 to set the photo to public, 0 to set it to private.
 is_friend (Required)
    1 to make the photo visible to friends when private, 0 to not.
 is_family (Required)
    1 to make the photo visible to family when private, 0 to not.
 perm_comment (Required)
    who can add comments to the photo and it's notes. one of:
    0: nobody
    1: friends & family
    2: contacts
    3: everybody
 perm_addmeta (Required)
    who can add notes and tags to the photo. one of:
    0: nobody / just the owner
    1: friends & family
    2: contacts
    3: everybody 

Returns
 True if success; undef if failure.

   Authentication : required
Flickr API method : flickr.photos.setPerms

=cut

sub set_permissions {
  my ($self,$params) = @_;

  my $ispublic     = $params->{isfriend}     or return "Please supply a value for ispublic\n";
  my $isfriend     = $params->{isfriend}     or return "Please supply a value for isfriend\n";
  my $isfamily     = $params->{isfamily}     or return "Please supply a value for isfamily\n";
  my $perm_comment = $params->{perm_comment} or return "Please supply a value for perm_comment\n";
  my $perm_addmeta = $params->{perm_addmeta} or return "Please supply a value for perm_addmeta\n";
  
  my $id = $self->id;  
  my $api = $self->api;
  my $auth_token = $self->auth_token;
  
  my $response = $api->execute_method('flickr.photos.setMeta',
				      { auth_token => $auth_token,
					photo_id   => $id,
					ispublic   => $ispublic,
					isfamily   => $isfamily,
					isfriend   => $isfriend,
					perm_comment => $perm_comment,
					perm_addmeta => $perm_addmeta,
				      });
  return 1 if $response;
  return; 
}

=head2 $photo->set_content_type(\%params);

Set the content type of a photo.

Params
 content_type (Required)
    The content type of the photo. Must be one of: 1 for Photo,
    2 for Screenshot, and 3 for Other.

Returns
 True if success; undef if failure.

   Authentication : required
Flickr API method : flickr.photos.setContentType

=cut

sub set_content_type {
  my ($self,$params) = @_;
  
  my $content_type = $params->{content_type};
  return "Please provide a content type of 1, 2, or 3\n" unless $content_type =~ /[1|2|3]/;  

  my $id = $self->id;  
  my $api = $self->api;
  my $auth_token = $self->auth_token;
  
  my $response = $api->execute_method('flickr.photos.setContentType',
				      { auth_token   => $auth_token,
					photo_id     => $id,
					content_type => $content_type,
				      });
  return 1 if $response;
  return; 
}



=head2 $photo->delete;

Delete the given photo from Flickr.

Params
 None.

Returns
 True if success; undef if failure.

   Authentication : required
Flickr API method: flickr.photos.delete

=cut  

sub delete_photo {
  my $self = shift;
  
  my $id  = $self->id;  
  my $api = $self->api;
  my $auth_token = $self->auth_token;
  
  my $response = $api->execute_method('flickr.photos.delete',
				      { auth_token => $auth_token,
					photo_id   => $id,
				      });
  return 1 if $response;
  return;
}

=head2 $photo->remove_tag(\%params);

Delete the given photo from Flickr.

Params
 tag_id  One of tag_id or a F::A::S::Tag object
 tag

Returns
 True if success; undef if failure.

   Authentication : required
Flickr API method: flickr.photos.removeTag

=cut  

sub remove_tag {
  my ($self,$params) = @_;

  my $id  = $self->id;  
  my $api = $self->api;

  return unless $params->{tag} || $params->{tag_id};
  my $tag_id = $params->{tag_id} || $params->{tag}->id;  
  my $auth_token = $self->auth_token;
  
  my $response = $api->execute_method('flickr.photos.removeTag',
				      { auth_token => $auth_token,
					tag_id     => $tag_id,
					photo_id   => $id,
				      });
  return 1 if $response;
  return;
}

=head1 $photo->get_all_contexts;

Get all visible sets and pools a photo belongs to.

Params
 None.

Returns
 Array reference of F::A::S::User objects

   Authentication : not required
Flickr API method : flickr.photos.getAllContexts

=cut  

sub get_all_contexts {
  my ($self,$tags) = @_;

  my $id  = $self->id;  
  my $api = $self->api;
  my $auth_token = $self->auth_token;
  
  my $response = $api->execute_method('flickr.photos.getAllContexts',				      
				      {				
				       photo_id => $id,
				      });

  my $contexts = $self->parse_tree(@{$response->{tree}->{children}->[1]->{children}});
    
  # Turn these into the appropriate Flickr::API::Simple objects
  # TODO: Pools and Sets should probably be broken out.
  my @objects = $self->factory("Flickr::API::Simple::Context",$contexts);
  return \@objects;
}

=head1 $photo->favorited_by(\%params)

Get a list of Flickr users who have favorited a photo.

Params
 page       page to begin with. Defaults to 1.
 per_page   Items per page. Max: 500. Default: 100.

Returns
 Array reference of F::A::S::User objects

   Authentication : required
Flickr API method : flickr.photos.getFavorites

=cut  

sub favorited_by {
  my ($self,$params) = @_;
  my $page     = $params->{page}     || 1;
  my $per_page = $params->{per_page} || 100;
  
  my $api = $self->api;
  my $response = $api->execute_method('flickr.photos.getFavorites',
				      { photo_id => $self->id,
					per_page => $per_page,
					page     => $page
				      });
  
  my $users = $self->parse_tree(@{$response->{tree}->{children}->[1]->{children}});
  
  # Turn these into the appropriate Flickr::API::Simple objects
  my @objects = $self->factory("Flickr::API::Simple::User",$users);
  return \@objects;
}

=head2 $photo->sizes;

Get available sizes of a photo.

Params
 None

Returns
 A hash reference of hashes keyed by photo type:

          'Thumbnail' => {
                         'width' => '100',
                         'source' => 'http://farm4.static.flickr.com/3057/2736654313_2a9d044ae7_t.jpg',
                         'media' => 'photo',
                         'url' => 'http://www.flickr.com/photos/wormbase/2736654313/sizes/t/',
                         'label' => 'Thumbnail',
                         'height' => '38'
                       },

 Possible types are: Thumbnail, Small, Medium, Square, Original

=cut

sub sizes {
  my $self = shift;
  my $api      = $self->api;
  my $response = $api->execute_method('flickr.photos.getSizes',
				      { photo_id => $self->id,
				      });
  my $info = $self->parse_tree(@{$response->{tree}->{children}->[1]->{children}});

  my $sizes;
  foreach (@$info) {
    $sizes->{$_->{attributes}->{label}} = {
					   label  => $_->{attributes}->{label},
					   source => $_->{attributes}->{source},
					   width  => $_->{attributes}->{width},
					   media  => $_->{attributes}->{media},
					   url    => $_->{attributes}->{url},
					   height => $_->{attributes}->{height}
					  };
    
  }
#  print Dumper($sizes);
  return $sizes;
}







=head2 $photo->comments();

Get a list of comments on the photo.

Params
 None

Returns
 Array of arrays of comments for the photo.

 
=cut

sub comments {
  my $self = shift;
  my $api      = $self->api;
  my $response = $api->execute_method('flickr.photos.comments.getList',
				      { photo_id => $self->id,
				      });
  
  my $info = $self->parse_tree(@{$response->{tree}->{children}->[1]->{children}});
  #  print Dumper($info);
  
  # Instantiate comment objects
  my @objects = $self->factory("Flickr::API::Simple::Comment",$info);
  return \@objects;
}



# PRIVATE / ACCESSORS

sub photo_info { return shift->{photo_info}; }

sub _get_element {
  my ($self,$tag) = @_;
  my $info = $self->photo_info || $self->get_info;
  foreach (@$info) {
    return $_ if $_->{name} eq $tag;
  }
}


1;




