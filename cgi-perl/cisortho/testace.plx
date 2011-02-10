#!/usr/bin/perl -W


use Data::Dumper;

#print Dumper \%ENV; die;

use lib '/usr/local/wormbase/cgi-perl/lib';

use strict;
use vars qw($DB $GFFDB $BROWSER $allele $brain $gff_segment $WORMBASE $CONFIG %EXT_LINKS @results);
use Ace;
use Ace::Browser::AceSubs qw(:DEFAULT !TypeSelector AceRedirect AceMultipleChoices Configuration);
use ElegansSubs qw(:DEFAULT :locus :biblio :sequence format_references Bestname);

use Carp qw(FatalsToBrowser);

#%Input=Vars;

print start_html(-title=>'Test Page');
$abc = Apache->request->dir_config('AceBrowserConf');
$DB = OpenDatabase('c_elegans') || AceError("Couldn't open database.");
$DB->class('Ace::Object::Wormbase');

@results = $DB->fetch(-query=>"find Gene where Public_name=*cog-1*; follow Antibody");

#print Dumper \@results;
#$DB = OpenDatabase() || AceError("Couldn't open database.");
#@results = $DB->fetch(-class=>'Sequence',-count=>100);
print &pre(Dumper $abc);
print end_html;
