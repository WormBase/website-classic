#!/usr/local/bin/perl

# Author: Payan Canaran <canaran@cshl.edu>
# Copyright (c) 2007 Cold Spring Harbor Laboratory
# $Id: make_unique.pl,v 1.1.1.1 2010-01-25 15:40:08 tharris Exp $

use warnings;
use strict;
use Carp;
use IO::Prompt;

use DBI;

my $usage = "$0 <database> <username>";

my $database = shift;
my $username = shift;

die("Usage: $usage\n") unless ($database && $username);

prompt("Password: ", -echo => '*');
my $password = $_;

my $datasource = "DBI:mysql:database=$database;host=localhost;port=3306";

our $TABLE = 'wb_by_person2';

# Connect to database
our $DBH = DBI->connect(
    $datasource, $username, $password,
    {PrintError => 1, RaiseError => 1}
  )
  or croak("Cannot connect to database!");

# Is unique?
my $is_unique_sth = qq[SELECT count(*) FROM $TABLE
                        WHERE latitude = ? AND longitude = ?];
our $IS_UNIQUE_STH = $DBH->prepare($is_unique_sth);

# Set info
my $set_info_sth =
  qq[UPDATE $TABLE SET latitude = ?, longitude = ?  ,longitude_shift = ? 
                       WHERE id = ?];
our $SET_INFO_STH = $DBH->prepare($set_info_sth);

# Get info
my $get_info_sth = qq[SELECT latitude, longitude FROM $TABLE WHERE id = ?];
our $GET_INFO_STH = $DBH->prepare($get_info_sth);

# Get all ids
my @ids;
my $sth = $DBH->prepare(
    qq[SELECT id FROM $TABLE 
                           WHERE latitude IS NOT NULL 
                           AND longitude IS NOT NULL]
);
$sth->execute;
while (my ($id) = $sth->fetchrow_array) {
    push @ids, $id;
}

# Round all latitude & longitude
foreach my $id (@ids) {
    my ($latitude, $longitude) = get_info($id);

    my $longitude_shift = 0;

    set_info($latitude, $longitude, $longitude_shift, $id);
}

# Make unique
ID: foreach my $id (@ids) {
    my ($latitude, $longitude, $longitude_shift) = get_info($id);

    my ($new_latitude, $new_longitude, $new_longitude_shift) =
      ($latitude, $longitude, $longitude_shift);

    if (is_unique($new_latitude, $new_longitude)) {
        my $new_longitude_shift =
          $new_longitude - $longitude + $longitude_shift;
        set_info($new_latitude, $new_longitude, $new_longitude_shift, $id);
        next;
    }

    my $level     = 0;
    my $increment = 0.000100;

    while (1) {
        $level++;

        #        my $latitude_move  = int(rand(3));
        #        my $longitude_move = int(rand(3));

        foreach my $latitude_move (0 .. 2) {
            foreach my $longitude_move (0 .. 2) {
                if ($latitude_move eq '1') {
                    $new_latitude = $latitude - $level * $increment;
                }
                if ($latitude_move eq '2') {
                    $new_latitude = $latitude + $level * $increment;
                }
                if ($longitude_move eq '1') {
                    $new_longitude = $longitude + $level * $increment;
                }
                if ($longitude_move eq '2') {
                    $new_longitude = $longitude - $level * $increment;
                }

                print
                  "latmove: $latitude_move; longmove: $longitude_move; level: $level\n";

                my $new_longitude_shift =
                  $new_longitude - $longitude + $longitude_shift;
                set_info(
                    $new_latitude, $new_longitude, $new_longitude_shift,
                    $id
                );

                if (is_unique($new_latitude, $new_longitude)) {
                    next ID;
                }
            }
        }
    }
}

sub is_unique {
    my ($latitude, $longitude) = @_;

    $latitude  = sprintf("%6f", $latitude);
    $longitude = sprintf("%6f", $longitude);

    $IS_UNIQUE_STH->bind_param(1, $latitude);
    $IS_UNIQUE_STH->bind_param(2, $longitude);

    $IS_UNIQUE_STH->execute;

    my ($count) = $IS_UNIQUE_STH->fetchrow_array;

    return $count > 1 ? 0 : 1;
}

sub set_info {
    my ($new_latitude, $new_longitude, $longitude_shift, $id) = @_;

    $new_latitude    = sprintf("%6f", $new_latitude);
    $new_longitude   = sprintf("%6f", $new_longitude);
    $longitude_shift = sprintf("%6f", $longitude_shift);

    print
      "Setting: ID:$id, lat:$new_latitude, long:$new_longitude, error:$longitude_shift\n";

    $SET_INFO_STH->bind_param(1, $new_latitude);
    $SET_INFO_STH->bind_param(2, $new_longitude);
    $SET_INFO_STH->bind_param(3, $longitude_shift);
    $SET_INFO_STH->bind_param(4, $id);

    $SET_INFO_STH->execute;

    return 1;
}

sub get_info {
    my ($id) = @_;

    $GET_INFO_STH->bind_param(1, $id);

    $GET_INFO_STH->execute;

    my ($latitude, $longitude, $longitude_shift) =
      $GET_INFO_STH->fetchrow_array;

    $longitude_shift ||= 0;

    $latitude        = sprintf("%6f", $latitude);
    $longitude       = sprintf("%6f", $longitude);
    $longitude_shift = sprintf("%6f", $longitude_shift);

    return ($latitude, $longitude, $longitude_shift);
}

