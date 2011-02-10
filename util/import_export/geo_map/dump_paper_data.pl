#!/usr/bin/perl

# Author: Payan Canaran <canaran@cshl.edu>
# Copyright (c) 2007 Cold Spring Harbor Laboratory
# $Id: dump_paper_data.pl,v 1.1.1.1 2010-01-25 15:40:08 tharris Exp $

use Ace;
use strict;
use Time::Format qw(%time);
use Data::Dumper;

my $usage =
  "$0 [<host> <port> | <path>]; defaults to aceserver.cshl.org:2005";

my ($host, $port) = @ARGV;

if (!$host && !$port) {
    $host = "aceserver.cshl.org";
    $port = 2005;
}

my $dbh =
  ($host && $port)
  ? Ace->connect(-host => $host, -port => $port)
  : Ace->connect(-path => $host);
$dbh || die "Couldn't open database ($host, $port)";

my $file = 'data_dump';

dump_authors($dbh, "$file.authors");
dump_persons($dbh, "$file.persons");
dump_papers($dbh, "$file.papers");

$dbh->close;

# [END]

sub dump_persons {
    my ($dbh, $file) = @_;

    my $command = qq[find Person];

    my $iterator = $dbh->fetch_many(-query => $command)
      || die "Cannot fetch ($command)";

    open(FILE, ">$file") or die("Cannot write file ($file): $!");

    while (my $object = $iterator->next) {

        # Id
        my $id = "Person:$object";

        # Name
        my ($standard_name) = $object->Standard_name;
        $standard_name =~ s/\t/ /g;

        my $address = $object->at('Address');

        # Address
        my @address = $address->at('Street_address') if $address;
        my @country = $address->at('Country')        if $address;
        my $standard_address = join(", ", @address, @country);
        $standard_address =~ s/\t/ /g;

        # Email
        my $email = join(",", $address->at('Email')) if $address;

        # Institution
        my $institution = join(",", $address->at('Institution')) if $address;

        # Web_page
        my $web_page = join(",", $address->at('Web_page')) if $address;

        # Papers (number of)
        my @papers = $object->Paper;
        my $papers = @papers;

        # Supervised (number of)
        my @supervised = $object->Supervised;
        my $supervised = @supervised;

        my @data = (
            $id, $standard_name, $standard_address, $email, $institution,
            $web_page, $papers, $supervised
        );

        clean_data(\@data);

        print FILE join("|", @data) . "\n";
    }

    return 1;
}

sub dump_authors {
    my ($dbh, $file) = @_;

    my $command = qq[find Author];

    my $iterator = $dbh->fetch_many(-query => $command)
      || die "Cannot fetch ($command)";

    open(FILE, ">$file") or die("Cannot write file ($file): $!");

    while (my $object = $iterator->next) {

        # Id
        my $id = "Author:$object";

        # Name
        my ($standard_name) = $object->Full_name;
        $standard_name =~ s/\t/ /g;

        my $address = $object->at('Address');

        # Address
        my @address = $address->at('Mail') if $address;
        my $standard_address = join(", ", @address);
        $standard_address =~ s/\t/ /g;

        # Email
        my $email = join(",", $address->at('E_mail')) if $address;

        # Institution
        my $institution = '';

        # Web_page
        my $web_page = '';

        # Papers (number of)
        my @papers = $object->Paper;
        my $papers = @papers;

        # Supervised (number of)
        my $supervised = 0;

        my @data = (
            $id, $standard_name, $standard_address, $email, $institution,
            $web_page, $papers, $supervised
        );

        clean_data(\@data);

        print FILE join("|", @data) . "\n";
    }

    return 1;
}

sub dump_papers {
    my ($dbh, $file) = @_;

    my $command = qq[find Paper];

    my $iterator = $dbh->fetch_many(-query => $command)
      || die "Cannot fetch ($command)";

    open(FILE, ">$file") or die("Cannot write file ($file): $!");

    while (my $object = $iterator->next) {

        # Id
        my $id = "$object";

        # Type
        my ($type) = $object->Type;

        # Citation
        my ($citation) = $object->Brief_citation;

        # Authors
        my @authors = $object->Author;
        my @author_ids;

        foreach my $author (@authors) {
            my $author_id = "Author:$author";
            my ($possible_person) = $author->Possible_person;
            $author_id = "Person:$possible_person" if $possible_person;
            push @author_ids, $author_id;
        }

        foreach my $i (0 .. @author_ids - 1) {
            my $author_id       = $author_ids[$i];
            my $author_position = 'Other';
            if (@author_ids == 1) {
                $author_position = 'Single';
            }
            elsif ($i == 0) {
                $author_position = 'First';
            }
            elsif ($i == @author_ids - 1) {
                $author_position = 'Last';
            }

            my @data = ($id, $author_id, $author_position, $type, $citation);

            clean_data(\@data);

            print FILE join("|", @data) . "\n";

        }
    }

    sub clean_data {
        my ($data_ref) = @_;

        foreach (@$data_ref) {
            $_ = '\N' if (!defined $_ or $_ eq '');
            $_ =~ s/\n+$//;
            $_ =~ s/[\n\|]/_/g;
        }

        return 1;
    }
    return 1;
}
