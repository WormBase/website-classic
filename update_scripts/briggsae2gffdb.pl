#!/usr/bin/perl

# Build the C. briggsae GFF database
use strict;
use DBI;
use FindBin '$Bin';
use File::Basename 'basename';
use Getopt::Long;

use constant FASTA   => '/usr/local/ftp/pub/wormbase/genomes/briggsae/sequences/dna/briggsae_cb3.fa.gz';
use constant LIVE_DB => 'briggsae';
use constant LOAD_DB => 'briggsae_load';
use constant PASS    => 'kentwashere';
use constant USER    => 'root';


unless (-e FASTA) {
  chdir "/usr/local/ftp/pub/wormbase/genomes/briggsae/sequences/dna" or die $!;
  warn "Getting briggsae DNA...\n";
  system "wget ftp://ftp.wormbase.org/pub/wormbase/genomes/briggsae/sequences/dna/briggsae_cb3.fa.gz";
}

$ENV{TMP} ||= $ENV{TMPDIR}
||  $ENV{TEMP}
|| -d ('/usr/tmp') ? '/usr/tmp' : -d ('/tmp') ? '/tmp' : die 'NO TEMP DIR';

my ($fasta_dir,$gff_dir,$live_db,$load_db,$user,$pass,$release);
GetOptions('fasta=s' => \$fasta_dir,
	   'gff=s'   => \$gff_dir,
	   'live=s'  => \$live_db,
	   'load=s'  => \$load_db,
	   'user=s'  => \$user,
	   'pass=s'  => \$pass,
	   'release=s' => \$release,
	  ) || die <<USAGE;
Usage briggsae2gffdb.pl [options...]
  Mirror the briggsae data release and create a
  Bio::DB::GFF database.

 Options:
    -fasta    Briggsae fasta file (/usr/local/html/mirrored_data/briggsae/run_25/gff_db_load_files/briggsae_25.fa.gz)
    -gff      Briggsae GFF file (/usr/local/html/mirrored_data/briggsae/run_25/gff_db_load_files/briggsae_25.WS121.gz)
    -live     Name of live database (briggsae)
    -load     Name of temporary load database (briggsae_load)
    -user     Username for mysql access
    -pass     Password for mysql access
    -release  WSXXXX release number

USAGE
;

$release   ||  die "A release name [-release=WSXXX] is required\n";
$release = uc $release;
$release =~ /^WS\d+$/ or die "Release format should be: WSxxx\n";
$fasta_dir ||= FASTA;
$gff_dir   ||= `./process_briggsae_gff.pl $release` || die 'NO GFF!';
$live_db   ||= LIVE_DB. "_$release";
$load_db   ||= LOAD_DB;
$user      ||= USER;
$pass      ||= PASS;

my $auth = '';
$auth  = " --user $user" if $user;
$auth .= " --pass $pass" if $pass;

# grab the dna if it is on the ftp site
my $temp_dir;
if ($fasta_dir =~ /^ftp/) {
  print STDERR "downloading DNA files...";
  $temp_dir = "$ENV{TMP}/brigg$release";
  mkdir $temp_dir unless -d $temp_dir;
  chdir $temp_dir;
  system "wget -q $fasta_dir";
  print STDERR " Done\n";
  $fasta_dir = "$ENV{TMP}/brigg$release";
}

warn "loading briggsae GFF database...\n";
my $result = system("mysql --user $user -p$pass -e 'create database $live_db'");
my $result = system "bp_fast_load_gff.pl -c -d $live_db $auth --fasta $fasta_dir $gff_dir";
#my $result = system "bp_fast_load_gff.pl -c -d $load_db $auth --fasta $fasta_dir $gff_dir";
die "Something went wrong while loading $fasta_dir: non-zero result code" unless $result == 0;

# error check
my $db     = DBI->connect('dbi:mysql:'.$live_db,$user,$pass) or die "Can't DBI connect to database\n";
my $table_list = $db->selectall_arrayref("show tables")
  or die "Can't get list of tables: ",$db->errstr;

my @tables = map {$_->[0]}  @$table_list;
my @bak    = map {"${_}_bak"} @tables;
foreach (@tables) {
  my $arrayref = $db->selectall_arrayref("select count(*) from $_");
  die $live_db.".$_ is empty\n" unless $arrayref->[0][0] > 0;
}

# optimize some tables
$db->do("analyze table fattribute,fattribute_to_feature,fdata,fgroup,fmeta,ftype,fdna");

# remove all the _bak files (not necessarily an error)
#$db->do("create database $live_db");
#$db->do('use '.$live_db) or die "use(): ",$db->errstr;
#$db->do("drop table if exists ".join(',',@bak));

# back up all the tables
#warn qq(==> If running for the first few times, you will see a bunch of "Can't find file" errors here.<==\n);
#for (my $i=0;$i<@tables;$i++) {
#  # Modified LOAD/LIVE_DB to $load/live_db
#  my ($live,$load,$bak) = ($live_db .".$tables[$i]",$load_db . ".$tables[$i]",$bak[$i]);
#  $db->do("rename table $live to $bak");
#  my $result = $db->do("rename table $load to $live");
#  unless ($result) {  # back out of the whole thing!
#    $db->do("rename table $bak to $live");
#    die "REALLY REALLY BAD: $bak -> $live failed: ",$db->errstr;
#  }
#}

chdir("/usr/local/mysql/data");
system("rm -f briggsae");
system("ln -s $live_db briggsae");


warn "Loading the Briggsae GFFDB worked!\n";

system "rm -fr $temp_dir";

exit 0;
