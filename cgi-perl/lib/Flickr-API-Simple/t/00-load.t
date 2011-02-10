#!perl -T

use Test::More tests => 1;
use lib 'lib';

BEGIN {
	use_ok( 'Flickr::API::Simple' );
}

diag( "Testing Flickr::API::Simple $Flickr::API::Simple::VERSION, Perl $], $^X" );
