#!/usr/bin/perl

# Build the C. briggsae GFF database
use strict;
use DBI;
use FindBin '$Bin';
use File::Basename 'basename';
use Getopt::Long;


use constant LIVE_DB => 'briggsae';
use constant LOAD_DB => 'briggsae_load';

my ($fasta_dir,$gff_dir,$live_db,$load_db,$user,$pass,$release);
GetOptions(
	   'user=s'  => \$user,
	   'pass=s'  => \$pass,
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

#$fasta_dir = FASTA   unless defined $fasta_dir;
#$gff_dir   = GFF     unless defined $gff_dir;
$live_db   = LIVE_DB unless defined $live_db;
$load_db   = LOAD_DB unless defined $load_db;
$release   = ''      unless defined $release;

my $auth = '';
$auth  = " --user $user" if $user;
$auth .= " --pass $pass" if $pass;


# Modified LOAD_DB to $load_db
my $db     = DBI->connect('dbi:mysql:'.$load_db,$user,$pass) or die "Can't DBI connect to database\n";
my $table_list = $db->selectall_arrayref("show tables")
  or die "Can't get list of tables: ",$db->errstr;

my @tables = map {$_->[0]}  @$table_list;
my @bak    = map {"${_}_bak"} @tables;
foreach (@tables) {
  my $arrayref = $db->selectall_arrayref("select count(*) from $_");
  # Modified LOAD_DB to $load_db
  die $load_db.".$_ is empty\n" unless $arrayref->[0][0] > 0;
}

# optimize some tables
# $db->do("analyze table fattribute,fattribute_to_feature,fdata,fgroup,fmeta,ftype,fdna");

# remove all the _bak files (not necessarily an error)
# Modified LIVE_DB to $live_db
$db->do('use '.$live_db) or die "use(): ",$db->errstr;
$db->do("drop table if exists ".join(',',@bak));

# back up all the tables
warn qq(==> If running for the first few times, you will see a bunch of "Can't find file" errors here.<==\n);
for (my $i=0;$i<@tables;$i++) {
# Modified LOAD/LIVE_DB to $load/live_db
  my ($live,$load,$bak) = ($live_db .".$tables[$i]",$load_db . ".$tables[$i]",$bak[$i]);
  $db->do("rename table $live to $bak");
  my $result = $db->do("rename table $load to $live");
  unless ($result) {  # back out of the whole thing!
    $db->do("rename table $bak to $live");
    die "REALLY REALLY BAD: $bak -> $live failed: ",$db->errstr;
  }
}

warn "Wow!  Loading the Briggsae GFFDB worked!\n";
exit 0;
