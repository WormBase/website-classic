#!/usr/bin/perl

=pod

update_cshl_mirror.pl

Slightly misnamed, this script is used to update the live site, blast
server, and aceserver.  It does this by mirroring databases from the
development server.

Please see http://www.wormbase.org/docs/SOPs/updating_wormbase.html
for a full outline of the update procedure.

=cut

use strict;
use Carp;
use File::Path 'rmtree';
require '/usr/local/wormbase/conf/localdefs.pm';

my $release = shift or die "usage: update_cshl_mirror.pl WSXX\n";

# Set the umask for future invocations
# Is this appropriate for mysql databases?
umask(022);

# initial setup
my $WS           = $release;
my $HOST         = 'brie3.cshl.org';
my $PRIMARY_HOST = 'brie6.cshl.org';  # NO, instead we will rysnc to brie3 - the dev version, which should be up-to-date

# read passwords from LocalDefs.pm
my $acepass   = $main::ACEPASS or die 'put $ACEPASS into localdefs.pm';
my $mysqlpass = $main::MYSQLPASS or die 'put $MYSQLPASS into localdefs.pm';
my $aceserver_only = $main::ACESERVER;
my $site      = $main::MIRROR or warn 'The mirror variable should describe the machine...';

$ENV{RSYNC_RSH} =  'ssh';

## copy acedb directories
#chdir '/usr/local/acedb';
#rsync("$HOST\:/usr/local/acedb/elegans_$WS .");

# This was conditionally excluded for the
# aceserver. This is NOT correct - aceserver
# requires a full update, too.
#unless ($aceserver_only) {

#unless ($site eq 'BlastServer' || $site eq 'Open Aceserver') {
#  # copy ftp directories
#  my $ftp = homedir('ftp');
#  chdir "$ftp/pub";
#  rsync("--exclude='database_tarballs' --exclude='briggsae-for-mirrors' $HOST\:$ftp/pub/wormbase .");
#}

# copy BLAST directories
# excluding .tar.gz archives for space reasons
#chdir '/usr/local/wormbase';
#rsync("--exclude='*.tar.gz' $HOST\:/usr/local/wormbase/blast .");
#
## copy BLAT directories
#chdir '/usr/local/wormbase';
#rsync("$HOST\:/usr/local/wormbase/blat .");

## restart blat server
#for my $pair ([''               => 2003],
#	      ['briggsae/files' => 2004]) {
#    my ($files,$port) = @$pair;
#    my $blat_server   = "/usr/local/wormbase/blat/$files";
#    system ("/usr/local/blat/bin/gfServer stop localhost $port") ;
#    system ("/usr/local/blat/bin/gfServer start localhost $port $blat_server/*.nib &");
#    system ("rm $blat_server/*.dna");
#}

## copy mirrored directories
#unless ($site eq 'BlastServer' || $site eq 'Open Aceserver') {
#  chdir '/usr/local/wormbase/html/';
#  rsync("$HOST\:/usr/local/wormbase/html/chromosomes\* .");
#  #  rsync("$HOST\:/usr/local/wormbase/html/mirrored_data .");
#  rsync("$HOST\:/usr/local/wormbase/html/release_notes .");
#}

# copy mysql directories
# NOTE: had to make mysql var directory group writable and add myself
# to the mysql group -- eventually put this in a sgid perl script?
#my $mysql = homedir('mysql');
#$mysql = '/usr/local/var' if ($aceserver_only);
#chdir $mysql;
#croak("The $mysql directory isn't writable!") unless -w '.';
#for my $db (qw(briggsae elegans elegans_pmap)) {
#    rsync("--exclude='*_bak.*' $HOST\:/usr/local/mysql/var/$db/ $db.new/");
#    system <<"END" and die "Couldn't rearrange $db directories: $!\n";
#    rm -rf $db.old
#	mv $db.live $db.old
#	mv $db.new $db.live
#	mysqladmin -uroot -p$mysqlpass refresh
#END
#;
#}

# update acedb links
#my $acedb = homedir('acedb');
#chdir $acedb;
#system <<"END" and die "Couldn't fix acedb symbolic link: $!\n";
#rm elegans
#ln -sf elegans_$WS elegans
#END

## restart ace server
#system "ace.pl -port 2005 -user admin -pass $acepass -e 'shutdown now'";

# clear the cache
#chdir '/usr/local/wormbase/cache';
#my @remove;
#opendir(D,'.') or die "/usr/local/wormbase/cache: $!";
#while (my $f = readdir(D)) {
#  next unless -d $f;
#  next if $f eq 'README';
#  next if $f eq 'CVS';
#  next if $f =~ /^\./;
#  push @remove,$f;
#}
#closedir D;
#rmtree(\@remove,0,0);

## If this is the aceserver or the blastserver, rsync the software to brie6
#chdir('/usr/local/wormbase');
#rsync("$HOST\:/usr/local/wormbase/ .");

# send out notification
system '/usr/local/wormbase/update_scripts/notify.pl' if $main::MASTER;

print "DONE!\n";


sub homedir {
  my $user = shift;
  my $dir  = (getpwnam($user))[7];
  $dir or die "Unknown user $user\n";
  $dir;
}

sub rsync {
  my $fromto = shift;
  warn "copying $fromto\n";
#  my $status = system "rsync -Cavz $fromto";
  my $status = system "rsync -Cav $fromto";  # "z" flag has been giving problems!
  return if $status == 0;
  return if $status >> 8 == 23;  # various can't set permission errors
  croak("Couldn't run rsync: status code = ",$status>>8);
}
