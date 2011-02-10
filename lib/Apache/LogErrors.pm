package Apache::LogErrors;
use strict;

use Apache::Constants qw(:common :http);
use Apache::File;
use CGI qw(:standard *div);
use ElegansSubs qw(:DEFAULT Banner Footer);
use Ace::Browser::AceSubs 'Configuration','Style';
use Time::Format;
use Date::Manip;
use vars qw/$timestamp/;

use constant RECIPIENT => 'Todd Harris <harris@cshl.edu>';
use constant ERROR_LOG => '/usr/local/wormbase/logs/error_log';

$timestamp   = timestamp();

sub handler {
  my $r = shift;
 #  return DECLINED unless $r->content_type eq 'text/html';

  $r->content_type('text/html; charset=ISO-8859-1');
  $r->send_http_header;
  my ($status) = $r->status;
  if ($status == 404 || $status == 500) {
      print_response($status);
  } else {
      handle_email_query($status);
  }
#  return OK;
}

sub print_response {
    my ($status) = shift;

    my $uri = $ENV{REDIRECT_URL} || $ENV{REQUEST_URI} || $ENV{REDIRECT_REQUEST_URI};
    
    my $title;
    if ($status == 404) {
	$title = " $uri";
    }
    
    print start_html(-title=>"WormBase: $status $title",
		     -style=>Style());
    print Banner();
    print start_div({-style=>'width:60%;margin-left:auto;margin-right:auto'});
    
    my ($content);
    if ($status == 404) {
	$content = $uri;
	print h1("Oops!  We can't find that file");
        print p("The document you requested ($content) could not be found.  Please use your browser's
                 back button, or return to the <a href=\"/\">main WormBase page</a>.");
    } elsif ($status == 500) {
	$content = `tail -10 /usr/local/wormbase/logs/error_log`;	
	print h1("Oops! A server error just occurred");
	print p("We're terribly sorry, but an internal server error has occurred.");
    }
    
    print p("The WormBase team has been notified of the problem and we are already working to resolve the issue.");
        
#    print p('To be notified when this is problem is resolved, send us your email address. Rest assured, we will keep it private and only contact you when the problem is resolved.',
#	    p(start_form(-action => '/errors/request_processed',-method=>'post'),
#	      textfield({-name=>'email',-size=>'25'}),
#	      hidden({-name=>'status',-value=>$status}),
#	      hidden({-name=>'time',-value=>$timestamp}),
#	      submit(),end_form()));
    print end_div();
    print Footer();

#    email_error($status,$content,undef) unless $status == 404;  # too many emails!
    log_error($status,$content,undef);
}


sub handle_email_query {
    my $status = shift;
    # These vallues are passed by the first invocation
    # This makes it easier to match up timestamps
    my $time   = param('time');
    my $email  = param('email');
    my $status = param('status');
    my $comment = param('comment');

    # The byline here should be the actual apache error message.
    
    email_error($status,undef,$email) if $email;
    print start_html(-title=>'Request for notification: received',
	       -style=>Style());
    print Banner();
    print start_div({-style=>'width:60%;margin-left:auto;margin-right:auto'});
    print h1("We'll keep you posted");
    print p("We're terribly sorry you've encountered a problem."),
    p("We've already been notified of the problem and we'll let you know as soon as it is fixed."),
    p('Sincerely,'),
    p(i('-- The WormBase Consortium'));
    
    print Footer();
}


sub email_error {
    my ($status,$content,$from) = @_;
    my $hostname    = get_hostname();
    my $ua          = $ENV{HTTP_USER_AGENT};
    my $remote_addr = $ENV{REMOTE_ADDR};
    my $remote_host = $ENV{REMOTE_HOST};
    my $recipient   = RECIPIENT;
    
    my $subject;
    if ($status == 404) {
	$subject = "$status error on $hostname: $content";
    } elsif ($status == 500 && ! $from) {
	$subject = "$status error on $hostname";
    } else {
	$subject = 'Help desk: request for resolution';
    }

    $from         ||= RECIPIENT;

    # Fetch the correct IP passed along by squid
    my $ip = $ENV{HTTP_X_FORWARDED_FOR} || $ENV{REMOTE_ADDR};

    open (MAIL,"| /usr/lib/sendmail -t") or die ("Cannot open sendmail for email alert!");
    print MAIL <<END;
From: $from
To: $recipient
Subject: $subject

status     : $status
timestamp  : $timestamp
hostname   : $hostname ($ip)

Error:
$content

remote host : $remote_host ($remote_addr)
user agent  : $ua

END
    close MAIL or die "Cannot close sendmail: $!";
    }


sub log_error {
    my ($status,$byline) = @_;
    my $query;
    open OUT,">>/usr/local/wormbase/logs/errors/$status.log" or return;
    my $timestamp = timestamp();
    # Fetch the correct IP passed along by squid
    my $remote_addr = $ENV{HTTP_X_FORWARDED_FOR} || $ENV{REMOTE_ADDR};
    print OUT "[$timestamp]\t$remote_addr\t$byline\n";
    close OUT;
}


sub timestamp {
    my $time = time();
    return time_format('dd/Mon/yyyy:hh:mm:ss tz', $time);
}


sub get_hostname {
  my $hostname = `hostname` or die "Cannot determine hostname!\n";
  chomp $hostname;
  return $hostname;
}






1;
