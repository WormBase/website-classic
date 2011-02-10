#!/usr/bin/perl
# $Id: hunter.cgi,v 1.1.1.1 2010-01-25 15:36:05 tharris Exp $

use lib '../lib';
use strict;
use CGI qw/:standard center/;
use CGI::Cookie;
use CGI::Widget::Series;
use URI::Escape;
use Seqview;
use Ace;
use Ace::Sequence;
use Ace::Browser::GeneSubs;
use Ace::Browser::SearchSubs;
use Ace::Browser::AceSubs qw/:DEFAULT AceAddCookie AcePicRoot/;
use ElegansSubs qw/:DEFAULT/;
use Digest::MD5 'md5_hex';

# use constant MAX_LENGTH    => 200_000;  # maximum segment we will display
# use constant SUPPRESS_EST  => 20_000;   # point at which we start supressing EST display
# use constant LEVELS	   => 8;	# zooming levels = no of images for zooming

use vars qw($MAX_LENGTH $SUPPRESS_EST $LEVELS);
($MAX_LENGTH, $SUPPRESS_EST, $LEVELS) 	= (200000, 20000, 8);

# get a database handle
my $DB          = OpenDatabase() || die "couldn't open database";
$DB->class('Ace::Object::Wormbase');

my $dasdraw = Configuration->Das_draw;

my @valid_servers  = qw(WormBase);
my @valid_chroms   = qw(CHROMOSOME_I CHROMOSOME_II CHROMOSOME_III CHROMOSOME_IV CHROMOSOME_V CHROMOSOME_X);


my (@features)	= &_setFeatures();
my ($width)	= &_setImageWidth();

$width = 800 if !$width || $width < 100 || $width > 2000;
my $height;
my ($name, $chromosome, $start, $stop, $nav, $zoom, $dump, @servers) = 
		&_getParams(\@valid_chroms, \@valid_servers);

#these will eventually be replaced using DAS
#I think it will be good to put some of these in Configuration->method, such as $organism
my $organism       = "C.elegans";
my @valid_features = @{Configuration->Dasview_featurelist || []};


# the requested object is either a Sequence or a Locus we try one and then the other
my ($obj,$seq_obj);

# THE LOGIC HERE IS TOTALLY SCREWED UP -- ls
#hmm...
if ($name) {
  if ($name =~ /^\w{3,4}-[\d.]+$/) {
    my $locus = $DB->fetch(Locus=>$name);
    $obj = $locus->Sequence if $locus;
  }

  unless ($obj) {
    $obj = $DB->fetch(Sequence=>$name);
    unless ($obj) {
      my $locus = $DB->fetch(Locus=>$name);
      $obj = $locus->Sequence if $locus;
    }
  }

  unless ($obj) {
    if (my $acc = $DB->fetch(Accession_number=>$name)) {
      $obj = $acc->Sequence;
    }
  }

  $seq_obj = Ace::Sequence->new($obj) if $obj;

} elsif ($chromosome && $start && $stop) {
  zoomnav(\$start,\$stop,\$chromosome,\$zoom,\$nav) if $nav || $zoom;
  $obj     = $DB->fetch(Sequence=>$chromosome);
  $seq_obj = Ace::Sequence->new(-seq=>$obj,-start=>$start,stop=>$stop) if $obj;
}

Delete('name');  # never repeat

if ($seq_obj) {
    $seq_obj->absolute(1);
    if ($seq_obj->start > $seq_obj->stop) {  #oopsie.  reverse.
	$seq_obj = Ace::Sequence->new(-seq=>$seq_obj->refseq,
				      -start=>$seq_obj->stop,
				      -stop => $seq_obj->start);
    }
}



# dump view as requested (i.e.: 'FastA' or 'GFF')
if($obj && $dump){
  MakeSeqDump($dump,$seq_obj,$seq_obj->start,$seq_obj->stop,$chromosome,\@features,\@servers);
  exit;
}

# make sure all is consistent
($start, $stop, $chromosome)	= ($seq_obj->start, $seq_obj->stop, $seq_obj->refseq) if $seq_obj;

(my $clabel = $chromosome) =~ s/CHROMOSOME_//;
$clabel ||= $obj;
my $cstart = add_commas($start);
my $cstop  = add_commas($stop);

my $label = (defined($start) ? "$clabel:$cstart..$cstop (showing @{[$stop-$start]} bp)" : "$obj") || 'Sequence Search:';
PrintTop(undef,undef,$label);

print h2({-class=>'error'},"Unknown reference point") if ($name || $chromosome) && !$seq_obj;

#&show_javascript();
print start_form(-name=>'f1',-action=>url(-relative=>1));
print table({-border=>0, -width=>'100%'}, 
	    TR(
	       td({-class=>'searchbody',-align=>'left', -colspan=>2},
		  'Search by sequence name, gene name, locus, or chromosome range',
		  '(e.g. ', a({-href=>'hunter.cgi?name=unc-9'},'unc-9'),', ',
		  a({-href=>'hunter.cgi?name=B0019'},'B0019'), ', ' ,
		  a({-href=>"hunter.cgi?name=@{[uri_escape('V:12340..123412')]}"},'V:12340..123412'),' )', 
		 )),

	    TR({-class=>'searchtitle', -colspan=>2, -align=>'left'},
	       td({-class=>'searchtitle'}, b('Genome Hunter Search'),
		  textfield(-name=>'name', -value=>"",-size=>18,-force=>param('chromosome')), submit(-name=>'Go')),
	       td(
		  (($start && $stop) || $obj) ? 
		  ('Scroll/Zoom: ',&slidertable(\$start,\$stop,\$chromosome,\@features,\@servers, $zoom, $nav)) : ''
		 ),
	      ));

if(($start && $stop) || $obj) {
  my ($w,$h,$gd) = MakeSeqImageAndMap($seq_obj, \@features, \@servers, {width=>$width});
  my $signature = md5_hex($seq_obj,@features,@servers,$width);
  my $extension = $gd->can('png') ? '.png' : '.gif';
  my ($uri,$path) = AcePicRoot("Hunter");
  my $image       = sprintf("%s/%s.%s",$path,$signature,$extension);
  my $url         = sprintf("%s/%s.%s",$uri,$signature,$extension);
  unless (-e $image && -M $image < 0) {
    open (F,">$image") || AceError("Can't open image file $image for writing: $!\n");
    print F $gd->can('png') ? $gd->png : $gd->gif;
    close F;
  }
  print center(img({-src=>$url,-usemap=>'#hmap',-width => $w,-height => $h,-border=>0}));
}

print  searchtable($name,$start,$stop,$chromosome, \@features,\@valid_features, \@servers, \@valid_servers, \@valid_chroms, $width);

print end_form;
PrintBottom();



#_______________ SUBS ______________

sub searchtable{
  my($name,$start,$stop,$chromosome,$features,$valid_features,$servers,$valid_servers,$valid_chroms, $width) = @_;  
  $start	||= 0; 
  $stop		||= 0; 
  $name		||= '';
  $chromosome	||= 'CHROMOSOME_I';

# an array ref for the image widths that are possible to be selected
  my $imageWidths = Configuration->Imagewidths;

# set up the dumps line.
my @valid_dumps    = ( ['FastA',"hunter.cgi?dump=FastA;start=$start;stop=$stop;chromosome=$chromosome"],
		      ['GFF'  ,"hunter.cgi?dump=GFF;start=$start;stop=$stop;chromosome=$chromosome"]);
my $ds        = join(', ', (map{a({-href=>"@$_->[1]"},"@$_->[0]")} @valid_dumps));
   my $sTable 	= '';


# start advertisement
   $sTable	= qq{<h4><center><IMG src="/ico/new.gif">Try <a href="/db/searches/dasview?chromosome=$chromosome;start=$start;stop=$stop;s~Wormbase~elegans=all"><b>DasView</b></a>, our new sequence viewer.<IMG src="/ico/new.gif"></center></h4>} if ($start or $stop);
# end advertisement

   $sTable	.= table({-width=>'100%'},
	    th({-class=>'searchtitle', -colspan=>2, -align=>'left'},'Genome Hunter Search Settings:'),
	    '<!-- ',TR({-class=>'searchtitle', -colspan=>2, -align=>'left'},'Genome Hunter Search',
	       	    textfield(	-name=>'name', -value=>"",-size=>18, -force=>1), submit(-name=>'Go')),'-->',
            TR( td({-class=>'searchbody', -width=>150},'Dump view as: '),
	    	td({-class=>'searchbody'}, $ds)),
            TR(	td({-class=>'searchbody', -valign=>'top', -width=>150}, 'Show features: '),
		td({-class=>'searchbody'}, 
			checkbox_group(-name=>'feature',-values=>$valid_features,-defaults=>$features,-cols=>3))),
            TR( td({-class=>'searchbody', -width=>150},'Image Width: '),
	    	td({-class=>'searchbody'}, 
		radio_group( -name=>'width',
                               -values=>$imageWidths,
                               -default=>800)
		)),
	    TR(td({-class=>'searchbody',-colspan=>2, -align=>'left'},
	    hidden('chromosome'),hidden('start'),hidden('stop'),
	    submit(-name=>'Change Settings')))
        );
  return $sTable;
}

sub show_image {
  my ($organism, $name, $valid_chroms, $features, $servers, $start, $stop, $dasdraw, $width, $height) = @_;

  my $fs             = join ';feature=', map {CGI::escape($_)} @$features;
  my $ss             = join ';server=', @$servers;
  my $vcs            = join ' ', @$valid_chroms;

  #warn about briggsae contigs
  unless($vcs =~ /$name/){
    print h3({-class=>'error',-align=>'CENTER'},"You are not browsing $organism genomic sequence");
  }

  if($stop - $start <= $MAX_LENGTH){
    print center(img({-src=>"$dasdraw?".
		      join (';',
			    "name=$name","start=$start","stop=$stop",
			    "image=1","feature=$fs","server=$ss","width=$width"
			   ),
		      -usemap=>'#hmap',
		      -width  => $width,
		      -height => $height,
		      -border=>0}
		 ));
  } else {
    print h3({-class=>'error',-align=>'CENTER'},"Sorry, sequence display is limited to $MAX_LENGTH bp");
  }
}


# prints the zooming and navigation ar plus a informative line on what is displayed
sub slidertable {
  my ($start, $stop, $chr, $features, $servers, $zoom, $nav) = @_;
  my $buttonsDir	= Configuration->Zoomnavdir;

# first form tag
  my @lines;
  push @lines,(hidden(-name=>'start'     ,-value=>[$$start]  ,-force=>1),
	       hidden(-name=>'stop'      ,-value=>[$$stop]   ,-force=>1),
	       hidden(-name=>'chromosome',-value=>[$$chr]    ,-force=>1));
  
  push @lines, (image_button(-src=>"${buttonsDir}/green_l2.gif",-name=>'nav1',-border=>'0',-title=>"b1"),
		image_button(-src=>"${buttonsDir}/green_l1.gif",-name=>'nav2',-border=>'0',-title=>"b2"),
		&_zoomBar($start, $stop, $chr, $features, $servers, $zoom, $nav, $buttonsDir),
		image_button(-src=>"${buttonsDir}/green_r1.gif",-name=>'nav3',-border=>'0',-title=>"b3"),
		image_button(-src=>"${buttonsDir}/green_r2.gif",-name=>'nav4',-border=>'0',-title=>"b4"),
	       );

  #  print end_form;
  my $str	= join('', @lines);
  return $str;
}


# computes the new values for start and stop when the user made use of the zooming bar or navigation bar
sub zoomnav {
  my ($start,$stop,$chromosome,$zoom,$nav) = @_;
  my ($center, $ohalf, $nhalf, $span);

  $span	= $$stop - $$start;

  if($$zoom && $$zoom != -1){
	$center	= int($span / 2) + $$start;
	my $range = calc_range($$zoom)/2;
	($$start, $$stop)	= ($center - $range , $center + $range);

  } elsif($$nav){
    $span = $$stop - $$start;
    if($$nav == 1){ $$start -= int($span / 2); $$stop -= int($span / 2);};
    if($$nav == 4){ $$start += int($span / 2); $$stop += int($span / 2);};
    if($$nav == 2){ $$start -= int($span / 4); $$stop -= int($span / 4);};
    if($$nav == 3){ $$start += int($span / 4); $$stop += int($span / 4);};
  }

  $$start = 1 if $$start < 1;
}



sub _getParams{
  my($valid_chromes, $valid_server)	= @_;

  my @servers     = param('server') || @$valid_server;	# servers to query for data
  my $name = param('name');
  my $chromosome = param('chromosome');
  my $start = param('start');
  my $stop  = param('stop');

  $start =~ s/,//g;
  $stop =~ s/,//g;

  my $dump        = param('dump');	# which feature to dump, if any ?
  my ($zoom, $nav);			# the zooming level for the image

  for(my $i=1; $i <= $LEVELS; $i++){
    my $imgName	= "zoom${i}.x";		# create a name for a parameter and ...
    $zoom = $i if defined param($imgName);	# check to see if it was transmitted with the request
  };
  for(my $i=1; $i<=4; $i++){
    my $imgName	= "nav${i}.x";
    $nav		= $i if defined param($imgName);
  };

  # recognize special case of name containing a new range
  if (
      $name =~ /(?:CHROMOSOME_)?([IVX]+):([\d]+)(?:-|\.\.)?([\d]+)/
      && !$nav
      && !$zoom
     ) {
    $chromosome = $1;
    $start      = $2;
    $stop       = $3;
    $name       = '';

    $chromosome = "CHROMOSOME_$chromosome" if $chromosome =~ /^[IVX]+$/;
  }

  return ($name, $chromosome, $start, $stop, $nav, $zoom, $dump, @servers);
}


sub calc_range {
  my $val = shift;
  return ($val ** 3) * 400; #feels good
}

sub _zoomBar{
#image_button(-src=>"${buttonsDir}/green_r1.gif",
#-name=>'nav3',-border=>'0',-title=>"b3"),

  my ($start, $stop, $ref, $feature,$server,$zoom, $nav, $buttonsDir) = @_;

  my $span	= $$stop - $$start;

  my $render_button = sub {
    my $pos = shift;
    my $range = calc_range($pos);
    return image_button(-src    => "${buttonsDir}/1x1orange.gif",
			-alt    => "show $range bp",
			-title  => "show $range bp",
			-border => 0, 
			-height => ($pos*2)+5,
			-width  => 4,
			)."&nbsp;";
  };

  my $button_count = 8;
  my $series = CGI::Widget::Series->new(	length=>$button_count,
						render=>$render_button
				       );

  return $series;
}


sub _setFeatures{

    my %ckVal       = ();
    my $ckName      = 'hunter_feature';
    my %cookies;
    
    if((%cookies = fetch CGI::Cookie) && (defined $cookies{$ckName})){
        %ckVal  = @{$cookies{$ckName}->{'value'}};
    }else{
        %ckVal  = (map{$_ => 1} @{Configuration->Dasview_default});
    };

    if(param('feature')){
        %ckVal  = ();
        %ckVal  = (map{$_ => 1} param('feature'));
    }

    my $hunter_feature = CGI::Cookie->new( -name   =>$ckName,
                                        -value  =>\%ckVal,
                                        -expires=>'+1M',
                                        -path   =>'/'   );
	AceAddCookie($hunter_feature);
	return (keys %ckVal);
}


sub _setImageWidth{

    my %ckVal       = ();
    my $ckName      = 'hunter_width';
    my %cookies;

    if((%cookies = fetch CGI::Cookie) && (defined $cookies{$ckName})){
        %ckVal  = @{$cookies{$ckName}->{'value'}};
    }else{
        %ckVal  = (map{$_ => 1} (Configuration->Defaultimagewidth));
    };

    if(param('width')){
        %ckVal  = ();
        %ckVal  = (map{$_ => 1} (param('width')));
    }

    my $hunter_width = CGI::Cookie->new( -name   =>$ckName,
                                        -value  =>\%ckVal,
                                        -expires=>'+1M',
                                        -path   =>'/'   );
	AceAddCookie($hunter_width);
	return (keys %ckVal);
}

# I know there must be a more elegant way to insert commas into a long number...
sub add_commas {
  my $i = shift;
  $i = reverse $i;
  $i =~ s/(\d{3})/$1,/g;
  chop $i if $i=~/,$/;
  $i = reverse $i;
  $i;
}
