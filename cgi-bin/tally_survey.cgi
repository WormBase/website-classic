#!/usr/bin/perl

use CGI 'header',':html';
use CGI::Carp 'fatalsToBrowser';

use strict;
use constant SURVEY_FILE => '/usr/tmp/elegans_survey/survey.txt';

my $q = new CGI;
my $fh = new Locker(SURVEY_FILE) 
  || die "Can't get lock on questionnaire answer file.  Please try again later.\n";
print $fh "HOST=",$q->remote_host,"\n";
print $fh "REFERER=",$q->referer,"\n";
print $fh "DATE=",scalar localtime,"\n";
$q->save($fh);

print header(),
  start_html('WormBase Survey Acknowledgement'),
  h1('Thank You'),
  p('Your questionnaire has been filed.  Your answers will help make WormBase a better service',
    'for the research community.'),
  hr,
  p(a({-href=>'http://www.wormbase.org'},'WormBase Home Page')),
  end_html;

package Locker;

use IO::File;
use Fcntl qw(:flock O_WRONLY O_APPEND);

sub new {
  my $class = shift;
  my $file = shift;
  my $fh = IO::File->new($file,O_WRONLY|O_APPEND) 
    || die "Can't open questionnaire answer file: $!\n";
  my $counter = 10;
  while ($counter--) {
    last if flock($fh,LOCK_EX|LOCK_NB);
    sleep 1;
  }
  return unless $counter;
  return bless $fh,$class;
}
