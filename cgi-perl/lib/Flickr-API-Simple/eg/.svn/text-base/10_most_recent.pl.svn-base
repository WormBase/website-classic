#!/usr/bin/env perl

use strict;
use FindBin qw/$Bin/;

use lib "$Bin/../lib";
use Flickr::API::Simple;

my $flickr = Flickr::API::Simple->new();

my $photos = $flickr->get_user_photos({username => 'twharris'});

foreach my $photo (@$photos) {
  
  print "title: " . $photo->title . "\n";
  # print "desc: " . $photo->description . "\n";
  
  my $comments = $photo->comments;
  print "Comments: " . @$comments . "\n";
  foreach (@$comments) {
    my $author = $_->author;
    print '"' . $_->content . '"' .  ' by ' . $author->username .' (' . $author->realname. ')' . "\n";    
  }

  my $tags = $photo->tags;
  foreach (@$tags) {
    print join("\t",$_->name,$_->raw,$_->machine_tag,$_->id,$_->author),"\n";
  }
  
  #  $photo->sizes;
  die;
}
