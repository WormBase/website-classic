#!/bin/env perl

#this is the server that runs on the web server and serves as the
#proxy between the client and the backend.

use lib '/home/henry/usr/lib/perl5/site_perl/5.8.8';
use lib '.';

use JSON::RPC::Server::CGI;
#abc
my $server = JSON::RPC::Server::CGI->new;
$server->content_type('text/javascript');

#$server->content_type('application/json');
$server->dispatch('cisortho_relay')->handle();

#use Data::Dumper;
#warn Dumper $server->cgi;
