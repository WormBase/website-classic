#!/usr/bin/perl

# This is a simple script that maintains the rsync archives on
# dev.wormbase.org.  It is intended to be run on the development
# server which hosts the primary rsync repositories.

use strict;

use constant ARCHIVE => '/usr/local/ftp/pub/wormbase/mirror';

my $LIVE_HOST = 'brie6.cshl.org';

# The following files will be excluded from the rsync modules
# These should really be cleaned up in the source directories
my @exclude = (
               '/private/',  # Top level directory
               '*.private',  # protection of private files
               '02.wormbase.conf',
	       '*~',  # temporary files
	       'allenday/',
 	       'analog/',
	       'blast/',
	       'blat/',
	       'cache/',
	       'canaran/',
	       'chromosome*',
	       'CVS/',
	       'e-PCR.tar.gz',
               'e-PCR/',
               'elegans_gff3',
	       'fire_vectors-deprecated/',
               'gff_temp/',
	       'httpd.conf',
	       'htpass*',
	       'jack_remanei/',
 	       'largefiles/',
	       'localdefs.pm',
	       'logs/',
	       'lost+found/',
	       'mailarch/',
	       'mirrored_data/',
	       'monitor_load/',
	       'movies.bak',
               'rmagic/',
	       'servlet/',
	       'stats/',
               'stress_test/',
	       'test/',
	       'tmp',
	       '*tmp/*',
	       'tomcat/',
	       'passwd.wrm$',
 	       'serverpasswd.wrm$',
               'serverconfig.wrm$',
               'server.wrm$',
                );

$ENV{RSYNC_RSH} =  'ssh';

# Synchronize the live site
chdir ARCHIVE . '/wormbase-live';
#rsync( join(" ",map { "--exclude='$_'" } @exclude) . " --delete $LIVE_HOST\:/usr/local/wormbase/ .");
rsync( join(" ",map { "--exclude='$_'" } @exclude) . " --delete /usr/local/wormbase-production/ .");  

## Synchronize the development site
#chdir ARCHIVE . '/wormbase-dev';
#rsync( join(" ",map { "--exclude='$_'" } @exclude) . " --delete /usr/local/wormbase/ .");


sub rsync {
  my $fromto = shift;
  warn "copying $fromto\n";
#  my $status = system "rsync -Cavz $fromto";
  my $status = system "rsync -Cav --delete $fromto";  # "z" flag has been giving problems!
  return if $status == 0;
  return if $status >> 8 == 23;  # various can't set permission errors
  croak("Couldn't run rsync: status code = ",$status>>8);
}
