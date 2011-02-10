#!/usr/bin/perl

use strict;
use LWP::UserAgent;
use HTTP::Request::Common;
use Getopt::Long;

use constant WB => 'http://www.wormbase.org/db/searches/epcr';
use constant LENGTH_TOLERANCE     => 50;
use constant MISMATCH_TOLERANCE   =>  0;

my ($WB,$M,$N,$POS);

GetOptions( 'length_tolerance=i'   => \$M,
	    'mismatch_tolerance=i' => \$N,
	    'position'             => \$POS,
	    'wormbase=s'           => \$WB) or die <<USAGE;
Usage: $0 [options] sts_file

Run ePCR on wormbase, returning a report on overlapping genes.
Format of input file is:

  T05A10.2	CGATAAACAATCAACGGCATAAT	TTTGAAACTGATATAGAGGGGCA	1188
  T01B11.7	TATCCCACTACTAACCCCAAACC	AAAAGTTGGTACCTTCCGATTCT	1664

Format of output file is:
 # assay chromosome      start   end     genbank start   end     gene    exons covered   total exons

 assay1  II      4332211    4338292   AC006661  9803    15884   H20J04.3        1,2,3,4   4
 assay1  II      4332211    4338292   AC006661  9803    15884   H20J04.4        4,5,6,7   7
 assay2  IV      12089228   12091923  Z68297    8530    11225   F11A10.3        3,4,5     5

 Options:

      -length_tolerance     Slop in the accepted length   (50 bp)
      -mismatch_tolerance   Number of mismatches accepted ( 0 bp)
      -position             File is a list of positions, not a list of primer pairs
      -wormbase             CGI script to connect to (http://www.wormbase.org/db/seq/epcr)

If -position is specified, takes an input consisting of label and
chromosome- or genbank position, like this:

  assay1  II:4332211..4338292
  assay2  IV:12089228..12091923
USAGE
;

$M = LENGTH_TOLERANCE   unless defined $M;
$N = MISMATCH_TOLERANCE unless defined $N;
$WB = WB                unless defined $WB;

undef $/;   # slurp
my $data = <>;

my $request = POST($WB,
		   Content_type => 'form-data',
		   Content      => [ format       => 'text',
				     entry_type   => $POS ? 'pos' : 'sts',
				     M            => LENGTH_TOLERANCE,
				     N            => MISMATCH_TOLERANCE,
				     sts          => $data ]);
my $ua = LWP::UserAgent->new;
my $response = $ua->request($request);
die $response->message if $response->is_error;

print $response->content;

