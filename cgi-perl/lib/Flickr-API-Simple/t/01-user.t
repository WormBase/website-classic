#!perl -T

use Test::More tests => 14;
use lib 'lib';
use lib 't';
use TestConfig;

BEGIN {
  diag("Testing Flickr::API::Simple::User methods...");
  use_ok( 'Flickr::API::Simple' );	
}

my $api = Flickr::API::Simple->new({api_key => $api_key, app_secret => $app_secret});
ok($api,"new()");

my $test_connection = $api->test_flickr_connection();
ok($test_connection,"test_flickr_connection()");

#####################################################
# F::A::S::U
my $user = $api->find_user({username => "twharris"});
ok($user,"find_user(username => 'twharris') = $user");

# Test a variety of tags
my @tags = qw/realname username location photosurl profileurl mobileurl
	      first_photo_date
	      photo_count
	      nsid/;
foreach (@tags) {  
  my $data = $user->$_;
  ok($data,'$user->' . "$_: " . $data);
}

# Get the most recent photo for a user.
my $photos = $user->photos({page     => 1,
			    per_page  => 1});
ok($photos,'$user->photos: ' . $photos);
