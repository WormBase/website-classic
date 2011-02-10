#!/usr/bin/perl
# Create Marcella's elegans_pmap gff database

use DBI;
use FindBin '$Bin';
use File::Basename 'basename';
use Getopt::Long;
use Ace;

use constant ACEDB => '/usr/local/acedb/elegans';

my $ENV_TMP = $ENV{TMP} || $ENV{TMPDIR} || $ENV{TEMP} || -d ('/usr/tmp') ? '/usr/tmp' : -d ('/tmp') ? '/tmp' : die;

use constant LIVE_DB  => 'elegans_pmap';
use constant LOAD_DB  => 'elegans_pmap_load';

my ($live_db,$acedb,$load_db,$user,$pass,$release,$tmp,$output);
GetOptions('live=s'  => \$live_db,
	   'load=s'  => \$load_db,
	   'acedb=s' => \$acedb,
	   'user=s'  => \$user,
	   'pass=s'  => \$pass,
	   'release=s' => \$release,
	   'tmp=s'     => \$tmp,
	   'output=s'  => \$output,
	  ) || die <<USAGE;
Usage pmap2gff.pl [options...]
  Build the elegans_pmap gff database

 Options:
    -live     Name of live database (elegans_pmap)
    -load     Name of temporary load database (elegans_pmap_load)
    -acedb    Name of acedb database to dump from
    -user     Username for mysql access
    -pass     Password for mysql access
    -release  WSXXXX release number
    -tmp      tmp directory to write output (ENV{TMP})
    -output   Full path (and filename) to output file (gff/elegans-pmapWSXXX.gff)

USAGE
;

my $ACE = Ace->connect($acedb) or die "Can't open ace database:",Ace->error;
$tmp ||= $ENV_TMP;
$output ||= $tmp . "/elegans-pmap${release}.gff";

$live_db   = LIVE_DB unless defined $live_db;
$load_db   = LOAD_DB unless defined $load_db;
$release   = ''      unless defined $release;

my $auth = '';
$auth  = " --user $user" if $user;
$auth .= " --pass $pass" if $pass;

warn "generating elegans_pmap GFF database...\n";
print_gfftable();
warn "loading elegans_pmap GFF database...\n";
# Have to create the new database first - hardcoded for now
my $result = system "mysql -u root -pkentwashere -e 'create database $load_db'";
my $result = system "mysql -u root -pkentwashere -e 'grant all privileges on $load_db.* to $user\@localhost'";
my $result = system "bp_load_gff.pl -c -d $load_db $auth $output";
die "Something went wrong while loading the elegans pmap GFF database: non-zero result code" unless $result == 0;

# error check
# Modified LOAD_DB to $load_db
my $db     = DBI->connect('dbi:mysql:'.$load_db,$user,$pass) or die "Can't DBI connect to database\n";
my $table_list = $db->selectall_arrayref("show tables")
  or die "Can't get list of tables: ",$db->errstr;

# No longer necessary
#my @tables = map {$_->[0]}  @$table_list;
#my @bak    = map {"${_}_bak"} @tables;
#foreach (@tables) {
#  next if ($_ eq 'fdna');  # This table will always be empty with the pmap db
#  my $arrayref = $db->selectall_arrayref("select count(*) from $_");
#  # Modified LOAD_DB to $load_db
#  die $load_db.".$_ is empty\n" unless $arrayref->[0][0] > 0;
#}

# optimize some tables
$db->do("analyze table fattribute,fattribute_to_feature,fdata,fgroup,fmeta,ftype");

#No longer necessary
## remove all the _bak files (not necessarily an error)
#$db->do('use '.$live_db) or die "use(): ",$db->errstr;
#$db->do("drop table if exists ".join(',',@bak));

## back up all the tables
#warn qq(==> If running for the first few times, you will see a bunch of "Can't find file" errors here.<==\n);
#for (my $i=0;$i<@tables;$i++) {
## Modified LOAD/LIVE_DB to $load/live_db
#  my ($live,$load,$bak) = ($live_db .".$tables[$i]",$load_db . ".$tables[$i]",$bak[$i]);
#  $db->do("rename table $live to $bak");
#  my $result = $db->do("rename table $load to $live");
#  unless ($result) {  # back out of the whole thing!
#    $db->do("rename table $bak to $live");
#    die "REALLY REALLY BAD: $bak -> $live failed: ",$db->errstr;
#  }
#}

# Update symlinks
chdir("/usr/local/mysql/data");
unlink("elegans_pmap");
system("ln -s $live_db elegans_pmap");

warn "Wow!  Loading the elegans Pmap GFFDB worked!\n";
exit 0;






#############################################################
sub print_gfftable {
  open OUT,">$output" or die "Couldn't open the $output output file";
  my @contigs = $ACE->fetch(-class=>'Contig',-name=>'*',-fill=>1);
  my $c;
  foreach my $contig (@contigs) {
    $c++;
    print STDERR '   ---- ' . "$c / " . scalar @contigs . " processed..." if ($c % 5 == 0);
    print STDERR -t STDOUT && !$ENV{EMACS} ? "\r" : "\n";
    # get the physical map coordinates for the contig and eliminate
    # those contigs where the start is greater than the end value
    my ($start,$stop) = $contig->Pmap->row;
	print STDERR $contig->Pmap->col,"\n";
	print STDERR "contig $contig $start $stop\n";
    unless ($start > $stop) {
      # use the class tag as the method and the source for a contig
      my $source = 'contig';
      my $method = 'contig';

      # convert the physical map coordinates into positive numbers;
      # numbers > 100 are better visualized with GBrowse, so will
      # multiply everything by 10...

      # the downside is that everything now will start at 10 instead
      # of 1, is this ok?  plus, the negative numbers are going to
      # become huge!  e.g. -24 will be -240

      # TH: This is truly bizarre.  Is it still possible to display relative
      # starts using this method?  All the start positions
      # become flattened. I do not get it right now...
      my $offset = 1 - $start;  # same as  ((-1) * ($start)) +1
      $start     = 10 * ($start + $offset);
      $stop      = 10 * ($stop  + $offset);

      # these are irrelevant for the physical map
      my ($score,$strand,$phase) = qw/. . ./;

      # the group will be given by the class name and the id of each refseq
      my $group = "Contig $contig";

      # print gff 9-columns for the reference sequence (contig)
      print OUT join "\t",($contig,$source,$method,$start,$stop,$score,$strand,$phase,$group),"\n";
      
      # get all the clones within the contig, skipping those with no PMap coords
      my @ref_clones = $contig->follow('Clone');
      foreach my $clone (@ref_clones) {
	# get the pmap coordinates of each clone relative to the refseq contig
	next unless (my ($junk,$c_start,$c_stop) = eval {$clone->get('Pmap',1)->row});
	$c_start = 10 * ($c_start + $offset);
	$c_stop  = 10 * ($c_stop  + $offset);

	# print STDERR join('-',$contig,$clone,$c_start,$c_stop,$start,$stop),"\n";
      
	# get the same values (as above) for each clone within the refseq contig
	my $c_type   = eval {$clone->Type};
	my $c_source = lc ($c_type) || 'clone';
	my $c_method = 'clone';
	my ($c_score,$c_strand,$cphase) = qw/. . ./;
	
	# for the group column, get the class and id of the clone, as
	# well as whether the clone has an associated DNA sequence
	my $sequence    = eval {$clone->Sequence};
	my $seq_source;
	my $c_group = "Clone $clone";
	if (eval {$clone->Sequence}) {
	  $c_group .= "; Note Sequenced";
	  $seq_source = 'sequenced';
	}
	#	my $buried_clone;
	#	my @status = $clone->Sequence_status;	
	#	my $finished = eval {$clone->Finished};
	$c_group .= "; Accession number " . $clone->Accession_number if (eval {$clone->Accession_number});
	
	# print gff 9-columns for each clone
	print OUT join "\t",($contig,$c_source,$c_method,$c_start,$c_stop,$c_score,$c_strand,$c_phase,$c_group),"\n";

	if ($c_group =~ /Note/){
	  print OUT join "\t",($contig,$seq_source,$c_method,$c_start,$c_stop,$c_score,$c_strand,$c_phase,$c_group),"\n";
	}
      }
    }
  }
  close OUT;
}





