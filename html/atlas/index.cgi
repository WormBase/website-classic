#!/usr/bin/perl -w

use File::stat;
use URI::Escape;
use CGI 2.42 qw/:standard :html3 escape/;
use CGI::Carp qw/fatalsToBrowser/;
use Net::SMTP;
use Ace 1.51;

my $name = param('query');
my $class = "Atlas";

if (!$DB || !$DB->ping) {
    $DB = Ace->connect(-host=>'localhost',
		       -port=>2005,
		       -timeout=>50);
}

my ($results) = $DB->fetch(-class=>$class,
			   -name=>$name);

my $banner = $results->Banner(1);
my $name = $results->Name(1);
my $location = $results->Location(1);
my $up =  $results->Up_arrow(1);
my $dx =  $results->Dx_arrow(1);
my $sx =  $results->Sx_arrow(1);
my $down =  $results->Down_arrow(1);
my $title =  $results->Title(1);
my $comments =  $results->Comments(1);

$banner=~s/\s+//g;
$name=~s/\s+//g;
$location=~s/\s+//g;
$up=~s/\s+//g;
$down=~s/\s+//g;
$dx=~s/\s+//g;


if ($name == $query){  
  print header,
  
  start_html('-Title' =>'WormBase - Home Page',
	     '-bgcolor'=>'white');
print ('
<div id="Layer5" style="position:absolute; width:76px; height:93px; z-index:5; left: 25px; top: 9px">
<TABLE WIDTH="664" BORDER="0" CELLSPACING="0" CELLPADDING="2">
  <TR>
    <TD ALIGN="CENTER">
    <A HREF="/perl/ace/elegans/searches/basic"><IMG BORDER="0" WIDTH="109" SRC="/buttons/basic_off.gif" ALT="Simple Search" HEIGHT="20"></A>
    </TD>
    <TD ALIGN="CENTER">
    <A HREF="/perl/ace/elegans/searches/expr_search"><IMG BORDER="0" WIDTH="147" SRC="/buttons/expr_off.gif" ALT="Expr. Pattern Search" HEIGHT="20"></A>
    </TD>
    <TD ALIGN="CENTER">
    <A HREF="/perl/ace/elegans/searches/browser"><IMG BORDER="0" WIDTH="100" SRC="/buttons/browser_off.gif" ALT="Class Browser" HEIGHT="20"></A>
    </TD>
    <TD ALIGN="CENTER">
    <A HREF="/perl/ace/elegans/searches/blast"><IMG BORDER="0" WIDTH="99" SRC="/buttons/blast_off.gif" ALT="Blast Search" HEIGHT="20"></A>
    </TD>
    <TD ALIGN="CENTER">
    <A HREF="/perl/ace/elegans/searches/query"><IMG BORDER="0" WIDTH="129" SRC="/buttons/advanced_off.gif" ALT="Advanced Search" HEIGHT="20"></A>
    </TD>
    <TD ALIGN="CENTER">
    <A HREF="/atlas/atlas.html"><IMG BORDER="0" WIDTH="46" SRC="/buttons/atlas_on.gif" ALT="Worm Atlas" HEIGHT="20"></A>
    </TD>
  </TR>
  <TR>
    <TD ALIGN="LEFT" COLSPAN="6">
    <IMG WIDTH="640" SRC="/banners/defunct/logo_6.gif" HEIGHT="56" ALT="WormBase"><nobr><A HREF=""><IMG BORDER="0" WIDTH="20" SRC="/buttons/home_bottom.gif" ALT="WormBase home" HEIGHT="56"></A>
    </TD>
  </TR>
</TABLE>

<MAP NAME="logo_e.gif">  
<AREA SHAPE=POLY COORDS="3,0,3,20,109,20,109,0" HREF="../simple.html" alt="Basic Searches" >  
<AREA SHAPE=POLY COORDS="114,0,114,21,262,21,262,0" HREF="../expr_search.cgi" alt="Expression Patten Searches">  
<AREA SHAPE=POLY COORDS="265,0,265,22,366,22,366,0" HREF="../search.cgi" alt="Class Browser">  
<AREA SHAPE=POLY COORDS="371,0,371,21,464,21,465,0" HREF="../blast.html" alt="BLAST Searches">  
<AREA SHAPE=POLY COORDS="588,21,588,0,467,0,467,21" HREF="../advanced.html" alt="Advanced Searches">  
<AREA SHAPE=POLY COORDS="593,0,593,20,638,20,638,0" HREF="../atlas/atlas.html" alt="Atlas">  
<AREA SHAPE=POLY COORDS="641,21,659,22,659,77,641,77" HREF="../index.html" alt="Home">
</MAP>
</div> 
<BR>
<div id="Layer1" style="position:absolute; width:512px; height:518px; z-index:1; top: 102px; left: 24px">
<img SRC="');

if ($banner eq "yes"){

  print $location;
  print('" USEMAP="#map_pic2"  height=512 width=512 BORDER=0> 
<MAP NAME="map_pic2">
<AREA SHAPE=RECT COORDS="256,0,511,256" HREF="index.cgi?query=');
  print $name;
  print ('-2">
<AREA SHAPE=RECT COORDS="0,0,256,256" HREF="index.cgi?query=');
  print $name;
  print ('-1">
<AREA SHAPE=RECT COORDS="256,256,512,512" HREF="index.cgi?query=');
  print $name;
  print ('-4">
<AREA SHAPE=RECT COORDS="0,256,256,512" HREF="index.cgi?query=');
  print $name;
  print ('-3">
</MAP>
');
  
}else {
  print $location;
  print('" height=512 width=512>');
}
  print ('
</DIV>
<!-- here start the menu bar -->  
<div id="Layer2" style="position:absolute; width:150px; height:128px; z-index:2; left: 536px; top: 102px">   
<table BORDER CELLSPACING=0 CELLPADDING=4 COLS=1 WIDTH="148" BGCOLOR="#FFFFCC"><tr>  
<td>    
<center>  
');
  
  if($up =~ /^\s*$/){
    $up=undef;
  }
  if (defined ($up)) {
    print ('<a href="index.cgi?query=');
  print $up;
  print ('"><img SRC="arrow_up.gif" BORDER=0 alt="Go Up"></a><br> ');
}
else{print ('<img SRC="arrow_no.gif"><br>')};

if($sx =~ /^\s*$/){
  $sx=undef;
}
if (defined ($sx)) {
  print ('<a href="index.cgi?query=');
  print $sx;
  print ('"><img SRC="arrow_left.gif" BORDER=0 alt="Go Left"></a>');
}
else{print ('<img SRC="arrow_no.gif">')};

#if (defined($dx)){
  print ('<img src="arrow_home.gif">');

#}
if($dx =~ /^\s*$/){
  $dx=undef;
}
if (defined ($dx)||($sx)) {
  print ('<a href="index.cgi?query=');
  print $dx;
  print ('"><img SRC="arrow_right.gif" BORDER=0 alt="Go Right"><br></a>');
}
else{print ('<img SRC="arrow_no.gif"><br>')};

if($down =~ /^\s*$/){
  $down=undef;
}
if (defined ($down)) {
  print ('<a href="index.cgi?query=');
  print $down;
  print ('"><img SRC="arrow_down.gif" BORDER=0 alt="Go Down"></a><br> ');
}
else{print ('<img SRC="arrow_no.gif"><br>')};

print ('
</center>
</td>  
</tr>  
</table>  
</div> 
<!-- here finish the menu bar -->  

<!-- here start the layer for the text -->
<div id="Layer4" style="position:absolute; width:149px; height:250px; z-index:9; left: 536px; top: 230px">   
<table BORDER CELLSPACING=0 CELLPADDING=4 COLS=1 WIDTH="148" height="220">  
<tr>  
<td valign=top >  
<font color="#3333FF"><center><b>
');
print ('<!-- here is the title of the map -->  ');
print $title;
print ('</b></center></font><br>
<!-- here finish the title of the map -->
<!-- here is the txt of the picture --> 
<font size=-1>');
print $comments;  
print ('</font><!-- here finish the text of the picture -->
</td>  
</tr>  
</table></div>  
<!-- here start the small worm map --->
<div id="Layer3" style="position:absolute; width:149px; height:118px; z-index:3; left: 536px; top: 508px">   
<table BORDER CELLSPACING=0 CELLPADDING=0 COLS=1 WIDTH="148" BGCOLOR="#FFFFFF"><tr>  
<td>  
<center> 
<IMG SRC="pic_atlas/');

if ($banner eq "no"){
  $name =~ s/\-.+$//;
}

print $name;
print ('-very-small.gif" USEMAP="#mappa" WIDTH=140 HEIGHT=98 BORDER=0>
<MAP NAME="mappa">
<AREA SHAPE=POLY COORDS="2,51,8,46,12,43,17,35,4,36,0,47" HREF="index.cgi?query=a">
<AREA SHAPE=POLY COORDS="22,31,8,31,4,36,18,35" HREF="index.cgi?query=b">
<AREA SHAPE=POLY COORDS="8,31,11,27,24,29,22,31" HREF="index.cgi?query=c">
<AREA SHAPE=POLY COORDS="11,27,15,23,28,25,25,29" HREF="index.cgi?query=d">
<AREA SHAPE=POLY COORDS="15,23,18,19,30,23,27,26" HREF="index.cgi?query=e">
<AREA SHAPE=POLY COORDS="18,19,22,16,34,20,31,23" HREF="index.cgi?query=f">
<AREA SHAPE=POLY COORDS="22,16,25,12,38,17,35,20" HREF="index.cgi?query=g">
<AREA SHAPE=POLY COORDS="25,12,29,9,41,15,38,17" HREF="index.cgi?query=h">
<AREA SHAPE=POLY COORDS="29,9,34,7,47,14,42,15" HREF="index.cgi?query=i">
<AREA SHAPE=POLY COORDS="34,7,37,6,49,13,47,14" HREF="index.cgi?query=l">
<AREA SHAPE=POLY COORDS="37,6,41,3,53,13,50,13" HREF="index.cgi?query=m">
<AREA SHAPE=POLY COORDS="41,3,45,2,56,13,53,13" HREF="index.cgi?query=n">
<AREA SHAPE=POLY COORDS="45,2,53,1,56,13" HREF="index.cgi?query=o">
<AREA SHAPE=POLY COORDS="53,1,58,1,59,13,56,13" HREF="index.cgi?query=p">
<AREA SHAPE=POLY COORDS="58,1,59,13,64,13,65,1" HREF="index.cgi?query=q">
<AREA SHAPE=POLY COORDS="65,1,64,14,68,14,72,2" HREF="index.cgi?query=r">
<AREA SHAPE=POLY COORDS="68,14,72,2,78,4,72,16" HREF="index.cgi?query=s">
<AREA SHAPE=POLY COORDS="78,4,72,16,77,17,83,7" HREF="index.cgi?query=t">
<AREA SHAPE=POLY COORDS="84,7,77,17,80,20,89,11" HREF="index.cgi?query=u">
<AREA SHAPE=POLY COORDS="89,11,80,20,85,25,96,17" HREF="index.cgi?query=v">
<AREA SHAPE=POLY COORDS="96,17,84,25,92,33,101,23" HREF="index.cgi?query=z">
<AREA SHAPE=POLY COORDS="101,23,92,33,97,39,106,29" HREF="index.cgi?query=z2">
<AREA SHAPE=POLY COORDS="106,29,97,39,100,44,110,35" HREF="index.cgi?query=z">
<AREA SHAPE=POLY COORDS="100,44,110,36,118,51,110,59" HREF="index.cgi?query=z3">
<AREA SHAPE=POLY COORDS="109,59,118,51,123,65,116,71" HREF="index.cgi?query=z4">
<AREA SHAPE=POLY COORDS="123,65,116,71,117,79,123,79" HREF="index.cgi?query=z5">
<AREA SHAPE=POLY COORDS="117,79,122,80,123,88,119,90" HREF="index.cgi?query=z6">
<AREA SHAPE=POLY COORDS="120,90,123,88,127,91,124,94" HREF="index.cgi?query=z7">
<AREA SHAPE=POLY COORDS="126,91,139,95,133,97,125,93" HREF="index.cgi?query=z8">
</MAP>');

print ('
</center>  
</td>  
</tr>  
</table>  
</div>  
<!-- here finish the small worm map -->');

print ('
<div id="Layer7" style="position:absolute; width:149px; height:22px; z-index:8; left: 536px; top: 454px"> 
<table BORDER CELLSPACING=0 CELLPADDING=4 COLS=1 WIDTH="148" height="50" BGCOLOR="#FFFFCC">  
<tr><td valign="center">
');
if ($banner eq "no"){
  $name =~ s/\-.+$//;
  print ('<b><center><font size=-1><font color="#cc0000"><a href="index.cgi?query=');
  print $name;
  print ('">[Click here to zoom out]</font></b></a></font></center>');
}else{
  print ('<center><font size=-1><font color="#cc0000"><font size=-1><b>[Click on the picture to zoom more]</b></font></center>')};

print ('
</tr></td></table></div>
<div id="Layer6" style="position:absolute; width:661px; height:26px; z-index:6; left: 24px; top: 626px">   
<img SRC="foot_logo2.gif">');

print ' 
</div>
', end_html;

exit 0;

}

print header,
start_html('-Title' =>'WormBase - Home Page',
	   '-bgcolor'=>'white'),

('
<IMG SRC="logo_d.gif" USEMAP="#logo_d.gif" border=0>  
<MAP NAME="logo_d.gif">  
<AREA SHAPE=POLY COORDS="3,0,3,20,109,20,109,0" HREF="../simple.cgi" alt="Basic Searches" >  
<AREA SHAPE=POLY COORDS="114,0,114,21,262,21,262,0" HREF="../expre_search.cgi" alt="Expression Patten Searches">  
<AREA SHAPE=POLY COORDS="265,0,265,22,366,22,366,0" HREF="../search.cgi" alt="Class Browser">  
<AREA SHAPE=POLY COORDS="371,0,371,21,464,21,465,0" HREF=".././blast.html" alt="BLAST Searches">  
<AREA SHAPE=POLY COORDS="588,21,588,0,467,0,467,21" HREF=".././advanced.cgi" alt="Advanced Searches">  
<AREA SHAPE=POLY COORDS="593,0,593,20,638,20,638,0" HREF="../atlas.html" alt="Atlas">  
<AREA SHAPE=POLY COORDS="641,21,659,22,659,77,641,77" HREF="../index.cgi" alt="Home">
</MAP> 
<br>
<br>
<br>  
<table COLS=1 WIDTH="660" >  
<tr>  
<td>
<center>
<img SRC="pageNotFound.gif"></center>
<br>
<br>
<center>This site is under active construction.
<br> 
If a URL is not found, please try back in a few days. I am very sorry for the inconvenience. 
<br>
please contact <a href="mailto:mangone@cshl.org">mangone@cshl.org</a> and referrer <b>"query=');

print $query;

 print ('
"</b></center>
</tr>
</td>
</table>
'),
    end_html;

#    $smtp = Net::SMTP->new ('mailhost.cshl.org');
#    $smtp->mail("mangone\@cshl.org");
#    $smtp->to("mangone\@cshl.org");
#    $smtp->data("error from the Worm db; query=$query");
#    $smtp->datasend();
#    $smtp->quit;


exit 0;











