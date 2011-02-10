#!/usr/bin/perl -w

############################################################
#
#    written by Igor Antoshechkin
#    igor.antoshechkin@caltech.edu
#    Dec. 2005
#
############################################################

use strict;
use Ace;
use Search::Indexer;
use Getopt::Std;
use Storable qw(store retrieve nstore);

my %opts =();

getopts('d:f:i:s:l:e:a:poh',\%opts);

my $program_name=$0=~/([^\/]+)$/ ? $1 : '';

if (! defined $opts{d} ) {
    $opts{h}=1;
}

if ($opts{h}) {
    print "usage: $program_name [options] -d directory_to_index\n";
    print "       -h              help - print this message\n";
    print "       -i <dir>        index file directory; default current\n";
    print "       -a              path to acedb\n";
    print "       -d <dir>        directory to index; required\n";
#    print "       -f <dir_list>   file containing list of directories to index; either -f or -d is required\n";
#    print "       -l <lookup>     lookup table for file names; required\n";
    print "       -s <stopwords>  file containing words to exclude\n";
    print "       -e <exclude>    file containing directories to exclude\n";
#    print "       -p              index pdf files; default NO\n";
    print "       -o              overwrite previous database installation; default NO\n";
    exit(0);
}

print "Connecting to database...";
my $db = Ace->connect($opts{a}) || die "Connection failure: ", Ace->error;
my %status  = $db->status;
my $version = $db->status->{database}{version};


my $lookupFileName="lookup.strains";
my $pref='';
if($opts{i}) {
    # Stash all the files under the version
   # Create a versioned output directory
    $opts{i} = ($opts{i} =~ /(.*\/)$/) ? $1 : $opts{i} . '/';
    $pref=$opts{i}."/$version/";
}
if (-e $pref."ixw.bdb") {
    if ($opts{o}) {
	unlink $pref."ixw.bdb", $pref."ixp.bdb", $pref."ixd.bdb";
    }
    else {
	print "Index files already exist. They have to be removed first.\n";
	exit;
    }
}

my @exclude;
if ($opts{e}) {
    open (IN, "<$opts{e}") || die "cannot open $opts{e} : $!\n";
    while (<IN>) {
	chomp;
	next unless $_;
	push @exclude, $_;
    }
    close IN;
}

my $ix;
if ($pref) {
    if ($opts{s}) {
	$ix = new Search::Indexer(dir => $pref, writeMode => 1, stopwords => $opts{s});
    }
    else {
	$ix = new Search::Indexer(dir => $pref, writeMode => 1);
    }
}
else {
    if ($opts{s}) {
	$ix = new Search::Indexer(writeMode => 1, stopwords => $opts{s});
    }
    else {
	$ix = new Search::Indexer(writeMode => 1);
    }
}

my @allfilestmp;
my @dirs;
#if ($opts{d}) {
if ($pref) {
    @allfilestmp = `ls -R $pref`;
}
else {
    open (IN, "<$opts{f}") || die "cannot open $opts{f} : $!\n";
    while (<IN>) {
	chomp;
	next unless $_;
	my @tmp = `ls -R $_`;
	push @dirs, $_;
	push @allfilestmp, @tmp;
    }
    close IN;
}

my $pathtmp;
my @allfiles=();
foreach (@allfilestmp) {
    chomp;
next if $_ eq 'ixw.bdb';
next if $_ eq 'ixp.bdb';
next if $_ eq 'ixd.bdb';
next if $_ eq 'lookup.strains';

    next unless $_;
    if (/\:$/) {
	$pathtmp=$_;
	$pathtmp=~s/\://g;
	if (@exclude) {
	    foreach (@exclude) {
		if ($pathtmp=~/$_/) {
		    $pathtmp='';
		    last;
		}
	    }
	}
	next;

    }
    next unless $pathtmp;
    next unless  (/\.html$/i or /\.htm$/i);
    push @allfiles, "$pathtmp/$_";
}

foreach (@allfiles) {
    $_=~s/\/\//\//g;
}

if (!@allfiles) {
    print "no files found in $pref\n" if $pref;
    print "no files found in ", join ("; ", @dirs), "\n" if $opts{f};
    exit;
}

print scalar @allfiles, " found in $pref\n" if $pref;
print scalar @allfiles, " found in ", join ("; ", @dirs), "\n" if $opts{f};


my $i=0;

my %strain_hash=();

foreach my $f (sort {$a cmp $b} @allfiles) {
    my $content='';
    my $section='';
    my $inCGC='No';
    my $inWB='No';
    my $genotype='';
    my $title='';
    my $tmp_filename=$f;
    $tmp_filename=~s/$opts{d}//;
    open (FILE, "<$f") || die "cannot open $f : $!\n";
    while (<FILE>) {
	chomp;
	next unless $_;
	if (/<title.*>(.*)<\/title>/i) {
	    $title=$1;
	    $content.=$title;
	    my $lab=$title=~/(\D+)\d+/ ? $1 : '';
	    $content.=" $lab ";
	}
	elsif (/<dt\s+title=\"([^\"]+)\">/) {
	    $section=$1;

	}
	elsif (/<dd>/) {
	    $content.=" $_ ";
	    if ($section eq 'Available at CGC') {
		$inCGC=$_=~/Yes/ ? "Yes" : "No";
	    }
	    elsif ($section eq 'Genotype') {
		$genotype=$_;
		$genotype=~s/<.*?>//gs;
	    }
	    elsif ($section eq 'WormBase Strain Report') {
		$inWB=$_=~/class=Strain/ ? "Yes" : "No";
	    }
	}
    }    
	
    close FILE;
    $content=~s/<.*?>/ /gs;
    $content=~s/\t/ /g;
    $content=~s/\s{2,}/ /g;
    if (! $content) {
	next;
    }
    $ix->add($i, $content);
    $strain_hash{$i}{strain}=$title;
    $strain_hash{$i}{CGC}=$inCGC;
    $strain_hash{$i}{WB}=$inWB;
    $strain_hash{$i}{genotype}=$genotype;
    $strain_hash{$i}{file}=$tmp_filename;
    $i++;

    if ($i % 1000 == 0) {
	print "$i files processed\n";
    }
}

#my $tmpout=$pref.$opts{l}."\.strains";
my $tmpout=$pref.$lookupFileName;
nstore \%strain_hash, $tmpout || die "cannot store strain_hash in $tmpout : $!\n";
print "$i files indexed\n";
	   
		       
		       
		       
