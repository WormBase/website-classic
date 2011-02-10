#!/usr/bin/perl

# Create the stub documentation for a new archive
# Uasge:
#./create_archives.pl WS130 2004-09-09
# Release data refers to the date the database was released on www.wormbase.org
use strict;
use Getopt::Long;

my ($release,$date,$download);
GetOptions('release=s'  => \$release,
	   'date=s'     => \$date,
	   'download'   => \$download);
($release && $date) or die "Usage: ./create_archive.pl -release WS130 -date 2004-09-09 [-download]";

mkdir("$release-$date-Disc1");
mkdir("$release-$date-Disc2");
mkdir("$release-$date-Disc1/original_release");
mkdir("$release-$date-Disc2/prebuilt_databases");

my %months = ('01' => 'January',
	      '02'  => 'February',
	      '03'  => 'March',
	      '04'  => 'April',
	      '05'  => 'May',
	      '06'  => 'June',
	      '07'  => 'July',
	      '08'  => 'August',
	      '09'  => 'September',
	      '10'  => 'October',
	      '11'  => 'November',
	      '12'  => 'December');

$date =~ /(\d\d\d\d)\-(\d\d)\-(\d\d)/;
my $year  = $1;
my $mos   = $2;
my $month = $months{$mos};
my $day   = $3;


my $readme = <<END;
This is the archive version of WormBase Release $release.

Version      : $release
Release Date : $day $month $year

Contents:
Disc 1:
- Original_release/
    This directory contains raw sequence data, the original compressed
    Acedb database files, WormPep and WormRNA releases, chromosome
    feature dumps in GFF format, and fasta files.

Disc 2:
- prebuilt_databases/
    This directory contains compressed, prebuilt databases for the
    corresponding $release release.  This includes the acedb database,
    C. elegans and C. briggsae GFF databases, and BLAST and BLAT
    databases. See the enclosed HOWTO_INSTALL for installation
    instructions.

- wormbase-$release-$year-$mos-$day.tar.gz
    The software that drives WormBase.  See the enclosed INSTALL.html
    file for information on installing WormBase.

Todd Harris (harris\@cshl.org)
$day $month $year
END
;


open OUT,">$release-$date-Disc1/README";
print OUT $readme;
close OUT;




my $howto = <<END;
INSTALLING PREBUILT WORMBASE DATABASES

You will need roughly three times as much disk space as the compressed
databases in order to unpack and install them.

The enclosed shell script will unpack the databases and install them
in the proper locations.  The script must be executed with super user
privileges in order to copy files into protected locations and alter
file permissions.

Usage:

 % sudo ./unpack.sh ${release} [PATH_TO_TAR] [MYSQL_PATH]

Replace [PATH_TO_TAR] with the full path to the directory holding the
compressed databases.

Replace [MYSQL_PATH] with the full path to the MySQL data directory.

The Acedb databases will be installed at /usr/local/acedb.

A full command eg:

 % sudo ./unpack.pl ${release} /home/todd/${release} /usr/local/mysql/var

Todd Harris (harris\@cshl.org)
$day $month $year
END
;

open OUT,">$release-$date-Disc2/HOWTO_INSTALL";
print OUT $howto;
close OUT;


# Copy the install script over.
system("cp unpack.sh $release-$date-Disc2/.");


if ($download) {
  my $command = <<END;

# Fetch the original release
cd ${release}-${date}-Disc1/original_release
scp -r brie3.cshl.org:/usr/local/ftp/pub/wormbase/elegans/${release} .
mv ${release}/* .
rm -rf $release;

# Now fetch the database tarballs
cd ../../${release}-${date}-Disc2/prebuilt_databases
scp -r brie3.cshl.org:/usr/local/ftp/pub/wormbase/database_tarballs/${release} .
mv ${release}/* .
rm -rf ${release}
END
;

print "Downloading data release $release...";
system($command);
}
