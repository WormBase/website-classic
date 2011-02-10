#!/usr/bin/perl

# This script tests a variety of cgi scripts at wormbase
# looking for errors.  Although it tries to trap
# and report on those errors when they happen, it
# may also be useful to monitor the logs when they are running.

# Approach:
# Provided with a list of classes, use ElegansSubs and elegans.pm
# to direct the classes to the appropriate displays

use strict;
use WWW::Mechanize;
use HTML::TokeParser;
use Ace;

# URL Mapper
use lib '/usr/local/wormbase/conf';
use elegans;

use Ace::Browser::SiteDefs;

use CGI qw/:standard/;

use constant BASE  => 'http://dev.wormbase.org';
#use constant BASE  => 'http://localhost';
use constant ACEDB => '/usr/local/acedb/elegans';
# A fragment of the WormBase query string
use constant ERROR => 'The server encountered an internal error';
use constant LIMIT => 200;  # Set limit to 0 to test all objects. Not recommended
$|++;

my $CONFIG = Ace::Browser::SiteDefs->getConfig('elegans');


#_load('/usr/local/wormbase/conf/elegans.pm');

my $agent = WWW::Mechanize->new(agent=>'WormBase Bug Squasher (by Class), v0.1');
my $DB = Ace->connect(-path=>ACEDB) or die "Couldn't open local database: $!";
# Fetch all available visible classes from the database
my @CLASSES = $DB->classes(1);

foreach my $class (sort {$a cmp $b } @CLASSES) {
  print STDERR "Testing class: $class\n";
  my $data = {};
  my $limit = (LIMIT > 0) ? LIMIT : $DB->count($class => '*');
  
  my $i = $DB->fetch_many($class => '*');

  my ($directed_to,$c);
  while (my $object = $i->next) {
    $c++;
    if ($c == $limit + 1) {
      print STDERR "\n";
      last;
    }
    warning($c,$class,$object,$limit);
    my $url = Object2URL($object);
    do_query($url);
    my $display = url(-relative=>1);
    my ($display,$result) = map_url($display,$object);
    $directed_to = $CONFIG->display($display,'url');
    
    my ($flag,$message,$response) = check_response();	
    push (@{$data->{$message}},BASE . "$url");
    $data->{requests}++;
    $data->{success}++ if ($flag == 1);
    $data->{failure}++ if ($flag == 0);
  }
  generate_class_report($data,$class,$directed_to);
}


sub do_query {
  my $url = shift;
  my $query = BASE . "$url";
  $agent->get($query);
}


# Did the page load okay?
sub check_response {
  # Maybe we couldn't even fetch the page
  return (0,"Couldn't fetch page",$agent->response->status_line) unless $agent->success;
#  warn $agent->content;

  # Perhaps the page loaded OK, but an error message was sent to the browser.
  # The error message could be the custom error message. But sometimes the
  # apache error message trickles through
  # In general, let's look for something that looks like this:
  # [Thu Dec 11 17:07:53 2003]
  # [Thu Dec 11 17:07:53 2003] [error]

  my $content = $agent->content;
  my $error = ERROR;
  if ($content =~ /$error/ || $content =~ /\[error\]/) {
    return (0,'Internal error',$agent->response->status_line);
  }
  return (1,'Success',$agent->response->status_line);
}


sub generate_class_report {
  my ($data,$class,$directed_to) = @_;

  # Print out some summary information for the classes
  print "-----------------------------------------------\n";
  print "Class : $class\n";
  print "URL  : $directed_to\n";
  unless ($data->{requests} > 0) {
    print "No objects in database\n";
    return;
  }
  printf ("\t%-15s %-15s %-15s %-15s\n",'Requests','Success','Fail','% Successful');
  printf ("\t%-15s %-15s %-15s %-15s\n",$data->{requests},$data->{success}||0,$data->{failure}||0,
	  (($data->{success}/$data->{requests}) * 100));

  bad_requests($data);
  print "\n";
}


sub bad_requests {
  my $data = shift;
  return unless (eval {@{$data->{"Couldn't fetch page"}} } || eval { @{$data->{'Internal error'}}});
  print "\t---------------\n";
  print "\tfailed urls:\n";
  foreach my $error ("Couldn't fetch page","Internal error") {
    print map {"\t$error\t$_\n"} eval { @{$data->{$error}} };
  }
}



sub warning {
  my ($c,$class,$obj,$limit) = @_;
  print STDERR "\t...testing $c of $limit: $obj...";
  # print STDERR -t STDOUT && !$ENV{EMACS} ? "\r" : "\n";
  print STDERR -t STDERR && !$ENV{EMACS} ? "\r" : "\n";
}




sub Object2URL {
  my ($name,$class) = @_;
  my $display = url(-relative=>1);
  my ($disp,$parameters) = map_url($display,$name,$class);
  return $disp unless $parameters;
  return Url($disp,$parameters);
}


sub map_url {
  my ($display,$name,$class) = @_;
  $class ||= $name->class if ref($name) and $name->can('class');
  my (@result,$url);
  if (my $code = $CONFIG->Url_mapper) {
    if (@result = $code->($display,$name,$class)) {
      return @result;
    }
  }
  
  # if we get here, then take the first display
  my @displays = $CONFIG->displays($class,$name);
  push @displays,$CONFIG->displays('default') unless @displays;
  my $n = CGI->escape($name);
  my $c = CGI->escape($class);
  return ($displays[0],"name=$n;class=$c") if $displays[0];
  
  return unless @result = $CONFIG->Url_mapper->($display,$name,$class);
  return unless $url = $CONFIG->display($result[0],'url');
  return ($url,$result[1]);
}


sub Url {
  my ($display,$parameters) = @_;
  my $url = $CONFIG->display($display,'url');
  return ResolveUrl($url,$parameters);
}


sub ResolveUrl {
  my ($url,$param) = @_;
  my ($main,$query,$frag) = $url =~ /^([^?\#]+)\??([^\#]*)\#?(.*)$/ if defined $url;
  $main ||= '';
  $main .= "?$query" if $query; # put the query string back
  $main .= "?$param" if $param and !$query;
  $main .= ";$param" if $param and  $query;
  $main .= "#$frag" if $frag;
  return $main;
}
