#!/usr/local/bin/perl

# Author: Payan Canaran <canaran@cshl.edu>
# Copyright (c) 2007 Cold Spring Harbor Laboratory
# $Id: geo_code.pl,v 1.1.1.1 2010-01-25 15:40:08 tharris Exp $

use warnings;
use strict;

use LWP::Simple;
use Data::Dumper;

our $GMAP_KEY =
  "ABQIAAAAGB-Wqdj00NegDlW0aNTPQRTwM0brOpm-All5BF6PoaKBxRWWERQzDpPAzL-zTSiDg2J4QYhRS5jYTg";

my ($file) = @ARGV;

$| = 1;

open(IN,     "<$file")         or die("Cannot read file ($file): $!");
open(CACHE,  ">>$file.cache")  or die("Cannot write file ($file.cache): $!");
open(LOG,    ">>$file.log")    or die("Cannot write file ($file.log): $!");
open(OK,     ">>$file.ok")     or die("Cannot write file ($file.ok): $!");
open(FAILED, ">>$file.failed") or die("Cannot write file ($file.failed): $!");

our $ACCURACY_THRESHOLD = 4;

our %CACHE;
foreach my $file ("$file.cache") {
    if (-e $file) {
        open(READ, "<$file") || die $!;
        while (my $line = <READ>) {
            chomp $line;
            my ($address, $status, $accuracy, $latitude, $longitude) =
              split(/\|/, $line);
            $CACHE{$address} = [$status, $accuracy, $latitude, $longitude];
        }
    }
}

my $counter = 0;

my $time = time();

sleep 1;

while (my $line = <IN>) {
    chomp $line;
    $counter++;

    $line =~ s/^\s+$//;
    next if $line eq '';

    my ($address, $valid_address, $status, $accuracy, $latitude, $longitude) =
      split(/\|/, $line);

    if ($latitude && $longitude && $accuracy >= $ACCURACY_THRESHOLD) {
        print OK "$line\n";
    }

    else {
        ($valid_address, $status, $accuracy, $latitude, $longitude) =
          $accuracy ? geocode($address) : geocode($address, $valid_address);
        if ($latitude && $longitude && $accuracy >= $ACCURACY_THRESHOLD) {
            print OK join(
                '|',       $address, $valid_address, $status, $accuracy,
                $latitude, $longitude
              )
              . "\n";
        }
        else {
            print FAILED join(
                '|',       $address, $valid_address, $status, $accuracy,
                $latitude, $longitude
              )
              . "\n";
        }
    }

    my $elapsed = time() - $time;
    print "OK: $counter in $elapsed sec\n";

}

sub geocode {
    my ($address, $valid_address) = @_;

    print LOG "FROM: $address\n";

    return ('', '', '', '', '') unless $address;

    my @valid_addresses;

    if ($valid_address) {
        push @valid_addresses, $valid_address;
    }

    else {

        # Remove extra spaces
        $address =~ s/\s+/ /g;

        # Remove fields that contain number sign
        $address =~ s/[^,]*\#[^,]*//g;
        $address =~ s/,[,\s]*,/,/g;

        # Change Names
        $address =~ s/U\.S\.A\./USA/;
        $address =~ s/United States of America/USA/i;
        $address =~ s/Republic of Korea/Korea/i;
        $address =~ s/United Kingdom/UK/;
        $address =~ s/U\.K\./UK/;
        $address =~ s/People\'s Republic of China/China/;
        $address =~ s/Peoples Republic of China/China/;
        $address =~ s/Republic of China/China/;
        $address =~ s/USA1/USA/;
        $address =~ s/N\.C\./NC/ if $address =~ /USA/;
        $address =~ s/Massachusetts/MA/ if $address =~ /USA/;
        $address =~ s/Illinois/IL/ if $address =~ /USA/;
        $address =~ s/Wisconsin/WI/ if $address =~ /USA/;
        $address =~ s/Maryland/MD/ if $address =~ /USA/;
        $address =~ s/Iowa/IA/ if $address =~ /USA/;
        $address =~ s/Utah/UT/ if $address =~ /USA/;
        $address =~ s/Florida/FL/ if $address =~ /USA/;

        # Remove phone number
        $address =~ s/[\,\s]*PHONE:[\s0-9\-\(\)\,]*//;

        # Remove potential comma between state and zip code
        $address =~ s/( [A-Z]{2})[,\s]*(\d{5})/$1 $2/;

        # Clean zip code
        $address =~ s/(\d{5})-\d{4}/$1/;

        # Remove after zip code
        $address =~ s/([A-Z]{2} \d{5}).*$/$1/ if $address =~ /USA/;

        # Remove additional info
        $address =~
          s/( [A-Za-z\s]+,) [0-9\-]+, (Japan|China|South Korea|Greece|Israel|Italy)/$1$2/i;

        # Keep only last 4 fields
        my @address = split(/\s*,\s*/, $address);
        while (@address > 4) {
            shift @address;
        }

        # Make a series of addresses of decreasing specificity
        while (@address) {
            push @valid_addresses, join(',', @address);
            shift @address;
        }

        # Add single zip code if US
        if ($address =~ /[,\s]+[A-Z]{2} (\d{5})/) {
            push @valid_addresses, $1;
        }

        # Add zip code if UK/Canada
        if (
            (      $address =~ /England/i
                || $address =~ /Canada/i
                || $address =~ /UK/
            )
            && $address =~ /[\s,]([A-Z0-9]{3} [A-Z0-9]{3})[\s,]/
          ) {
            push @valid_addresses, $1;
        }

        # Add city-based addresses
        my %countries = (
            'Japan' => [
                qw(Tokyo Kobe Nagoya Osaka Mishima Tsukuba Sendai
                  Iwate Sendai Saitama Fukuoka Otsu Shizuoka
                  Kumamoto Saga Ishikawa Okayama Hiroshima
                  Kyoto Yokohama Isehara Toyohashi Maebashi Kasuagi
                  Kanagawa Ikoma Kawasaki Tokushima)
            ],
            'Korea' => [qw(Seoul  Soeul Chuncheon Daejon Gwangju Incheon)],
            'South Korea' =>
              [qw(Seoul  Soeul Chuncheon Daejon Gwangju Incheon)],
            'Republic of Korea' =>
              [qw(Seoul  Soeul Chuncheon Daejon Gwangju Incheon)],
            'France' => [qw(Marseille Lyon Paris Illkirch)],
            'UK'     => [
                qw(Cambridge Glasgow Bracknell Oxford Salford London
                  Manchester Edinburgh Birmingham Bristol Hinxton
                  Nottingham Dundee Southampton Brighton Essex
                  Aberystwyth Harefield Aberdeen)
            ],
            'India'             => [qw(Bangalore Aligarh Hyderabad)],
            'Republic of India' => [qw(Bangalore Aligarh Hyderabad)],
            'Germany'           => [
                qw(Koeln Freiburg Berlin Tricer Munich Dresden Gottingen
                  Hannover Tuebingen Tubingen Heidelberg Duesseldorf
                  Martinsried Munster Bielefeld Frankfurt Koln Dusseldorf Freising
                  Goettingen Braunschweig Garching Muenchen Giessen Saarbrucken
                  Hamburg)
            ],
            'China' => [
                qw(Nanjing Fujian Hefei Yunnan Beijing Shanghai Peking Fujian Quebec)
            ],
            'Canada' => [
                qw(Edmonton Alberta Montreal Toronto Vancouver Hamilton Burnaby Calgary Ste-Foy),
                'British Columbia'
            ],
            'Israel'      => [qw(Haifa Rehovot )],
            'Switzerland' => [
                qw(Zrich Zurich Zuerich Basel Lausanne-Dorigny Freiburg Fribourg Epalinges Geneva)
            ],
            'England' => [qw(Cambridge Brighton Essex London)],
            'Greece'  => [qw(Heraklion Crete Athens)],
            'Sweden'  =>
              [qw(Huddinge Goteborg Gothenburg Stockholm Uppsala Lund Umea)],
            'Belgium'     => [qw(Gent Ghent)],
            'Netherlands' => [
                qw(Amsterdam Utrecht Wageningen Leiden Hulshorst Rotterdam Groningen),
                'Den Haag'
            ],
            'Singapore'      => [qw(Crescent)],
            'Italy'          => [qw(Milan Naples Pavia Napoli Genoa)],
            'Czech Republic' => [qw(Prague)],
            'Poland'         => [qw(Warsaw Wroclaw)],
            'Taiwan'         => [qw(Taipei)],
            'Egypt'          => [qw(Giza)],
            'Brazil'         => [qw(Ilheus)],
            'Australia'      => [qw(Queensland Bundoora Victoria Acton)],
            'Spain'          => [qw(Barcelone)],
            'Portugal'       => [qw(Braga)],
            'Finland'        => [qw(Helsinki)],
            'Hungary'        => [qw(Budapest)],
            'France'         => [qw(Marseille)],
        );

        foreach my $country (keys %countries) {
            if ($address =~ /$country/i) {
                my $cities = $countries{$country};
                foreach my $city (@$cities) {
                    if ($address =~ /$city/i) {
                        push @valid_addresses, "$city, $country";
                    }
                }
            }
        }
    }

    foreach my $valid_address (@valid_addresses) {
        my ($status, $accuracy, $latitude, $longitude);

        if ($CACHE{$valid_address}) {
            ($status, $accuracy, $latitude, $longitude) =
              @{$CACHE{$valid_address}};
            print LOG "IN-CACHE: $valid_address\n";
        }

        else {
            my $url =
              "http://maps.google.com/maps/geo?q=$valid_address&key=$GMAP_KEY&output=csv";

            sleep 1 unless int(rand(3));

            my $content = get($url);

            print LOG "TRYING: $valid_address\n";

            if ($content) {
                ($status, $accuracy, $latitude, $longitude) =
                  split(",", $content);
            }
            $CACHE{$valid_address} =
              [$status, $accuracy, $latitude, $longitude];
            print CACHE join(
                '|', $valid_address, $status, $accuracy, $latitude,
                $longitude
              )
              . "\n";
        }

        if ($latitude && $longitude && $accuracy >= $ACCURACY_THRESHOLD) {
            return (
                $valid_address, $status, $accuracy, $latitude,
                $longitude
            );
        }
    }

    return ('', '', '', '', '');
}

