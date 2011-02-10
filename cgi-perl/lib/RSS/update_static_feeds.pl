#!/usr/bin/perl

# Pre-generate a series of feeds and aggregate information

use strict;
#use CGI qw/:standard/;
use Ace;
use Getopt::Long;
use lib '.';
use ObjectHistory;

my ($host,$port,$path);
GetOptions( 'host=s' => \$host,
	    'port=i' => \$port,
	    'path=s' => \$path);

$host ||= 'localhost';
$port ||= '2005';
$|++;

my $ace = $path
  ? Ace->connect($path)
  : Ace->connect(-host => $host,-port => $port) or die "Couldn't connect to Ace: $!";

# Turn on the timestamps!
$ace->timestamps(1);

#my @classes = $ace->classes();
#my @classes = qw/Gene Sequence Protein/;
#my @classes = qw/Gene/;
my @classes = qw/Gene/;

# Prepopulate the database so that we have a baseline for comparing
# future modifications

my $emacs = $ENV{EMACS};
my $delim = $emacs ? "\n" : "\r";
my $count;

foreach my $class (@classes) {
    my $i = $ace->fetch_many(-class => $class,
			     -name  => '*',
			     -fill  => 1);
    print STDERR "Loading $class...\n";
    
    while (my $object = $i->next) {
	my $history = ObjectHistory->new($object,$ace->version);
	print STDERR "loaded $count $class objects$delim" if ++$count % 100 == 0;
	$history->build_static_feed();
    }
}


$ace->timestamps(0);

