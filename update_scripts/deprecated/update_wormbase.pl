#!/usr/bin/perl

# Things remaining to clean up...
# Passing of global variables.  place in the manager obj
# verify rebuild, update wsversion handling
# command line switching to turn on / off different processes


use strict;
BEGIN {
    use constant WORMBASE => $ENV{WORMBASE}     || '/usr/local/wormbase';
    use constant ACEDB    => $ENV{ACEDB}        || '/usr/local/acedb';
    use constant FTP_SITE => $ENV{WORMBASE_FTP} || '~ftp/pub/wormbase';
    use lib WORMBASE . '/lib';
}

$ENV{PATH} = '/bin:/usr/bin:/usr/local/bin:/usr/local/acedb/bin:/usr/local/wublast/bin:/usr/local/wublast:/usr/local/mysql/bin';

# Set the umask liberally so we don't choke on subsequent runs
umask(002);

use Mirror;
use Net::FTP;
use Getopt::Long;
use POSIX 'strftime';
use Cwd 'cwd';

# adjust these to turn on and off steps of the process
use constant CHECKNR        => 1;  # check for new releases
use constant MIRROR         => 1;  # copy from Sanger to tmp directory
use constant MIRROR_CB      => 1;  # copy from dev.wormbase.org to tmp directory
use constant UNTAR          => 1;  # unpack database
use constant SKEL           => 1;  # add local users to database login
use constant COPY_TO_FTP    => 1;  # copy mirrored files to FTP directories
use constant CHROMTABLE     => 0;  # dump CHROMOSOME*.html files  NO LONGER NEEDED
use constant INTERPOLATED   => 0;  # dump interpolated positions  NO LONGER NEEDED
use constant BLAST_NUC      => 1;  # create BLAST database for genome
use constant BLAST_PEP      => 0;  #   "      "     "      "   wormpep
use constant BLAST_EST      => 1;  #   "      "     "      "   ESTs
use constant BLAST_BRIG     => 1;  #   "      "     "      "   briggsae
use constant GFFDB_LOAD     => 1;  # load the elegans GFF database
use constant CB_GFFDB_LOAD  => 0;  # load the briggsae GFF database, off by default since briggsae rarely changes
use constant PMAP_GFFDB_LOAD=> 1;  # load the elegans_pmap GFF database
use constant EPCR_LOAD      => 1;  # load the PCR/OLIGO database
use constant INDEX_UPDATE   => 1;  # update home page with new release
use constant MAKE_GENENAME  => 1;  # make the gene name table dump
use constant BUILD_BLAT     => 1;  # rebuild the blat database
use constant DUMP_BRIEF_IDS => 0;  # create a file of concise descriptions for genes

# The following options fine tune the behavior of the script
use constant REMOVE_MIRRORED => 0; # remove mirrored data after copying to FTP site

# change this if you have a mysql user and password
use constant MYSQL_USER        => '';
use constant MYSQL_PASS        => '';

# The locations of your WormBase and mirrored directories
use constant HTML     => WORMBASE . '/html';
use constant MIRRORED => WORMBASE . '/mirrored_data';


###################################################
#   NO USER-SERVICEABLE OPTIONS BELOW THIS POINT
###################################################
# Mirroring paths
use constant LOCALP   => '/current_release';
use constant REMOTEH  => 'ftp.sanger.ac.uk';
use constant REMOTEV  => '/pub/wormbase';
use constant REMOTEP  => '/pub/wormbase/development_release'; # used for checking new release
use constant SKELD    => WORMBASE . '/wspec';  # our wspec files
use constant BLAST    => WORMBASE . '/blast';

# Briggsae files and paths
# Currently no versioning in place for briggsae
use constant REMOTEH_CB => 'dev.wormbase.org';
use constant REMOTEV_CB => '/pub/wormbase/briggsae-for-mirrors';
use constant CB_RELEASE => 'CB25';
use constant CB_FASTA   => 'gff_db_load_files/run_25/briggsae_25.fa.gz';
use constant CB_GFF     => 'gff_db_load_files/run_25/briggsae_25.WS121.gff.gz';

# These two directories will be created within each release directory
# Constants in case we ever get sick of 'em
# If copying to the FTP site, we will also symlink these to the current release
use constant DNA_DUMPS  => 'DNA_DUMPS';
use constant GENE_DUMPS => 'GENE_DUMPS';
use constant CB_CURRENT => 'briggsae-current_release';
use constant CE_CURRENT => 'elegans-current_release';
#use constant WORMPEP_CURRENT => 'wormpep_current';
#use constant WORMRNA_CURRENT => 'wormrna_current';

# Scripts
use constant BLASTN_SCRIPT     => WORMBASE . '/update_scripts/dump_nucleotide.pl';
use constant BLASTN_EST_SCRIPT => WORMBASE . '/update_scripts/dump_est.pl';
use constant BLAT_SERVER       => WORMBASE . '/blat';
use constant BRIEF_IDS_SCRIPT  => WORMBASE . '/update_scripts/dump_brief_ids.pl';
use constant CBGFFDB_SCRIPT    => WORMBASE . '/update_scripts/briggsae2gffdb.pl';
use constant CHROMTAB_SCRIPT   => WORMBASE . '/update_scripts/dump_genome.pl';
use constant EPCR_SCRIPT       => WORMBASE . '/update_scripts/make_epcr_db.pl';
use constant GENENAME_SCRIPT   => WORMBASE . '/update_scripts/dump_names.pl';
use constant GFFDB_SCRIPT      => WORMBASE . '/update_scripts/ace2gffdb.pl';
use constant INTERPOL_SCRIPT   => WORMBASE . '/update_scripts/dump_interpolated.pl';
use constant PMAPGFFDB_SCRIPT  => WORMBASE . '/update_scripts/pmap2gff.pl';

$| = 1;

my ($ws_version,$rebuild,$passive);
GetOptions('rebuild=s'    => \$rebuild,
	   'wsversion=s'  => \$ws_version,
	   'passive'      => \$passive,
	  ) || die <<USAGE;
Usage update_wormbase.pl [options...]
  Mirror current acedb database from Sanger and update wormbase.

 Options:
      -rebuild <dir>   Don\'t mirror, just rebuild from mirrored database
                       located in indicated directory (use "0" for current release).

      -wsversion <ver> Mirror indicated WS** version.

      -passive         Force passive FTP transfers
USAGE
;

my $manager = Manager->new({-mirror_base => MIRRORED,
			    -ftp_base    => FTP_SITE,
			   });

my ($ACE_DIR,$CE_RELEASE);
if (defined $rebuild) {
  logit("Rebuilding web files for database in $rebuild; this should be a full, still-packed WSXX version");
  ($ACE_DIR,$CE_RELEASE) = get_installedace($rebuild || ACEDB . "/elegans");
  
  # Some logic redundancy here.
  $manager->add_species({-name         => 'elegans',
			 -release      => $CE_RELEASE,
			 -copy_to_ftp  => COPY_TO_FTP, # boolean to control final release path
			});

  # Eventually, I should discover the briggsae version.
  $manager->add_species({-name         => 'briggsae',
			 -release      => CB_RELEASE,  # $CB_RELEASE;
			 -copy_to_ftp  => COPY_TO_FTP, # boolean to generate final release path
			});
}

# Mirroring, unpacking, copying
unless (defined $rebuild) {
  my $CE_RELEASE = check_for_new_release($ws_version)
    or logit("No new release. Quitting") and exit 0 if CHECKNR || $ws_version;
  
  # Create the mirrored directory (under wormbase)
  make_target(MIRRORED,'creating top-level mirror directory') or die "Couldn't create top-level mirror directory: $!";

  if ($CE_RELEASE) {
    $ACE_DIR = ACEDB . "/elegans_$CE_RELEASE";
  } else {
    ($ACE_DIR,$CE_RELEASE) = get_dirname(MIRRORED) or die "Can't deduce new elegans directory name";
  }

  $manager->add_species({-name         => 'elegans',
			 -release      => $CE_RELEASE,
			 -copy_to_ftp  => COPY_TO_FTP, # boolean to control final release path
			});

  # Eventually, I should discover the briggsae version.
  $manager->add_species({-name         => 'briggsae',
			 -release      => CB_RELEASE,  # $CB_RELEASE;
			 -copy_to_ftp  => COPY_TO_FTP, # boolean to generate final release path
			});

  do_mirror()          or die "mirroring from Sanger failed.\n" if MIRROR;
  do_briggsae_mirror() or die "mirroring from dev.wormbase.org failed.\n" if MIRROR_CB;
}


copy_chrom_dumps() or die "can't copy chromosome files into DNA_DUMPS and GENE_DUMPS.\n";
briggsae_legacy_issues() or die "couldn't copy briggsae fasta to unpacked dir.\n";

if (COPY_TO_FTP) {
  foreach my $species (qw/elegans briggsae/) {
    next if ($species eq 'briggsae' && !MIRROR_CB);
    copy_to_ftp($species) or die "can't copy $species mirrored files at ",
      $manager->mirror_path($species) . ' to FTP site at ' . $manager->release_path($species) . "\n";
  }
  update_symbolic_links();
}

do_untar($ACE_DIR)      or die "untar failed.\n" if UNTAR;
do_customize($ACE_DIR)  or die "do_customize() failed\n" if SKEL;


## THESE TWO SCRIPTS ARE DEPRECATED
dump_chromtable($ACE_DIR)         or die "can't dump chromtable\n" if CHROMTABLE;

dump_interpolated($ACE_DIR)       or die "can't dump interpolated blast table\n" if INTERPOLATED;

make_nucleotide_blastdb($ACE_DIR) or die "can't dump nucleotide blast table\n" if BLAST_NUC;

make_protein_blastdb()     or die "can't make wormpep blast table\n" if BLAST_PEP;

make_est_blastdb($ACE_DIR) or die "can't dump nucleotide EST blast table\n" if BLAST_EST;

make_briggsae_blastdb($ACE_DIR) or die "can't dump briggsae blast tables\n" if BLAST_BRIG;

load_epcr($ACE_DIR)       or die "can't create e-PCR database\n"        if EPCR_LOAD;

load_gffdb($ACE_DIR)      or die "can't create GFF database: $?\n"          if GFFDB_LOAD;

load_cbgffdb($ACE_DIR)    or die "can't create briggsae GFF database: $?\n" if CB_GFFDB_LOAD;

load_pmapgffdb($ACE_DIR)  or die "can't create briggsae GFF database\n" if PMAP_GFFDB_LOAD;

copy_chr_files_for_blat() or die "can't copy chromosome files from mirrored directory \n" if BUILD_BLAT;

make_genename_table($ACE_DIR) or die "Can't make gene name table\n" if MAKE_GENENAME;

dump_brief_ids($ACE_DIR) or die "Can't create brief IDs file\n" if DUMP_BRIEF_IDS;

copy_release_notes($ACE_DIR) or die "can't copy release notes";

#update_index($ACE_DIR,$CE_RELEASE) or die "can't update index \n" if INDEX_UPDATE;

# create new links
unlink ACEDB.'/elegans';
symlink $ACE_DIR,ACEDB.'/elegans';

#send_notification();

logit("Release $CE_RELEASE successfully created.  Old files not unlinked");

logit("You need to restart server");


###############################################################################
##                            SUBROUTINES
###############################################################################


################################
##         VERSIONING
################################

sub check_for_new_release {
  my $desired_release = shift;
  logit($desired_release ? "checking for release $desired_release" : "checking for new release");
  
  my $ftp = Net::FTP->new(REMOTEH) or die "check_for_new_release(): Can't open ${\REMOTEH}";
  $ftp->login(anonymous => 'webmaster@www.wormbase.org') 
    or die "check_for_new_release(): can't login",$ftp->message;
  
  if ($desired_release) {
    $ftp->cwd(REMOTEV . "/$desired_release")
      or die "check_for_new_release(): Can't cd to release $desired_release",$ftp->message; 
  } else {
    my $result = $ftp->cwd(REMOTEP);
    unless ($result) {
      warn "error for FTP server: ",$ftp->message,"Manually searching for newest release\n";
      $ftp->cwd(REMOTEV);
      my $release = 0;
      my $number  = 0;
      foreach ($ftp->dir) {
	next unless /\s+(WS(\d+))/;
	warn "found $1\n";
	next unless $number < $2;
	$release = $1;
	$number = $2;
      }
      $release or die "Couldn't find latest release.  Aborting\n";
      $ftp->cwd(REMOTEV . "/$release") or die "check_for_new_release(): Can't cd to release $release",$ftp->message; 
    }
  }
  my $release;
  foreach ($ftp->ls) {
    next unless /^database\.(WS\d+).+\.tar\.gz$/;
    $release = $1;
    last;
  }
  $release or die "check_for_new_release(): can't find release name";
  return 0 if !$desired_release && -d ACEDB . "/elegans_$release"; 
  $release;
}

sub get_dirname {
  my $tmp = shift;
  my $release;
  if (-d $tmp) {
    opendir(D,$tmp) or warn "get_dirname(): can't open $tmp for reading" and return;
    while (defined($_ = readdir(D))) {
      next unless /^database\.(WS\d+).+\.tar\.gz$/;
      $release = $1;
      last;
    }
    closedir D;
    return (ACEDB . "/elegans_$release",$release);
  }
  elsif (-l ACEDB . "/elegans") {
    warn "no temporary directory, dumping from current elegans release directory";
    return get_installedace(ACEDB . "/elegans");
  }
}

sub get_installedace {
  my $dir = shift;
  my $release;
  my $realdir = -l $dir ? readlink $dir : $dir;
  ($release) = $realdir =~ /(WS\d+)$/;
  $release or warn "Couldn't find release name" and return;
  return wantarray ? (ACEDB . "/elegans_$release", $release) : ACEDB . "/elegans_$release";
}



#=pod
#  
#  =head1 do_mirror($version)
#  
#  Mirror the latest Sanger release directly to the WormBase FTP site at
#  ~ftp/pub/wormbase/elegans/$VERSION, creating intermediate directories
#  first, if required. Symlink $ftp/elegans_current_release to the new
#  version.
#
#  =cut

################################
##         MIRRORING
################################

sub do_mirror {
  my $species = shift;
  $species ||= 'elegans';
  my $release = $manager->release($species);
  logit("Mirroring $species $release from " . REMOTEH);
  make_target(MIRRORED . "/$species",'do_mirror');
  my $m = Mirror->new(-host      => REMOTEH,
		      -path      => REMOTEV . "/$release",
		      -verbose   => 1,
		      -localpath => MIRRORED . "/$species",
		      -passive   => $passive,
		     );
  if ($m->mirror) {  # success
    return 1;
  } else { # error
    system 'rm','-rf',MIRRORED . "/$release";
    return;
  }
}

## Currently no versioning of the briggsae releases
sub do_briggsae_mirror {
  my $release = $manager->release('briggsae');
  logit("Mirroring C. briggsae $release data from " . REMOTEH_CB);
  make_target(MIRRORED . '/briggsae','do_briggsae_mirror');
  my $m = Mirror->new(-host      => REMOTEH_CB,
		      -path      => REMOTEV_CB . "/$release",
  		      -verbose   => 1,
  		      -localpath => MIRRORED . '/briggsae',
  		      -passive   => $passive,
  		     );
  
  if ($m->mirror) {
    return 1;
  } else {
    return;
  }
}

sub copy_to_ftp {
  my $species = shift;
  logit ("Copying $species mirrored data to FTP site");
  my ($mirrored_path,$release_path) = ($manager->mirror_path($species),$manager->release_path($species));
  my $ftp = interpolate(FTP_SITE . "/$species");

  make_target($ftp,'copy_to_ftp') or return;
  system("rm","-rf","$release_path")
    and warn "copy_to_ftp(): couldn't remove previous release: $!\n" and return;  # Remove old, possibly failed attempts

  system("cp -r $mirrored_path $ftp")
    and warn "copy_to_ftp(): couldn't copy to mirror: $!\n"  and return;

  system("rm -rf $mirrored_path")
    and warn "copy_to_ftp(): couldn't remove temp dir: $!\n" and return if (REMOVE_MIRRORED);
  1;
}

# Legacy paths and file locations (related to path contained in ace2gff)
# This should be resolved
sub briggsae_legacy_issues {
  logit("Resolving briggsae legacy issues");
  my $fasta_path = interpolate($manager->mirror_path('elegans') . '/' . DNA_DUMPS . '/unpacked/cbriggsae.fa.gz');
  my $command = "cp " . $manager->mirror_path('briggsae') . '/' . CB_FASTA . " $fasta_path";

  # Remove previously existing copy
  my $fasta = $fasta_path;
  $fasta =~ s/\.gz$//;
  system("rm","-rf",$fasta_path) and warn "briggsae_legacy_issues(): couldn't remove old .fa: $!\n"    and return;
  system("rm","-rf",$fasta)      and warn "briggsae_legacy_issues(): couldn't remove old .fa.gz: $!\n" and return;
  system ($command)              and warn "briggsae_legacy_issues(): couldn't copy briggsae.fa: $!\n"  and return;
  system ("gunzip $fasta_path")  and warn "briggsae_legacy_issues(): couldn't gunzip fa: $!\n"         and return;
  1;
}


# Rearrange the  CHROMOSOMES directory into DNA_DUMPS and GENE_DUMPS
# This is partly a legacy issue...
# This could go into the release_path as well (will be the same if not copying to ftp)
sub copy_chrom_dumps {
  logit("Moving CHROMOSOME_* files to DNA_DUMPS and GENE_DUMPS");
  my $mirror_path = $manager->mirror_path('elegans');
  my $dna   = interpolate("$mirror_path/" . DNA_DUMPS);
  my $genes = interpolate("$mirror_path/" . GENE_DUMPS);
  make_target($dna,'copy_chrom_dumps') or return;
  make_target("$dna/unpacked",'copy_chrom_dumps') or return;
  make_target($genes,'copy_chrom_dumps') or return;
  system("rm -rf $mirror_path/" . DNA_DUMPS  . "/*dna.gz");  # Clear out the old for rebuilding
  system("rm -rf $mirror_path/" . GENE_DUMPS . "/*gff.gz");
  system("cp $mirror_path/CHROMOSOMES/CHROMOSOME*dna.gz $dna/.")   and warn "copy_chrom_dumps(): couldn't copy: $!\n" and return;
  system("cp $mirror_path/CHROMOSOMES/CHROMOSOME*gff.gz $genes/.") and warn "copy_chrom_dumps(): couldn't copy: $!\n" and return;
  #  system("mv $mirror_path/CHROMOSOMES/* $mirror_path/.");
  #  system("rm","-rf","$mirror_path/CHROMOSOMES");
  1;
}



################################
##  UNPACKING / CUSTOMIZATION
################################

sub do_customize {
  my $dir = shift;
  logit("Updating Acedb passwd file with local info");
  -d $dir or warn "do_customize(): no directory $dir" and return;
  # right now, just copy our own wspec files into release directory
  system "chmod ug+rw $dir/wspec/*.wrm" and return;
  foreach (<${\SKELD}/*.wrm>) {
  system "cp","$_","$dir/wspec" and warn "Can't copy $_ to new wspec" and return;
}
1;
}

sub do_untar {
  logit("Untarring Acedb directory");
  my $dest = shift;
  my $src = $manager->release_path('elegans');
  make_target($dest,'do_untar') or return;
  system 'chgrp','acedb',$dest;
  system 'chmod','g+ws',$dest  and return;
 
  chdir $dest or warn "do_untar() can't chdir to $dest: $!" and return;
  foreach (<$src/database*.tar.gz>) {
    system "gunzip -c $_ | tar xvf -" and warn "Tar failure: code $?" and return;
  }
  if (-e "$src/pictures.tar.gz" && ! -d "$dest/pictures") {
    logit("Untarring pictures");
    mkdir("$dest/pictures",0777) or warn "Can't make pictures directory: $!" and return;
    chdir "$dest/pictures" or warn "can't change to pictures directory: $!"  and return;
    system "gunzip -c $src/pictures.tar.gz | tar xvf -" and return;
  }
  system 'chmod','g+ws',"$dest/database" and return;
  1;
}


################################
##         GFF DBS
################################

sub load_gffdb {
  logit("Building the C. elegans GFF database. This may take some time");
  my $acedbdir = shift;
  my $release = $manager->release('elegans');
  my $release_path = $manager->release_path('elegans');
  my $fasta = interpolate("$release_path/" . DNA_DUMPS);
  my $gff   = interpolate("$release_path/" . GENE_DUMPS);
  my $gffdb = GFFDB_SCRIPT;
  my $auth = '';
  $auth .= "-user ${\MYSQL_USER}"  if MYSQL_USER;
  $auth .= " -pass ${\MYSQL_PASS}" if MYSQL_PASS;
  my $command = "$gffdb $auth -release $release -acedb $acedbdir -fasta $fasta -gff $gff";
  logit("   running command $command");
  system $command and warn "load_gffdb(): failed: $?\n" and return;
  1;
}

sub load_cbgffdb {
  logit("Building the C. briggsae GFF database. This may take some time");
  my $acedbdir = shift;
  my $release_path = $manager->release_path('briggsae');
  my $release      = $manager->release('briggsae');
  my $fasta = interpolate("$release_path/" . CB_FASTA);
  my $gff   = interpolate("$release_path/" . CB_GFF);
  my $gffdb = CBGFFDB_SCRIPT;
  my $auth = '';
  $auth .= "-user ${\MYSQL_USER}"  if MYSQL_USER;
  $auth .= " -pass ${\MYSQL_PASS}" if MYSQL_PASS;
  my $command = "$gffdb $auth -release $release -fasta $fasta -gff $gff";
  logit("   running command $command");
  system $command and warn "load_cbgffdb(): failed: $?\n" and return;
  1;
}

sub load_pmapgffdb {
  my ($acedbdir,$species) = @_;
  logit("Building $species pmap GFF database");
  $species ||= 'elegans';
  my $release = $manager->release($species);
  my $gffdb = PMAPGFFDB_SCRIPT;
  my $release_path = $manager->release_path($species);

  my $auth = '';
  $auth .= "-user ${\MYSQL_USER}"  if MYSQL_USER;
  $auth .= " -pass ${\MYSQL_PASS}" if MYSQL_PASS;
  my $command = "$gffdb $auth -release $release -acedb $acedbdir -tmp $release_path/" . GENE_DUMPS;
  logit("  running command $command");
  my $result = system $command;
  
  # Again, this throws the same error (3328, 13, permission denied, bad file descriptor)
  # ($result == 0) or warn "$gffdb failed: $?" and return;
  my $dump_file = interpolate("$release_path/" . GENE_DUMPS . "/$species-pmap.gff");
  unless (-e $dump_file) {
    system("gzip",$dump_file) and warn "load_pmapgffdb(): failed: $?\n" and return;
  }
  1;
}

sub load_epcr {
  logit("Building the epcr GFF database");
  my $acedbdir = shift;
  my $release = $manager->release_path('elegans');
  my $fasta = interpolate("$release/" . DNA_DUMPS);
  my $epcr_script = EPCR_SCRIPT;
  my $command = "$epcr_script $fasta";
  logit("running command $command");
  system $command and warn "load_epcr(): $epcr_script failed: $?" and return;
  1;
}



################################
##         BLAST DBs
################################

sub make_nucleotide_blastdb {
  my ($dir,$species) = @_;
  $species ||= 'elegans';

  logit("Making $species genomic BLAST table");

  make_target(BLAST,'make_nucleotide_blastdb') or return;

  my $release = $manager->release($species);
  my $target = BLAST . "/blast_$release";
  make_target($target,'make_nucleotide_blastdb') or return;
  
  my $command = "${\BLASTN_SCRIPT} tace:$dir > $target/Elegans";
  logit("interpolated command: $command");
  
  my $result = system $command;
  # There is an ongoing file-descriptor problem with some systems
  # My hunch is that acedb/AcePerl is not releasing them
  # Instead we will check for the existence of the file and assume it worked...
  # ($result == 0) or warn ("dump_nucleotide(): ${\BLASTN_SCRIPT} failed: $!, system error: ",$? >> 8," ($?)") and return;
  (-e "$target/Elegans") or warn ("dump_nucleotide(): ${\BLASTN_SCRIPT} failed: $!, system error: ",$? >> 8," ($?)") and return;
  my $release = $manager->release('elegans');
  $result = system "pressdb -t 'C elegans genome release $release' $target/Elegans";
  ($result == 0) or warn "dump_nucleotide(): pressdb failed: $?" and return;
  relink_blast() or warn "make_nucleotide_blastdb(): can't symlink $target to ${\BLAST}/blast: $!" and return;
 return 1;
}

sub make_briggsae_blastdb {
  my $dir = shift;
  logit("Making briggsae blast tables");
  my $release = $manager->release('elegans');
  make_blast($dir,"Briggsae_genomic",'Briggsae_genomic','dna',
	     "C. briggsae genome, WormBase release $release");
  make_blast($dir,"Briggpep",        'Protein BP* Peptide','peptide',
	     "C. briggsae proteins, WormBase release $release");
}

sub make_blast {
  my $dir           = shift;
  my ($blast_db_name,$datatype,$type,$title) = @_;
  my $release = $manager->release('elegans');
  my $target = BLAST . "/blast_$release";
  make_target($target,'make_briggsae_blastdb') or return;
  open DEST,">$target/$blast_db_name" 
    or warn "make_blast(): Can't open $target/$blast_db_name: !" and return;
   open TEMP,">$target/commands.ace"
    or warn "make_blast(): Can't open $target/commands.ace: $!" and return;
  print TEMP "query find $datatype\n";
  print TEMP "$type\n";
  close TEMP;

  open (TACE,"tace $dir < $target/commands.ace|")
    or warn "make_blast(): can't open pipe from tace: $!" and return;
  while (<TACE>) { # parent reads from tace and filters
    s/^acedb>\s+//;
    next unless /^>/ .. m!^//!;
    next if m!^//!;
    print DEST;
  }
  close TACE 
    or warn "make_blast(): failure while closing pipe from tace: $?" and return;
  close DEST;
  unlink "$target/commands.ace";

  my $result = $type eq 'dna' ? system "pressdb -t '$title' $target/$blast_db_name"
    : system 'setdb','-t',$title,"$target/$blast_db_name";
  ($result == 0) or warn "make_blast(): pressdb/setdb failed: $?" and return;
  relink_blast() or warn "make_blast(): can't symlink $target to ${\BLAST}/blast: $!" and return;
  return 1;
}

# This is rather brittle
sub make_protein_blastdb {
  logit("Making C. elegans protein BLAST table");
  my $release_path = $manager->release_path('elegans');
  my $release      = $manager->release('elegans');
  my $id = $release;
  $id =~ s/WS//;
  my $wormpep = interpolate($release_path . "/wormpep$id.tar.gz");
  
  # Create the blast target dir
  my $target = BLAST . "/blast_$release";
  make_target($target,'make_protein_blastdb') or return;

  # Unpack and copy the current wormpep file
  chdir($target);
  my $command = "cp $wormpep $target/wormpep$id.tar.gz";
  system($command) unless -e ("$target/wormpep$id.tar.gz");

  system("gunzip -c wormpep$id.tar.gz | tar xvf -") and warn "making_protein_blastdb(): couldn't unpack: $!\n" and return;
  system("rm -rf WormPep");  # remove the old wormpep;
  system("cp","wormpep$id/wormpep$id","WormPep") and warn "making_protein_blastdb(): couldn't copy wormpep: $!\n" and return;
  system("rm -rf wormpep$id") and warn "making_protein_blastdb(): couldn't remove unpacked directory: $!\n" and return;
  system("rm","-rf","wormpep$id.tar.gz") and return;
  system 'setdb','-t',"C elegans WormPep release $release","$target/WormPep" and return;
  relink_blast() or warn "make_protein_blastdb(): can't symlink $target to ${\BLAST}/blast: $!" and return;
  1;
}

sub make_est_blastdb {
  logit("Dumping C. elegans EST blast table");
  my $dir = shift;
  my $release = $manager->release('elegans');
  my $target = BLAST . "/blast_$release";
  make_target($target,'make_est_blastdb') or return;
  open DEST,">$target/EST_Elegans" 
    or warn "make_est_blastdb(): Can't open $target/EST_Elegans: $!" and return;
  
  open TEMP,">$target/commands.ace"
    or warn "make_est_blastdb(): Can't open $target/commands.ace: $!" and return;
  print TEMP <<END;
query find cDNA_Sequence
dna
query find NDB_Sequence
dna
END
;

    close TEMP;

    open (TACE,"tace $dir < $target/commands.ace|")
	or warn "make_est_blastdb(): can't open pipe from tace: $!" and return;
    while (<TACE>) { # parent reads from tace and filters
	s/^acedb>\s+//;
	next unless /^>|^[gatcn]+$/i;
	print DEST;
    }
    close TACE 
	or warn "make_est_blastdb(): failure while closing pipe from tace: $?" and return;
    close DEST;
  unlink "$target/commands.ace";
  
  my $result = system "pressdb -t 'C elegans genome release $release' $target/EST_Elegans";
  ($result == 0) or warn "make_est_blastdb(): pressdb failed: $?" and return;
 
  relink_blast() or warn "make_est_blastdb(): can't symlink $target to ${\BLAST}/blast: $!" and return;
  my $ftp = interpolate(FTP_SITE . "/" . DNA_DUMPS. "/EST_Elegans.dna.gz");
  system "gzip -c $target/EST_Elegans > $ftp" and warn "make_est_blastdb(): couldn;t copy EST file to FTP site\n" if (COPY_TO_FTP);
  return 1;
}

sub copy_chr_files_for_blat {
  logit ("Copying files and setting up blat server");
  my $release_path = $manager->release_path('elegans');
  my $blat_server   = interpolate(BLAT_SERVER);
  # Clear out old *.dna files just in case they exist
  system("chmod 0666 $blat_server/*.dna");  # They might be write-protected.
  system ("rm $blat_server/*.dna") and warn "copy_chr_files_for_blast(): removing old .dna files failed: $!\n";

  logit ("Copying files old *.nib files to blat/old_nib");
  system ("rm -rf $blat_server/old_nib");
  system ("mkdir $blat_server/old_nib");
  system ("cp $blat_server/*.nib $blat_server/old_nib/.");

  system ("cp $release_path/" . DNA_DUMPS . "/CHROMOSOME*dna.gz $blat_server")
    and warn "copy_chr_files_for_blast(): couldn't copy files: $!\n" and return;
  system ("gunzip $blat_server/*.dna.gz") and warn "copy_chr_files_for_blast(): couldn't gunzip files: $!\n" and return;

  foreach (my @tmp= qw(I II III IV V X MtDNA)  ) {
    system ("/usr/local/blat/bin/faToNib $blat_server/CHROMOSOME_$_.dna $blat_server/CHROMOSOME_$_.nib")
      and warn "copy_chr_files_for_blast(): couldn't faToNib: $!\n";
  }

  system ("/usr/local/blat/bin/gfServer stop localhost 2003") 
    and warn "copy_chr_files_for_blast(): couldn't stop blat server: $!\n";
  system ("/usr/local/blat/bin/gfServer start localhost 2003 $blat_server/*.nib &") 
    and warn "copy_chr_files_for_blast(): couldn't restart blat server: $!\n";
  system("chmod 0666 $blat_server/*.dna");  # They might be write-protected, suppress command line warnings
  system ("rm $blat_server/*.dna") and warn "copy_chr_files_for_blast(): couldn't remove old .dna files: $!\n";
  1;
}

sub relink_blast {
  my $target = BLAST . "/blast_" . $manager->release('elegans');
  unlink(BLAST . '/blast');
  symlink ($target,BLAST . '/blast') or warn "blast_(): can't symlink $target to ${\BLAST}/blast: $!" and return;
  1;
}


################################
##         DATA DUMPS
################################

sub make_genename_table {
  logit("Making gene name table");
  my $dir     = shift;
  my $dest    = $manager->release_path('elegans') . '/' . GENE_DUMPS . '/gene_names.txt';
  my $auth = '';
  $auth .=  "-user ${\MYSQL_USER}" if MYSQL_USER;
  $auth .= " -pass ${\MYSQL_PASS}" if MYSQL_PASS;
  my $command = "${\GENENAME_SCRIPT} --acedb tace:$dir $auth > $dest";
  system($command) and warn "make_genename_table(): ${\GENENAME_SCRIPT} failed: $?" and return;
  1;  # I give up
}

sub dump_brief_ids {
  logit("Creating brief IDs/concise descriptions file");
  my $dir = shift;
  my $dest = $manager->release_path('elegans') . '/' . GENE_DUMPS . '/gene_summaries.txt';
  my $command = "${\BRIEF_IDS_SCRIPT} tace:$dir > $dest";
  warn "interpolated command: $command";
  system $command and warn "dump_brief_ids(): ${\BRIEF_IDS_SCRIPT} failed: $?" and return;
}

### DEPRECATED
#sub dump_chrotable {
###   logit("Dumping HTML chromosome tables");
###    my $dir = shift;
###    my $command = CHROMTAB_SCRIPT;
###    my $target = HTML . "/chromosomes_$CE_RELEASE";
###    -d $target or mkdir $target,0775
###	or warn "dump_chromtable(): can't mkdir $target: $!" and return;
###    my @options = ('-path' => $dir, '-max'=>2, -dir => $target);
###    logit("Chromtables command => $command,@options");
###    my $result = system $command,@options;
###    return unless $result == 0;
###    my $link = HTML . "/chromosomes";
###    if (-e $link) {
###	if (-l $link) {
###	    unlink $link
###		or warn "dump_chromtable(): can't remove $link: $!" and return;
###	} else {
###	    warn "dump_chromtable(): $link exists and is not a link" and return;
###	}
###   }
###    symlink $target,HTML . "/chromosomes" 
###	or warn "dump_chromtable(): can't create symlink: $!" and return;
###    1;
#}
###
### deprecated

#sub dump_interpolated {
### logit("Dumping interpolated positions");
###  my $dir = shift;
###  my $command = INTERPOL_SCRIPT;
###  my $target = HTML . "/chromosomes_$CE_RELEASE";
###  -d $target or mkdir $target,0775 
###    or warn "dump_chromtable(): can't mkdir $target: $!" and return;
###
###  logit("interpolated command => $command $dir >$target/interpolated_positions.txt");
###  my $result = system "$command $dir >$target/interpolated_positions.txt";
###  logit("interpolated script result code = $result");
###
###  #return unless $result == 0;
###  return unless -s "$target/interpolated_positions.txt" ;
###  my $link = HTML . "/chromosomes";
###  if (-e $link) {
###    if (-l $link) {
###      unlink $link 
###	or warn "dump_interpolated(): can't remove $link: $!" and return;
###    } else {
###      warn "dump_interpolated(): $link exists and is not a link" and return;
###    }
###  }
###  symlink $target,HTML . "/chromosomes" 
###    or warn "dump_interpolated(): can't create symlink: $!" and return;
###
###  1;
#}


#####################################
##   UPDATING SITE / NOTIFICATIONS
#####################################

sub copy_release_notes {
  logit("Copying release notes to wormbase");
  my $release_path = $manager->release_path('elegans');
  my $target = HTML . "/release_notes";
  system "cp $release_path/letter.* $target/";
  1;
}

sub update_index {
  logit("Updating home page");
  my $release_path = $manager->release_path('elegans');
  my $release      = $manager->release('elegans');

  my $index = HTML . "/index.html";
  -r $index or warn "update_index(): $index doesn't exist" and return;
  -d $release_path  or warn "update_index(): $release_path doesn't exist" and return;
  my $modtime = (stat($release_path))[9];
  my $long_ts = strftime("WormBase release $release: %d %b %Y",localtime($modtime));
  my $short_ts = strftime("%B %Y",localtime($modtime));
  
  local $/ = undef;
  open (I,$index) or warn "update_index(): can't open $index: $!" and return;
  my $data = <I>;
  close I;
  
  $data =~ s{(<!--\s*\#long-release-start\s*-->)[^<]+(<!--\s*\#long-release-end\s*-->)}
    {$1$long_ts$2}xgis;
  
  $data =~ s{(<!--\s*\#short-release-start\s*-->)[^<]+(<!--\s*\#short-release-end\s*-->)}
    {$1$short_ts$2}xgis;
  
  open (I,">$index.new") or warn "update_index(): can't open $index for writing: $!" and return;
  print I $data;
  close I  or warn "update_index(): couldn't close $index: $!" and return;
  
  rename "$index","$index.bak" or warn "update_index(): couldn't back up $index: $!" and return;
  rename "$index.new","$index"  or warn "update_index(): couldn't rename $index: $!" and return;;
  1;
}

sub send_notification {
  my $release_path = $manager->release_path('elegans');
  my $release      = $manager->release('elegans');
  my $file = "$release_path/letter.$release";
  return unless -e $file;
  logit("Sending out announcement...\n");
  open (MAIL,"| /usr/lib/sendmail -oi -t") or return;
  print MAIL <<END;
From: "Wormbase" <wormbase_help\@wormbase.org> 
To: wormbase-announce\@wormbase.org
Subject: Preliminary WormBase release $release now online

This is an automatic announcement that the WormBase development site
(http://dev.wormbase.org) has just been updated to reflect new data.
This is a "sneak preview" of the data that will be made live on the
main WormBase site (http://www.wormbase.org) one week from now.  The
WormBase team uses this 1 week holding period to identify data and
software bugs before going live; please treat the database contents
with some caution, and realize that some pages on the development site
may not be working properly.

The text of the AceDB release notes, which contains highlights of the
new data is attached.  You can download the full AceDB files from:

   ftp://dev.wormbase.org/pub/wormbase/current_release/

END
;

  foreach ($file) {
    open (F,$_) or next;
    while (<F>) { print MAIL $_; }
  }
  close F;
  close MAIL;
}

=pod
  
=head2 update_symbolic_links($release)

This is still species-specific.

Upon successful completion of the mirroring process, create a variety
of symlinks at the top level of the ~ftp/pub/wormbase:

- elegans_current_release -> elegans/$VERSION
    
=cut

sub update_symbolic_links {
  logit("Updating FTP site symbolic links");
  my $ce_release = $manager->release_path('elegans');
  my $cb_release = $manager->release_path('briggsae');
  my $cwd = cwd;
  my $ftp = interpolate(FTP_SITE);
  $ce_release =~ s/$ftp\///;
  $cb_release =~ s/$ftp\///;

  chdir $ftp;
  # Top level elegans and briggsae
  unlink(CE_CURRENT) or warn "Couldn't unlink: $!";
  symlink "$ce_release",CE_CURRENT or warn "Couldn't symlink: $!";
 
  unlink(CB_CURRENT) or warn "Couldn't unlink: $!";
  symlink "$cb_release",CB_CURRENT or warn "Couldn't symlink: $!";
  
  # Gene and DNA_dumps
  unlink(GENE_DUMPS) or warn "Couldn't unlink: $!";
  symlink("$ce_release/" . GENE_DUMPS,GENE_DUMPS);
  unlink(DNA_DUMPS) or warn "Couldn't unlink: $!";
  symlink("$ce_release/" . DNA_DUMPS,DNA_DUMPS);

  my $release = $manager->release('elegans');
  my $id = $release;
  $id =~ s/WS//;
  foreach (qw/wormpep wormrna confirmed_genes/) {
    my $target = ($_ eq 'confirmed_genes') ? "$ce_release/$_" . ".$release.gz"
      : "$ce_release/$_$id.tar.gz";
    unlink($_ . "_current.tar.gz") or warn "Couldn't unlink: $!";
    symlink $target,$_ . "_current.tar.gz" or warn "Couldn't symlink: $!";
  }
  chdir $cwd;
}


################################
##         UTILITIES
################################

sub logit {
  my $localtime = localtime;
  my $msg = "@_";
  $msg =~ s/\n$//;
  print "$localtime $msg...\n";
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


# Should this be -d instead?
sub make_target {
  my ($target,$caller) = @_;
  -e $target or mkdir $target,0775
    or warn "$caller(): Can't mkdir $target: $!" and return 0;
  1;
}



1;




# This is a simple object to track current version and mirror and release paths
package Manager;
use strict;

sub new {
  my ($self,$params) = @_;
  my $this = {};
  bless $this,$self;
  foreach (keys %$params) {
    my $val = $params->{$_};
    $_ =~ s/^\-//;
    $this->{$_} = $val;
  }
  return $this;
}

sub add_species {
  my ($self,$params) = @_;
  my $name    = $params->{-name};
  my $release = $params->{-release};
  my $copy_to_ftp = $params->{-copy_to_ftp};
  
  $self->{$name}->{mirror_path} = interpolate($self->mirror_base . "/$name/$release");
  $self->{$name}->{release_path} =
    ($copy_to_ftp) ?
      interpolate($self->ftp_base . "/$name/$release")
	: $self->mirror_path($name);
  $self->{$name}->{release} = $release;
}

# Accessors
sub ftp_base     { return shift->{ftp_base} };
sub mirror_base  { return shift->{mirror_base} };
sub release_path {
  my ($self,$species) = @_;
  return $self->{$species}->{release_path};
}
sub mirror_path {
  my ($self,$species) = @_;
  return $self->{$species}->{mirror_path};
}
sub release {
  my ($self,$species) = @_;
  return $self->{$species}->{release};
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


1;



=pod

=head1 update_wormbase.pl, Users Guide

=head2 Description

update_wormbase.pl provides automatic updating of a WormBase
installation. It's behaviour can be controlled broadly by passing one
of three flags on the command line or by turning on and off steps of
the process by editing the top this document.

=head2 Paths

This script will mirror data releases to
/usr/local/wormbase/mirrored_data. If you so choose (see below), data
will also be copied to ~ftp.

=head2 Disk space required

You will need a substantial amount of disk space to run this script.

 path                  purpose                   minimum
 /usr/local/wormbase   holds mirrored data       3-5 GB
 /usr/local/acedb      unpacked acedb database   7 GB
 /usr/local/var (1,2)  GFF databases             12 GB
 ~ftp (3)              FTP site                  5 GB

   1. Or wherever your mysql data directory lives.
   2. This value is enough for two releases as the update process
      transfers new databases->old databases during update, always
      maintaining the current and past revision.
   3. Only required if you are copying to the FTP site.

All of these values assume that you are only mirroring a single
release. To save multiple releases, increase these values
appropriately.

=head2 Options
You can periodically clean out
this directory following succesful builds.  If you'd like to do this
automatically, edit this document and set the following line => 1:

          REMOVE_MIRRORED => 0  # set this to 1

By default, mirrored files will be copied to the FTP directory.  If
you do not plan to run an FTP server, you can safely disable this step
by setting the following option to 0:

          COPY_TO_FTP => 1

=cut
