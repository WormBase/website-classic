package Flickr::API::Simple;

use warnings;
use strict;
use Log::Log4perl;
use FindBin qw/$Bin/;
use Data::Dumper;
use base "Flickr::API";
use Flickr::API::Simple::Tag;
use Flickr::API::Simple::Photo;
use Flickr::API::Simple::User;
use Flickr::API::Simple::Comment;

=head1 NAME

Flickr::API::Simple - The great new Flickr::API::Simple!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Flickr::API::Simple;

    my $foo = Flickr::API::Simple->new();
    ...

=head1 FUNCTIONS

=head2 $flickr = Flickr::API::Simple->new(\%params);

Params
  config      Full path to flickr configuration file.
                 If not provided defaults to $Bin/flickr.conf
                 or $ENV{HOME}/.flickr.conf.
  api_key     Your Flickr API key (or specified in the config file)
  app_secret  Your Flickr application secret (or specified in the
              config file)
  ua          User agent. Defaults to Flickr::API::Simple. Note that
              authentication tokens are generated
  verbosity   Set Log::Log4perl logging level to screen:
              [FATAL ERROR WARN INFO DEBUG TRACE]
              Default: ERROR

=cut

sub new {
  my ($class,$params) = @_;
  my $self = bless {},$class;  
  
#  Log::Log4perl->init("$Bin/log4perl.conf");
  
  my $config = $params->{config} || "$Bin/../flickr.conf" || "$ENV{HOME}/.flickr.conf";
  
  $self->{debug_mode}++ if $self->{debug};

  if (-e $config) {
    open CONFIG,$config or warn "Couldn't open the configuration file at $config; using passed values";
    while (<CONFIG>) {
      next if /^[#|\s]/;
      chomp;
      my ($key,$val) = split ("=");
            
      # The api_key and app_secret can be handed to the
      # new constructor or placed in the configuration
      # file.
      $self->{lc($key)} = $val;
    }
  }
  
  # Override configuration file values
  # with those provided to the constuctor
  foreach (keys %$params) {
    $self->{lc($_)} = $params->{$_};
  }

  # 1. Instantiate Flickr::API and stash it
  my $api = Flickr::API->new({key    => $self->api_key,
			      secret => $self->app_secret,
			     }) or die "Couldn't instantiate a Flickr::API object: $!";
  $self->{api} = $api;

  my $ua = $params->{ua} ? $params->{ua} . "/$VERSION" : "Flickr::API::Simple/$VERSION";
  
  # 2. Set the UA - keep it the same as the uploader so I don't need a new token
  $self->api->agent($ua);
  
  return $self;
}

sub test_flickr_connection {
  my ($self,$username) = @_;
  my $api = new Flickr::API({'key' => $self->api_key });
  my $response = $api->execute_method ('flickr.people.findByUsername',
				       {
					username => $username,
				       });
  
  $self->debug("Flickr connection test ");
  if ($response->{success}) {
    $self->debug("success: $response->{success}");
    return 1;
  } else {
    $self->debug("failed. Error code: $response->{error_code}");
    return 0;
  }
}



# NOTE: The guts of this authentication strategy 
# borrow *heavily* from Flickr::Upload...

# authenticate() is called internally for methods that
# require that an authentication token be passed.
sub authenticate {
  my $self = shift;
  
  # The user wants to authenticate. There's really no nice way to handle this.
  # So we have to spit out a URL, then hang around or something until
  # the user hits enter, then exchange the frob for a token, then tell the user what
  # the token is and hope they care enough to stick it into .flickrrc so they
  # only have to go through this crap once.
  
  # Perhaps we've already authenticated
  return $self->auth_token if $self->auth_token;
  
  # 1. get a frob
  my $frob = $self->get_frob();
  
  # 2. get a url for the frob
  my $url = $self->request_auth_url('write', $frob);
  
  # 3. tell the user what to do with it
  print "1. Enter the following URL into your browser\n\n",
    "$url\n\n",
      "2. Follow the instructions on the web page\n",
	"3. Hit <Enter> when finished.\n\n";
  
  # 4. wait for enter.
  <STDIN>;
  
  # 5. Get the token from the frob
  my $auth_token = $self->get_auth_token($frob);
  die "Failed to get authentication token!" unless defined $auth_token;
  
  # 6. Tell the user what they won.
  print "Your authentication token for this application is\n\t\t",
    $auth_token, "\n";
  
  exit 0;
}


sub get_frob {
  my $self = shift;
  my $api  = $self->api;
  
  my $res = $api->execute_method("flickr.auth.getFrob");
  return undef unless defined $res and $res->{success};
  
  my $frob = $res->{tree}->{children}->[1]->{children}->[0]->{content};
  $self->{frob} = $frob;
  return $frob;
}


sub get_auth_token {
  my $self = shift;
  my $api  = $self->api;
  my $frob = $self->frob;
  
  my $res = $api->execute_method("flickr.auth.getToken",
				 { frob => $frob } );
  
  return undef unless defined $res and $res->{success};
  $self->debug(Dumper($res));
  my $auth_token = $res->{tree}->{children}->[1]->{children}->[1]->{children}->[0]->{content};

  $self->{auth_token} = $auth_token;  
  die "Failed to get authentication token!" unless defined $auth_token;
  return $auth_token;
}

=head2 $api->find_user(\%params);

Find a Flickr user by username or email.

Params
 You must supply one of the following:
 user_id     Flickr ID of user
 username    The username you wish to fetch.
 email       An email address. May be primary or secondary.

Returns
  A F::A::S::User object or undef if the user
  is not found.

=cut

sub find_user {
  my ($self,$params) = @_;
  
  my $user_id  = $params->{user_id};
  my $username = $params->{username};
  my $email    = $params->{email};
  return "You must supply a username, user_id, email" unless ($username || $user_id || $email);
  
  my $api = $self->api;
  my $response;
  if ($username) {
    $response = $api->execute_method ('flickr.people.findByUsername',
				      {
				       'username' => $username,
				      });
    
  } elsif ($email) {
    $response = $api->execute_method ('flickr.people.findByEmail',
				      {
				       'email' => $email,
				      });   
  }
  # Get a user by userid
  my $uid;
  if ($response->{success}) {
    my $element = $response->{tree}->{children}->[1];
    #->{attributes}->{nsid};
    my $object      = $self->factory("Flickr::API::Simple::User",[$element]);
    return $object;
  } else {
    $self->debug("failed. Error code: $response->{error_code}");
    return undef;
  }
}



=head2 $api->get_user_photos(\%params)

Retrieve a user's photos in batch.

Params
 username    Required. At least one of the username or 
 userid         userid is required.
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
   $api->get_user_photos( username => 'twharris',
                          page     => $i);

   ... do things
}

=cut

sub get_user_photos {
  my ($self,$params) = @_;
  my $username = $params->{'username'};
  my $userid   = $params->{'userid'};

  die "get_user_photos: please provide a username or userid" unless ($username || $userid);

  
  # If supplied with a username but not a userid, fetch a
  # user object and get their ID.
  if ($username && !$userid) {
    my $user = $self->find_user({username => $username});
    $userid  = $user->id;
  }
  
  my $page     = $params->{page}     || 1;
  my $per_page = $params->{per_page} || 100;
  
  my $api = $self->api;
  my $response = $api->execute_method('flickr.people.getPublicPhotos',
				      { user_id  => $userid,
					per_page => $per_page,
					page => $page
				      });
  $self->debug("get_user_photos(): " . Dumper($response));
  
  return undef unless defined $response and $response->{success};
  
  my $photos = $self->parse_tree(@{$response->{tree}->{children}->[1]->{children}});
  
  # Turn these into the appropriate Flickr::API::Simple objects
  my @objects = $self->factory("Flickr::API::Simple::Photo",$photos);
  return \@objects;
}



=head2 $api->search_photos(\%params)

Searches a user's photos in batch.

Params
 username    Required. At least one of the username or 
 userid         userid is required.
 group_id    Search a group ID.
 tags        An array reference of tags to search.
 tag_mode    any (for OR boolean) or all (for AND). Default = any. 
 text        Text for a free-text search of description, titles, etc.
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
   $api->get_user_photos( username => 'twharris',
                          page     => $i);

   ... do things
}

=cut

sub search_photos {
  my ($self,$params) = @_;

  # If supplied with a username but not a userid, fetch a
  # user object and get their ID.
  my $username = $params->{username};
  my $userid   = $params->{userid};
  if ($username && !$userid) {
    my $user = $self->find_user({username => $username});
    $userid  = $user->id;
  }
  
  my %args;
  # Optionally search using a provided userid or groupid;
  $args{user_id} = $userid if $userid;
  $args{group_id} = $params->{group_id} if $params->{group_id};

  # Tags or free text?
  $args{tags}    = join(',',@{$params->{tags}}) if $params->{tags};
  my $tag_mode = ($params->{tags}) ? ($params->{tag_mode} ? $params->{tag_mode} : 'any') : undef;
  $args{tag_mode} = $tag_mode;
  $args{text} = $params->{text} if $params->{text};


  $args{page}     = $params->{page}     || 1;
  $args{per_page} = $params->{per_page} || 100;

  my $api = $self->api;
  my $response = $api->execute_method('flickr.photos.search',
				      \%args,
				     );
  $self->debug("search_photos(): " . Dumper($response));
 
  return undef unless defined $response and $response->{success}; 
  my $photos = $self->parse_tree(@{$response->{tree}->{children}->[1]->{children}});
  
  # Turn these into the appropriate Flickr::API::Simple objects
  my @objects = $self->factory("Flickr::API::Simple::Photo",$photos);
  return \@objects;
}


# Flickr's XML-based data struct has a lot of 
# extra junk when converted into Perl
sub parse_tree {
  my ($self,@entries) = @_;
  my @clean;
  my $count = 1;
  foreach (@entries) {
    $count++;
    next if $count % 2 == 0;
    push @clean,$_;
  }
  return \@clean;
}
    


=head1 GETTERS / SETTERS

=cut

sub        api { return shift->{api};        }
sub    api_key { return shift->{api_key};    }
sub app_secret { return shift->{app_secret}; }
sub       frob { return shift->{frob};       }
sub auth_token { 
  my $self = shift;
  
  # Perhaps we already have an auth_token.  If so, check
  # that is is still valid.
  my $auth_token = $self->{auth_token};
  
  if ($auth_token) {
    
    my $api   = $self->api;
    my ($res) = $api->execute_method("flickr.auth.checkToken",
				     { 'api_key'    => $self->api_key,
				       'auth_token' => $auth_token,
				     });
    if ($res) {
      return $auth_token;
    } else {
      die "Your authentication is no longer valid. Please authenticate again.\n";
    }
  }
}



=head1 PRIVATE METHODS

=head2 $self->factory

=cut

sub factory {
  my ($self,$package,$entries) = @_;
  
#  $entries = (ref $entries =~ /ARRAY/) ? $entries : [$entries];

  # I have to pass along the api with EACH
  # factory object kind of a strange design decision.
  my @objects;
  foreach my $entry (@$entries) {
    $entry->{api} = $self->api;
    my $this = bless $entry,$package;
    push @objects,$this;
  }
  return wantarray ? @objects : $objects[0];
}

# Parse the flickr data tree for a specific tag
sub _get_element {
  my ($self,$tag) = @_;
  my $info = $self->user_info || $self->get_info;
  foreach (@$info) {
    return $_ if $_->{name} eq $tag;
  }
}

sub debug {
  my ($self,$message) = @_;
  if ($self->{debug_mode}) {
    print "$message\n";
  }
}







=head1 AUTHOR

Todd W. Harris, C<< <info at toddharris.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-flickr-api-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Flickr-API-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 FLICKR METHOD SUPPORT SUMMARY

This section documents the extent of support of the Flickr API.

In this wrapper, some Flickr methods map more cleanly to different
classes than described on the Flickr Services page 
(http://www.flickr.com/services/api/).  An asterisk indicates that
the functionality of the method.  The Flickr::API::Simple class
that provides that support follows the method name.

API Methods
activity

    - flickr.activity.userComments
    - flickr.activity.userPhotos

auth

    * flickr.auth.checkToken
    * flickr.auth.getFrob
    * flickr.auth.getFullToken
    * flickr.auth.getToken

blogs

    - flickr.blogs.getList
    - flickr.blogs.postPhoto

contacts

    - flickr.contacts.getList
    - flickr.contacts.getPublicList

favorites

    - flickr.favorites.add
    - flickr.favorites.getList
    - flickr.favorites.getPublicList
    - flickr.favorites.remove

groups

    - flickr.groups.browse
    - flickr.groups.getInfo
    - flickr.groups.search

groups.pools

    - flickr.groups.pools.add
    - flickr.groups.pools.getContext
    - flickr.groups.pools.getGroups
    - flickr.groups.pools.getPhotos
    - flickr.groups.pools.remove

interestingness

    - flickr.interestingness.getList

people

    * flickr.people.findByEmail ................ User::find_user
    * flickr.people.findByUsername ............. User::find_user
    * flickr.people.getInfo .................... User::get_info
    - flickr.people.getPublicGroups
    - flickr.people.getPublicPhotos
    - flickr.people.getUploadStatus

photos

    * flickr.photos.addTags ................... Photo::add_tags
    * flickr.photos.delete .................... Photo::delete
    - flickr.photos.getAllContexts (PHOTO) NOT DONE - needs to create context objects
    - flickr.photos.getContactsPhotos        (USER)
    - flickr.photos.getContactsPublicPhotos .. (USER)
    + flickr.photos.getContext .. Photo::get_context (not supported in v0.01)
    - flickr.photos.getCounts (Photo - not yet supported)
    - flickr.photos.getExif
    * flickr.photos.getFavorites ............. Photo::favorited_by
    * flickr.photos.getInfo .................. Photo::get_info
    - flickr.photos.getNotInSet (USER)
    * flickr.photos.getPerms ................. Photo::get_permissions
    + flickr.photos.getRecent (GENERAL|SEARCH)
    * flickr.photos.getSizes ................. Photo::sizes
    + flickr.photos.getUntagged (USER)
    + flickr.photos.getWithGeoData (USER)
    + flickr.photos.getWithoutGeoData (USER)
    + flickr.photos.recentlyUpdated (USER)
    * flickr.photos.removeTag ................ Photo::remove_tag
    */+ flickr.photos.search ................. Simple::search_photos
    * flickr.photos.setContentType ........... Photo::set_content_type
    + flickr.photos.setDates .. Photo::set_dates (not supported in v0.01)
    * flickr.photos.setMeta .................. Photo::set_meta
    * flickr.photos.setPerms ................. Photo::set_permissions
    * flickr.photos.setSafetyLevel ........... Photo::set_safety_level
    * flickr.photos.setTags .................. Photo::set_tags

photos.comments

    - flickr.photos.comments.addComment
    - flickr.photos.comments.deleteComment
    - flickr.photos.comments.editComment
    * flickr.photos.comments.getList ......... Photo::comments

photos.geo

    - flickr.photos.geo.getLocation
    - flickr.photos.geo.getPerms
    - flickr.photos.geo.removeLocation
    - flickr.photos.geo.setLocation
    - flickr.photos.geo.setPerms

photos.licenses

    - flickr.photos.licenses.getInfo
    - flickr.photos.licenses.setLicense

photos.notes

    - flickr.photos.notes.add
    - flickr.photos.notes.delete
    - flickr.photos.notes.edit

photos.transform

    - flickr.photos.transform.rotate

photos.upload

    - flickr.photos.upload.checkTickets

photosets

    - flickr.photosets.addPhoto
    - flickr.photosets.create
    - flickr.photosets.delete
    - flickr.photosets.editMeta
    - flickr.photosets.editPhotos
    - flickr.photosets.getContext
    - flickr.photosets.getInfo
    - flickr.photosets.getList
    - flickr.photosets.getPhotos
    - flickr.photosets.orderSets
    - flickr.photosets.removePhoto

photosets.comments

    - flickr.photosets.comments.addComment
    - flickr.photosets.comments.deleteComment
    - flickr.photosets.comments.editComment
    - flickr.photosets.comments.getList

places

    - flickr.places.find
    - flickr.places.findByLatLon
    - flickr.places.resolvePlaceId
    - flickr.places.resolvePlaceURL

prefs

    - flickr.prefs.getContentType
    - flickr.prefs.getGeoPerms
    - flickr.prefs.getHidden
    - flickr.prefs.getPrivacy
    - flickr.prefs.getSafetyLevel

reflection

    - flickr.reflection.getMethodInfo
    - flickr.reflection.getMethods

tags

    - flickr.tags.getClusters
    - flickr.tags.getHotList
    - flickr.tags.getListPhoto ................... Photo::tags
    - flickr.tags.getListUser
    - flickr.tags.getListUserPopular
    - flickr.tags.getListUserRaw
    * flickr.tags.getRelated ..................... Tag::get_related

test

    - flickr.test.echo
    - flickr.test.login
    - flickr.test.null

urls

    - flickr.urls.getGroup
    - flickr.urls.getUserPhotos
    - flickr.urls.getUserProfile
    - flickr.urls.lookupGroup
    - flickr.urls.lookupUser

=head1 APPENDIX 2: photo_info data structure

$VAR1 = [
          {
            'name' => 'owner',
            'children' => [],
            'type' => 'tag',
            'attributes' => {
                              'realname' => 'User Name',
                              'location' => 'Montana, USA',
                              'nsid'     => 'this is the user ID',
                              'username' => 'This is the username'
                            }
          },
          {
            'name' => 'title',
            'children' => [
                            {
                              'content' => 'This is the photo title',
                              'type' => 'data'
                            }
                          ],
            'type' => 'tag',
            'attributes' => {}
          },
          {
            'name' => 'description',
            'children' => [
                            {
                              'content' => 'This is the photo description',
                              'type' => 'data'
                            }
                          ],
            'type' => 'tag',
            'attributes' => {}
          },
          {
            'name' => 'visibility',
            'children' => [],
            'type' => 'tag',
            'attributes' => {
                              'isfriend' => '0',
                              'ispublic' => '1',
                              'isfamily' => '0'
                            }
          },
          {
            'name' => 'dates',
            'children' => [],
            'type' => 'tag',
            'attributes' => {
                              'lastupdate' => '1218409432',
                              'posted' => '1217988734',
                              'taken' => '2006-04-18 14:31:11',
                              'takengranularity' => '0'
                            }
          },
          {
            'name' => 'editability',
            'children' => [],
            'type' => 'tag',
            'attributes' => {
                              'cancomment' => '0',
                              'canaddmeta' => '0'
                            }
          },
          {
            'name' => 'usage',
            'children' => [],
            'type' => 'tag',
            'attributes' => {
                              'candownload' => '1',
                              'canprint' => '0',
                              'canblog' => '0'
                            }
          },
          {
            'name' => 'comments',
            'children' => [
                            {
                              'content' => '0',
                              'type' => 'data'
                            }
                          ],
            'type' => 'tag',
            'attributes' => {}
          },
          {
            'name' => 'notes',
            'children' => [],
            'type' => 'tag',
            'attributes' => {}
          },
          {
            'name' => 'tags',
            'children' => [
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'caenorhabditiselegans',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-1689606',
                                                'raw' => 'Caenorhabditis elegans'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'expressionpattern',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-24286605',
                                                'raw' => 'expression pattern'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'nematode',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-732460',
                                                'raw' => 'nematode'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'genomics',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-486905',
                                                'raw' => 'genomics'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'wwwwormbaseorg',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-27188004',
                                                'raw' => 'www.wormbase.org'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'wormbase',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-8229827',
                                                'raw' => 'WormBase'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'newgroup',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-2916791',
                                                'raw' => 'new_group'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'wbgene00022671',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-27289972',
                                                'raw' => 'WBGene00022671'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'wbbt0005772',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-27249592',
                                                'raw' => 'WBbt:0005772'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'intestine',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-122779',
                                                'raw' => 'intestine'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'reportergene',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-27188010',
                                                'raw' => 'reporter gene'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'zk1773',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-27289974',
                                                'raw' => 'ZK177.3'
                                              }
                            },
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'tag',
                              'children' => [
                                              {
                                                'content' => 'expr7759',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'machine_tag' => '0',
                                                'author' => '26871026@N02',
                                                'id' => '26850678-2736654313-27420117',
                                                'raw' => 'Expr7759'
                                              }
                            },
                            {
                              'content' => '
	',
                              'type' => 'data'
                            }
                          ],
            'type' => 'tag',
            'attributes' => {}
          },
          {
            'name' => 'urls',
            'children' => [
                            {
                              'content' => '
		',
                              'type' => 'data'
                            },
                            {
                              'name' => 'url',
                              'children' => [
                                              {
                                                'content' => 'http://www.flickr.com/photos/wormbase/2736654313/',
                                                'type' => 'data'
                                              }
                                            ],
                              'type' => 'tag',
                              'attributes' => {
                                                'type' => 'photopage'
                                              }
                            },
                            {
                              'content' => '
	',
                              'type' => 'data'
                            }
                          ],
            'type' => 'tag',
            'attributes' => {}
          }
        ];


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

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Flickr::API::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Flickr-API-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Flickr-API-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Flickr-API-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Flickr-API-Simple>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Todd W. Harris, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
