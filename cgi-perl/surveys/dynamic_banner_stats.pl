#!/usr/bin/perl 

use strict;

my $RESPONSES = '/usr/local/wormbase/logs/2007_wormbase.log';

open IN,$RESPONSES;
while (<>) {




    open IN,SURVEY_STATS_COUNTRIES;
    my @countries = (<IN>);
    close IN;
    push @countries,param('country_of_access');

    my %countries_seen = map {$_++} @countries;
    
    open OUT,>SURVEY_STATS_COUNTRIES;
    print OUT,join("\n",@countries);
    close OUT;
    
    
    open IN,SURVEY_STATS_JOBS;
    my @jobs = (<IN>);
    close IN;
    
    push @jobs,param('job_description');
    my %jobs_seen = map {$_++} @jobs;
        
    open OUT;
    print OUT,join("\n",@jobs),"\n";
    close OUT;
    
    # Create the SSI banner
    
