#!/usr/bin/perl

use strict;

use constant ELEGANS  => '/usr/local/acedb/elegans';
use constant RELEASENOTES => '/usr/local/wormbase/html/release_notes';

my $real  = readlink(ELEGANS) or die "Can't read link: $!";
my ($release) = $real=~ /elegans_(WS\d+)/;
send_notification(RELEASENOTES,$release);

sub send_notification {
  my $dir = shift;
  my $release = shift;
  my $file = "$dir/letter.$release";
  return unless -e $file;
  warn("sending out announcement\n");
  open (MAIL,"| /usr/lib/sendmail -oi -t") or return;
  print MAIL <<END;
From: "WormBase" <wormbase\@wormbase.org>
To: wormbase-announce\@wormbase.org, wormbase\@wormbase.org
Subject: WormBase release $release now online

This is an automatic announcement that WormBase
(http://www.wormbase.org) has just been updated.  New releases occur
roughly every three weeks.

The text of the AceDB release notes, which contains highlights of the
new data is attached.  You can download the full AceDB files from:

   ftp://ftp.sanger.ac.uk/pub/wormbase/current_release/
   or
   ftp://ftp.wormbase.org/pub/wormbase/elegans/current_release

END
;

  foreach ($file) {
    open (F,$_) or next;
    while (<F>) { print MAIL $_; }
  }
  close F;
  close MAIL;
}
