#!/usr/bin/perl

# WHOOPS!  I accidentally deleted the UPDATE_CONFIG direcytory

use strict;
use lib'.';
use UPDATE_CONFIG;
#require "./UPDATE_CONFIG.pm";

use DBI;
use FindBin '$Bin';
use File::Basename 'basename';
use Getopt::Long;

my $SPECIES = 'remanei';

my ($release);
GetOptions('release=s' => \$release);
	  
my $usage =  <<USAGE;
Usage remanei2gffdb.pl [options...]
  Transform the GFF flat files into a lean and mean 
  Bio::DB::GFF database.

 Options:
    -release  WSXXXX release number

USAGE
;

$release or die $usage;


$release =~ /WS(.*)/;
my $numeric = $1;
my $load_db = $SPECIES . "_$release";

my $fasta_dir  = "$FTP_ROOT/acedb/$release/CHROMOSOMES/remagff$numeric";
my $gff_dir    = "$FTP_ROOT/acedb/$release/CHROMOSOMES/remagff$numeric";
my $dna_output = "$FTP_ROOT/genomes/remanei/sequences/dna/$SPECIES.$release.fa.gz";
my $gff_output = "$FTP_ROOT/genomes/remanei/genome_feature_tables/GFF2/$SPECIES.${release}.gff.gz";

# Unpack DNA
my $unpacked = $fasta_dir . "/unpacked";
mkdir $unpacked,0777;
for my $file (glob("$fasta_dir/*.dna.gz")) {
    (my $name = $file) =~ s/\.dna\.gz$/\.fa/;
    $name = basename($name);
    warn "unpacking $file...\n";
#    system "zcat $file | perl -p -e 's/^>CHROMOSOME_/>/' > $unpacked/$name";
    system "zcat $file > $unpacked/$name";
}

# Archive the DNA file
system("cp $fasta_dir/$SPECIES.dna.gz $dna_output");

# ARchive the GFF file.
system("cp $gff_dir/$SPECIES.gff.gz $gff_output");

my $auth = '';
$auth    = " --user $MYSQL_USER" if $MYSQL_USER;
$auth   .= " --pass $MYSQL_PASS" if $MYSQL_PASS;

# Have to create the new database first	 
# This is required as we create new databases called species_[VERSION]
warn "Creating new GFF database and granting privileges..."; 
my $result = system "mysql -u root -pkentwashere -e 'create database $load_db'";	 
my $result = system "mysql -u root -pkentwashere -e 'grant all privileges on $load_db.* to $MYSQL_USER\@localhost'";

warn "loading GFF database...\n";
my $cmd = "bp_bulk_load_gff.pl -c -d $load_db $auth --fasta $fasta_dir/unpacked/*.fa $gff_output";
my $result = system($cmd);
die "Something went wrong: non-zero result code: $!" unless $result == 0;

# error check
# modified LOAD_DB to $load_db
my $db     = DBI->connect('dbi:mysql:'.$load_db,$MYSQL_USER,$MYSQL_PASS) or die "Can't DBI connect to database\n";
my $table_list = $db->selectall_arrayref("show tables")
  or die "Can't get list of tables: ",$db->errstr;

# optimize some tables
$db->do("analyze table fattribute,fattribute_to_feature,fdata,fgroup,fmeta,ftype,fdna");

# Update symlinks
chdir($MYSQL_DATA_DIR);
system("rm $SPECIES");
system("ln -s " . $SPECIES . "_$release $SPECIES");

warn "Wow!  It worked!\n";
exit 0;
