#!perl -T

use Test::More tests => 25;
use lib 'lib';
use lib 't';
use TestConfig;

BEGIN {
  diag("Testing Flickr::API::Simple::Photo methods...");
  use_ok( 'Flickr::API::Simple' );	
}

my $api = Flickr::API::Simple->new({api_key => $api_key, app_secret => $app_secret});
ok($api,"new()");

my $test_connection = $api->test_flickr_connection();
ok($test_connection,"test_flickr_connection()");

#####################################################
# F::A::S::P
# Fetch a user.
my $user = $api->find_user({username => "twharris"});
ok($user,"find_user(username => 'twharris') = $user");

# Fetch recent photos
my $photos = $user->photos({per_page => 1});
ok($photos,'$user->photos()');

# Test a variety of tags
my @tags = qw/id owner title description isfriend isfamily ispublic lastupdate date_posted
	      date_taken can_comment can_add_meta can_download can_print can_blog
	      tags photopage_url favorited_by sizes comments
	     /;
foreach my $photo (@$photos) {
  foreach my $tag (@tags) {      
    my $data = $photo->$tag;

    # Can't is() a reference in this manner - they will be different for each method call.
    if ($data =~ /ARRAY/ || $data =~ /HASH/) {
      ok($data,'$photo->' . "$tag: " . $data);
    } else {
      is($photo->$tag,undef || $data,'$photo->' . "$tag: " . $data);
    }      
  }
}
