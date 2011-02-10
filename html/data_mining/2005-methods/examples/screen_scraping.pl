#!/usr/bin/perl -w
# This script demonstrates one way to "screen scrape" WormBase

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

  # Parse out the Concise Description.
  my ($description) = 
    ($content =~ /Concise\sDescription.*?body\">(.*?)\s\[/);

  print "$gene\t$description\n";
  sleep 3;
}
