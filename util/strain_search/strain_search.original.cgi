#!/usr/bin/perl -w

############################################################
#
#    written by Igor Antoshechkin
#    igor.antoshechkin@caltech.edu
#    Dec. 2005
#
############################################################

use strict;
use Search::Indexer;
use Storable qw(store retrieve);

use lib '../lib';
use Ace::Browser::AceSubs qw(:DEFAULT);
use ElegansSubs qw/:DEFAULT/;
use CGI qw/:standard/;
use vars qw/$DB/;

$DB = OpenDatabase() || AceError("Couldn't open database.");

$|=1; #turn off output buffering

my $confFile="strain_search.conf";

open CONF, "<$confFile";
if (!fileno(CONF)) {
    die "cannot open configuration file $confFile\n";
}

my $indexDir='';
my $htmlRoot='';
while (<CONF>) {
    chomp;
    my @tmp=split('\s+');
    unless($tmp[0] eq "indexDir" || $tmp[0] eq "htmlRoot") {
	next;
    }
    if (!$tmp[1]) {
	die "invalid configuration line: $tmp[0]\n";
    }
    $tmp[1]=~s/\"//g;
    $tmp[1]=~s/\'//g;
    if ($tmp[0] eq "indexDir") {
	$indexDir=$tmp[1];
    }
    elsif ($tmp[0] eq "htmlRoot") {
	$htmlRoot=$tmp[1];
    }
}
close CONF;

unless ($indexDir && $htmlRoot) {
    die "invalid configuration file\n";
}


#my $indexDir="/home/igor/Projects/Perl/strainsearch";                      # directory in which index files are (ixw.bdb, ixp.bdb, ixd.bdb)
#my $strainFile="/home/igor/Projects/Perl/strainsearch/lookup.strains";    # full name of lookup.strains file
#my $htmlRoot="http://elbrus.caltech.edu/~igor/strains/";                  # URL that prefixes all pages (e.g. http://www.wormbook.org)
my $strainFile=$indexDir."/lookup.strains";
#my $htmlRoot="/~igor/strains/";                                            #relative URL that prefixes all pages

my $q=new CGI;
my $script_name=$q->script_name;

my $name = param('name');
PrintTop("Search Strain Database");

my %values = ( any    => 'Any words',
	       all    => 'All words',
	       phrase => 'Phrase',
	       query  => 'Use query syntax');

if (param('query') && ! param('noQueryString')) {
print h1('Search Strain Database'),
    start_form({-action=>$script_name}),
    table(
	  TR(
	     td(
		b('Search strain list for:'),
		),
	     td(textfield({-name=>'query',-size=>'40'}),
		submit({-name=>'search',-value=>'Search'}),
		reset())),
	  TR(
	     td(),
	     td('Search strains available at CGC only',
		checkbox({-name=>'CGConly'-values=>[qw/on off/]}))),
	  TR(
	     td(),
	     td('Find records containing:',
		radio_group({-name=>'words',-values=>\%values,-default=>'any'}),
		))),
    end_form();
PrintBottom();
exit;
}




if (! $ENV{QUERY_STRING} && $q->param("query") && ! $q->param("noQueryString")) {    # prints query params on the URL line (use with JavaScript-based highlighling of terms in other pages)
    my $self_url=$q->self_url;
    $self_url=~s/;search=Search//;
    print $q->redirect($self_url);
}

my $query=$q->param("query");
my $search=$q->param("search");
my $CGConly=$q->param("CGConly");
my $words=$q->param("words");

#############################################################
#  
#     put your header html here (css, header, etc.)
#     e.g. print "<link rel=\"stylesheet\" href=\"http://elbrus.caltech.edu/~igor/wormbase.css\">";
#
#############################################################

my $ix = new Search::Indexer(dir => $indexDir);

my %strain_hash=();


my $ref = retrieve($strainFile) || die "cannot retrieve $strainFile : $!\n";
%strain_hash=%$ref;

if ($words ne "query") {
    $query=~s/\"//g;
    $query=~s/\'//g;
    $query=~s/ AND / /ig;
    $query=~s/ OR / /ig;
    $query=~s/ NOT / /ig;
    $query=~s/\s{2,}/ /g;
}

if ($words eq "all") {
    my @words=split(/\s/, $query);
    $query='';
    foreach (@words) {
	$query=join(' AND ', @words);
    }
}
elsif ($words eq "any") {
    my @words=split(/\s/, $query);
    $query='';
    foreach (@words) {
	$query=join(' OR ', @words);
    }
}
elsif ($words eq "phrase") {
    $query="\"".$query."\"";
}
else {  # use query
}


my $result = $ix->search($query);
my @tmp_docIds = keys %{$result->{scores}};


my @docIds=();
foreach (@tmp_docIds) {
    if ($CGConly) {
	if ($strain_hash{$_}{CGC} eq "Yes") {
	    push @docIds, $_;
	}
    }
    else {
	push @docIds, $_;
    }
}

=head
if (scalar @docIds == 1) {
    my $URL='';
    if ($strain_hash{$docIds[0]}{WB} eq "Yes") {
#	$URL="http://www.wormbase.org/db/gene/strain?name=$strain_hash{$docIds[0]}{strain};class=Strain";
	$URL=$htmlRoot."/".$strain_hash{$docIds[0]}{file};
    }
    else {
	$URL=$htmlRoot."/".$strain_hash{$docIds[0]}{file};
    }
    print $q->redirect($URL);
}
=cut

if (scalar @docIds == 1) {
    my $URL='';
    if ($strain_hash{$docIds[0]}{WB} eq "Yes") {
#	$URL="\"http://www.wormbase.org/db/gene/strain?name=$strain_hash{$docIds[0]}{strain};class=Strain\"";
	$URL="\"".$htmlRoot."/".$strain_hash{$docIds[0]}{file}."\"";
    }
    else {
	$URL="\"".$htmlRoot."/".$strain_hash{$docIds[0]}{file}."\"";
    }

    print $q->header("text/html");
    print "<html><script type=\"text/javascript\">window.location.replace($URL)</script></html>";  #both work
    exit;
}


print $q->header("text/html");
#print "<body bgcolor=\"FFFFF0\">";
#print $q->start_html(-title=>'Strain Search Results');
PrintTop('Strain Search Results');
print "<h1>Results of search for $query</h1>";
print "Your search for $query found ", scalar @docIds, " strains:<br>";

print "<ol>\n";

foreach my $doc (sort {$strain_hash{$a}{strain} cmp $strain_hash{$b}{strain}} @docIds) {
    my $URL='';
    if ($strain_hash{$doc}{WB} eq "Yes") {
#	$URL="http://www.wormbase.org/db/gene/strain?name=$strain_hash{$doc}{strain};class=Strain";
	$URL=$htmlRoot."/".$strain_hash{$doc}{file};
    }
    else {
	$URL=$htmlRoot."/".$strain_hash{$doc}{file};
    }
    print "<li><a href=\"$URL\">$strain_hash{$doc}{strain}</a>&nbsp;$strain_hash{$doc}{genotype}</li>\n";
}
print "</ol>\n";

#print "<hr width=100%><a href=\"mailto:webmaster\@wormbase.org\">webmaster\@www.wormbase.org</a></body></html>";
PrintBottom();

#############################################################
#  
#     put your footer html here 
#
#############################################################




