#!/usr/bin/perl

# by Payan Canaran
# re-write of update_wormbase script
# $Id: update_wormbase-dev.pl,v 1.1.1.1 2010-01-25 15:36:09 tharris Exp $

use strict;
no strict 'refs';

use Net::FTP::Recursive;
use Getopt::Long;
use Config::General;
use Cwd;
use File::Copy;
use Tie::IxHash;
use DBI;
use Bio::SeqIO;

# Record this information for logging
my $cmd = "$0 " . join(' ', @ARGV);
my $cwd = getcwd();
my $usage =<<USAGE;


To start a new session:
-----------------------
$0 -start_new (-mirror (latest_live|latest_dev|<release>) | -dir <directory>) -status <status_file> -config <config_file> -log <log_file> -species <species> [-verbose]


To continue a failed session:
-----------------------------
$0 -continue  -status <status_file>


Notes:
------
- Use only absolute paths, do not use <.> or <..> when specifying paths

USAGE

# Parse and check command-line options - retrieve previous run information if the script is to be continued
my $ref_o = process_command_line($usage);

# Create manager object - This object contains configuration information, command line options and status information; it is used for logging as well
my $m = Manager->new($ref_o);
$m->clear_step_id;

# Make config-file dependent assignments through $manager
$ENV{PATH} = $m->cfg('PATH');

# Initialize this run in the log file
$m->lg;
$m->lg('/'x87);
$m->lg('/'x40, ' START ', '/'x40);
$m->lg('/'x87);
$m->lg;
$m->lg("Starting ..."); 
$m->lg("Working directory: $cwd");
$m->lg("Command line: $cmd");
$m->lg;

# Run all steps:
run_all_steps($m);

# Notify that things everything's complete

$m->lg;
$m->lg('/'x87);
$m->lg('/'x31, ' UPDATE SEQUENCE COMPLETE ', '/'x30);
$m->lg('/'x31, ' CHECK LOG FILE(S)        ', '/'x30);
$m->lg('/'x87);
$m->lg;

# --- END ---

##################################
# MAIN JOB PROCESSING SUBROUTINE #
##################################

sub run_all_steps {
	my ($m) = @_;
	
	my $steps = $m->cfg('STEPS');
	
	my @steps; 
	@steps = @{$steps} if ref($steps);
	@steps = ($steps) if !ref($steps);

	$m->lg("The following steps are going to be performed for this species:");
	$m->lg;
	foreach my $step (@steps) { $m->lg("\t\tSTEP:$step") }
	$m->lg;
	
	foreach my $step (@steps) { 
		my ($sub, @args) = split(':', $step);
		&{$sub}($m, @args) or $m->die_n("Cannot perform step ($step), please check log file for details and re-start");
		}
	}

############################
# SUBROUTINES - PROCESSING #
############################

# This sub checks for *basic* requirements for the update sequence to complete successfully.
# It is aware of what steps are going to be performed and by default doesn't run the tests that are not relevant.

sub check_requirements {
	my ($m, $test) = @_;
	
	my $id = 'check_requirements'; $m->set_step_id($id, @_);

	$m->lg("Checking for requirements");

	$m->check_if_complete and return 1;

	my $steps = $m->cfg('STEPS');

	my $temp_file = $m->cfg('CHECK_REQ_TEMP_FILE');
	my ($temp_file_name) = $temp_file =~ /([^\/]+)\/*$/;

	# Create *the* temporary load table
	open (TEMP, ">$temp_file") or $m->lg("Cannot write temp file ($temp_file)"), return;
	for (my $i; $i <= 100; $i++) { print TEMP "$i\tthis is test data\n"; }
	
	my @steps; 
	@steps = @{$steps} if ref($steps);
	@steps = ($steps) if !ref($steps);
	
	my %steps; foreach my $step (@steps) { $steps{$step} = 1; }

	my $pass = 1;

	# Check diskspace (WORMBASE, BUILD_ROOT_DIR, ACEDB_ROOT_DIR, MYSQL_DATA_DIR)
	if ($test eq 'diskspace') {
		my %inventory;
		foreach my $key qw(WORMBASE BUILD_ROOT_DIR ACEDB_ROOT_DIR MYSQL_DATA_DIR) {

			# Exceptions:
			if ($key eq 'BUILD_ROOT_DIR' and $m->opt('DIR', 'no_check')) {
			  $m->lg("No data will be downloaded, skipping 'BUILD_ROOT_DIR' for diskspace requirement check");
			  next;
			}

##			if ($key eq 'FTP_ROOT_DIR' and !$steps{copy_to_ftp}) { 
##			  $m->lg("Data will not be copied to FTP server, skipping 'FTP_ROOT_DIR' for diskspace requirement check"); 
##			  next;
##			}

			my $dir = $m->cfg($key);
			my ($mount_point, $available_space) = _get_available_space($m, $dir); # calculated in GB
			my $required_space = $m->cfg("DS_REQ_FOR_$key");
			$inventory{$mount_point}{available_space} = $available_space;
			$inventory{$mount_point}{required_space} += $required_space;
			push @{$inventory{$mount_point}{components}}, "$key:$dir";
			}
		
		foreach my $mount_point (sort keys %inventory) {
			my $available_space = $inventory{$mount_point}{available_space};
			my $required_space = $inventory{$mount_point}{required_space};
			my $components = join(" ", @{$inventory{$mount_point}{components}});
			
			if ($available_space >= $required_space) {
				$m->lg("System has $available_space GB available and meets diskspace requirement ($required_space GB) for the following components: $components");
				}
		
			else {
				$m->lg("WARNING: System has only $available_space GB available and *does not* meet the total diskspace requirement ($required_space GB) for the following component(s): $components");
				$pass = 0;
				}
			}
		}
	
	# Check mysql_access
	if ($test eq 'mysql_access') {

		# Foreach 4 or 2 databases (based on provided steps) check if they exist, if so try to write to them and load infile
		
		my @databases;
		if ($steps{'load_gffdb:main'}) { push @databases, $m->cfg('MAIN_GFFDB_LOAD_DB'); push @databases, $m->cfg('MAIN_GFFDB_LIVE_DB') }
		if ($steps{'load_gffdb:pmap'}) { push @databases, $m->cfg('PMAP_GFFDB_LOAD_DB'); push @databases, $m->cfg('PMAP_GFFDB_LIVE_DB') }
		if ($steps{'load_gffdb:briggsae'}) { push @databases, $m->cfg('BRIGGSAE_GFFDB_LOAD_DB'); push @databases, $m->cfg('BRIGGSAE_GFFDB_LIVE_DB') }
		if ($steps{'load_gffdb:remanei'}) { push @databases, $m->cfg('REMANEI_GFFDB_LOAD_DB'); push @databases, $m->cfg('REMANEI_GFFDB_LIVE_DB') }
		
		my $user = $m->cfg('GFFDB_MYSQL_USER');
		my $password = $m->cfg('GFFDB_MYSQL_PASS');
		
		foreach my $database (@databases) {

			my $datasource = "dbi:mysql:$database";
			my $dbh = DBI->connect($datasource, $user, $password, { PrintError => 0, RaiseError => 0, AutoCommit => 0 }) or $m->lg("WARNING: Datasource ($datasource) is not accessible, create it or make it accesible: $DBI::errstr") and $pass = 0;
			
			if ($dbh) {
				my $test_table_check = $dbh->do('DROP TABLE IF EXISTS test_table');
				unless (defined $test_table_check) { $m->lg("WARNING: An error occured when dropping (if exists) table test_table from datasource ($datasource), the rest of the test *may* fail: $DBI::errstr") };
				
				my $rv = $dbh->do('CREATE TABLE test_table (second_row INT, third_row VARCHAR(30))')
					or $m->lg("WARNING: Cannot create table at datasource ($datasource): $DBI::errstr"), $pass = 0;
					
				if ($rv) {
					$dbh->do("LOAD DATA INFILE \'$temp_file\' INTO TABLE test_table")
						or $m->lg("WARNING: Cannot load LOCAL INFILE data to table test_table at datasource ($datasource), provide user with FILE privilege: $DBI::errstr"), $pass = 0;
					$dbh->do('DROP TABLE test_table')
						or $dbh->disconnect, $m->die_n("WARNING: Cannot drop test table (test_table) from datasource ($datasource): $DBI::errstr");
					}
				$dbh->disconnect;	
				}
			}
		}	

	# Check file_write
	if ($test eq 'file_write') {
		foreach my $key qw(WORMBASE BUILD_ROOT_DIR ACEDB_ROOT_DIR) {
			# Exceptions:
			if ($key eq 'BUILD_ROOT_DIR' and $m->opt('DIR')) {
			  $m->lg("No data will be downloaded, skipping 'BUILD_ROOT_DIR' for file_write requirement check");
			  next;
			}
##			if ($key eq 'FTP_ROOT_DIR' and !$steps{copy_to_ftp}) {
##			  $m->lg("Data will not be copied to FTP server, skipping 'FTP_ROOT_DIR' for file_write requirement check");
##			  next;
##			}

			my $current_dir = cwd;
			
			my $dir = $m->cfg($key);

			chdir($dir) or $m->lg("WARNING: Cannot chdir to directory ($dir)"), $pass = 0;
			
			my $copy_result = copy($temp_file, ".") or $m->lg("WARNING: Cannot write to directory ($dir)"), $pass = 0;
			
			if ($copy_result) { unlink($temp_file_name) or $m->lg("WARNING: Cannot remove from directory ($dir)"); $pass = 0 };
						
			chdir($current_dir) or $m->lg("WARNING: Cannot chdir to initial directory ($current_dir)"), $pass = 0;
			}
		}	

	unless ($pass) { $m->lg("Checking for requirements failed!"); return; }

	$m->lg("Requirement ($test) met");
	$m->lg;
	$m->mark_as_complete or return;
	return 1;
	}	

# This sub checks for the latest release in the ftp server specified for a given species
# Currently it's able to handle elegans and briggsae.
#
# It cd's to the latest_dev or latest_live directories and checks if these are symlinks
# If they are symlinks retrieves the actual directory name and uses the actual directory name for identifying release name and release id
# 
# Returns the name of the release and release id based on which type of release was requested (current dev or current live) 

sub check_for_new_release {
	my ($m) = @_;
	
	my $id = 'check_for_new_release'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;

	my $species = $m->opt('SPECIES');
	my $mirror = $m->opt('MIRROR');

	my $ftp_server = $m->cfg('FTP_SERVER');
	my $contact_email = $m->cfg('CONTACT_EMAIL');	

	my $latest_dir;
	if ($mirror eq 'latest_live') { $latest_dir = $m->cfg('FTP_LATEST_LIVE_DIR'); }
	elsif ($mirror eq 'latest_dev') { $latest_dir = $m->cfg('FTP_LATEST_DEV_DIR'); }
	
	my $mirror = $m->opt('MIRROR');

	$m->lg;
	$m->lg("Checking for new release ($mirror) for species $species ...");
	
	$m->lg("Connecting to ftp_server ($ftp_server)");	
	my $ftp = Net::FTP->new($ftp_server) or $m->lg("Can't open ftp server ($ftp_server)!"), return;	
	$ftp->login('anonymous' => "$contact_email") or $m->lg("Cannot login", $ftp->message), return;

	# Latest dir is most likely a symlink; there is no readlink in ftp; manually figure out the actual directory
	$m->lg("Latest dir is $latest_dir; Checking if this is a symlink (actual dir name is needed to identify release name/id)");
	
	my ($parent_dir, $dir_name) = _parse_file_name($m, $latest_dir) or return;

	$m->lg("Cd'ing to parent_dir ($parent_dir)");
	$ftp->cwd($parent_dir) or $m->lg("Cannot cd to parent_dir ($parent_dir)"), return;

	my $actual_dir_name;	
	my @dirs = $ftp->dir or $m->lg("Cannot get directory listing"), return;
	foreach my $i (@dirs) {
		if ($i =~ /$dir_name -> (\S+)/) { $actual_dir_name = $1; last; }
		}
	
	if ($actual_dir_name) { $m->lg("Directory is a symlink; it points to $actual_dir_name"); }
	else { $m->lg("Directory name is not a symlink"); $actual_dir_name = $dir_name };
		
	$m->lg("Cd'ing to directory ($actual_dir_name) for verification");
	$ftp->cwd($actual_dir_name) or $m->lg("Cannot cd to actual_dir_name ($actual_dir_name)"), return;
	$m->lg("Verified directory ($actual_dir_name)");

	my ($release, $release_id);
	if ($actual_dir_name =~ /(\w+(\d+))\/*$/) {
	    ($release, $release_id) = ($1, $2);   # e.g. WS119, CB25
	} else {
	    $m->lg("Cannot parse directory name ($actual_dir_name) to obtain release and release id!\n"); 
	    return;
	} 
	
	$m->sts('RELEASE', $release);
	$m->sts('RELEASE_ID', $release_id);
	$m->sts('OLD_RELEASE',$release_id - 1);

	$m->lg("Latest release ($mirror) is $release and release_id is $release_id");

	$m->lg;
	$m->mark_as_complete or return;
	return ($release, $release_id);
	}

# This sub determines which data is to be used for the build. There are 3 options:
# 1-) if mirror=latest_live or mirror=latest_dev then retrieve the name of the most current Wormbase release (dev/live), mirror it into a directory and use it
# 2-) if mirror=<release> then mirror that particular release into a directory and use it
# 3-) if dir=<directory> then use that directory contents for the build
#
# If one of the latest release is requested, it checks for the
# appropriate latest release using the "check_for_new_release"
# sub. Based on the release name it captures from that retrieval or if
# the release name was explicitly specified, it mirrors that directory
# to a local location. It sets the location of the local copy in the
# status file. If a directory is specified , no mirroring is
# needed. It only sets the local copy parameter to that directory and
# returns.
#
# Returns true if successfull.

sub retrieve_build {
	my ($m) = @_;

	my $id = 'retrieve_build'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;
	
	$m->lg;
	$m->lg("Determining data build to be used ...");
	
	my $mirror = $m->opt('MIRROR', 'no_check');

	my $local_storage_dir = $m->cfg('BUILD_ROOT_DIR');

	if ($mirror) {
		if ($mirror eq 'latest_live' || $mirror eq 'latest_dev') { 
			$m->lg("Will mirror a release ($mirror); but first need to determine which particular release that is");
			check_for_new_release($m) or $m->lg("Check for new release failed!"), return;			
			$m->set_step_id($id, @_); # Set step_id back as it is changed
			}

		else {
			my $release = $mirror;
			$m->lg("The particular release name is already specified in the command line ($release); will mirror that");
			# Release id is assumed to be in the form WS123 CB25
			my ($release_id) = $release =~ /(\d+)$/ or $m->lg("Cannot determine release_id from release name ($release)"), return;
			$m->sts('RELEASE', $release);
			$m->sts('RELEASE_ID', $release_id);
			}
			
		my $release    = $m->sts('RELEASE');
		my $release_id = $m->sts('RELEASE_ID');

		-e $local_storage_dir or _reset_dir($m, $local_storage_dir, 'local mirror directory') or return;

		$m->lg("Mirroring (downloading) release $release");
		do_mirror($m) or $m->lg("Cannot mirror release!"), return;
		$m->set_step_id($id, @_); # Set step_id back as it is changed
		
		$m->lg("Successfully downloaded release into local directory: $local_storage_dir");
		}
	
	else {
		my $dir = $m->opt('DIR');
		$m->lg("Will use an already downloaded release directory ($dir), will parse directory name for release and release id");
		my $d = $dir; $d =~ s/\/+$//; 
		my ($release) = $d =~ /([^\/]+)$/;
		my ($release_id) = $release =~ /(\d+)$/ or $m->lg("Cannot determine release_id from release name ($release)"), return;
		$m->sts('RELEASE', $release);
		$m->sts('RELEASE_ID', $release_id);
		$m->sts('DOWNLOAD_DIR', $dir);
		$m->lg("Release is $release and release_id is $release_id");
		}
	
	# This is the point where the build is either downloaded or located in the already existing directory
	# Masked chromosome files were added to the Sanger build (starting WS127). This segment here is added to move masked chromosome files (if applicable)
	# into a new directory, so that they do not interfere (get loaded) witht the gff loading stage.
	# This only applies to elegans
	# This segment can be moved to another location in the future or completely removed if Sanger makes modifications to its directory hierarchy - 20Jul2004

	if ($m->opt('SPECIES') eq 'elegans') {
		$m->lg("Starting WS127, masked chr files are included in the build, if they exist will move them to a separate directory");
		my @masked_chr_files = glob($m->cfg('CHROMOSOMES_MASKED_GLOB'));
		if (@masked_chr_files) {
			my $masked_dir = $m->cfg('CHROMOSOMES_MASKED_DIR');
			_reset_dir($m, $masked_dir, 'local masked chromosome directory') or return;
			foreach (@masked_chr_files) { move($_, $masked_dir) or $m->lg("Cannot move masked chr file ($_) to directory ($masked_dir)"), return; }
			}
		else { $m->lg("WARNING: Cannot find any masked chr files, glob used was: " . $m->cfg('CHROMOSOMES_MASKED_GLOB')); }
		}
	
	$m->lg;
	$m->mark_as_complete or return;
	return 1;
	}
	

# This sub downloads a db release from an ftp server using the Net::FTP::Recursive module
#
# Returns true if successfull.

sub do_mirror {
	my ($m) = @_;

	my $id = 'do_mirror'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;
	
	my $contact_email = $m->cfg('CONTACT_EMAIL');
	my $ftp_server = $m->cfg('FTP_SERVER');

	my $remote_dir = $m->cfg('FTP_RELEASE_DIR');
	my $local_dir = $m->cfg('DOWNLOAD_DIR');
	
	$m->lg("Mirroring release from $ftp_server ($remote_dir)");

	$m->lg("Resetting local mirror directory ($local_dir)");
	_reset_dir($m, $local_dir, 'local mirror directory') or return;
	
	my $cwd = getcwd();

	$m->lg("Changing to local mirror directory ($local_dir)");
	chdir $local_dir or $m->lg("Cannot chdir to local mirror directory ($local_dir)!"), return;
	
	$m->lg("Starting download ...");
	my $ftp = Net::FTP::Recursive->new($ftp_server, Debug => 0) or $m->lg("Cannot construct Net::FTP::Recursive object: $@"), return;
    $ftp->login('anonymous', $contact_email) or $m->lg("Cannot login to ftp server"), return;
    $ftp->binary() or $m->lg("Cannot change to binary mode for download: $@"), return;
    $ftp->cwd($remote_dir) or $m->lg("Cannot chdir to remote dir ($remote_dir)"), return;
    my $r = $ftp->rget(); 
	if ($r) {
		$m->lg("rget (of Net::FTP::Recursive) failed: $r");
		$m->lg("Mirror failed. Cleaning local bmirror directory is: $local_dir!");
		_remove_dir($m, $local_dir, 'local mirror directory') or $m->lg("Cannot clean local mirror directory ($local_dir)! Remove manually to proceed!");
		return;
		}
    $ftp->quit;

	$m->lg("Changing back to initial working directory ($cwd)");
	chdir $cwd or $m->lg("WARNING: Cannot chdir to initial working directory ($cwd)!");
	
	$m->sts('DOWNLOAD_DIR', $local_dir);
	$m->lg("Mirror successful. Local mirror directory is: $local_dir");
	
	$m->lg;
	$m->mark_as_complete or return;
	return 1;
      }



# Copies the downloaded or provided local mirror directory to the ftp server.
# It does *not* update symlinks, this is done by another script
#
# Returns true if successfull.

# DEPRECATED!  This has not been updated!
# Now building in the FTP path
sub copy_to_ftp {
	my ($m) = @_;

	my $id = 'copy_to_ftp'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;

	my $local_dir = $m->sts('LOCAL_MIRROR_DIR');
	
	my $ftp_dir = $m->cfg('LOCAL_FTP_SPECIES_DIR');
	my $ftp_release_dir = $m->cfg('LOCAL_FTP_RELEASE_DIR');
	my $remove_mirror = $m->cfg('REMOVE_MIRROR');	

	$m->lg("Copying local mirror ($local_dir) to ftp site ($ftp_release_dir)");

	_make_dir($m, $ftp_dir, 'ftp directory') or return;
	
	_reset_dir($m, $ftp_release_dir, 'ftp release directory') or return;

	$m->lg("Copying local mirror ($local_dir/*) to ftp release directory ($ftp_release_dir)");
	system("cp -r $local_dir/* $ftp_release_dir")
	  and $m->lg("Cannot copy local mirror directory ($local_dir/*) to ftp site ($ftp_dir): $!")
	    and return;
	
	$m->lg("Copy successfull");

	if ($remove_mirror) { _remove_dir($m, $local_dir, 'local mirror directory') or return; }

  	$m->sts('LOCAL_MIRROR_DIR', "$ftp_release_dir");

	$m->lg("Local mirror directory sucessfully copied to ftp site, the new location of the local mirror dir is $ftp_release_dir");

	$m->mark_as_complete or return;	
	return 1;
	}





sub create_directories {
  my ($m) = @_;

  my $id = 'create_directories'; $m->set_step_id($id, @_);

  # Make database dirs
  my $release = $m->sts('RELEASE');
  my $db_path = $m->cfg('SUPPORT_DB_ROOT') . "/$release";
  my $components = $m->cfg('SUPPORT_DB_COMPONENTS');
  my @components = split(/\s/,$components);

  -e "$db_path" or _make_dir($m, $db_path, 'database directory') or return;
  foreach (@components) {
      -e "$db_path/$_" or _make_dir($m, "$db_path/$_", 'database directory') or return;
  }
  
  $m->check_if_complete and return 1;
  my $dna_unpacked   = $m->cfg('DNA_UNPACKED_DIR');
  $m->lg("Creating/Resetting necessary directories");
  _reset_dir($m, $dna_unpacked, 'unpacked directory') or return;
  $m->mark_as_complete or return;
  return 1;
}


# This updates symlinks - two types ftp, acedb.  It issues a warning if
# cannot create the symlink but dies only if it cannot parse the
# symlink entry from the config file
#
# Returns true if successfull 

sub update_symbolic_links {
	my ($m, $type) = @_;

	my $id = 'update_symbolic_links'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;

	my $symlinks;
	if ($type eq 'ftp') { $symlinks = $m->cfg('LOCAL_SYMLINKS'); }
	elsif ($type eq 'acedb') { $symlinks = $m->cfg('LOCAL_ACEDB_SYMLINKS'); }
	elsif ($type eq 'databases') { $symlinks = $m->cfg('DATABASES_DIR_SYMLINKS'); }
	else { $m->lg("Internal error: Cannot determine what to symlink based on type ($type)"); return }
	
	my @symlinks; 
	@symlinks = @{$symlinks} if ref($symlinks);
	@symlinks = ($symlinks) if !ref($symlinks);

	$m->lg("Updating ($type) symlink(s)");

	foreach my $symlink (@symlinks) {
		my ($alias, $target) = split(/\s+/, $symlink);

		unless ($alias && $target) { $m->lg("Symlink entry ($alias) does not parse properly, please check config file!"); return }
	
		_update_symlink($m, $target, $alias) or $m->lg("WARNING: Cannot update symlink: $alias -> $target");
		}

	$m->lg("Symlink(s) updated");

	$m->mark_as_complete or return;	
	return 1;
	}

# Untars necessary database components into acedb directory
#
# Returns true if successfull

sub do_untar {
	my ($m) = @_;

	my $id = 'do_untar'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;

	my $species = $m->opt('SPECIES');

	my $dest      = $m->cfg('ACEDB_RELEASE_DIR');
	my $src       = $m->cfg('ACEDB_DOWNLOAD_DIR');
	my $acedb_grp = $m->cfg('ACEDB_GROUP');
	
	my $untar_log_file = $m->cfg('UNTAR_LOG_FILE');
	if (-e $untar_log_file) {
		unlink($untar_log_file) or ($m->lg("WARNING: Cannot unlink untar log file ($untar_log_file): $!"), return);
		}
	
	$m->lg("Installing Acedb directory");

	_reset_dir($m, $dest, 'Acedb release directory') or return;
	system("chgrp $acedb_grp $dest") and $m->lg("Cannot chgrp $dest to $acedb_grp: $!"), return;
	system("chmod g+ws $dest") and $m->lg("Cannot chmod $dest to g+ws: $!"), return;

	$m->lg("Changing to acedb release directory");
	chdir $dest or $m->lg("Cannot chdir to $dest: $!"), return;
	$m->lg("Changed to directory");

	$m->lg("Untarring database files");
	foreach (<$src/database*.tar.gz>) {
		my $cmd = "gunzip -c $_ | tar xvf - >> $untar_log_file.database-files 2>&1"; # perl test.pl  >> tmp 2>&1
		$m->lg("Untarring $_ ($cmd)");
		system $cmd and $m->lg("Cmd failed ($cmd): code $?"), return;
		}
	$m->lg("Database files processed");

	if (-e "$src/pictures.tar.gz" && ! -d "$dest/pictures") {
		$m->lg("Untarring pictures");

		$m->lg("Resetting picture directory ($dest/pictures)");
		_reset_dir($m, "$dest/pictures", 'acedb pictures directory') or return;
		$m->lg("Directory reset");		

		$m->lg("Changing to picture directory ($dest/pictures)");
		chdir "$dest/pictures" or $m->lg("Cannot change to pictures directory: $!"), return;
		$m->lg("Changed to directory");		
		
		my $cmd = "gunzip -c $src/pictures.tar.gz | tar xvf - &> $untar_log_file.picture-file";
		$m->lg("Untarring $src/pictures.tar.gz ($cmd)");		
		system $cmd and $m->lg("Cmd failed ($cmd): $!"), return;

		$m->lg("Picture file processed");
		}

	system("chmod g+ws $dest/database") and $m->lg("Cannot chmod $dest/database to g+ws: $!"), return;
	
	$m->lg("Successfully installed Acedb directory");

	$m->mark_as_complete or return;	
	return 1;
	}


# Copies the local wspec directory into the current acedb database directory to allow access from local users (admins)
# 
# Returns true if successfull

sub do_customize {
	my ($m) = @_;

	my $id = 'do_customize'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;

	my $target_wspec = $m->cfg('ACEDB_WSPEC_DIR');
	my $source_wspec = $m->cfg('SOURCE_WSPEC_DIR');

	$m->lg("User customization: Copying local wspec directory contents ($source_wspec) into new wspec directory ($target_wspec)");

	system("chmod ug+rw $target_wspec/*.wrm") and $m->lg("Cannot chmod ug+rw $target_wspec/*.wrm: $!"), return;
	foreach (<${source_wspec}/*.wrm>) {
		copy($_, $target_wspec) or $m->lg("Cannot copy wspec file ($_) to directory ($target_wspec)"), return;
		$m->lg("Copied $_ to $target_wspec");
		}

	$m->mark_as_complete or return;
	return 1;
	}


# Dumps sequence files for making blastable databases
# Blastable databases are not created at this time.
#
# Returns true if successfull
#-----------------------------------------
sub dump_sequences {
	my ($m, $type) = @_;

	my $id = 'dump_sequences'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;

	my $species = $m->opt('SPECIES');
	my $blastdb_dir = $m->cfg('BLASTDB_DIR');
	my $blastdb_release_dir = $m->cfg('BLASTDB_RELEASE_DIR');
        my $blastdb_cb_release_dir = $m->cfg('BLASTDB_CB_RELEASE_DIR');
    
	$m->lg("Dumping sequences ($type) for BLAST database");
	
	-e $blastdb_release_dir or _make_dir($m, $blastdb_release_dir, 'release blast directory') or return;
	-e $blastdb_cb_release_dir or _make_dir($m, $blastdb_cb_release_dir, 'release blast (cb) directory') or return;
    	
	if ($type eq 'nucl' && $species eq 'elegans') {

		my $chromosomes_dir = $m->cfg('CHROMOSOMES_DIR');
		my $script = $m->cfg('DUMP_NUCL_SCRIPT');
		my $file = $m->cfg('NUCL_FASTA_FILE');
		my $log_file = $m->cfg('NUCL_FASTA_LOG_FILE');
		
		my $cmd = "($script $chromosomes_dir $file) &> $log_file";
		
		system($cmd) and $m->lg("Cmd failed ($cmd)! Failed to dump ($type) sequences for the species ($species): $!"), return;
		}

	elsif ($type eq 'nucl' && $species eq 'briggsae') {

		my $acedb = $m->cfg('ACEDB_RELEASE_DIR');
		my $script = $m->cfg('TACE_SCRIPT');
		my $file = $m->cfg('NUCL_FASTA_FILE');
		my $temp_ace_file = $m->cfg('TEMP_ACE_FILE');
		
		open TEMP,">$temp_ace_file" or $m->lg("Cannot write file ($temp_ace_file): $!"), return;
		print TEMP "query find Briggsae_genomic\ndna\n";
		close TEMP;

		open DEST,">$file" or $m->lg("Cannot write file ($file): $!"), return;

		my $cmd = "$script $acedb < $temp_ace_file";
		open (TACE,"$cmd|") or $m->lg("Cannot open pipe ($cmd): $!"), return;

		while (<TACE>) { # parent reads from tace and filters
			s/^acedb>\s+//;
			next unless /^>/ .. m!^//!;
			next if m!^//!;
			print DEST;
			}
		
		close TACE or $m->lg("Failure while closing pipe from tace: $?"), return;
		close DEST;

		unlink "$temp_ace_file";
		}
		
	elsif ($type eq 'ests' && $species eq 'elegans') {

		my $acedb = $m->cfg('ACEDB_RELEASE_DIR');
		my $script = $m->cfg('TACE_SCRIPT');
		
		my $file = $m->cfg('ESTS_FASTA_FILE');
		my $file_unpacked = $m->cfg('ESTS_FILE_UNPACKED');
		my $file_zipped = $m->cfg('ESTS_FILE_ZIPPED');
		
		my $unpacked_dir = $m->cfg('DNA_UNPACKED_DIR');
		
		my $temp_ace_file = $m->cfg('TEMP_ACE_FILE');
		
		open TEMP,">$temp_ace_file" or $m->lg("Cannot write file ($temp_ace_file): $!"), return;
		print TEMP "query find cDNA_Sequence\ndna\nquery find NDB_Sequence\ndna\n";
		close TEMP;

		open DEST,">$file" or $m->lg("Cannot write file ($file): $!"), return;

		my $cmd = "$script $acedb < $temp_ace_file";
		open (TACE,"$cmd|") or $m->lg("Cannot open pipe ($cmd): $!"), return;

		while (<TACE>) { # parent reads from tace and filters
			s/^acedb>\s+//;
			next unless /^>|^[gatcn]+$/i;
			print DEST;
		    }
		
#		close TACE or $m->lg("Failure while closing pipe from tace: $?"), return;
		close TACE;
		close DEST;

		# Copy to unpacked dir also
		copy($file, $file_unpacked) or $m->lg("Cannot copy EST file ($file) to unpacked directory ($file_unpacked): $!"), return;
		
		# Zip and copy to DNA_DUMPS directory
		-e $unpacked_dir or _make_dir($m, $unpacked_dir, 'unpacked directory') or return;		
		system("gzip -c $file > $file_zipped") and $m->lg("Cannot zip/copy EST file ($file) to DNA DUMPS directory ($file_zipped): $!"), return;

		unlink "$temp_ace_file";
		}	

	elsif ($type eq 'prot' && $species eq 'elegans') {
		my $dir = $m->cfg('BLASTDB_RELEASE_DIR');
		my $pkg = $m->cfg('WORMPEP_PKG');
		my $unpacked_dir = $m->cfg('WORMPEP_UNPACKED_DIR');
		my $source_file_01 = $m->cfg('WORMPEP_FILE_01'); # Redundancy here to handle two types of wormpep pkg (i) extracts into a directory (ii) extracts wirhout directory hierarchy
		my $source_file_02 = $m->cfg('WORMPEP_FILE_02');
		my $target_file = $m->cfg('PROT_FASTA_FILE');

		-e $unpacked_dir or _make_dir($m, $unpacked_dir, 'unpacked directory') or return;
		
		system("tar --ungzip -C $dir -xf $pkg") and $m->lg("Cannot unpack wormpep package ($pkg): $!"), return;
		
		my $source_file;
			print "$source_file_01 $source_file_02 $pkg $dir";
		if (-e $source_file_01 && -f $source_file_01) { $source_file = $source_file_01 }
		elsif (-e $source_file_02 && -f $source_file_02) { $source_file = $source_file_02 }
		else { $m->lg("Cannot determine which file is the wormpep file"); return; }
		
		move($source_file, $target_file) or $m->lg("Cannot move wormpep file ($source_file to $target_file)"), return;
		_remove_dir($m, "$unpacked_dir", 'wormpep package directory') or return;
		}

	elsif ($type eq 'prot_cb' && $species eq 'elegans') {

		my $acedb = $m->cfg('ACEDB_RELEASE_DIR');
		my $script = $m->cfg('TACE_SCRIPT');
		my $file = $m->cfg('PROT_CB_FASTA_FILE');
		my $temp_ace_file = $m->cfg('TEMP_ACE_FILE');
		
		open TEMP,">$temp_ace_file" or $m->lg("Cannot write file ($temp_ace_file): $!"), return;
		print TEMP "query find Protein BP* Peptide\npeptide\n";
		close TEMP;

		open DEST,">$file" or $m->lg("Cannot write file ($file): $!"), return;

		my $cmd = "$script $acedb < $temp_ace_file";
		open (TACE,"$cmd|") or $m->lg("Cannot open pipe ($cmd): $!"), return;

		while (<TACE>) { # parent reads from tace and filters
			s/^acedb>\s+//;
			next unless /^>/ .. m!^//!;
			next if m!^//!;
			print DEST;
			}
		
		#close TACE or $m->lg("Failure while closing pipe from tace: $?"), return;
		close TACE;
		close DEST;

		unlink "$temp_ace_file";
		}
	
	else {
		$m->lg("Internal error: Cannot determine how to dump sequences based on type ($type) and species ($species)");
		return;
		}
	
	$m->mark_as_complete or return;
	return 1;
	}		


# Creates the blastdb for the dumped sequences
#
# Returns true if successfull

sub make_blastdb {
	my ($m, $type) = @_;

	my $id = 'make_blastdb'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;

	my $species = $m->opt('SPECIES');
	
	my $cmd;
	
	if ($type eq 'nucl') { $cmd = $m->cfg('NUCL_FORMATDB_CMD'); }
	elsif ($type eq 'ests') { $cmd = $m->cfg('ESTS_FORMATDB_CMD'); }
	elsif ($type eq 'prot') { $cmd = $m->cfg('PROT_FORMATDB_CMD'); }	
    elsif ($type eq 'prot_cb') { $cmd = $m->cfg('PROT_CB_FORMATDB_CMD'); }	
	
	else { $m->lg("Internal error: Cannot determine how to make blastdb based on type ($type)"); return; }		

	system("$cmd") and $m->lg("Cmd ($cmd) failed! Cannot make blastdb based on type ($type) for species ($species): $!"), return;
	
	$m->mark_as_complete or return;
	return 1;
	}


# This will create a single chunked chr file for e-pcr
#
# Returns true if successfull

sub load_epcr {
	my ($m) = @_;

	my $id = 'load_epcr'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;

	$m->lg("Chunking and concatenating (loading) chromosome files for e-pcr");

	my $epcr_script = $m->cfg('EPCR_SCRIPT');
    my $epcr_release_dir = $m->cfg('EPCR_RELEASE_DIR');
    my $epcr_destination_file = $m->cfg('EPCR_DESTINATION_FILE');
    my $oligo_destination_file = $m->cfg('OLIGO_DESTINATION_FILE');    
	my $chr_dir = $m->cfg('CHROMOSOMES_DIR');
	my $log_file = $m->cfg('EPCR_LOG_FILE');

	-e $epcr_release_dir or _make_dir($m, $epcr_release_dir, 'epcr root directory') or return;

  	my $cmd = "$epcr_script $chr_dir $epcr_destination_file $oligo_destination_file &> $log_file";

	system $cmd and $m->lg("Script failed ($cmd): $!"), return;

	$m->mark_as_complete or return;
	return 1;
	}

# Loads gff databases
# 
# Handles 2 types of load (main - briggsae or elegans, pmap)
#
# Returns true if successfull

sub load_gffdb {
	my ($m, $type) = @_;

	my $id = 'load_gffdb'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;

	$m->lg("Loading gffdb (of type $type)");

#	my $mysql_user = $m->cfg('GFFDB_MYSQL_USER');
#	my $mysql_pass = $m->cfg('GFFDB_MYSQL_PASS');
	
#	my $auth = '';
#		$auth .= " -user $mysql_user"  if $mysql_user;
#		$auth .= " -pass $mysql_pass" if $mysql_pass;
	
	my $cmd;
	
	if ($type eq 'main') { $cmd = $m->cfg('MAIN_GFFDB_CMD'); }
	elsif ($type eq 'pmap') { $cmd = $m->cfg('PMAP_GFFDB_CMD'); }
	elsif ($type eq 'briggsae') { $cmd = $m->cfg('BRIGGSAE_GFFDB_CMD'); }
	else { $m->lg("Internal error: Cannot determine type of gffdb to load based on provided type key ($type)"); return; }
	
#	$cmd .= $auth if $auth;

	$m->lg("Running cmd: $cmd");
        # This FAILS for pmap2gffdb.pl
	system $cmd; #and $m->lg("Script failed ($cmd): Cannot load gff db: $!"), return;

	$m->mark_as_complete or return;
	return 1;
	}

# Creates and adds patches to gff database
# The script /usr/local/wormbase/temporary_patches/current.sh 
# (i) creates a set of GFF2 files, (ii) creates a gmap MySQL gff database, loads files, (iii) loads files to main gff MySQL database 
# 
# *** This needs to be run after load_gffdb and before gff2to3 ***
# 
# *** This is a temporary segment, it references a shell script, make sure to check for log file for errors ***
#
# Returns true if successfull

sub add_patch { 
	my ($m) = @_;

	my $id = 'add_patch'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;

	$m->lg("Creating and adding GFF patch");

	my $cmd = $m->cfg('ADD_PATCH_CMD');

	$m->lg("Running cmd: $cmd");
	system $cmd and $m->lg("Script failed ($cmd): Cannot create/add patch: $!"), return;
    
	$m->mark_as_complete or return;
	return 1;
	}

# Converts GFF2 database (one generated in CSHL) to GFF3 - makes a second copy
# 
# Returns true if successfull

sub gff2to3 { 
	my ($m) = @_;

	my $id = 'gff2to3'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;

	$m->lg("Converting GFF2 to GFF3");

	my $cmd = $m->cfg('GFF2TO3_CMD');
    my $gzip_cmd = $m->cfg('GFF2TO3_GZIP_CMD');

	$m->lg("Running cmd: $cmd");
	system $cmd and $m->lg("Script failed ($cmd): Cannot convert gff db: $!"), return;
    
	$m->lg("Running cmd: $gzip_cmd");
	system $gzip_cmd and $m->lg("Script failed ($cmd): Cannot gzip converted gff db: $!"), return;

	$m->mark_as_complete or return;
	return 1;
	}
	
# Back-up old nib files, copy chromosome files to blat directory and Fatonib them.
# It eventually starts the blat server.
#
# Returns true if successfull.

sub run_blat_server {
	my ($m) = @_;

	my $id = 'run_blat_server'; $m->set_step_id($id, @_);

	$m->check_if_complete and return 1;
	
	my $species = $m->opt('SPECIES');

	my $blat_root_dir = $m->cfg('BLAT_ROOT_DIR');
    my $blat_dir = $m->cfg('BLAT_DIR');
	
# 	my $blat_server_host = $m->cfg('BLAT_SERVER_HOST');
# 	my $blat_server_port = $m->cfg('BLAT_SERVER_PORT');

	my $fatonib = $m->cfg('FATONIB_EXEC');
# 	my $gfserver = $m->cfg('GFSERVER_EXEC');
	
	my $fatonib_log_file = $m->cfg('FATONIB_LOG_FILE');

	# Create blat_dir if it doesn't exist
	-e $blat_root_dir or _make_dir($m, $blat_root_dir, 'blat root dir') or return; 
	-e $blat_dir or _make_dir($m, $blat_dir, 'blat dir') or return; 
	
	if ($species eq 'elegans') {
	
#		my $local_build = $m->sts('BUILD_ROOT_DIR');
	
		my $dna_dumps_dir = $m->cfg('CHROMOSOMES_DIR');
	
		# Copy new dna.gz files to blat dir
		system ("cp $dna_dumps_dir/CHROMOSOME*dna.gz $blat_dir") and $m->lg("Cannot copy CHR files ($dna_dumps_dir/CHROMOSOME*dna.gz) to blat dir ($blat_dir): $!"), return;	
		system ("gunzip $blat_dir/*.dna.gz") and $m->lg("Cannot gunzip files ($blat_dir/*.dna.gz): $!"), return;
		}

# 	elsif ($species eq 'briggsae') {
# 	
# 		my $fasta = $m->cfg('CB_CHUNK_FASTA'); # This is s gzipped file
# 		my $fasta_gunzipped = $m->cfg('CB_CHUNK_FASTA_GUNZIPPED');
# 		my $out = $m->cfg('BLAT_DIR');
# 		my $log = $m->cfg('CB_CHUNK_LOG_FILE');
# 			
# 		# Gunzip fasta file
# 		system ("gunzip -c $fasta > $fasta_gunzipped") and $m->lg("Cannot gunzip fasta ($fasta) to fasta_gunzipped ($fasta_gunzipped): $!"), return;	
# 
# 		# Chunk fasta file
# 		_chunk_fasta($m, $fasta_gunzipped, $out, $log) or return;
# 		
# 		}
	
	else {
		$m->lg("Internal error: Cannot determine type of blat db from species ($species)");
		return;
		}
	
	# Fatonib
	foreach my $file (glob("$blat_dir/*.dna")) {
		my ($root_dir, $nib_file_name) = _parse_file_name($m, $file) or return;
		$nib_file_name =~ s/\.dna$/\.nib/; 
		my $cmd = "$fatonib $file $blat_dir/$nib_file_name &> $fatonib_log_file";
		system($cmd) and $m->lg("Fatonib failed (Cmd: $cmd): $!"), return;
		}
	
#     # Make nib list
# 	system("ls $blat_dir/*.nib > $blat_dir/all_nib_files.list") and $m->lg("Cannot generate nib list: $!"), return;
#     
# 	# Stop running blat server
# 	my $stop_cmd = "$gfserver stop $blat_server_host $blat_server_port";
# 	system($stop_cmd) and $m->lg("WARNING: Cannot stop blat server (Cmd: $stop_cmd): $!");
# 	
# 	# Start blat server, wait and confirm it's running
#     my $proc_simple = Proc::Simple->new();
# 	my $start_cmd = "$gfserver start $blat_server_host $blat_server_port $blat_dir/*.nib";
#     my $result = $proc_simple->start($start_cmd) or $m->die_n("Cannot (re)start blat server (Cmd: $start_cmd): $!");
#     sleep 10; 
#     if(!$proc_simple->poll) { $m->die_n("Cannot confirm running BLAT server!"); }

# 	# Remove .dna files
# 	system("rm -rf $blat_dir/*.dna") and $m->lg("Cannot remove dna files ($blat_dir/*.dna): $!");
	
	$m->mark_as_complete or return;
	return 1;
	}


# Dumps a number of features (gene_names, brief_ids, swissprot, go) 
#
# Returns true if successfull

sub dump_features {
    my ($m, $type) = @_;
    
    my $id = 'dump_features'; $m->set_step_id($id, @_);
    
    $m->check_if_complete and return 1;
    
    $m->lg("Dumping features ($type) ...");
    
    # Generically select the appropriate CMD
    my $prefix = uc($type);
    my $cmd = $m->cfg($prefix . '_CMD');
    unless ($cmd) { 
	$m->lg("Internal error: Cannot determine how to dump features based on type ($type)");
	return;
    }
    
    $m->lg("Running command ($cmd) ...");
	# This fails for the dump_genetic_interactions.pl script.   Why?
    system($cmd);# and $m->lg("Script failed (Cmd: $cmd): $!"), return;
    
    my $file = $m->cfg($prefix . '_OUTPUT');
    $m->lg("Running cmd: gzip $file");

    system("gzip -f $file") and $m->lg("Script failed (gzip $file): Cannot gzip feature dump $file: $!"), return;
    
    # Update the symlink
    # Fetch the full path of the target file without the file itself
    my ($alias_path,$filename)  = $file =~ /(.*\/)(.*)/;

    $alias_path .= 'current.txt';
    if ($file =~ /.*tar\.gz$/) {
	$alias_path .= '.tar.gz';
    } elsif ($file =~/\.gz$/) {
	$alias_path .= '.gz';
    } else {
	$alias_path .= '.gz';
    }
    
    $filename .= '.gz';
    
    _update_symlink($m, $filename, $alias_path) or $m->lg("WARNING: Cannot update symlink: $alias_path -> $filename");	
    $m->mark_as_complete or return;
    return 1;
}

# Copies release notes file to corresponding directory
#
# Returns true if successfull

sub copy_release_notes {
    my ($m) = @_;
    
    my $id = 'copy_release_notes'; $m->set_step_id($id, @_);
    
    $m->check_if_complete and return 1;
    
    my $letter = $m->cfg('LETTER');
    my $html_dir = $m->cfg('HTML_DIR');
    my $release_notes_dir = $m->cfg('RELEASE_NOTES_DIR');
    
    -e $html_dir or _make_dir($m, $html_dir, 'HTML directory') or return;
    
    system("cp $letter $release_notes_dir") and $m->lg("Cannot copy release notes ($letter to $release_notes_dir): $!"), return;
    
    $m->mark_as_complete or return;
    return 1;
}


sub install_ontology_files {
    my ($m) = @_;
    my $id = 'install_ontology_files';
    $m->set_step_id($id,@_);
    
    $m->check_if_complete and return 1;
    my $dir     = $m->cfg('ONTOLOGY_TARGET_DIR');
    my $source  = $m->cfg('ONTOLOGY_SOURCE_DIR');
    my $release = $m->sts('RELEASE');

    _make_dir($m, $dir, 'ontology target directory') or return;
    
    system ("cp -r $source $dir/ontology") and $m->lg("Cannot copy $source/* to $dir: $!"), return;
    $m->mark_as_complete or return;
    return 1;
}


sub build_autocomplete_db {
    my ($m) = @_;
    my $id = 'build_autocomplete_db';
    $m->set_step_id($id,@_);
    
    $m->check_if_complete and return 1;

    $m->lg("Loading autocomplete database");
    my $create     = $m->cfg('AUTOCOMPLETE_DB_CREATE_SCRIPT');
    my $create  = $m->cfg('AUTOCOMPLETE_DB_BUILD_SCRIPT');
    
    system $cmd;
    $m->mark_as_complete or return;
    return 1;
}

# Archives specified files in the archive directory
# Before starting resets the archive directory and re-creates its directory hierarchy
#
# Returns true if successfull

sub archive_files {
    my ($m) = @_;
    
    my $id = 'archive_files'; $m->set_step_id($id, @_);
    
    $m->check_if_complete and return 1;
    
    my $archive_dir = $m->cfg('BUILD_SPECIES_DIR');
    my $src_dir     = $m->cfg('DOWNLOAD_DIR');
    
#	my @archive_subdirs = split(/\s+/, $m->cfg('ARCHIVE_RELEASE_SUBDIRS'));
    
    my $archive_files =  $m->cfg('TO_COPY');
    
    # This section resets the archive directory, but due to the sensitive nature of the archive directory, 
    # a few checks are implemented to make sure what we are resetting is what we want to reset
#	if (-e $archive_dir) {
#		my $valid_subdirs = 0; foreach (@archive_subdirs) { $valid_subdirs++ if -e "$archive_dir/$_" }
#		if ($valid_subdirs == scalar @archive_subdirs and $valid_subdirs) { _reset_dir($m, $archive_dir, 'archive directory') or return; }
#		else { $m->lg("Archive dir ($archive_dir) exists but cannot validate it for deletion, you must manually make sure it's ok to remove it and remove it to proceed"); return; }
#		}
#	
##	# Make archive_dir
##	unless (-e $archive_dir) { _make_dir($m, $archive_dir, 'archive directory') or return; }
    
##	# Create subdirs
##	foreach (@archive_subdirs) { _make_dir($m, "$archive_dir/$_", 'archive directory subdir') or return; }
    
    # Copy over each file
    my @archive_files;
    @archive_files = @{$archive_files} if ref($archive_files);
    @archive_files = ($archive_files) if !ref($archive_files);
    
    foreach my $archive_file (@archive_files) {
	my ($target, $destination) = split(/\s+/, $archive_file);
	my $target_path;
	if ($target =~ /wormpep/ || $target =~ /wormrna/) {
	    my @files = glob("$src_dir/$target");
	    $target_path = $files[0];
	    ($target) = $target_path =~ /.*\/(.*)/;
	} else {
	    $target_path = "$src_dir/$target";
	}

	unless ($target and $destination) { $m->lg("Target ($target) and destination ($destination) both must be defined: $!"); return; }
	copy($target_path, $destination) or $m->lg("Cannot copy target ($target) to destination ($destination): $!"), return;
	$m->lg("Copied $target");

	# Create appropriate symlinks
	# Update the symlink
	# Fetch the full path of the target file without the file itself
	
	my $alias_path = $destination . '/current';
	if ($target =~ /.*tar\.gz$/) {
	    $alias_path .= '.tar.gz';
	} else {
	    $alias_path .= '.gz';
	}
	_update_symlink($m, "$target", $alias_path) or $m->lg("WARNING: Cannot update symlink: $alias_path -> $destination/$target");	
    }
       
    $m->mark_as_complete or return;
    return 1;	
}

###########################
# SUBROUTINES - UTILITIES #
###########################

sub process_command_line {
    my ($usage) = @_;
    
    my %o; GetOptions(\%o, 'start_new', 'continue', 'mirror=s', 'dir=s', 'config=s', 'status=s', 'log=s', 'verbose', 'species=s') || die "Usage: $usage\n";
    
    my $start_new = $o{start_new};
    my $continue  = $o{continue};
    my $mirror    = $o{mirror};
    my $dir       = $o{dir}; 
    my $log       = $o{log}; 
    my $status    = $o{status};
    my $config    = $o{config}; 
    my $species   = $o{species};
    
    if ($start_new && $continue) { die "Usage: $usage\n" };
    unless ($start_new || $continue) { die "Usage: $usage\n" };
    
    foreach my $param ($dir, $config, $status, $log) {
	if ($param) {
	    unless ($param =~ /^\//) { die "Usage: $usage\n" };
	    if ($param =~ /\/\.{1,2}\//) { die "Usage: $usage\n" };
	}
    }	
    
    if ($start_new) {
	# Check usage
	unless (($mirror || $dir) && $config && $log && $status) { die "Usage: $usage\n" };
	if ($mirror && $dir) { die "Usage: $usage\n" };
	if ($mirror =~ /^latest_/ && !($mirror eq 'latest_live' || $mirror eq 'latest_dev')) { die "Usage: $usage\n" };
	
	# Check files
	unless (-e $config) { die "Cannot find config file ($config)!\n" };
	if (-e $log) { die "Log file ($log) already exists!\n" };
	if (-e $status) { die "Status file ($status) already exists!\n" };	
	
	# Make options all upper-case (case insensitive: ci)
	my %ci_o;
	foreach my $i (keys %o) {
	    $ci_o{uc($i)} = $o{$i};
	}
	
	return \%ci_o;
    }
    
    if ($continue) {
	# Check usage
	unless ($status) { die "Usage: $usage\n" };
	if ($mirror || $dir || $config || $log) { die "Usage: $usage\n" };
	
	# Check files
	unless (-e $status) { die "Cannot find status file ($status)!\n" };
	
	# Retrieve initial run params
	tie my %s, "Tie::IxHash";
	my $s = new Config::General(-ConfigFile => $status, -InterPolateVars => 0, -Tie => "Tie::IxHash");
	%s = $s->getall();
	
	return $s{params};
    }
    
}	

sub _reset_dir {
    my ($m, $target, $msg) = @_;
    
    my $s = '[_reset_dir]';
    
    $target =~ /\S+/ or $m->lg("$s No directory specified"), return;
	
    $msg or $msg = 'directory';
    
    $m->lg("$s Resetting $msg ($target)");
    
    _remove_dir($m, $target, $msg) or return;
    _make_dir($m, $target, $msg) or return;    
    $m->lg("$s Target reset");

    return 1;
}

sub _remove_dir {
    my ($m, $target, $msg) = @_;

    my $s = '[_remove_dir]';

    $target =~ /\S+/ or $m->lg("$s No target spcified"), return;

    $msg or $msg = 'directory';

    $m->lg("$s Removing $msg ($target)");

    -e $target or $m->lg("$s WARNING: $msg ($target) does not exist"), return 1;
    system ("rm -rf $target") and $m->lg("$s Cannot remove $msg ($target): $!"), return;

    $m->lg("$s Target removed");

    return 1;
}

sub _make_dir {
    my ($m, $target, $msg) = @_;
         
    my $s = '[_make_dir]';

    $target =~ /\S+/ or $m->lg("$s No target spcified"), return;

    $msg or $msg = 'directory';

    $m->lg("$s Creating $msg ($target)");

        -e $target and $m->lg("$s WARNING: $msg ($target) already exists")
        or mkdir $target, 0775
	    or $m->lg("$s Cannot mkdir $target: $!"), return;

    $m->lg("$s Target created");
        
    return 1;
}

sub _update_symlink {
	my ($m, $target, $link) = @_;
	
	my $s = '[_update_symlink]';
	
	my $success = 1;
	
	$m->lg("$s Updating symlink $target to $link");

	unlink($link) or $m->lg("$s Couldn't unlink ($link): $!") and $success = 1;
	symlink($target, $link) or $m->lg("$s Couldn't symlink ($target to $link): $!") and $success = 0;

	$m->lg("$s Symlink updated");

	return $success;
	}

sub _parse_file_name {
	my ($m, $file_name) = @_;

	my $s = '[_parse_file_name]';
	
	my $i = $file_name;
	$i =~ s/\/+/\//g;
	
	if ($i eq '/') { return ('/', ''); }
	
	$i =~ s/\/$//;
	if ($i =~ s/\/([^\/]+)$//) { return ($i, $1) }
	
	$m->lg("$s: Cannot parse file name ($file_name)");
	return
	}

sub _get_available_space {
	my ($m, $dir) = @_;

	my $s = '[_get_available_space]';

	unless($dir) { $m->die_n("$s: Internal error: No dir supplied to _get_available_space") }
	unless(-e $dir) { $m->die_n("$s: Internal error: dir ($dir) supplied to _get_available_space does not exist") }

	my $cmd = "df -k $dir";
	
	open (IN, "$cmd |") or $m->die_n("$s: Cannot run df command ($cmd): $!");
	
	my ($mount_point, $available_space);
	
	my $counter;
	while (<IN>) {
		next unless /^\//;
		my ($filesystem, $blocks, $used, $available, $use_percent, $mounted_on) = split(/\s+/);
		$mount_point = $mounted_on;
		$available_space = sprintf("%.2f", $available/1048576);
		$counter++;
		}
	
	if ($counter > 1) { $m->die_n("$s: Internal error: Multiple info lines at cmd ($cmd)") }
	if ($counter == 0) { $m->die_n("$s: Internal error: No info lines at cmd ($cmd)") }
	unless ($mount_point and $available_space) { $m->die_n("$s: Internal error: Cannot parse df cmd ($cmd)") }
	
	return ($mount_point, $available_space);
	}

sub _chunk_fasta {
	my ($m, $fasta, $out, $log) = @_;

	my $s = '[_chunk_fasta]';

	open (LOG, ">$log") or $m->lg("$s: Cannot write file $log"), return;

	my $io = Bio::SeqIO->new(-file=>"$fasta", -format=>'fasta');
	my $counter++;
	while (my $s = $io->next_seq) {
		my $id = $s->display_id;
		my $file_name = "$id.dna";
		open (OUT, ">$out/$file_name") or $m->lg("$s: Cannot write file $out/$file_name"), return;
		my $seq = $s->seq; $seq =~ s/(\S{60})/$1\n/g; chomp $seq;
		print OUT ">$id\n";
		print OUT $seq, "\n";
		$counter++;
		print LOG "Wrote sequence #$counter, $file_name\n";
		}
	
	close LOG;
	close OUT;
	return 1;
	}

###########################
# MANAGER PACKAGE         #
###########################

package Manager;

use strict;
use Time::Format qw(%time);
use Data::Dumper;
sub new {
	my ($self, $ref_o) = @_;

	my %o = %{$ref_o};
	my $config_file = $o{CONFIG}; # Must be hardcoded in CAPS; cannot be retrieved by object method
	my $status_file = $o{STATUS}; # Must be hardcoded in CAPS; cannot be retrieved by object method
	my $log_file = $o{LOG}; # Must be hardcoded in CAPS; cannot be retrieved by object method

	tie my %config, "Tie::IxHash";
	my $config = new Config::General(-ConfigFile => $config_file, -InterPolateVars => 1, -Tie => "Tie::IxHash");
	%config = $config->getall();

	tie my %status, "Tie::IxHash";
	if (-e $status_file) {	
		my $status = new Config::General(-ConfigFile => $status_file, -InterPolateVars => 1, -Tie => "Tie::IxHash");
		%status = $status->getall();
		}
	
	%{$status{params}} = %o;
	
	bless {'_config' => \%config, '_status' => \%status, '_options' => \%o}, $self;
	}

sub lg {
	my ($self, @message) = @_;
#	my $timestamp = $time{"dd-Mon-yy hh:mm:ss"};
	my $timestamp ='timestamp-disabled';

	my $caller_name = $self->sts('STEP_ID', undef, 'no_check');
	if ($caller_name) { $caller_name = "[$caller_name] "; }
	
	my $message = join('', @message); $message =~ s/\n$//g;	
	my $log_file = $self->opt('LOG');
	my $verbose = $self->opt('VERBOSE', 'no_check');
	
	my $log_line = "[$timestamp] ${caller_name}${message}\n";
	
	open (OUT, ">>$log_file") || die "Cannot write file ($log_file)\n";
	print OUT $log_line; if ($verbose) { print $log_line; }
	close OUT;
	
	return 1;
	}

sub die_n { # ($@) 
	my ($self, @message) = @_;
	my $verbose = $self->opt('VERBOSE', 'no_check');
	
	$self->lg("FATAL ERROR: ", @message);
	unless ($verbose) { print "FATAL ERROR: Check log file - Exiting!\n"; }
	$self->clear_step_id;
	exit 1; # Exit non-zero
	}

sub _dump_status {
	my ($self) = @_;
	my $status_file = $m->opt('STATUS');
	my $ref_status = $self->{_status};
	Config::General::SaveConfig($status_file, $ref_status);
	}
	

sub cfg {
	my ($self, $key, $no_check) = @_;

	my $s = '[cfg]';

	if ($no_check and $no_check ne 'no_check') { die("$s Internal error: <no_check> cannot be any value other than 'no_check'") }
	
	unless ($key) { $self->die_n("$s Internal error: A cfg key must be specified") }
	$key = uc($key); # Now key is case insensitive

	my $species = $self->opt('SPECIES');
	
	unless (defined $self->{_config}->{params}->{$key} or defined $self->{_config}->{params}->{$species}->{$key}) {
		if ($no_check) { return undef }
		else { die ("$s Internal error: This cfg key ($key) is not defined"); }
		}
	
	if (defined $self->{_config}->{params}->{$key} and defined $self->{_config}->{params}->{$species}->{$key}) {
		die("$s Internal error: This cfg key ($key) is defined as global and species-specific simultaneously"); 
		}
	
	my $values;

	if (defined $self->{_config}->{params}->{$key}) { $values = $self->{_config}->{params}->{$key} }
	elsif (defined $self->{_config}->{params}->{$species}->{$key}) { $values = $self->{_config}->{params}->{$species}->{$key} }

	my @values;

	if (ref($values) eq "ARRAY") { @values = @{$values} }
	else { @values = ($values) }

	my @processed_values;
	
	foreach my $value (@values) {
		
		# Check if place holder
		if ($value =~ /place/ && $value =~ /holder/) { $m->lg("$s WARNING: Value ($value) for this cfg key ($key) might be a place holder") }

		# Substitute magic (run-time) variables in the cfg file
		if ($value =~ /\[SPECIES\]/) { my $rep = $self->opt('SPECIES'); $value =~ s/\[SPECIES\]/$rep/g; }
        if ($value =~ /\[RELEASE\]/) { my $rep = $self->sts('RELEASE'); $value =~ s/\[RELEASE\]/$rep/g; }
		if ($value =~ /\[RELEASE_ID\]/) { my $rep = $self->sts('RELEASE_ID'); $value =~ s/\[RELEASE_ID\]/$rep/g; }
		if ($value =~ /\[DOWNLOAD_DIR\]/) { my $rep = $self->sts('DOWNLOAD_DIR'); $value =~ s/\[DOWNLOAD_DIR\]/$rep/g; }
		if ($value =~ /\[LOG_FILE\]/) { my $rep = $self->opt('LOG'); $value =~ s/\[LOG_FILE\]/$rep/g; }
#		if ($value =~ /\[TIMESTAMP\]/) { my $rep = $time{"yy-mm-dd.hh-mm-ss"}; $value =~ s/\[TIMESTAMP\]/$rep/g; }
		if ($value =~ /\[TIMESTAMP\]/) { my $rep = "disabled"; $value =~ s/\[TIMESTAMP\]/$rep/g; }
		if ($value =~ /\[NULL\]/) { my $rep = ""; $value =~ s/\[NULL\]/$rep/g; }
		if ($value =~ /\[NONE\]/) { my $rep = "\'\'"; $value =~ s/\[NONE\]/$rep/g; }
		if ($value =~ /\[NEXT_RELEASE_ID\]/) { my $rep = $self->sts('RELEASE_ID') + 1; $value =~ s/\[NEXT_RELEASE_ID\]/$rep/g; }
		if ($value =~ /\[PREV_RELEASE_ID\]/) { my $rep = $self->sts('RELEASE_ID') - 1; $value =~ s/\[PREV_RELEASE_ID\]/$rep/g; }
		if ($value =~ /\[SPECIES_LONG\]/) { 
            my $species = $self->opt('SPECIES'); 
            my %translation = ( elegans => 'c_elegans', briggsae => 'briggsae' );
            my $rep = $translation{$species} or $self->die_n("Cannot resolve species designation ($species) to SPECIES_LONG!");
            $value =~ s/\[SPECIES_LONG\]/$rep/g; 
            }        
		
        # Process alone NULL
		if ($value eq '[NULL]') { $value = undef };

		# Check if all magic variables are removed
		if ($value =~ /[\[\]]/) { die("$s Internal error: Key ($key) can not be fully interpolated (Value: $value)!\n"); }

		push(@processed_values, $value);
		}

	if (@processed_values > 1) { return \@processed_values; }

	return $processed_values[0];
	}
	

sub opt {
	my ($self, $key, $no_check) = @_;

	my $s = '[opt]';

	if ($no_check and $no_check ne 'no_check') { die("$s Internal error: <no_check> cannot be any value other than 'no_check'") }

	unless ($key) { $self->die_n("$s Internal error: A opt key must be specified") }
	$key = uc($key); # Now key is case insensitive

	unless (defined $self->{_options}->{$key}) { 
		if ($no_check) { return undef }
		else { die("$s Internal error: This opt key ($key) is not defined") }
		}
	my $value = $self->{_options}->{$key};
	
	return $value;
	}
	

sub sts {
	my ($self, $key, $set, $no_check) = @_;
	
	my $s = '[sts]';
	
	unless ($key) { die("$s Internal error: A sts key must be specified") }
	$key = uc($key); # Now key is case insensitive

	if ($set eq 'no_check') { die("$s Internal error: <set> cannot be 'no_check'") }
	if ($no_check and $no_check ne 'no_check') { die("$s Internal error: <no_check> cannot be any value other than 'no_check'") }

	unless (defined $set) {
		unless (defined $self->{_status}->{$key}) { 
			if ($no_check) { return undef }
			else { die("$s Internal error: This sts key ($key) is not defined") }
			}
		my $value = $self->{_status}->{$key};
		return $value;
		}
	
	$self->{_status}->{$key} = $set;
	$self->_dump_status;		
	return $set;
	}

sub check_if_complete {
	my ($self) = @_;	
	my $step_id = "STEP:" . $self->sts('STEP_ID');
	my $status = $self->sts($step_id, undef, 'no_check');
	$m->lg;
	if ($status) { $self->lg("WARNING: This step ($step_id) has been completed before, skipping ..."); $m->lg; return 1; }
	else { $self->lg("This step ($step_id) has *NOT* been completed before, proceeding ..."); $m->lg; return; }
	}

sub mark_as_complete {
	my ($self) = @_;	
	my $step_id = "STEP:" . $self->sts('STEP_ID');
	$self->sts($step_id, '1') or return;
	return 1;
	}

sub set_step_id {
	my ($self, $id, @args) = @_;	
	shift @args;
	my $step_id = join(":", $id, @args);
	$m->sts('STEP_ID', $step_id) or die "Internal error: Cannot set step id to $step_id";
	return 1;
	}

sub clear_step_id {
	my ($self) = @_;	
	$m->sts('STEP_ID', undef, 'no_check');
	return 1;
	}


#################
# Documentation #
#################

=pod

=head1 Updating WormBase (Development/Mirror Sites)

Updating Wormbase consists of multiple steps as explained in updating_wormbase.pod (please
refer to that document before using this one). One of the steps consist of updating the WormBase Development Site. 
This is done by the update_scripts/update_wormbase.pl. A re-write of this script has been made 
(committed to CVS early June 2004) to address issues resulting from the expanding
nature of Wormbase. This document is written as a user manual for this new update script (update_wormbase-dev.pl).

=head1 Background

Updating the development site uses raw data files from ftp servers of the Sanger Center (for C. elegans) 
and Cold Spring Harbor Laboratory (C. briggsae). The files are processed and copied/loaded into corresponding 
locations. When the development site is ready to be made live, it is transferred to the live server by another script
which basically copies over the components. As update_wormbase-dev.pl script is used to process raw data files, it can 
also be used to make mirror site installations as well.

The steps that make up the process of updating the site can be grouped as follows:

 1- Downloading the necessary data release
 2- Unpacking files and creating the AceDB database
 3- Generating necessary GFF raw files and loading them into MySQL
 4- Dumping/copying sequences and creating BLAST and BLAT databases, starting BLAT server
 5- Copying files to the FTP site directory
 6- Updating symlinks in the server directory hierarchy
 7- Restarting servers (Apache, Ace) - needs to be done manually
 8- Updating software - needs to be done manually

=head1 New features

A number of new features have been implemented in the new update script:

1- The configuration information has been separated from the script and placed in a separate file. All (well, almost) hardcoded information such as the directory/file
names within the script has been removed and placed in the configuration file. Configuration file has been designed in a way to separate information for different species
from eachother allowing independent handling of each species during installation. This makes it easier to specify different requirements for different species and 
would make it easier to add new species.

2- All steps involved had been strictly placed into individual subroutines and most of them had been made generic so that they can handle different species by taking species
name (and other options) as a parameter. This allows same code to be used for multiple species and creates a structure easier to maintain/troubleshoot.

3- An error tracking method has been implemented. Individual steps are tracked and in case the script is restarted due to a failure, previously completed steps are not repeated.

4- Extensive logging has been added. Script provides detailed logs of all steps and also captures standard input/output from critical external applications it executes.

=head1 Usage

The script can be initiated in three different scenarios:

1- The user does not know which particular release to install and wants either the latest development or latest live release. 
Script determines the particular release to download.

 update_wormbase-dev.pl -start_new -mirror latest_live|latest_dev -status <status_file> -config <config_file> -log <log_file> -species <species> [-verbose]

 -start_new:  This is a new session (versus a previously failed attempt, will be explained later)
 -mirror:     A release will be mirrored (downloaded). Recognizes latest_live or latest_dev.
 -status:     Name of the file that the script will use to keep status (original command line options and which steps are completed).
 -config:     Name of the config file.
 -log:        Name of the file that the script will use to keep its log.
 -verbose:    If set, all log information recorded in the log file is also displayed on the screen.

2- The user knows which particular release to install and specifies the name of that particular release (e.g. WS125, CB25).

 update_wormbase-dev.pl -start_new -mirror <release> -status <status_file> -config <config_file> -log <log_file> -species <species> [-verbose]

Instead of providing one of the keywords 'latest_live' or 'latest_dev' the name of the release is specified. Please note that anything other than
these two words will be interpreted as the name of a release.

3- The user has a local directory that contains the *complete* download of a release and wants to install that particular release.

 update_wormbase-dev.pl -start_new -dir <directory> -status <status_file> -config <config_file> -log <log_file> -species <species> [-verbose]

Instead of providing a -mirror option a -dir option is provided:

 -dir:       Specifies the name of the local directory that contains the release.

When specifying file names/directories, absolute paths must be used.

Independent of how the script was intitated (a new session was started), if it fails/stopped, it can be re-started by specifying the status file only.
The status file contains all initial parameters specified and an inventory of the steps that have already been 
completed. Again, the file name must be specified using its absolute path. The following command-line is used:

 update_wormbase-dev.pl -continue -status <status_file>

=head1 Configuration File Design

The script uses a configuration file parseable by the CPAN Config::General module.

Configuration file is structured as follows:

 <params>
     GLOBAL_PARAM1    value
     GLOBAL_PARAM2    value
     ...
     <species1>
         PARAM1    value
         PARAM2    value
         ...
     </species1>
     <species2>
         PARAM1    value
         PARAM2    value
         ...
     </species2>
     ...
 </params>

A parameter defined can be used later in the config file. For example
GLOBAL_PARAM1 can be used within <species1> as '$GLOBAL_PARAM1' as
part of a value and is interpolated.  Please check Config::General
documentation for details of parameter interpolation within the
configuration file.

When called from within the script, parameter names are
case-insensitive, however if you are going to do parameter
interpolation using Config::General's capabilities, case should be
identical.

A number of 'magic variables' have been introduced into the
configuration file. These variables are interpolated into their
corresponding run-time values and they can be used anywhere in the
file. Currently the script recognizes the magic variables listed
below:

 [SPECIES]           Name of species specified
 [RELEASE]           Name of release, e.g. WS123
 [RELEASE_ID]        Number part of the release, e.g. 123 is the release id for release WS123
 [LOG_FILE]          Name of logfile
 [TIMESTAMP]         This is interpolated into a timestamp (everytime it is being used, not when config file is loaded) in the format "yy-mm-dd.hh-mm-ss"
 [NULL]              Interpolates into ""
 [NONE]              Interpolates into "\'\'"

Some values in the config file are provided as
'__place_holder__'. These are primarily parameters that are not
relevant to a particular species but included to be comprehensive. If
they are accessed during a session, script logs a warning. Under
normal processing conditions, these are parameters that are not needed
to be accessed.

=head1 Requirements and Customizing Configuration File

Most of the configuration file components are not intended for the
user to manipulate. They contain information that reflect the current
design of the raw data files and the installation. For example, unless
the name of a particular tarball or where it is extracted is changed,
the parameters defining these do not change.  Practically such a
change would in most cases would require a closer look at the
installation process to make sure things work.

For a typical update, a handful of parameters are needed to be changed
(or at least checked to make sure that they are correct). For a
typical setup even most of of these will not need to be changed but if
you want to run a test installation, make sure you understand and
change at least these parmaters. Otherwise, you might overwrite your
current installation. In the config file template provided
(update_wormbase-dev.cfg), these are marked with the text
'***CHECK***'. They are described below:

Global parameters (under <params>; species-independent)

 WORMBASE               Wormbase installation directory                                      - /usr/local/wormbase
 BUILD_ROOT_DIR         Where downloaded releases will be stored                             - /usr/local/ftp/pub/wormbase
 ACEDB_ROOT_DIR         Acedb database installation directory                                - /usr/local/acedb
 ACEDB_ROOT_GROUP       Name of the UNIX group that some acedb files will be changed to      - acedb
 MYSQL_DATA_DIR         Location of the local mysql server data directory; used for checking mysql diskspace requirements    - /usr/local/mysql
 SCRIPT_DIR             Location of the side scripts                                         - $WORMBASE/update_scripts

Species-specific parameters

 GFFDB_MYSQL_USER       Username to connect to the MySQL database                              - read below
 GFFDB_MYSQL_PASS       Password to connect to the MySQL database                              - read below
 MAIN_GFFDB_LOAD_DB     Name of main gff database in mysql, used for initial loading           - elegans_load for elegans, briggsae_load for briggsae
 MAIN_GFFDB_LIVE_DB     Name of main gff database in mysql, used for the perm db after loading - elegans for elegans, briggsae for briggsae
 PMAP_GFFDB_LOAD_DB     Name of pmap gff database in mysql, used for initial loading           - elegans_pmap_load for elegans, briggsae does not have one
 PMAP_GFFDB_LIVE_DB     Name of pmap gff database in mysql, used for the perm db after loading - elegans_pmap for elegans, briggsae does not have one
 BLAT_SERVER_PORT       BLAT server port number for the genomic sequence database              - 2003 for elegans, 2004 for briggsae

The user used for the gff load must have the following privileges:
 - 'ALL' privileges on the databases provided
 - 'FILE' privilege on *.*

Although, not intended to be modified by the user, the steps that are performed in the installation can be customized. For each species, the necessary steps 
are provided as a list in the configuration file. Unless, you know the inner workings of the particular step (corresponds to a single subroutine) do
not modify this list.

For example, for elegans, the following list is provided.

Each step corresponds to a subroutine and parameters can be passed onto the subroutine as follows:

 STEPS name_of_subroutine:parameter:parameter:...


 STEPS     check_requirements:diskspace         --> Checks diskspace requirements
 STEPS     check_requirements:mysql_access      --> Checks mysql access requirements
 STEPS     check_requirements:write_to_dirs     --> Checks directory writing permissions
 STEPS     retrieve_build                       --> Determines which release to download/copy and retrieves it
 STEPS     copy_to_ftp                          --> Copies the raw release files into the ftp directory
 STEPS     copy_chrom_dumps                     --> Copies chromosome files to corresponding directory
 STEPS     do_untar                             --> Untars Acedb database packages
 STEPS     do_customize                         --> Copies native wspec directory to the new acedb database, to allow previous users access to the new database
 STEPS     dump_sequences:nucl                  --> Dumps genomic sequence set
 STEPS     make_blastdb:nucl                    --> Makes the genomic sequence set blastable
 STEPS     dump_sequences:prot                  --> Dumps protein sequence set
 STEPS     make_blastdb:prot                    --> Makes the protein sequence set blastable
 STEPS     dump_sequences:ests                  --> Dumps EST sequence set
 STEPS     make_blastdb:ests                    --> Makes the EST sequence set blastable
 STEPS     load_epcr                            --> Creates an e-PCR database (file)
 STEPS     load_gffdb:main                      --> Loads the main GFF database
 STEPS     load_gffdb:pmap                      --> Loads the pmap GFF database
 STEPS     run_blat_server                      --> Prepares genomic sequences, converts to .nib format and starts the gfserver
 STEPS     dump_features:gene_names             --> Dumps gene names
 STEPS     dump_features:brief_ids              --> Dumps brief ids
 STEPS     dump_features:swissprot              --> Dumps swissprot associations
 STEPS     dump_features:go                     --> Dumps GO associations
 STEPS     copy_release_notes                   --> Copies release notes to corresponding location
 STEPS     update_symbolic_links:ftp            --> Updates ftp server symbolic links
 STEPS     update_symbolic_links:acedb          --> Updates acedb directory symbolic links
 STEPS     update_symbolic_links:blastdb        --> Updates blast directory symbolic links
 STEPS     archive_files                        --> Archives a set of files

=head1 Directions and Troubleshooting

Retrieve the config file provided and customize it for your system as explained above. 

Run the script with the customized config file for each species. As of
this writing (June 2004) C. elegans and C. briggsae data is available
in Wormbase. For a complete installation, both elegans and briggsae
components should be installed. Due to the way data is packaged,
elegans components should be updated before briggsae update is
performed. Briggsae data relies on elegans data set for some of its
components.

Script performs a number of simple checks (These are steps that can be
disabled if necessary, please see section on customization of the
config file). It checks for available disk space mysql access and
directory write permissions.

In the event of a failure, under normal conditions, script will die
nicely and log file should be sufficient to idetify the problem. The
log file contains information on actions taken directly by the
script. For side applications that the script runs, standard out and
error are captured in a file (file name:
<log_file>.timestamp.<some_identification_extension>).  These files
can be used to identify problems originating from side scripts.

It's always a good idea to examine the logfile throughly. Certain
problems are not considered critical but logged as a 'WARNING'
(labeled as a WARNING in the log file). For example, if a directory is
instructed to be removed but it does not exist, this would not fail
the script but a warning will be issued. Please check warnings and
confirm that they do not adversely affect the update.

The update process (as of this writing, June 2004) assumes an already
running installation exists and it only updates the data
components. It does not do an installation from scratch. Also, after
the update is done the following steps should be taken:

 - Correct software version should be installed (basically a CVS update of the correct branch would be sufficient, make sure all conflicts are resolved if applicable).
 - Apache should be restarted.
 - Sgifaceserver should be restarted.

(These components may be incorporated into the update script in future releases).

=head1 Author

 Author: Payan Canaran (canaran@cshl.org)
 Copyright@2004 Cold Spring Harbor Laboratory

=cut
