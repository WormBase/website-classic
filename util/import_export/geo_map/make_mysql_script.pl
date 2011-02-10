#!/usr/bin/perl

# Author: Payan Canaran <canaran@cshl.edu>
# Copyright (c) 2007 Cold Spring Harbor Laboratory
# $Id: make_mysql_script.pl,v 1.1.1.1 2010-01-25 15:40:08 tharris Exp $

use strict;
use warnings;
use Cwd;

my $usage = "$0 [<dir>]";

my ($dir) = @ARGV;

$dir ||= getcwd();
$dir =~ s/\/+$//;

die("Directory ($dir) must be specified as an absolute path!\n")
  unless $dir =~ /^\//;

foreach (
    qw(data_dump.persons data_dump.authors 
       data_dump.papers all_addresses.txt.ok)) {
    die("Directory ($dir) must contain file $_!\n")
      unless -e "$dir/$_";
}

my $mysql_script;

{
    local $/;
    $mysql_script = <DATA>;
}

$mysql_script =~ s/\[DIR\]/$dir/g;

print $mysql_script;

# [END]

__DATA__

DROP TABLE IF EXISTS wb_author;

CREATE TABLE `wb_author` (
    `id`                int(11) NOT NULL auto_increment,
    `author_id`         varchar(60),
    `name`              varchar(250),
    `address`           varchar(1500),
    `email`             varchar(250),
    `institution`       varchar(250),
    `web_page`          text,
    `papers`            int(11),
    `supervised`        int(11),
    PRIMARY KEY         (`id`),
    KEY                 (`author_id`)
    ) ENGINE=MyISAM;

LOAD DATA LOCAL INFILE '[DIR]/data_dump.persons'
INTO TABLE wb_author
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(author_id, name, address, email, institution, web_page, papers, supervised);

LOAD DATA LOCAL INFILE '[DIR]/data_dump.authors'
INTO TABLE wb_author
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(author_id, name, address, email, institution, web_page, papers, supervised);

DROP TABLE IF EXISTS wb_paper;

CREATE TABLE `wb_paper` (
    `id`                int(11) NOT NULL auto_increment,
    `paper_id`          varchar(60),
    `author_id`         varchar(60),
    `author_pos`        varchar(60),
    `type`              varchar(60),
    `citation`          text,
    PRIMARY KEY         (`id`),
    KEY                 (`paper_id`),
    KEY                 (`author_id`)
    ) ENGINE=MyISAM;

LOAD DATA LOCAL INFILE '[DIR]/data_dump.papers'
INTO TABLE wb_paper
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(paper_id, author_id, author_pos, type, citation);

DROP TABLE IF EXISTS wb_address;

CREATE TABLE `wb_address` (
    `id`                int(11) NOT NULL auto_increment,
    `address`           varchar(1500),
    `valid_address`     varchar(1500),
    `status`            varchar(10),
    `accuracy`          int(2),
    `latitude`          double,
    `longitude`         double,
    PRIMARY KEY         (`id`),
    KEY                 (`address` (200))
    ) ENGINE=MyISAM;

LOAD DATA LOCAL INFILE '[DIR]/all_addresses.txt.ok'
INTO TABLE wb_address
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(address, valid_address, status, accuracy, latitude, longitude);

DROP TABLE IF EXISTS wb_by_paper;

CREATE TABLE `wb_by_paper` (
    `id`                int(11) NOT NULL auto_increment,
    `paper_id`          varchar(60),
    `type`              varchar(60),
    `author_pos`        varchar(60),
    `citation`          text,
    `author_id`         varchar(60),
    `name`              varchar(250),
    `address`           varchar(1500),
    `institution`       varchar(250),
    `papers`            int(11),
    `supervised`        int(11),
    `accuracy`          int(2),
    `latitude`          double,
    `longitude`         double,
    `longitude_shift`   double,
    PRIMARY KEY         (`id`),
    KEY                 (`paper_id`),
    KEY                 (`author_pos`),
    KEY                 (`papers`),
    KEY                 (`supervised`),
    KEY                 (`accuracy`),
    KEY                 (`latitude`),
    KEY                 (`longitude`)
    ) ENGINE=MyISAM;

INSERT INTO `wb_by_paper`
(paper_id, type, author_pos, citation, author_id, name, address, institution,
papers, supervised, accuracy, latitude, longitude)
SELECT 
pa.paper_id, pa.type, pa.author_pos, pa.citation, 
pa.author_id, au.name, au.address, au.institution, au.papers, au.supervised,
ad.accuracy, ad.latitude, ad.longitude
FROM 
wb_paper pa
LEFT JOIN wb_author au ON (au.author_id = pa.author_id)
LEFT JOIN wb_address ad ON (ad.address = au.address);

DROP TABLE IF EXISTS wb_by_person;

CREATE TABLE `wb_by_person` (
    `id`                 int(11) NOT NULL auto_increment,
    `person_id`          varchar(60),
    `name`               varchar(250),
    `address`            varchar(1500),
    `institution`        varchar(250),
    `papers`             int(11),
    `papers_rounded`     varchar(10),
    `supervised`         int(11),
    `supervised_rounded` varchar(10),   
    `accuracy`           int(2),
    `latitude`           double,
    `longitude`          double,
    `longitude_shift`    double,
    PRIMARY KEY          (`id`),
    KEY                  (`papers`),
    KEY                  (`papers_rounded`),
    KEY                  (`supervised`),
    KEY                  (`accuracy`),
    KEY                  (`latitude`),
    KEY                  (`longitude`)
    ) ENGINE=MyISAM;

INSERT INTO `wb_by_person`
(person_id, name, address, institution,
papers, supervised, accuracy, latitude, longitude)
SELECT 
au.author_id, au.name, au.address, au.institution, au.papers, au.supervised,
ad.accuracy, ad.latitude, ad.longitude
FROM 
wb_author au
LEFT JOIN wb_address ad ON (ad.address = au.address)
WHERE 
au.author_id LIKE "Person%";

UPDATE wb_by_person SET papers_rounded="No"     WHERE papers IS NULL OR  papers =0;
UPDATE wb_by_person SET papers_rounded="1-5"    WHERE papers >=1     AND papers <=5;
UPDATE wb_by_person SET papers_rounded="6-25"   WHERE papers >=6     AND papers <=25;
UPDATE wb_by_person SET papers_rounded="26-125" WHERE papers >=26    AND papers <=125;
UPDATE wb_by_person SET papers_rounded="> 126"  WHERE papers >=126;

UPDATE wb_by_person SET supervised_rounded="Mentor"   WHERE supervised IS NOT NULL AND supervised > 0;
UPDATE wb_by_person SET supervised_rounded="Student"  WHERE supervised IS NULL     OR  supervised = 0;

DROP TABLE IF EXISTS wb_by_person2;

CREATE TABLE `wb_by_person2` (
    `id`                 int(11) NOT NULL auto_increment,
    `person_id`          varchar(60),
    `name`               varchar(250),
    `address`            varchar(1500),
    `institution`        varchar(250),
    `papers`             int(11),
    `papers_rounded`     varchar(10),
    `supervised`         int(11),
    `supervised_rounded` varchar(10),   
    `accuracy`           int(2),
    `latitude`           double,
    `longitude`          double,
    `longitude_shift`    double,
    PRIMARY KEY          (`id`),
    KEY                  (`papers`),
    KEY                  (`papers_rounded`),
    KEY                  (`supervised`),
    KEY                  (`accuracy`),
    KEY                  (`latitude`),
    KEY                  (`longitude`)
    ) ENGINE=MyISAM;

INSERT INTO wb_by_person2 SELECT * FROM wb_by_person;

