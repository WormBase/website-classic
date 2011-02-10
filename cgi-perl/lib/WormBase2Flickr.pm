package WormBase2Flickr;

use Flickr::API;
use strict;
use Data::Dumper;
use constant DEBUG => 0;

my $version = '0.01';

sub new {
    my $this = shift;
    my $self = bless {},$this;  
    
    my $constants = (-e './flickr.conf' ? './flickr.conf' : '/usr/local/wormbase/conf/flickr.conf');
    
    open CONSTANTS,$constants or die;
    while (<CONSTANTS>) {
	next if /^[#|\s]/;
		   chomp;
		   my ($key,$val) = split ("=");
		   $self->{$key} = $val;
	       }
	
	# 1. Instantiate the API ua
	my $api = Flickr::API->new({'key'    => $self->{API_KEY},
				    'secret' => $self->{APP_SECRET}
				}) or die "$!";
	$self->{api} = $api;

#	my $url = $api->request_auth_url('write',$self->get_frob);
#	print $url;

	# 2. Set the UA - keep it the same as the uploader so I don't need a new token
	$self->api->agent( "WormBaseUploader/$version" );
	
	$self->get_frob();
	$self->get_auth_token();    
	return $self;
    }
    
    sub flickr_connection_test {
	my ($self,$username) = @_;
  my $api = new Flickr::API({'key' => $self->api_key });
  my $response = $api->execute_method ('flickr.people.findByUsername', {
									'username' => $username,
								       });
  
  print "Flickr connection test ";
  if ($response->{success}) {
    print "success: $response->{success}\n";
  } else {
    print "failed. Error code: $response->{error_code}\n";
  }
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
  
  # 4. Get an auth_token if we don't already have one
  my $auth_token = $self->{AUTH_TOKEN};
  
  if ($auth_token) {
      # Check the existing token
      my ($res) = $api->execute_method("flickr.auth.checkToken",
				       { 'api_key'    => $self->api_key,
					 'auth_token' => $auth_token,
				       });
      
      return $auth_token;
  }      
  
  my $res = $api->execute_method("flickr.auth.getToken",
				 { 'frob' => $frob } );
  
  return undef unless defined $res and $res->{success};
  print Dumper($res) if DEBUG; 
  my $auth_token = $res->{tree}->{children}->[1]->{children}->[1]->{children}->[0]->{content};
  $self->{AUTH_TOKEN} = $auth_token;

  die "Failed to get authentication token!" unless defined $auth_token;
}


# Get the nsid for a username; defaults to the wormbase user

sub get_uid {
  my ($self,$username) = @_;

  my $username ||= $self->{FLICKR_WORMBASE_USER};
  my $api = $self->api;
  my $response = $api->execute_method ('flickr.people.findByUsername', {
									'username' => $username,
								       });
  my $uid;
  if ($response->{success}) {
    $uid = $response->{tree}->{children}->[1]->{attributes}->{nsid};
    print "successfully retrieved user ID $uid\n" if DEBUG;
  } else {
      print "failed. Error code: $response->{error_code}\n" if DEBUG;
  }
  return $uid;
}
  

# Get all photos for a given user
sub get_user_photos {
  my ($self,%params) = @_;
  my $username = $params{user};

  die "get_user_photos: please provide a username" unless $username;

  my $uid = $self->get_uid($username);
  my $api = $self->api;
    
  # Get the WormBase group ID
  my $group_id = $self->{WORMBASE_GROUP_ID};

  my $page = $params{page};
  
  # Get all photos for this user
  my $photo_res = $api->execute_method('flickr.people.getPublicPhotos',
				       { user_id => $uid,
					 per_page => 500,
					 page => $page
				       });
  my @photos = @{$photo_res->{tree}->{children}->[1]->{children}};
  return \@photos;    
}


# Post images to a group (by default, to the 
sub post_images_to_group {
    my ($self,%params) = @_;
    my $photos = $params{photos};
    my $group_id = $params{group_id} || $self->{WORMBASE_GROUP_ID};
    
  my $api = $self->api;

  
  # Even numbered hashes are empty
  my $c = 1;
  foreach (@$photos) { 
    $c++;
    next if $c % 2 == 0;
    my $id = $_->{attributes}->{id}; 
    
    my $request = new Flickr::API::Request({
					    'method' => 'flickr.groups.pools.add',
					    'args' => {
						       auth_token  => $self->{AUTH_TOKEN},
						       photo_id    => $id,
						       group_id    =>$group_id}
					   });
    
    my $response = $api->execute_request($request);
    print Dumper($response) if DEBUG;
    print "Response: $response\n" if DEBUG;
  }
}




# ACCESSORS
sub        api { return shift->{api};        }
sub       frob { return shift->{frob};       }
sub auth_token { return shift->{AUTH_TOKEN}; } 
sub    api_key { return shift->{API_KEY};    }
sub app_secret { return shift->{APP_SECRET}; }


# WormBase specific accessors
sub flickr_wormbase_user { return shift->{FLICKR_WORMBASE_USER}; }
sub wormbase_url         { return shift->{WORMBASE_URL};         }
