#!/bin/env perl

#this is the cgi server that dispatches heavy lifting routines

use Data::Dumper;

#warn Dumper \%INC;

BEGIN {
	delete $INC{"cisortho.pm"};
}


use lib '/home/henry/usr/lib/perl5/site_perl/5.8.8';
use lib '.';
use cisortho;


use JSON::RPC::Server::CGI;
#abc
my $server = JSON::RPC::Server::CGI->new;
#$server->content_type('text/javascript');

$server->content_type('application/json');

#$server->dispatch('cisortho_relay')->handle();
$server->dispatch('cisortho')->handle();
