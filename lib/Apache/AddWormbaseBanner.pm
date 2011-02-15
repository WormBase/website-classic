package Apache::AddWormbaseBanner;
# $Id: AddWormbaseBanner.pm,v 1.1.1.1 2010-01-25 15:47:30 tharris Exp $
# file Apache/AddWormbaseBanner.pm;

use strict;



#use Apache2::Const -compile => qw(constant);
use Apache2::compat;
use Apache::Constants qw(:common);
use Apache::File;

# mod_perl2
#use Apache2::RequestUtil ();
# Problems with mp2 and mod_dir: DirectoryIndex does not work.
use Apache2::Const -compile => qw(DIR_MAGIC_TYPE OK DECLINED);
use Apache2::SubRequest;


use ElegansSubs 'Banner','Footer';
use Ace::Browser::AceSubs 'Configuration','Style','OpenDatabase';

sub handler {
  my $r = shift;


  # A directory request has content-type = httpd/unix-directory
  # we check that the uri ends in a slash, since only in that case
  # do we want to redirect, and finally to avoid redirect loops
  # we only do this on the initial request.
  # You must load Apache2::SubRequest in order to run internal_redirect
    if ($r->content_type eq 'httpd/unix-directory' 
        && $r->uri =~ '/$' && $r->is_initial_req ) {
	print STDERR "Accepting Directory Request\n";
	warn "internal request";
	$r->internal_redirect($r->uri . 'index.html');
	return OK;
    }


  # We only want to serve text, xml, or directory content
  # So we decline everything else
#   if ($r->content_type && 
#       $r->content_type !~ m{^text|xml|httpd/unix-directory}io) {
#       print STDERR "Declining Request\n";
#       return DECLINED;
#   }


  # Fixup for broken mp2/mod_dire redirect to index.html
#  if ($r->handler eq 'perl-script' &&
#      -d $r->filename              &&
#      $r->is_initial_req) {
#      warn $r->filename;
#      $r->handler(Apache2::Const::DIR_MAGIC_TYPE);
#
#      return Apache2::Const::OK;
#
#  }

  return DECLINED unless $r->content_type eq 'text/html';
  -r $r->filename || return DECLINED;

  # This code handles the "If-Modified-Since" code.
  my $mtime = Configuration->modtime;
  $r->update_mtime;
  $r->update_mtime($mtime);
  $r->set_last_modified;

  my $rc = $r->meets_conditions;
  return $rc unless $rc == OK;

  my $fh = Apache::File->new($r->filename) || return DECLINED;

  my $stats;
  if ($r->filename =~ /stats/) {
    $stats++;
  }

  my $cache;
  if ($r->uri =~ /squid/) {
   $cache++;
  }

  # My pregenerated pages.
  if ($r->uri =~ /cache/) {
      $cache++;
  }
      
  $r->send_http_header;
  return OK if $r->header_only;

  my $boiler = 0; #don't show the boilerplates (header, footer)
  my $db = OpenDatabase();
  while (<$fh>) {

    if (m!</head(.*)!) {
      if (my $style = Style()) {
	$r->print(qq(<link rel="stylesheet" href="$style->{-src}">\n)) if (!$stats);
      }
    }

    #so that we can turn off the auto-added header if need be
    if ($stats || $cache) {
      $r->print($_);
      next;
    } elsif (m!<body(.*)>!i && (!m/noboiler/i)) {
      $boiler = 1;
      $r->print($_);
      $r->print(Banner($db));
      next;
    } elsif (m!</body.*>!i && $boiler) {
      $r->print( Footer());
      return OK;
    }
    $r->print($_);
  }
  return OK;
}

1;

