#!/usr/bin/perl -w

use strict;
use OBrowse;
use Getopt::Std;


my %opts=();
getopts('s:l:q:h',\%opts);
my $program_name=$0=~/([^\/]+)$/ ? $1 : '';


if (! defined $opts{s}) {
    $opts{h}=1;
}

if ($opts{h}) {
    print "usage: $program_name -s socket\n";
    print "       -h                 help - print this message\n";
    print "       -q <query>         e.g. mitosis or GO:0007067\n";
    print "       -l <list of terms> terms to retrieve annotations for\n";
    exit(0);
}

my $obo=OBrowse->new(Peer=>$opts{s}, Type=>SOCK_STREAM) || die "cannot create object: $!\n";

my $ver=$obo->VERSION();
print "version: $ver\n";


if ($opts{l}) {
    my @terms=split('\|', $opts{l});
    my $ref=$obo->getAnnotations(\@terms, $opts{n}) || die "cannot get annotations: $!";
    print scalar @$ref, " annotations retrieved\n";
    foreach (@$ref) {
	print join("\t", @$_), "\n";
    }
    exit;
}

if ($opts{q}) {
    my $ref=$obo->findTerms($opts{q}) || die "cannot find terms: $!";
    print scalar keys %$ref, " terms found\n";
    foreach (sort {$$ref{$a}{name} cmp $$ref{$b}{name}} keys %$ref) {
	print "$_\t$$ref{$_}{name}\t$$ref{$_}{namespace}\n";
	foreach my $o (keys %{$$ref{$_}{other}}) {
	    print "$o:\t${$$ref{$_}{other}}{$o}[0]\n";
	}
	print "\n";
    }
    exit;
}
