#!/usr/bin/perl -w

# This script demonstrates one way to "screen scrape"
# WormBase for annotated Concise Descriptions displayed on
# the Gene Summary page.6  # This script may break if the user interface changes!

use strict;
use WWW::Mechanize;

# The URL of the target page
use constant URL =>
  'http://aceserver.cshl.org/db/gene/gene?name=';

# A list of genes to fetch
my @genes = qw/unc-2 unc-26 unc-70 unc-119 dyn-1 vab-3/;

foreach my $gene (@genes) {
  my $agent = WWW::Mechanize->new();
  $agent->get(URL . $gene);  # Create the full URL
  $agent->success
    or die "Sorry, I couldn't fetch the page for $gene: $!";
  
  my $content = $agent->content;
  
  # Parse out the Concise Description.  This is usually the
  # most difficult task of a screen-scraping program. Here
  # we use a Perl regular expression to fetch the desired
  # data. One must examine the HTML source to develop an
  # appropriate expression.
  
  my ($description) =
    ($content =~ /Concise\sDescription.*?body\">(.*?)\s\[/);
  
  # Print out the data
  print "$gene\t$description\n";
  
  # Prevent a tragedy of the commons. Send a request
  # to WormBase only every three seconds out of courtesy
  # to other users.
  sleep 3;
}
