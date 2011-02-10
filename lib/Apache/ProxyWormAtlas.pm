package Apache::ProxyWormAtlas;
# $Id: ProxyWormAtlas.pm,v 1.1.1.1 2010-01-25 15:47:30 tharris Exp $
# file Apache/ProxyWormAtlas

use strict;

use Apache::Constants qw(:common);
use Apache::File;
use LWP::UserAgent;
use ElegansSubs 'PrintTop','Banner','Footer';
use Ace::Browser::AceSubs 'Configuration','Style';
use CGI 'start_html','end_html','pre','hr','a','br','center';

sub handler {
  my $r = shift;

  my $proxy = $r->path_info or return DECLINED;
  $proxy       =~ s!^/!http://!g;
  my $agent    = LWP::UserAgent->new;
  my $response = $agent->request(HTTP::Request->new(GET=>$proxy));
  return NOT_FOUND unless $response->is_success;

  $r->send_http_header($response->content_type);
  return OK if $r->header_only;

  unless ($response->content_type eq 'text/html') {
    $r->print($response->content);
    return OK;
  }

  local $_     = $response->content;

  # get rid of any stylesheet in there now
  if (my $style = Style()) {
    s!<link\s*rel="stylesheet".*?>!!ims;
    # add our own
    s!(</head.+?)!<link rel="stylesheet" href="$style->{-src}">$1!ims;
  }

  # insert banner
  my $banner = Banner();
  $banner    =~ s!src="/images/l.gif"!src="/images/wormatlas.jpg"!i;
  $banner    =~ s!alt="WormBase"!alt="WormAtlas"!i;
  $banner    =~ s!a href="/"!a href="http://www.wormatlas.org"!i;
  $banner    =~ s!src="/images/banner_right.*?"!src="/images/l.gif"!i;
  $banner    =~ s!alt="A Worm Image"!alt="WormBase"!i;
  s!(<body.*?>)!$1$banner!ims;

  s!(</body.*?>)!hr().center(a({-href=>$proxy},"Fetch original document from $proxy")).br.Footer()!imes;

  $r->print($_);
  return OK;
}

1;

