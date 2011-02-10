#!/usr/bin/perl

# unpack the fasta files & load them and the GFF files
use strict;
use DBI;
use FindBin '$Bin';
use File::Basename 'basename';
use Getopt::Long;

#use constant FASTA => (getpwnam('ftp'))[7]   . '/pub/wormbase/elegans-current_release/DNA_DUMPS';
#use constant GFF   => (getpwnam('ftp'))[7]   . '/pub/wormbase/elegans-current_release/GENE_DUMPS';

use constant BRIGGSAE_PACKED => (getpwnam('ftp'))[7] . '/pub/wormbase/genomes/briggsae/sequences/dna/briggsae.CB25.dna.fa.gz';
use constant ACEDB => (getpwnam('acedb'))[7] . '/elegans';
use constant TMP   => (getpwnam('acedb'))[7] . '/tmp';
use constant LIVE_DB => 'elegans';
use constant LOAD_DB => 'elegans_load';

$ENV{TMP} = $ENV{TMP} || $ENV{TMPDIR} || $ENV{TEMP} || -d ('/usr/tmp') ? '/usr/tmp' : -d ('/tmp') ? '/tmp' : 
die 'Cannot find a suitable temp dir';

my ($fasta_dir,$gff_dir,$live_db,$load_db,$acedb,$user,$pass,$release,$output,$dna_output);
GetOptions('fasta=s' => \$fasta_dir,
	   'gff=s'   => \$gff_dir,
	   'live=s'  => \$live_db,
	   'load=s'  => \$load_db,
	   'acedb=s' => \$acedb,
	   'user=s'  => \$user,
	   'pass=s'  => \$pass,
	   'release=s' => \$release,
           'output=s'  => \$output,
	   'dna_output=s' => \$dna_output,
	  ) || die <<USAGE;
Usage ace2gffdb.pl [options...]
  Transform the GFF flat files into a lean and mean 
  Bio::DB::GFF database.

 Options:
    -fasta    Directory in which fasta files live (~ftp/pub/wormbase/DNA_DUMPS)
    -gff      Directory in which GFF files live (~ftp/pub/wormbase/GENE_DUMPS)
    -live     Name of live database (elegans)
    -load     Name of temporary load database (elegans_load)
    -acedb    Path to local acedb (for getting genes and other things
                     that aren't in the gff)
    -user     Username for mysql access
    -pass     Password for mysql access
    -release  WSXXXX release number
    -output   Full path (and filename) to output file (gff/elegansWSXXX.gff)

USAGE
;

$fasta_dir  = "/usr/local/ftp/pub/wormbase/acedb/$release/CHROMOSOMES" unless defined $fasta_dir;
$gff_dir    = "/usr/local/ftp/pub/wormbase/acedb/$release/CHROMOSOMES"   unless defined $gff_dir;
die unless $live_db && $load_db;

$acedb      = ACEDB   unless defined $acedb;
$release    = ''      unless defined $release;
$dna_output = '/usr/local/ftp/pub/wormbase/genome/elegans/sequences/dna/elegans.fa.gz' unless defined $dna_output;

my $unpacked = $fasta_dir . "/unpacked";
#my $epcrdb   = "$unpacked/epcr_db.fa";
my $estdb    = "$unpacked/EST_Elegans.fa";
my $briggdb  = "$unpacked/briggsae.CB25.dna.fa";
$output ||= $gff_dir . "/elegans${release}.gff";

mkdir $unpacked,0777;
for my $file (glob("$fasta_dir/*.dna.gz")) {
    (my $name = $file) =~ s/\.dna\.gz$/\.fa/;
    $name = basename($name);
    warn "unpacking $file...\n";
    system "zcat $file | perl -p -e 's/^>CHROMOSOME_/>/' > $unpacked/$name";
}
# build a concatenated fasta file if it isn't there already
unless (-e $dna_output && -M $dna_output <= -M "$fasta_dir/CHROMOSOME_I.dna.gz") {
  warn "building fasta file";
  system "cat $unpacked/CHROMOSOME_*.fa > $dna_output";
}

# HACK ALERT!
# Copy the cbriggsae.fa file into the unpacked dir.
# Why oh why is this file loaded?  Is it still necessary?
my $result = system("cp " . BRIGGSAE_PACKED . " $unpacked");
system "gunzip -f $unpacked/briggsae.CB25.dna.fa.gz";

my $auth = '';
$auth    = " --user $user" if $user;
$auth   .= " --pass $pass" if $pass;

# Have to create the new database first	 
# This is required as we create new databases called species_[VERSION]
warn "Creating new GFF database and granting privileges...";	 
my $result = system "mysql -u root -pkentwashere -e 'create database $load_db'";	 
my $result = system "mysql -u root -pkentwashere -e 'grant all privileges on $load_db.* to $user\@localhost'";

# Check if we have supplementary gff files
my $supp_dir = "$gff_dir/SUPPLEMENTARY_GFF";

my @supp_gff = glob("$supp_dir/*.gff");
#foreach my $file qw(miranda.gff pictar.gff) {
#    -e "$supp_dir/$file" ? push @supp_gff, "$supp_dir/$file"
#                         : warn "Cannot locate $supp_dir/$file, skipping!";
#    }
if (@supp_gff == 0) {
    warn "WARNING: Supplementary gff directory ($supp_dir) does not contain any *.gff file!";
}

my $supp_gff = join(" ", @supp_gff);

warn "loading GFF database...\n";
warn "-c -d $load_db $auth --fasta $dna_output\n";
warn "$Bin/process_gff.pl $acedb $gff_dir/CHROMOSOME*.gff.gz $supp_gff\n";

my $cmd = "$Bin/process_gff.pl $acedb $gff_dir/CHROMOSOME*.gff.gz $supp_gff | tee $output | bp_bulk_load_gff.pl -c -d $load_db $auth --fasta $dna_output -";
warn "Process gff command: $cmd";
my $result = system($cmd);
die "Something went wrong: non-zero result code: $!" unless $result == 0;

system "gzip -f $output";
system "gzip -f $dna_output";

for my $file ($estdb,$briggdb) {
  # modified LOAD_DB to $load_db
  my $result = system "bp_load_gff.pl -d $load_db $auth --fasta $file </dev/null";
  die "Something went wrong while loading $file: non-zero result code" unless $result == 0;
}

# error check
# modified LOAD_DB to $load_db
my $db     = DBI->connect('dbi:mysql:'.$load_db,$user,$pass) or die "Can't DBI connect to database\n";
my $table_list = $db->selectall_arrayref("show tables")
  or die "Can't get list of tables: ",$db->errstr;

# No longer required
#my @tables = map {$_->[0]}  @$table_list;
#my @bak    = map {"${_}_bak"} @tables;
#foreach (@tables) {
#  my $arrayref = $db->selectall_arrayref("select count(*) from $_");
#  # modified LOAD_DB to $load_db
#  die $load_db.".$_ is empty\n" unless $arrayref->[0][0] > 0;
#}

# optimize some tables
$db->do("analyze table fattribute,fattribute_to_feature,fdata,fgroup,fmeta,ftype,fdna");

# NO LONGER NECESSARY
## remove all the _bak files (not necessarily an error)
#$db->do('use '.$live_db) or die "use(): ",$db->errstr;
#$db->do("drop table if exists ".join(',',@bak));
#
## back up all the tables
#warn qq(==> If running for the first few times, you will see a bunch of "Can't find file" errors here.<==\n);
#for (my $i=0;$i<@tables;$i++) {
#  # modified LOAD/LIVE_DB to $load/live_db
#  my ($live,$load,$bak) = ($live_db .".$tables[$i]",$load_db . ".$tables[$i]",$bak[$i]);
#  $db->do("rename table $live to $bak");
#  my $result = $db->do("rename table $load to $live");
#  unless ($result) {  # back out of the whole thing!
#    $db->do("rename table $bak to $live");
#    die "REALLY REALLY BAD: $bak -> $live failed: ",$db->errstr;
#}
#}
				   
# Update symlinks
chdir("/usr/local/mysql/data");
system("rm elegans");
system("ln -s $live_db elegans");
#unlink("elegans") or warn "unlinking failed: $!";
#link($live_db,'elegans') or warn "linking failed: $!";


warn "Wow!  It worked!\n";
exit 0;
