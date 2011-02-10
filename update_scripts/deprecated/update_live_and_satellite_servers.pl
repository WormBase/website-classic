#!/usr/bin/perl

=pod

=head1 NAME

update_live_and_satellite_servers.pl - maintain WormBase satellite servers

=head1 DESCRIPTION

update_live_and_satellite_servers.pl serves dual functions:

1. Update the primary WormBase server to a new release of the
database.

2. Keep WormBase satellite servers in sync with the primary server.

=head1 USAGE

 % update_live_and_satellite_servers.pl [username]

Depending on which server the script is executed on, the script will
automatically determine which version of the database it should sync
to and from which host.  No other configuration options are supported.

If running with super-user privileges, you may specify a username.
This will be used to establish the rsync connection through an SSH
tunnel.

=head1 1. Updating the primary server with a new release

update_live_and_satellite_servers.pl updates the primary server by copying
databases and files from the current release on the development
server.  It performs the following steps:

 - analyze logs
 - rsync acedb
 - rsync ftp
 - rsync misc
 - rsync mysql
 - rysnc blast/blat
 - update acedb symlink
 - clear cache
 - restart sgiface
 - restart httpd
 - send notification

update_live_and_satellite_servers.pl SHOULD NOT be run under cron on the primary
server (unless you want to automatically mirror development versions
onto the live site)!

=head1 2. Keeping WormBase satellite servers in sync

update_live_and_satellite_servers.pl keeps WormBase satellite servers in sync by
syncing to the current version on the primary live site.  It performs
the following steps for these servers (each described below):

 - rsync acedb
 - rsync mysql
 - update acedb symlink
 - clear cache
 - restart blat
 - restart httpd
 - restart sgiface

=head1 Running under cron (on satellite servers ONLY)

update_live_and_satellite_servers.pl is intended to be run under cron on
satellite servers only.  This will ensure that any bug fixes migrated
onto the live site are automatically migrated onto the satellite
servers in a timely basis. A suggested cron entry -- updating these
servers every 8 hours, is as follows:

0 2,10,6 * * * /usr/local/wormbase/update_scripts/update_satellite_servers.pl

Please see http://www.wormbase.org/docs/SOPs/updating_wormbase.html
for a full outline of the update procedure.

=cut

use strict;
use Bio::GMOD::Update;
use Bio::GMOD::Util::CheckVersions;
use Carp;
use File::Path 'rmtree';
require '/usr/local/wormbase/conf/localdefs.pm';

# Fetch the currently installed version on the live site.
my $gmod     = Bio::GMOD::Util::CheckVersions->new(-mod => 'WormBase');

# The primary server will sync to the current development version
my %dev_version = $gmod->development_version() or die "Cannot discern the current development version\n";
my $dev_version  = $dev_version{version};

# Satellite servers will sync to the current live version
my %live_version = $gmod->live_version() or die "Cannot discern the current live version\n";
my $live_version = $live_version{version};

# The locally installed version
my %local_version = $gmod->local_version() or die "Cannot discern the locally installed version\n";
my $local_version = $local_version{version};

# Set the umask for future invocations
# Is this appropriate for mysql databases?
umask(022);

$ENV{RSYNC_RSH} =  'ssh';

my $USER             = shift;
$USER ||= 'todd';
my $DEVELOPMENT_HOST = 'brie3.cshl.org';
my $PRIMARY_HOST     = 'brie6.cshl.org';  # NO, instead we will rysnc to brie3 - the dev version, which should be up-to-date

# read passwords from LocalDefs.pm
my $acepass      = $main::ACEPASS   or die 'place $ACEPASS into localdefs.pm';
my $mysqlpass    = $main::MYSQLPASS or die 'place $MYSQLPASS into localdefs.pm';
my $is_aceserver = $main::ACESERVER;
my $site         = $main::MIRROR or print 'localdefs::$mirror is not set; assuming that we are the primary server...',"\n";

# If we are executing the script on the live site,
# move the current development version onto the live site.
if ($main::MASTER) {
  print "Upgrading the live site from $live_version to $dev_version...\n";
#  analyze_logs($live_version);  # Ha!  This is the CURRENT live version when executed on the live site
  rsync_acedb($DEVELOPMENT_HOST,$dev_version);
  rsync_ftp($DEVELOPMENT_HOST);
  rsync_misc($DEVELOPMENT_HOST);
  rsync_mysql($DEVELOPMENT_HOST);
  rsync_blast_blat($DEVELOPMENT_HOST);

  update_acedb_symlink($dev_version);
  # restart_blat();
  clear_cache();
  reset_squid_cache();
  restart_sgiface();
  restart_httpd();
  send_notification();
  print "The live site has been successfully upgraded to $dev_version...\n";
  exit;
}



# Satellite servers like the blast.wormbase.org and aceserver.cshl.org)
# We'll only do some of these steps if necessary
if ($site eq 'BlastServer' || $site eq 'Open Aceserver') {
  if ($live_version eq $local_version) {
     print "Database up-to-date...\n";
     print "Syncing the satellite server $site to $PRIMARY_HOST...\n";
  } else {
     print "Upgrading the satellite server $site from $local_version to $live_version...\n";
  }
  unless ($live_version eq $local_version) {
    rsync_acedb($PRIMARY_HOST,$live_version);
    update_acedb_symlink($live_version);
    rsync_mysql($PRIMARY_HOST);
    rsync_blast_blat($PRIMARY_HOST);
  }

  # rsync the software regardless
  rsync_software($PRIMARY_HOST);

  if ($live_version eq $local_version) {
     print "The satellite server $site has been synced to the live site...\n";
     exit;
  };

  unless ($live_version eq $local_version) {
    clear_cache();
    restart_blat();
    restart_sgiface();
    restart_httpd();
  }
  print "The satellite server $site has been successfully upgraded to $live_version...\n";
}

#####################################################
#  BEGIN SUBS
#####################################################

# Analyze logs fot the current release
sub analyze_logs {
  my $version = shift;
  # Let's exec instead of system so we don't have to wait around
  exec("/usr/local/wormbase/util/log_analysis/analyze_logs.sh $version www.wormbase.org");
  # restart httpd to create the new logs
  restart_httpd();
}

# rsync the appropriate acedb database
# Maybe this should just be scp?
sub rsync_acedb {
  my ($host,$version) = @_;
  chdir '/usr/local/acedb';
  rsync("--exclude='oldlogs/' --exclude='serverlog*' --exclude='log.wrm' $host\:/usr/local/acedb/elegans_$version .");
}

# rsync ftp directories (only necessary for the primary server)
sub rsync_ftp {
  my $host = shift;
  my $ftp = homedir('ftp');

  my @exclude = (#'database_tarballs/',
		 'briggsae-for-mirrors/'
		);
  my $exclude = format_exclude(\@exclude);

  chdir "$ftp/pub";
  rsync("$exclude $host\:$ftp/pub/wormbase .");
}

# rsync the blast and blat directories (only necessary for primary server)
# (and even then, not really required)
sub rsync_blast_blat {
  my $host = shift;
  # excluding .tar.gz archives for space reasons
  my @exclude = ('*.tar.gz',
		 'old_nib/'
		);
  my $exclude = format_exclude(\@exclude);

  chdir '/usr/local/wormbase';
  rsync("$exclude $host\:/usr/local/wormbase/blast .");

  # rsync BLAT directories
  chdir '/usr/local/wormbase';
  rsync("$exclude $host\:/usr/local/wormbase/blat .");
}

# rsync the mysql databases
# NOTE: User executing the script must be part of the mysql group
# and the mysql data directory needs to be group writable
# aceserver has a different directory structure.  Symlink?
sub rsync_mysql {
  my $host = shift;
  # mysql data dirs.  Ugh.
  #  brie6 => '/usr/local/var',
  #  brie3 => '/usr/local/mysql/var';
  #  aceserver => '/usr/local/var';
  #  blast     => '/usr/local/mysql/data';

  # The local data dir
  my $local_data_dir = '/usr/local/var';

  # The remote data dir is either on brie3 (for updating brie6), or on brie6 (for updating satellites)
  my $remote_data_dir = ($main::MASTER) ? '/usr/local/mysql/var' : '/usr/local/var';
  chdir($local_data_dir);
  croak("The $local_data_dir directory isn't writable!") unless -w '.';
#  for my $db (qw(briggsae elegans elegans_pmap)) {
   for my $db (qw(elegans)) {
    rsync("--exclude='*_bak.*' $host\:$remote_data_dir/$db/ $db.new/");
    system <<"END" and die "Couldn't rearrange $db directories: $!\n";
    rm -rf $db.old
	mv $db.live $db.old
	mv $db.new $db.live
	mysqladmin -uroot -p$mysqlpass refresh
END
;
  }
}

# copy some miscellaneous files (primary server only)
sub rsync_misc {
  my $host = shift;
  chdir '/usr/local/wormbase/html/';
  rsync("$host\:/usr/local/wormbase/html/chromosomes\* .");
  rsync("$host\:/usr/local/wormbase/html/release_notes .");
}

# rsync the software, excluding specific configuration files and
# tarballs for space reasons
sub rsync_software {
  my $host = shift;
  my @exclude = ('logs/',
		 'localdefs.pm',
		 'httpd.conf',
		 'blast.*.tar.gz',
		 'blat',
		 'cache/',
		 'tmp/');
  my $exclude = format_exclude(\@exclude);
  my $update = Bio::GMOD::Update->new(-mod=>'WormBase');
  $update->rsync_software(-module       => 'wormbase-live',
			  -exclude      => $exclude,
			  -install_root => '/usr/local/wormbase/',
			 );

  #  chdir('/usr/local/wormbase');
  #  rsync("$exclude $host\:/usr/local/wormbase/ .");
}

sub format_exclude {
  my $list = shift;
  my $exclude = join(" ",map {"--exclude='$_'" } @$list);
  return $exclude;
}


# update acedb links
sub update_acedb_symlink {
  my $version = shift;
  my $acedb = homedir('acedb');
  chdir '/usr/local/acedb';
system <<"END" and die "Couldn't fix acedb symbolic link: $!\n";
rm elegans
ln -s elegans_$version elegans
END
}

# clear the cache
sub clear_cache {
  chdir '/usr/local/wormbase/cache';
  my @remove;
  opendir(D,'.') or die "/usr/local/wormbase/cache: $!";
  while (my $f = readdir(D)) {
    next unless -d $f;
    next if $f eq 'README';
    next if $f eq 'CVS';
    next if $f =~ /^\./;
    push @remove,$f;
  }
  closedir D;
  rmtree(\@remove,0,0);
}

sub reset_squid_cache {
	# Purge all objects from the squid cache
	system("sudo /etc/rc.d/init.d/squid stop");
my $command = <<END;
cd /usr/local/squid/var
mv cache old_cache
mkdir cache
chown squid:squid cache
END
my $result = system($command) or die "Couldn't reset the squid cache";
system("sudo /etc/rc.d/init.d/squid resetcache");
system("sudo /etc/rc.d/init.d/squid start");
system("sudo rm -rf old_cache");
}

sub send_notification {
  # send out notification
  system "sudo -u $USER /usr/local/wormbase/update_scripts/notify.pl" if $main::MASTER;
}

# restart sgifaceserver
sub restart_sgiface {
  system "ace.pl -port 2005 -user admin -pass $acepass -e 'shutdown now'";
}

# restart the blat server
sub restart_blat {
  for my $pair ([''               => 2003],
		['briggsae/files' => 2004]) {
    my ($files,$port) = @$pair;
    my $blat_server   = "/usr/local/wormbase/blat/$files";
    system ("/usr/local/blat/bin/gfServer stop localhost $port") ;
    system ("/usr/local/blat/bin/gfServer start localhost $port $blat_server/*.nib &");
    system ("rm $blat_server/*.dna");
  }
}

sub restart_httpd {
  system("sudo /usr/local/apache/bin/apachectl restart");
}


sub homedir {
  my $user = shift;
  my $dir  = (getpwnam($user))[7];
  $dir or die "Unknown user $user\n";
  $dir;
}

sub rsync {
  my $fromto = shift;
  # Commands will be run as the appropriate user to avoid having to
  # execute rsync commands as root
  warn "copying $fromto\n";
#  my $status = system "rsync -Cavz $fromto"; 
  # This expects that the script will already been run as root/sudo
  #  my $status = system "sudo -u $USER rsync -Cav $fromto";  # "z" flag has been giving problems!
  my $status = system "rsync -Cav $fromto";  # "z" flag has been giving problems!
  return if $status == 0;
  return if $status >> 8 == 23;  # various can't set permission errors
  croak("Couldn't run rsync: status code = ",$status>>8);
}

