#!/usr/bin/perl -w

use strict;
use Getopt::Std;
use OBrowse;

my %opts=();

getopts('o:a:s:h',\%opts);

my $program_name=$0=~/([^\/]+)$/ ? $1 : '';

if (! defined $opts{o} || ! defined $opts{s} ) {
    $opts{h}=1;
}

if ($opts{h}) {
    print "usage: $program_name [options] -o ontology -s socket\n";
    print "       -h               help - print this message\n";
    print "       -o <ontology>    OBO file; required\n";
    print "       -s <socket>      socket name; required\n";
    print "       -a <annotations> file containing annotations\n";
    exit(0);
}


my $obo=OBrowse->new(Local=>$opts{s}, Type=>SOCK_STREAM, Listen=>10) || die "cannot create OBrowse object: $!\n";

my $term_count=$obo->loadOntology($opts{o}) || die "cannot open load ontology from $opts{o}: $! \n";
print "$term_count terms read from $opts{o}\n";

if ($opts{a}) {
    my $annotation_count=$obo->loadAnnotations($opts{a}) || die "cannot load annotations from $opts{a}: $!\n";
    print "$$annotation_count[0] annotations read\n";
    print "$$annotation_count[1] NOT annotations read\n";
}

$obo->startServer() || die "cannot start server: $!\n";
