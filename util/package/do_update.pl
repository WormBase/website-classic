#!/usr/bin/perl

# Author: T. Harris, 3/2004

# This script handles
# 1. identifying and downloading new releases
# 2. checking out revised wormbase code
# 3. updating permissions

# Creates three logs:
# 1. Full log (STDOUT)
# 2. Error log (STDERR)
# 3. Messages (used by the progress update) ~/.wormbase/update.messages

# Under download tarballs,
# I need to add permissions for the current databases

use strict;
use Net::FTP;
use Getopt::Long;

use constant FTP_SITE      => 'dev.wormbase.org';
use constant FTP_PATH      => '/pub/wormbase/database_tarballs';
use constant FTP_LIBRARIES => '/pub/wormbase/software/macosx/libraries';
use constant ACEDB         => '/usr/local/acedb/elegans';
use constant CVS_ROOT      => ':pserver:anonymous@gorgonzola.cshl.org:/usr/local/cvs';
use constant MYSQL         => '/usr/local/mysql/data';
use constant TMP           => '/usr/local/tmp/wormbase';


# The temp directory will be created under the current user...
#my $TMP = $ENV{TMP} || $ENV{TMP_DIR} || $ENV{TMPDIR} || -d ('/tmp') ? '/tmp' : -d ('/usr/tmp') ? '/usr/tmp' : '';
#my $TMP = interpolate("~/.wormbase/downloads");
my $TMP = TMP;


my ($ftp_site,$ftp_path,$acedb_path,$cvs,$cvs_type,$mysql,$tmp,
    $desired_release,$update_only,@options);
GetOptions('ftp_site=s'    => \$ftp_site,
	   'ftp_path=s'    => \$ftp_path,
	   'tmp=s'         => \$tmp,
	   'acedb_path=s'  => \$acedb_path,
	   'release=s'     => \$desired_release,
	   'options=s'     => \@options,
	   'cvs=s'         => \$cvs,
	   'cvs_type=s'    => \$cvs_type,
	   'mysql=s'       => \$mysql,
	   'update_only=s' => \$update_only,
	  ) || die <<USAGE;
Usage: do_update.pl [options...]
  Update a WormBase installation using prebuilt database packages

 Options:
  -ftp_site   FTP site holding releases (ftp://dev.wormbase.org)
  -ftp_path   Path on FTP site to database tarballs (/pub/wormbase/database_tarballs)
  -tmp       [optional] Temporary path to download files to (/usr/local/tmp/wormbase)
  -options   [optional] Components to install. Available options are libraries,
             elegans_gff, briggsae_gff, blast_blat, and acedb databases. If not specified,
             all will be installed.
  -cvs       [optional] CVS pserver and path
  -cvs_type  [optional] (update|branch) Do a CVS update or switch to new branch.
                        Defaults to update.
  -acedb_path[optional] Full path to local acedb (/usr/local/acedb/elegans)
  -mysql     [optional] Full path to the mysql data directory (/usr/local/mysql/data)
  -release   [optional] Use the specified WSXXX release.
  -update_only [boolean] If set, only the CVS options will be executed. No files will be fetched.

Examples:
Fetch new packages and unpack, ignoring CVS updates:
 ./do_update.pl

Switch to the most recent development branch, ignoring new files
 ./do_update.pl -cvs_type branch -update_only

USAGE
;


# Defalt options
push (@options,qw/libraries elegans_gff briggsae_gff acedb blast_blat adjust_permissions/) unless (@options);
my %options = map {$_ => 1 } @options;

$ftp_site   = FTP_SITE  unless defined $ftp_site;
$ftp_path   = FTP_PATH  unless defined $ftp_path;
$cvs        = CVS_ROOT  unless defined $cvs;
$acedb_path = ACEDB     unless defined $acedb_path;
$mysql      = MYSQL     unless defined $mysql;


# Open the messages log
my $LOG_PATH = interpolate($ENV{HOME} . '/.wormbase');
my $messages = $LOG_PATH . '/update.messages';
open MESSAGES,">$messages";

logit('===========================================================',1);
logit('Updating WormBase installation');
logit('===========================================================',1);
messages("[" . localtime() . '] Starting WormBase update');

my $current_installed = get_current($acedb_path);
my $current_release   = check_for_new_release($desired_release) or die "Couldn't find a current release\n";

# Do a code update or swtich to branch...
# THIS NEEDS TO BE MORE ROBUST
do_cvs_update() if ($cvs_type eq 'update');
checkout_revision($current_release) if ($cvs_type eq 'branch');

# Is the currently installed release up-to-date?
# On my machine, the currently installed release is always more up-to-date
# than the live_release...
messages($current_release);
messages($current_installed);
if (!$desired_release && ($current_release eq $current_installed)) {
  messages("WormBase is already up to date");
  end("SUCCEEDED");
  exit 0;
}


unless ($update_only) {
  prepare_tmp_dir($current_release);
  download_acedb($current_release) if (defined $options{acedb});
  download_elegans_gff($current_release)  if (defined $options{elegans_gff});
  download_blast_blat($current_release)   if (defined $options{blast_blat});
  download_briggsae_gff($current_release) if (defined $options{briggsae_gff});
  download_libraries($current_release)    if (defined $options{libraries});
  cleanup();
}

if (defined $options{adjust_permissions}) {
  adjust_permissions() or log_death("Couldn't adjust permissions");
}

end('SUCCEEDED');
exit;


#############################################
# RELEASE CHECKING
#############################################
# Fetch the ID of the currently installed ace
sub get_current {
  messages('Checking version of currently installed Acedb');
  my $installed = `get_installed_ace.pl`;
  #  my $dir = shift;
  #  my $installed;
  #  my $realdir = -l $dir ? readlink $dir : $dir;
  #  ($installed) = $realdir =~ /(WS\d+)$/;
  #  open OUT,">$LOG_PATH/installed_ace.out";
  #  $installed = ($installed) ? $installed : 'none',"\n";
  #  print OUT $installed;
  #  close OUT;
  #  $installed or log_warn("Couldn't find a local recent release at $dir") and return;
  return $installed;
}

sub check_for_new_release {
  my $desired_release = shift;
  logit($desired_release ? "Checking for release $desired_release" : "Checking for new release");
  messages($desired_release ? "Checking for release $desired_release" : "Checking for new release");
  
  my $ftp = Net::FTP->new($ftp_site) or log_death("check_for_new_release(): Can't open $ftp_site");
  $ftp->login(anonymous => 'MacWormBase@www.wormbase.org')
    or log_death("check_for_new_release(): can't login",$ftp->message);
  
  my $release = 0;
  my $number  = 0;
  if ($desired_release) {
    $ftp->cwd("$ftp_path/$desired_release")
      or log_death("check_for_new_release(): Can't cd to release $desired_release",$ftp->message);
    $release = $desired_release;
  } else {
    my $result = $ftp->cwd("$ftp_path/live_release");
    if ($result) {
      foreach ($ftp->ls) {
	next unless /^elegans_(WS\d+).+\.tgz$/;
	$release = $1;
	last;
      }
    } else {
      log_warn("error for FTP server: ",$ftp->message,"Manually searching for newest release");
      $ftp->cwd($ftp_path);
      foreach ($ftp->dir) {
	next unless /\s+(WS(\d+))/;
	log_warn("found $1");
	next unless $number < $2;
	$release = $1;
	$number = $2;
      }
      $release or log_death("Couldn't find latest release.  Aborting\n");
      $ftp->cwd("$ftp_path/$release") 
	or log_death("check_for_new_release(): Can't cd to release $release",$ftp->message);
    }
  }
  
  $release or log_death("check_for_new_release(): can't find release name");
  $release;
}



#############################################
# Check out the corresponding code revision
# (if checkout already in place, then switch to new branch)
#############################################
sub checkout_revision {
  my $release = shift;
  #  my $cvs_pass = $ENV{PWD} . '/cvs_pass';
  # Package dependent path
  my $cvs_pass = $ENV{PWD} . '/WormBase.app/Contents/Resources/cvs_pass';
  my $command;
  if (-d "/usr/local/wormbase/CVS") {
    if ($release eq $current_installed) {
      do_cvs_update();
      return;
    } else {
      # We are trying to move to a new branch
      logit("Switching to development branch: $release");
      messages("Switching to development branch: $release");
      $command = <<END;
export CVSROOT=$cvs
export CVS_PASSFILE=${cvs_pass}

cd /usr/local/wormbase
cvs update -r $release

END
;

  }
} else {
  logit("Doing CVS checkout from code branch: $release");
  messages("Doing CVS checkout from code branch: $release");
  # Do a checkout using the provided release
  $command = <<END;
export CVSROOT=$cvs
export CVS_PASSFILE=${cvs_pass}

#echo "     - creating the WormBase directory /usr/local/wormbase..."
#mkdir -p /usr/local/wormbase
cd /usr/local/wormbase
mkdir -p /usr/local
cd /usr/local

# Check out the branch for this release
echo "     - fetching current code release ($release) from CVS server..."
cvs -d $cvs co -r $release -d wormbase wormbase-site

echo "     - moving files..."
mv wormbase-site/* .

echo "     - removing temporary directory..."
rm -rf wormbase-site

echo "     - adjusting permissions..."
sudo chgrp -R wormbase /usr/local/wormbase

END
;
}

# Need more error checking/reporting here
  my $result = system($command);
if ($result == 0) {
  messages("CVS checkout/update successful");
}

}


# Do a simple CVS update
  sub do_cvs_update {
    logit("Doing: CVS update -d");
    messages("Updating WormBase software via CVS");
    my $command = <<END;

cd /usr/local/wormbase
cvs update -d

END
;

# Need more error checking/reporting here
my $result = system($command);
  if ($result == 0) {
    messages("CVS update successful");
  }
}



#########################################################
# Download tarballs if they don't already exist locally #
#########################################################
sub prepare_tmp_dir {
  my $release = shift;
  logit("Creating temporary directory at " . TMP);
  messages("Creating directory at " . TMP);

  unless (-e TMP) {
    my $tmp = TMP;
    my $command = <<END;
mkdir -p $tmp/$release
chmod -R 0775 $tmp
END
;
  my $result = system($command);
    if ($result == 0) {
      messages("Succesfully created temporary directory");
    } else {
      log_death("Cannot make temporary directory: $!\n");
    }
  }
}

sub download_acedb {
  my $release = shift;
  my $ftp = "ftp://$ftp_site/$ftp_path/$release";
  chdir("$TMP/$release");

  if (! -e "elegans_$release.ace.tgz") {
    logit("Downloading elegans_$release.ace.tgz - the C. elegans Acedb database");
    messages("Downloading elegans_$release.ace.tgz - this will take awhile");
    system("curl -O $ftp/elegans_$release.ace.tgz")
      and log_death("Couldn't fetch elegans ace database: $!\n");
  }
  
  logit("Unpacking and installing elegans_$release.ace.tgz");
  messages("Unpacking and installing elegans $release acedb");
  chdir('/usr/local/acedb');
  system("gunzip -c $TMP/$release/elegans_$release.ace.tgz | tar xf -");
  unlink('/usr/local/acedb/elegans');
  symlink("elegans_$release",'elegans');
  # Print out the currently installed string
  open OUT,">$LOG_PATH/installed_ace.out";
  print OUT $release;
  close OUT;
}

sub download_elegans_gff {
  my $release = shift;
  my $ftp = "ftp://$ftp_site/$ftp_path/$release";
  chdir("$TMP/$release") or die;

  if (! -e "elegans_$release.gff.tgz") {
    logit("Downloading elegans_$release.gff.tgz - the C. elegans GFF database");
    messages("Downloading elegans_$release.gff.tgz - this will take awhile");
    system("curl -O $ftp/elegans_$release.gff.tgz") and log_death("Couldn't fetch elegans gff database: $!\n");
  }

  logit("Unpacking and installing elegans_$release.gff.tgz");
  messages("Unpacking and installing elegans GFF");
  system("gunzip -c elegans_$release.gff.tgz | tar xf -");
  system("mv $mysql/elegans $mysql/elegans.bak");
  system("mv elegans $mysql/elegans");
  system("rm -rf $mysql/elegans.bak");
  system("mv $mysql/elegans_pmap $mysql/elegans_pmap.bak");
  system("mv elegans_pmap $mysql/elegans_pmap");
  system("rm -rf $mysql/elegans_pmap.bak");
}

sub download_blast_blat {
  my $release = shift;
  my $ftp = "ftp://$ftp_site/$ftp_path/$release";
  chdir("$TMP/$release");
  
  if (! -e "blast.$release.tgz") {
    logit("Downloading blast.$release.tgz - the blast and blat databases");
    messages("Downloading blast.$release.tgz - this will take awhile");
    system("curl -O $ftp/blast.$release.tgz") and log_death("Couldn't fetch blast/blat databases: $!\n");
  }
  
  logit("Unpacking and installing $release.blast.tgz");
  messages("Unpacking and installing blast/blat databases");
  system("gunzip -c blast.$release.tgz | tar xf -");
  system("rm -rf /usr/local/wormbase/blat");
  system("mv blat /usr/local/wormbase/.");
  mkdir("/usr/local/wormbase/blast",0775) unless -d ("/usr/local/wormbase/blast");
  system("mv blast_$release /usr/local/wormbase/blast/.");
  unlink("/usr/local/wormbase/blast/blast");
  chdir("/usr/local/wormbase/blast");
  symlink("blast_$release",'blast');
}

sub download_briggsae_gff {
  my $release = shift;
  my $ftp = "ftp://$ftp_site/$ftp_path/$release";
  chdir("$TMP/$release");

  my $ignore_briggsae;
  if (! -e "briggsae_$release.gff.tgz") {
    # If there are no new briggsae databases
    # then we will assume they were not needed
    logit("Downloading briggsae_$release.gff.tgz - the C. briggsae GFF database");
    messages("Downloading briggsae_$release.gff.tgz - this may take awhile");
    $ignore_briggsae = system("curl -O $ftp/briggsae_$release.gff.tgz");
    messages("Couldn't fetch/no new briggsae gff database: $!, not rebuilding\n") if ($ignore_briggsae);
    messages("No new briggsae release for $release") if ($ignore_briggsae);
  }
  unless ($ignore_briggsae) {
    logit("Unpacking and installing briggsae_$release.gff.tgz");
    messages("Unpacking and installing briggsae GFF");
    system("gunzip -c briggsae_$release.gff.tgz | tar xf -");
    system("mv $mysql/briggsae $mysql/briggsae.bak");
    system("mv briggsae $mysql/briggsae");
    system("rm -rf $mysql/briggsae.bak");
  }
}

sub download_libraries {
  my $release = shift;
  my $ftp = "ftp://$ftp_site/$ftp_path/$release";
  chdir("$TMP/$release");

  my $ignore_libraries;
  if (! -e "libraries_$release.tgz") {
    logit("Downloading libraries_$release.ace.tgz - $release-specific libraries");
    messages("Downloading libraries_$release.ace.tgz");
    my $lib_path = $ftp_site . FTP_LIBRARIES;
    $ignore_libraries = system("curl -O ftp://$lib_path/libraries_$release.tgz");
    # $ignore_libraries = system("curl -O ftp://$lib_path/libraries_current.tgz");
    logit("Couldn't fetch/no new libraries for $release: $!, not rebuilding\n") if ($ignore_libraries);
    messages("No new libraries for $release") if ($ignore_libraries);
  }
  
  unless ($ignore_libraries) {
    logit("Unpacking and installing libraries_$release.tgz");
    messages("Unpacking and installing libraries");
    system("gunzip -c libraries_$release.tgz | tar xf -");
    chdir("libraries_$release");
    system("cp -r Library /Library");
    system("cp -r usr /usr");
    # Link the current blast databases
    chdir("/usr/local/blast");
    symlink('/usr/local/wormbase/blast/blast','databases');
  }
}


# This should be optional
sub cleanup {
  # If we've gotten this far, we have succeeded!
  # Clean up the temp dir
  logit("Cleaning up $TMP");
  messages("Cleaning up the temporary directory");
  # system("rm -rf $TMP/*");
}


#########################################################
# Fix permissions
#########################################################
# Adjust permissions of all the newly installed files
sub adjust_permissions {
  logit("Adjusting user and group permissions");
  messages("Adjusting user and group permissions");
  
  # Not using the root user and group names
  # my @info = getpwnam('root');

my $command = <<END;
chown -R acedb /usr/local/acedb
chgrp -R acedb /usr/local/acedb
chmod 2775 /usr/local/acedb
chown root /usr/local/acedb/bin/*
chgrp root /usr/local/acedb/bin/*

chown -R root /usr/local/wormbase
chgrp -R wormbase /usr/local/wormbase
chmod 2775 /usr/local/wormbase

mkdir -p /usr/local/wormbase/logs
chmod 2775 /usr/local/wormbase/logs

chown -R root /usr/local/wublast
chgrp -R wormbase /usr/local/wormbase
chmod 2775 /usr/local/wublast

chown -R root /usr/local/blat
chgrp -R wormbase /usr/local/blat
chmod 2775 /usr/local/blat

END
;

my $result = system($command);
  return if ($result != 0);
  return 1;
}

sub add_user_perms_to_db {
  # Configure MySQL for access to the current database
  # I should make sure that the database is running.
  # If not, start it.
  
  # This privs should be granted to the current user?
  # Granting of privs will be handled in the individual data modules
  #mysql -u root -e 'create database elegans'
  #mysql -u root -e 'create database elegans_load'
  #mysql -u root -e 'grant all privileges on elegans.* to me@localhost'
  #mysql -u root -e 'grant all privileges on elegans_load.* to me@localhost'
  #mysql -u root -e 'grant file on *.* to me@localhost'
  #mysql -u root -e 'grant select on elegans.* to nobody@localhost'
}



#########################################################
# Utilities
#########################################################
sub logit {
  my ($msg,$suppress) = @_;
  my $localtime = localtime;
  $msg =~ s/\n$//;
  if ($suppress) {
    print "$msg\n";
  } else {
    print "$localtime $msg...\n";
  }
}

sub log_death {
  my $localtime = localtime;
  my $msg = "@_";
  $msg =~ s/\n$//;
  print "$localtime $msg...\n";
  end('FAILED');
  die;
}

sub log_warn {
  my $msg = shift;
  my $localtime = localtime;
  $msg =~ s/\n$//;
  warn "$localtime $msg...\n";
}


# The messages log is used to display brief messages
# above the progress meter of the application
sub messages {
  my $msg = shift;
  print MESSAGES "$msg...\n";
}

# This is appended to the messages log to signify to the application
# that the update process has ended
sub end {
  my $msg = shift;
  print MESSAGES "__UPDATE_$msg" . "__\n";
  logit('===========================================================',1);
  logit("Updating complete: $msg");
  logit('===========================================================',1);
  close MESSAGES;
}

sub interpolate {
  my $path = shift;
  my ($to_expand,$homedir);
  return $path unless $path =~ m!^~([^/]*)!;
 
  if ($to_expand = $1) {
    $homedir = (getpwnam($to_expand))[7];
  } else {
    $homedir = (getpwuid($<))[7];
  }
  return $path unless $homedir;
  $path =~ s!^~[^/]*!$homedir!;
  return $path;
}
