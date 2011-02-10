#!/usr/bin/perl

# Populate the core database with a series of objects as the baseline

use strict;
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
my @classes = qw/Sequence/;

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
    print STDERR "loaded $count $class objects$delim" if ++$count % 100 == 0;

    my $history = ObjectHistory->new($object,$ace->version);

    # Stash the object but only if we haven't seen it before
    $history->store_object() if ! $history->objectid;

    # Parse the object and look for timestamps more recent
    # than the last_modification_date
    # This will of course be ridiculous for objects we've just stashed.
    $history->check_for_updates('parse_object');
  }
}

$ace->timestamps(0);
