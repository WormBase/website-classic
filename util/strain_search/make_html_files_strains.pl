#!/usr/bin/perl 

use strict;
use Getopt::Std;
use Ace;
use lib '/usr/local/wormbase/util/strain_search';
use IgorSubs;

my %opts =();

getopts('i:o:n:m:e:a:hw',\%opts);

$|=9;   #turn off output caching

my $program_name=$0=~/([^\/]+)$/ ? $1 : '';

if (! defined $opts{i} or ! defined $opts{o} ) {
    $opts{h}=1;
}

if ($opts{h}) {
    print "usage: $program_name [options] -i input_file -o output_directory\n";
    print "       -h              help - print this message\n";
    print "       -a              path/URI to the acedb database to use\n";
    print "       -i <file>       input file\n";
    print "       -o <dir>        output directory\n";
    print "       -w              parse WormBase strains; default NO\n";
    print "       -n <notinCGC>   write wormbase strains not in CGC\n";
    print "       -m <notinWB>    write CGC strains not in wormbase\n";
    print "       -e <empty>      write strains with no data\n";
    exit(0);
}


open IN, "<$opts{i}" || die "$!\n";

if ($opts{n}) {
    open CGC, ">$opts{n}" || die "$!\n";
}

if ($opts{m}) {
    open WB, ">$opts{m}" || die "$!\n";
}

if ($opts{e}) {
    open EMPTY, ">$opts{e}" || die "$!\n";
}


print "Connecting to database...";

my $db = Ace->connect($opts{a}) || die "Connection failure: ", Ace->error;

#my $db = Ace->connect(-path => '/home/igor/AceDB',  -program => '/home/igor/AceDB/bin/tace') || die print "Connection failure: ", Ace->error;
#my $db = Ace->connect('sace://elbrus.caltech.edu:40004') || die "Connection failure: ", Ace->error;

print "done\n";

my %status=$db->status;
my $version = $db->status->{database}{version};

# Create a versioned output directory
$opts{o} = ($opts{o} =~ /(.*\/)$/) ? $1 : $opts{o} . '/';
my $output = $opts{o} . "/$version";
if (! -e $output) {
    mkdir($output,0777) or die "Couldn't create the output directory: $output...\n";
}


my $now=localtime;

my $query="find strain";

my @tmp=$db->find($query);
print scalar @tmp, " strains in $status{database}{title} $status{database}{version} found on $now\n";
my %strain_hash_wb=();
foreach (@tmp) {
    $strain_hash_wb{$_}=1;
}


#my ($strain, $species, $genotype, $description, $mutagen, $outcrossed, $reference, $made_by, $recieved);
my %hash=();
my $count=0;
my $strain='';
my $section='';
my $content='';
my $not_in_wormbase_count=0;
my %strain_hash_cgc=();
my $body = qq{onload='highlightIgorSearchTerms(document.referrer);' class="noboiler"};
while (<IN>) {
    s/\r\n/\n/g;
    s/\r/\n/g;
    chomp;
    next unless $_;
    next if /----------/;
    if (/Strain:/) {
	if ($strain) {
	    my $filename = "$output/$strain.html";
	    open OUT, ">$filename" || die "cannot open $filename\n";
#	    print OUT "<html><head><title>$strain</title><script language=\"JavaScript\" src=\"js/highlightTerms.js\"></script></head>\n";
#	    print OUT "<body bgcolor=\"FFFFF0\" onload=\'highlightIgorSearchTerms(document.referrer);\'><h1>$strain</h1>\n";
#	    print OUT "<html><body>";
	    PrintTop($strain, \*OUT, $body);
	    print OUT qq{<script language="JavaScript" src="/js/highlightTerms.js"></script><h1>$strain</h1>};

	    print OUT qq{<div class="warning">The details of this new strain have been drawn from the CGC. The full record will be integrated into WormBase in the near future.</div>};
	    print OUT "<dl>\n";
	    foreach my $s ('Strain', 'Species', 'Genotype', 'Description', 'Mutagen', 'Outcrossed', 'Available at CGC', 'WormBase Strain Report', 'Reference', 'Made by', 'Received') {
		if (!$hash{$s}) {
		    $hash{$s}='';
		} 
		$hash{$s}=~s/\t/ /g;
		$hash{$s}=~s/\s{2,}/ /g;
		print OUT "<dt title=\"$s\"><strong>$s:</strong></dt>\n";
		print OUT "<dd>$hash{$s}</dd>\n";
	    }
	    print OUT "<br>\n";
	    PrintBottom(\*OUT);
#	    print OUT "<script language=\"JavaScript\">highlightIgorSearchTerms(document.referrer);</script></body></html>\n";
	    print OUT "</body></html>\n";
#	    print OUT "</dl><hr><a href=\"mailto:webmaster\@wormbase.org\">webmaster\@www.wormbase.org</a></body></html>\n";
	    close OUT;
	}
	%hash=();
	$section="Strain";
	$strain=$_=~/Strain:\s+(.+)/ ? $1 : 'no_name';
	$hash{$section}.=$strain;
	$hash{'Available at CGC'}='Yes';
	if ($strain_hash_wb{$strain} || $strain_hash_wb{lc $strain} || $strain_hash_wb{uc $strain}) {
	    $hash{'WormBase Strain Report'}="<a href=/db/gene/strain?name=$strain;class=Strain>$strain</a>";
	}
	else {
	    $hash{'WormBase Strain Report'} = "Strain not yet available through WormBase";
	    $not_in_wormbase_count++;
	    if ($opts{m}) {
		print WB "$strain\n";
	    }
	}
	if ($strain_hash_cgc{$strain}) {
	    print "$strain already parsed\n";
	}
	else {
	    $strain_hash_cgc{$strain}=1;
	    $count++;
	}
    }
    elsif (/Species:/) {
	$section="Species";
	$content=$_=~/^\s*\w+:\s+(.+)/ ? $1 : '';
	$hash{$section}.=$content;
    }
    elsif (/Genotype:/) {
	$section="Genotype";
	$content=$_=~/^\s*\w+:\s+(.+)/ ? $1 : '';
	$hash{$section}.=$content;
    }
    elsif (/Description:/) {
	$section="Description";
	$content=$_=~/^\s*\w+:\s+(.+)/ ? $1 : '';
	$hash{$section}.=$content;
    }
    elsif (/Mutagen:/) {
	$section="Mutagen";
	$content=$_=~/^\s*\w+:\s+(.+)/ ? $1 : '';
	$hash{$section}.=$content;
    }
    elsif (/Outcrossed:/) {
	$section="Outcrossed";
	$content=$_=~/^\s*\w+:\s+(.+)/ ? $1 : '';
	$hash{$section}.=$content;
    }
    elsif (/Reference:/) {
	$section="Reference";
	$content=$_=~/^\s*\w+:\s+(.+)/ ? $1 : '';
	$hash{$section}.=$content;
    }
    elsif (/Made by:/) {
	$section="Made by";
	$content=$_=~/^\s*Made by:\s+(.+)/ ? $1 : '';
	$hash{$section}.=$content;
    }
    elsif (/Received:/) {
	$section="Received";
	$content=$_=~/^\s*\w+:\s+(.+)/ ? $1 : '';
	$hash{$section}.=$content;
    }
    else {
	$hash{$section}.=$_;
    }
}

if ($strain) {
    my $filename= "$output/$strain.html";
    open OUT, ">$filename" || die "cannot open $filename\n";
#    print OUT "<html><head><title>$strain</title><script language=\"JavaScript\" src=\"js/highlightTerms.js\"></script></head>\n";
#    print OUT "<body bgcolor=\"FFFFF0\" onload=\'highlightIgorSearchTerms(document.referrer);\'><h1>$strain</h1>\n";
    PrintTop($strain, \*OUT, $body);
    print OUT "<script language=\"JavaScript\" src=\"js/highlightTerms.js\"></script><h1>$strain</h1>\n";
    print OUT qq{<div class="warning">This new CGC strain has not yet been entered into WormBase.</div>};

    print OUT "<dl>\n";
    foreach my $s ('Strain', 'Species', 'Genotype', 'Description', 'Mutagen', 'Outcrossed', 'Available at CGC', 'WormBase Strain Report', 'Reference', 'Made by', 'Received') {
	if (!$hash{$s}) {
	    $hash{$s}='';
	} 
	$hash{$s}=~s/\t/ /g;
	$hash{$s}=~s/\s{2,}/ /g;
	print OUT "<dt title=\"$s\"><strong>$s:</strong></dt>\n";
	print OUT "<dd>$hash{$s}</dd>\n";
    }
    print OUT "<br>\n";
    PrintBottom(\*OUT);
#    print OUT "<script language=\"JavaScript\">highlightIgorSearchTerms(document.referrer);</script></body></html>\n";
    print OUT "</body></html>\n";
#    print OUT "</dl><hr><a href=\"mailto:webmaster\@wormbase.org\">webmaster\@www.wormbase.org</a></body></html>\n";
    close OUT;
}


my $not_in_cgc_count=0;
my $no_info_count=0;
if ($opts{w}) {
    print "parsing strains from WormBase\n";
    $query="find strain";
    @tmp=$db->find($query);

    foreach (@tmp) {
	%hash=();
	if ($strain_hash_cgc{$_} || $strain_hash_cgc{lc $_} || $strain_hash_cgc{uc $_}) {
	    next;
	}
	else {
	    my $line='';
	    eval {
		$line=$_->asAce();
	    };
	    if ($@) {
#		print "$_\n";
#		print "$@\n";
		$no_info_count++;
		if ($opts{e}) {
		    print EMPTY "$_\n";
		}
		$line='';
	    }

	    my @lines=split('\n', $line);
	    $strain=$_;
	    $hash{'Available at CGC'}='No';
	    $hash{'WormBase Strain Report'}="<a href=http://www.wormbase.org/db/gene/strain?name=$strain;class=Strain>$strain</a>";
	    $hash{'Strain'}=$strain;

	    foreach (@lines) {
		if (/^Contains\s+Gene/) {
		    $section="Gene";
		    my @tmp=split('\t');
		    $tmp[2]=~s/\"//g;
		    my $name=$db->fetch(Gene=>$tmp[2])->Public_name;
		    push @{$hash{$section}}, $name;
		}
		elsif (/^Contains\s+Variation/) {
		    $section="Variation";
		    my @tmp=split('\t');
		    $tmp[2]=~s/\"//g;
		    push @{$hash{$section}}, $tmp[2];
		}
		elsif (/^Contains\s+Rearrangement/) {
		    $section="Rearrangement";
		    my @tmp=split('\t');
		    $tmp[2]=~s/\"//g;
		    push @{$hash{$section}}, $tmp[2];
		}
		elsif (/^Contains\s+Clone/) {
		    $section="Clone";
		    my @tmp=split('\t');
		    $tmp[2]=~s/\"//g;
		    push @{$hash{$section}}, $tmp[2];
		}
		elsif (/^Contains\s+Transgene/) {
		    $section="Transgene";
		    my @tmp=split('\t');
		    $tmp[2]=~s/\"//g;
		    push @{$hash{$section}}, $tmp[2];
		}
		elsif (/^Genotype/) {
		    $section="Genotype";
		    my @tmp=split('\t');
		    $tmp[1]=~s/\"//g;
		    push @{$hash{$section}}, $tmp[1];
		}
		elsif (/^Outcrossed/) {
		    $section="Outcrossed";
		    my @tmp=split('\t');
		    $tmp[1]=~s/\"//g;
		    push @{$hash{$section}}, $tmp[1];
		}
		elsif (/^Mutagen/) {
		    $section="Mutagen";
		    my @tmp=split('\t');
		    $tmp[1]=~s/\"//g;
		    push @{$hash{$section}}, $tmp[1];
		}
		elsif (/^Location/) {
		    $section="Laboratory";
		    my @tmp=split('\t');
		    $tmp[1]=~s/\"//g;
		    push @{$hash{$section}}, $tmp[1];
		}
		elsif (/^Made_by/) {
		    $section="Made by";
		    my @tmp=split('\t');
		    $tmp[1]=~s/\"//g;
		    push @{$hash{$section}}, $tmp[1];
		}
		elsif (/^Remark/) {
		    $section="Description";
		    my @tmp=split('\t');
		    $tmp[1]=~s/\"//g;
		    push @{$hash{$section}}, $tmp[1];
		}
		elsif (/^Reference/) {
		    $section="Reference";
		    my @tmp=split('\t');
		    $tmp[1]=~s/\"//g;
		    my $paper=$db->fetch(Paper=>$tmp[1])->Brief_citation;
		    push @{$hash{$section}}, $paper;
		}
	    }

	    if ($opts{n}) {
		print CGC "$strain";
		if ($hash{'Genotype'}) {
		    print CGC "\t", join(', ', @{$hash{'Genotype'}}), "\n";
		}
		else {
		    print CGC "\n";
		}
	    }
	    
	    my $filename="$output/$strain.html";
	    open OUT, ">$filename" || die "cannot open $filename\n";
	    if (! fileno(OUT)) {
		print "$filename file is not opened\n";
		next;
	    }
#	    print OUT "<html><head><title>$strain</title><script language=\"JavaScript\" src=\"js/highlightTerms.js\"></script></head>\n";
#	    print OUT "<body bgcolor=\"FFFFF0\" onload=\'highlightIgorSearchTerms(document.referrer);\'><h1>$strain</h1>\n";
	    PrintTop($strain, \*OUT, $body);
	    print OUT "<script language=\"JavaScript\" src=\"js/highlightTerms.js\"></script><h1>$strain</h1>\n";
	    print OUT "<dl>\n";
	    foreach my $s ('Strain', 'Species', 'Genotype', 'Description', 'Mutagen', 'Outcrossed', "Gene", "Variation", "Rearrangement", "Clone", "Transgene", 'Available at CGC', "Laboratory", 'WormBase Strain Report', 'Reference', 'Made by', 'Received') {
		if (!$hash{$s}) {
		    next;
		}
		eval {
		    $hash{$s}=join(', ', @{$hash{$s}});
		};
		if ($@) {
#		    print "$@";
		}
		
		$hash{$s}=~s/\t/ /g;
		$hash{$s}=~s/\s{2,}/ /g;
		print OUT "<dt title=\"$s\"><strong>$s:</strong></dt>\n";
		print OUT "<dd>$hash{$s}</dd>\n";
	    }
	    print OUT "<br>\n";
	    PrintBottom(\*OUT);
#	    print OUT "<script language=\"JavaScript\">highlightIgorSearchTerms(document.referrer);</script></body></html>\n";
	    print OUT "</body></html>\n";
#	    print OUT "</dl><hr><a href=\"mailto:webmaster\@wormbase.org\">webmaster\@www.wormbase.org</a></body></html>\n";
	    close OUT;
	    $not_in_cgc_count++;
	    $count++;
	    if ($not_in_cgc_count % 100 == 0) {
#		print "$not_in_cgc_count strains processed\n";
	    }
	
	}
    }
}

print "$count files generated\n";
print scalar keys %strain_hash_cgc, " strains available from CGC\n";
print "$not_in_wormbase_count strains in CGC are not in WormBase\n";
print "$not_in_cgc_count strains in WormBase are not in CGC\n";
print "$no_info_count strains in WormBase have no information\n";

