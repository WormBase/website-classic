#!/opt/bin/perl -w

# Genome Hunter, hunter.cgi  by Marco Mangone (Mang1)
# This program require the following parameter: start. end, chromosome, more

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start ---> start position
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# end -----> end position
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# chromosome-->chromosome number in this format:
#         Chromosome_x (where x is I II III IV X)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# more--->specify which query to run; could be:
# 
#         yes---> (additional info + picture)  
#         both--> (both)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# this program needs make_pic.cgi in the same directory

use strict;
use lib '../lib';
use vars '$results';
use URI::Escape;
use CGI qw/:standard :html3 Map area escape *dl *blockquote/;
use CGI::Carp qw/fatalsToBrowser/;
use Ace 1.5;
use Ace::Sequence;
use ElegansSubs qw(:DEFAULT FindPosition);
use Ace::Browser::GeneSubs;
use Ace::Browser::SearchSubs;
use Ace::Browser::AceSubs;

#collects parameters for Genome Hunter
my $start = param('start'); #start position
my $end = param ('end');   #end position
my $chromosome = param ('chromosome'); #chromosome number
my $more = param ('more') || 'yes'; #more informations
my $name = param ('name'); # name of the locus
my $zoom = param ('zoom'); # zoom available
my $gff  = param ('gff');  #request of gff table
my $format =param ('format'); #request to save in a particolar format
my $save =param ('save'); #save parameter
my $x100 =param ('plus'); #zoomx100
my $obj;

my $num1=@_;
my $num2=@_;
my $length;
my $flag;

if (defined(param('plus'))){
  $start = $start+100;
  $end =  $end+100;
}

if (defined(param('submit'))){
  if (param('submit') =~/zoom/i and defined($zoom)) {
    $zoom =~ /(\d+)\-(\d+)/;
    $start = $1;
    $end = $2;
    param('start' => $start);
    param('end'   => $end);
  }
}
# start Ace
my $DB = OpenDatabase() || AceError("Couldn't open database.");
$DB->class('Ace::Object::Wormbase');

if (defined($name)){
  ($start,$end,$length,$chromosome,$obj) = Fetch_name($name,$DB);
}

if(defined($start)){
  $length = ($end-$start)+1;
}

#welcome page
if (!defined($start)) {
  Welcome_page();
  exit;
}

#if (!defined($more)) {
#  Welcome_page();
#  exit;
#}

if (defined($gff)){
  
  print header(
	       -type=>'application/octet-stream',
	       -Content_disposition=>'attachment; filename="gff.txt"',
               -Content_length=>length($gff));
  
  
  my $seq1 = Ace::Sequence->new(-seq=>$chromosome,
				-db=>$DB,
				-offset=>$start-1,
				-length=>$length);
  print $seq1->gff;
  exit;
}

#partono gli estrattori sequenzici
$results = Ace::Sequence->new(-seq=>$chromosome,
			      -db=>$DB,
			      -offset=>$start-1,
			      -length=>$length);

my  $x = $results->dna(1);

my $features = $results->feature_list;
my @genes =$results->features('Sequence:curated');

do_save($save,$start,$end,$chromosome,$x) if defined($save) && param('save') eq 'yes';

#start web page
PrintTop($obj,param('class'),'Genome Hunter');

my  $totale=@genes;
# left arrow pic
my $left_start=undef;
$left_start=$start-1000;
my $left_end=undef;
$left_end=$end-1000;
# right arrow pic
my $right_start=undef;
$right_start=$start+1000;
my $right_end=undef;
$right_end=$end+1000;


#choose which subroutines
if ($more eq "no"){
  Seq($chromosome,$start,$end,$x);
}elsif ($more eq "yes"){
  More_sub($DB,$chromosome,$start,$end,$totale,$left_end,$right_end,$left_start,$right_start,@genes);
}elsif ($more eq "both"){
  More_sub($DB,$chromosome,$start,$end,$totale,$left_end,$right_end,$left_start,$right_start);
  Seq($chromosome,$start,$end,$x);
}


#print footer and stop web page
PrintBottom;
#down here starts the subroutines

exit;

#################################################################################

sub Seq {
  my ($chromosome,$start,$end,$x) = @_;
  
  if (!defined(param('format'))){
    print ('<table width="670"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>>nx | xxxx | ');
    print $chromosome,' C.elegans partial sequence from # ',$start,' to ',$end,br;
    
    my @x = split //,$x;
    my $newline=0;
    my $count;
    my $length = ($end-$start)+1;
    for ($count=0; $count<=$length; $count++){
      $newline++;
      if ($newline==81){
	$newline=0;
	print br;
      }else{
	if  ($x[$count]=~ m/a/){$x[$count]='A'};
	if  ($x[$count]=~ m/t/){$x[$count]='T'}; 
	if  ($x[$count]=~ m/c/){$x[$count]='C'};
	if  ($x[$count]=~ m/g/){$x[$count]='G'};
	$x[$count]=~s/s+//g;
	print $x[$count];
      }
    }
    print ('</pre></td></tr></table>');
  }
  if (param ('format') eq "fasta"){
   File_fasta($start,$end,$chromosome,$x);
  }
  
  if (param ('format') eq "stanford"){
    File_stanford($start,$end,$chromosome,$x);
  }
  
  if (param ('format') eq "genbank"){
    File_genbank($start,$end,$chromosome,$x);
  }
  
   if (param ('format') eq "nbrf"){
     File_nbrf($start,$end,$chromosome,$x);
   }
  
  if (param ('format') eq "embl"){
    File_embl($start,$end,$chromosome,$x);
  }
  
  if (param ('format') eq "gcg"){
    File_embl($start,$end,$chromosome,$x);
  }
  
  if (param ('format') eq "strider"){
    File_strider($start,$end,$chromosome,$x);
  }
  
  if (param ('format') eq "fitch"){
    File_fitch($start,$end,$chromosome,$x);
  }
  
   if (param ('format') eq "phylip32"){
     File_phylip32($start,$end,$chromosome,$x);
   }
  
  if (param ('format') eq "phylip"){
    File_phylip($start,$end,$chromosome,$x);
  }
  
  if (param ('format') eq "plain"){
    File_plain($start,$end,$chromosome,$x);
  }
  
  if (param ('format') eq "codata"){
    File_codata($start,$end,$chromosome,$x);
  }
  
  if (param ('format') eq "msf"){
    File_msf($start,$end,$chromosome,$x);
  }
  
  if (param ('format') eq "asn"){
    File_asn($start,$end,$chromosome,$x);
  }
  
  if (param ('format') eq "nexus"){
    File_nexus($start,$end,$chromosome,$x);
  }
  
  print ('</pre></td></tr></table>');
  return;
}

###############################################################################
sub More_sub {
  
  my ($DB,$chromosome,$start,$end,$totale,$left_end,$right_end,$left_start,$right_start,@genes) = @_; 
  my $sopra=0;
  my @mapping;
  print 'Found ', b($totale),' genes in this partial sequence.',br;
  print 'Use the clickable map to browse through this region on ',
  b($chromosome),
  ', download the features of this region or use the zoom button to magnify',
  ' the region and download the sequence in various formats',br,br;

  my $pic_link='make_pic.cgi?chromosome='.$chromosome.'&start='.$start.'&end='.$end;

  print img({-src=>$pic_link,
	     -border=>'0',
	     -usemap=>'#hmap'});

  print '
<table width="670" bgcolor="#ffffcc" cellspacing=0 cellpadding=4 border>
<tr>
<th bgcolor="#fee8ba"><font size=-1>Position
<th bgcolor="#fee8ba"><font size=-1>Zoom
<th bgcolor="#fee8ba"><font size=-1>More information
<th bgcolor="#fee8ba"><font size=-1>Sequence
</th>
<tr>
<td>
<center>';
  autoEscape(0);  
  print start_form( -action=>'/perl/ace/elegans/hunter/hunter.cgi');
  print hidden(-name=>'chromosome', value=>"$chromosome");
  print hidden(-name=>'more', value=>"yes");
  print textfield(-name=>'start', -value=>$start, -size=>7),'&nbsp;',b('-'),'&nbsp;',textfield(-name=>'end', -value=>$end, -size=>7);
  print '<font size=-1>';
  print br,checkbox(-name=>'gff',-value=>'yes', label=>'Save GFF to disk'),'&nbsp;';
  print submit(-name=>'submit',value=>'Go!'),'&nbsp;','</font>';
  print '<br></center></td><td>';
  print '<font size=-1>';
  print popup_menu(
		   -name=>('zoom'),
		   -default=>"$start-$end",
		   -value=>[
			    ($start+10000).'-'.($end-10000), 
			    ($start+1000).'-'.($end-1000), 
			    ($start+100).'-'.($end-100), 
			    ($start+10).'-'.($end-10), 
			    "$start-$end",
			    ($start-10).'-'.($end+10), 
			    ($start-100).'-'.($end+100), 
			    ($start-1000).'-'.($end+1000), 
			    ($start-10000).'-'.($end+10000), 
			   ],
		   
		   -labels=>{"$start-$end"                     =>'none',
			     ($start+10).'-'.($end-10)         =>'In 10 bp',
			     ($start+100).'-'.($end-100)       =>'In 100 bp', 
			     ($start+1000).'-'.($end-1000)     =>'In 1,000 bp', 
			     ($start+10000).'-'.($end-10000)   =>'In 10,000 bp', 
			     ($start-10).'-'.($end+10)         =>'Out 10 bp',
			     ($start-100).'-'.($end+100)       =>'Out 100 bp', 
			     ($start-1000).'-'.($end+1000)     =>'Out 1,000 bp', 
			     ($start-10000).'-'.($end+10000)   =>'Out 10,000 bp',
	  
			    },
		  );
  
  print '<center>';
  print checkbox(-name=>'plus',-value=>'yes', label=>'&plusmn;100'),'&nbsp;';
  print submit(-name=>'submit',value=>'Zoom'),'&nbsp;','</font>';
  print '
</center>
</td>

<td>';
  print end_form;
  my $length = ($end-$start)+1;
  autoEscape(1);
  print "<font size=-1>Partial DNA sequence from <b>$start</b> to <b>$end</b> from <b>$chromosome</b>  (total <b>$length</b> bp)";
  print '
</td>

<td>
<font size=-1>
<center>
<form METHOD=GET ACTION="/perl/ace/elegans/hunter/hunter.cgi">  
<input type="hidden" name="start" value="',$start,'">
<input type="hidden" name="end" value="',$end,'">
<input type="hidden" name="chromosome" value="',$chromosome,'">
<input type="hidden" name="more" value="no">
<select NAME="format">  
<option VALUE="fasta">FASTA  
<option VALUE="stanford">IG/Stanford
<option VALUE="genbank">Genbank
<option VALUE="nbrf">NBRF
<option VALUE="embl">EMBL
<option VALUE="gcg">GCG
<option VALUE="strider">DNA Strider  
<option VALUE="fitch">Fitch  
<option VALUE="phylip32">Phylip 3.2
<option VALUE="phylip">Phylip
<option VALUE="plain">Plain
<option VALUE="codata">PIR/CODATA
<option VALUE="msf">MSF
<option VALUE="asn">ASN 1
<option VALUE="nexus">Paup/NEXUS
</select>
<br>
<input type="radio" name="save" value="no" checked>View
<input type="radio" name="save" value="yes">Save
<input TYPE="submit" value="Go!">  
</font>
</td>
</form>
</center>
';

  print '
</tr>
</table>';
  if ($totale>0){
    print h1('Detailed Report');
    print p('Region',b($start),'to',b($end),'relative to chromosome',b($chromosome),);
    print '
</td>
</tr>
</table>
<table width="670" bgcolor="#f4f4f4" cellspacing=0 cellpadding=4 border>
<tr>
<th bgcolor="#34ADEF"><font size=-1>#
<th bgcolor="#34ADEF"><font size=-1>Sequence
<th bgcolor="#34ADEF"><font size=-1>Position
<th bgcolor="#34ADEF"><font size=-1>Description
<th bgcolor="#34ADEF"><font size=-1>Display
</th>
</tr>';
    
    # features tables sequences are ordered here
    my %list;
    my $i;
    my $absstart = $results->start;
    for ($i=0; $i<$totale; $i++)
      { 

	my $num1 = $genes[$i]->start;
	my $num2 = $genes[$i]->end;

	#reverse the sequences errors 
	if ($num1>$num2){
	my $temp2;
	$temp2 = $num1;
	$num1 = $num2;
	$num2 = $temp2;
      }
	my $tmp = $genes[$i]->info;
	$tmp =~ /\.(\d+)$/;
	my $tmp2 = $1;
	$list{$tmp}->{val} = $tmp2;
	$list{$tmp}->{num} = [];
	push(@{$list{$tmp}->{num}},$num1);
	push(@{$list{$tmp}->{num}},$num2);
      }
    my @kys = keys %list;
    @kys = sort{$list{$a}->{num}->[0] <=> $list{$b}->{num}->[0]} @kys;
    $a=0;
    foreach(@kys){
      my $start_position;
      my $end_position;
      my $acc = $_;
      my $num1 = $list{$acc}->{num}->[0];
      my $num2 = $list{$acc}->{num}->[1];
      $a++;
      
      #ask for orientation of the clone 
      my $values = $DB->fetch(-class=>'Sequence',
			      -name=>$acc);
      my $remark= $values->get('Brief_identification'=>1);     
      my $seq = Ace::Sequence->new(-class=>'Sequence',
				   -db=>$DB,
				   -seq=>$acc);
      my @homol = $seq->features('similarity');
      my $feature = $homol[0];
      
      if (defined($feature)){
	my $strand = $feature->strand(1);
      }
      if ($start>$end){
	my $temp1;
	$temp1 = $start;
	$start = $end;
	$end = $temp1;
      }
    
    my  $start_position1 = (($num1-$absstart)*658)/$length;
    my  $end_position1   = (($num2-$absstart)*658)/$length;
    
    if ($start_position1<=0){
      $start_position=0;
    }
    if ($start_position1>0){
      $start_position=($start_position1);
    }
    if ($end_position1<613){
      $end_position=$end_position1;
    }
    if ($end_position1>=613){
      $end_position=613;
    }
    # verify same line in a range of 4 pixels
    #my $sopra=0;
    if (($sopra>$start_position-4)||($sopra>$end_position+4)){
      $i=$i+10;
      $sopra = $end_position;
    }else{
	$sopra = $end_position;
      }
      my  $aaa=$start_position+15;
      my  $bbb=$end_position+40;
      my  $vario=60-$i;
      my  $map_position = "$aaa,$vario,$bbb,65";
      my  $ex1=$num1+$start;
      my  $ex2=$num2+$start;
      my $link="hunter.cgi?chromosome=".$chromosome."&start=".$ex1."&end=".$ex2."&more=yes"; 
    if (!defined($remark)){
      $remark = "Predicted coding region";
    }  
    push (@mapping,area({-shape=>'rect',
			 -coords=>$map_position,
			 -href=>$link,
			 -alt=>"Go to $remark"}),
	 );
    
    ############################     
#      warn "$acc: num1=$num1, num2=$num2, start=$start"; 
    
    print '
<tr>
<td><form method=get action="hunter.cgi">',font({-size=>"-1"},$a),'
<input TYPE="hidden" NAME="chromosome" value="',$chromosome,'"> 
<input TYPE="hidden" NAME="more"  value="yes">
</td>
<td>
<a href="/perl/ace/elegans/seq/sequence?name=',$acc,'">',font({-size=>"-1"},$acc),'</a>
</td>
<td>
<center>
<input TYPE="text" NAME="start" size="7" value="',$num1+$start,'">-<input TYPE="text" NAME="end" size="7" value="',$num2+$start,'"><font size=-1>';
    print br,checkbox(-name=>'gff',-value=>'yes', label=>'Save GFF to disk'),'&nbsp;';
    print'
<input TYPE="submit" value="Go!">
</center>
</td>
</form>
<td>';
  if  (defined($remark)){
    print font({-size=>"-1"},$remark,'(', b(($num2)-($num1)," bp"),")");	
  }else{
    print font({-size=>"-1"},('predicted coding region','(', b(($num2)-($num1)," bp"),')'));
  }
  print ' </td>
<td>
<center>
<font size=-1>
<form METHOD=GET ACTION="/perl/ace/elegans/hunter/hunter.cgi">  
<input type="hidden" name="start" value="',$num1+$start,'">
<input type="hidden" name="end" value="',$num2+$start,'">
<input type="hidden" name="chromosome" value="',$chromosome,'">
<input type="hidden" name="more" value="no">
<select NAME="format">  
<option VALUE="fasta">FASTA 
<option VALUE="stanford">IG/Stanford
<option VALUE="genbank">Genbank
<option VALUE="nbrf">NBRF
<option VALUE="embl">EMBL
<option VALUE="gcg">GCG
<option VALUE="strider">DNA Strider  
<option VALUE="fitch">Fitch  
<option VALUE="phylip32">Phylip 3.2
<option VALUE="phylip">Phylip
<option VALUE="plain">Plain
<option VALUE="codata">PIR/CODATA
<option VALUE="msf">MSF
<option VALUE="asn">ASN 1
<option VALUE="nexus">Paup/NEXUS
</select><br>  
<input type="radio" name="save" value="no" checked>View
<input type="radio" name="save" value="yes">Save
<input TYPE="submit" value="Go!">  
</font>  
</td>
</form>
</center>'
}
    print ('</tr></table><br>');
    # left arrow pic
    my  $left_URL = "hunter.cgi?chromosome=$chromosome&more=yes&start=$left_start&end=$left_end";
  #  print $left_URL,br;
    push (@mapping,area({-shape=>'rect',
			 -coords=>'2,1,22,14',
			 -href=>$left_URL,
			 -alt=>$left_start."-".$left_end}),
	 );

    # right arrow pic
    my $right_URL = "hunter.cgi?chromosome=$chromosome&more=yes&start=$right_start&end=$right_end";
  #  print $right_URL,br;
    push (@mapping,area({-shape=>'rect',
			 -coords=>'635,2,655,16',
			 -href=>$right_URL,
			 -alt=>$right_start."-".$right_end}),
	 ); 
  }
  print Map({-name=>'hmap'},@mapping);
  return;
}

###############################################################################
sub Welcome_page{

  #start web page
  PrintTop($obj,param('name'),'Genome Hunter Search');

  DisplayInstructions('',
		       'Genome Hunter allows you to browse segments of the <i>C. elegans</i> genome ' .
		       'and to extract sequence and annotations in a variety of formats.',
		       'You may search for locus names such as <i>cel-1</i>, or genomic segments such as <i>B0545</i>.',
		       'Due to technical limitations, please request segments in units of 200 Kb or less.',
		       'The next version of Genome Hunter will include the start and end positions of clones.'
		      );
  print '<br clear=all>';
  display_search_form_hunter(); 
  
  PrintBottom();
  
  return;
  
}


###############################################################################
sub display_search_form_hunter{
  
  autoEscape(0);
  
  AceSearchTable_hunter('Genome Hunter: Gene Extraction',
			font ({size=>'-1'},b('Locus or Sequence name: (ie. cel-1) ')),
			textfield(-name=>'name',-size=>18),
			submit(-action=>'/perl/ace/elegans/hunter/hunter.cgi',
			       -label=>'Search'),
			br,
			radio_group(-name=>'more',
				    -value=>['no','yes','both'],
				    -default=>'yes',
				    -labels=>{
					      no=>font ({size=>'-1', -color=>'#000000'},b('DNA (FASTA Format)&nbsp;&nbsp;&nbsp;&nbsp')),
					      yes=>font ({size=>'-1',-color=>'#000000'},b('Annotations&nbsp;&nbsp;&nbsp;&nbsp')),
					      both=>font ({size=>'-1',-color=>'#000000'},b('DNA (FASTA Format) + Annotations&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'))}),
		       ),
  autoEscape(1);
  return;
}

###############################################################################
sub AceSearchTable_hunter {
  my ($title,@body) = @_;
  print
    start_form (-action=>'/perl/ace/elegans/hunter/hunter.cgi'),
    a({-name=>'search'}),
    table({-border=>1,-cellspacing=>0,-cellpadding=>4,-width=>'100%'},
	  TR(th({-class=>'searchtitle'},$title),
	     TR({-align=>'center'},
		td({-class=>'searchbody'},@body)))),
    end_form;
  return;
}


###############################################################################
sub Fetch_name {
  
  my ($name,$DB)=@_;
  
  my $results2 = $DB->fetch(-class => 'Locus',
			    -name  => $name);

  if (defined($results2)){
    $name = $results2->Sequence;
  } elsif ($results2 = $DB->fetch(-class => 'Sequence', -name  => $name)) {
    $name = $results2;
  } else {
    Error();
  }
  unless ($name) {
    Error('Sorry.  This genetic locus has not been mapped to genomic sequence coordinates.');
  }

  my ($start,$end,$reference) = FindPosition($DB,$name);

  my  $chromosome = $reference;
  if ($start>$end){
    my $temp1;
    $temp1 = $start;
    $start = $end;
    $end = $temp1;
  }
  my $length = ($end-$start)+1;
  return ($start,$end,$length,$chromosome,$name);
}

###############################################################################

sub Error{
  my $msg = shift;
  # this check that $end is not bigger than $start  
  PrintTop($obj,param('name'),param('name'));  
  $msg ||= 'Not Found.',br,br,b('NB: it is not possible to visualize sequences bigger than 200 Kb');
  print p($msg);
  Delete('name');
  print a({-href=>self_url()},'Search again');
  PrintBottom;
  end_html;
  exit 0;
}


sub No_results{
  my ($chromosome,$start,$end)=(shift,shift,shift);
  
  print header(-title=>'hunter'),
  
  PrintTop(undef,undef,'Genome Hunter Error');  
  
  my @Chromosome_number = split /_/,$chromosome;
  
  if ($Chromosome_number[0] == 'I'){
    print (' sorry, the Chromosome 1 has only <b>13,467,562</b> bp ');
  }
  elsif ($Chromosome_number[0] == 'II'){
    print (' sorry, the Chromosome 1 has only <b>15,116,321</b> bp ');
  }
  elsif ($Chromosome_number[0] == 'III'){
    print (' sorry, the Chromosome 1 has only <b>12,476,799</b> bp ');
  }
  elsif ($Chromosome_number[0] == 'IV'){
    print (' sorry, the Chromosome 1 has only <b>15,919,001</b> bp ');
  }
  elsif ($Chromosome_number[0] == 'V'){
    print (' sorry, the Chromosome 1 has only <b>20,666,302</b> bp ');
  }
  elsif ($Chromosome_number[0] == 'X'){
    print (' sorry, the Chromosome 1 has only <b>17,432,311</b> bp ');
  }
  print  'and I cannot extract from position <b>',$start,'</b> to <b>',$end,'</b>';
  PrintBottom;
  end_html;
  exit 0;
}

###############################################################################
###############################################################################


sub File_fasta {
  
  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file;
  if(!defined($flag)){
    print 'The following is the C.elegans partial sequence in FASTA format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
    
    print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
    print '>nx | xxxx | ';
    print $chromosome,' C.elegans partial sequence from # ',$start, ' to ' ,$end, br;
  }else{
    push (@file,">nx | xxxx |");
    push (@file,$chromosome);
    push (@file," C.elegans partial sequence from # ");
    push (@file,$start);
    push (@file," to ");
    push (@file,$end);
    push (@file,"\n");
  }
  $x =~ tr/a-z/A-Z/;
  $x =~ s/\s+//;
  $x =~ s/(.{1,50})/$1\n/g;
  push @file,$x;
  print @file,"\n";
  return;
}

##########################################################
sub File_stanford{
  
  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file;
  if(!defined($flag)){
    print 'The following is the C.elegans partial sequence in IG/Stanford format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
    
    print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
    
    print ';nx | xxxx | ';
    print $chromosome,' C.elegans partial sequence from # ',$start, ' to ' ,$end, br;
  }
  push (@file,';nx | xxxx | ');
  push (@file,$chromosome);
  push (@file,' C.elegans partial sequence from # ');
  push (@file,$start);
  push (@file,' to ');
  push (@file,$end);
  push (@file,"\n");
  $x =~ tr/a-z/A-Z/;
  $x =~ s/\s+//;
  $x =~ s/(.{1,50})/$1\n/g;
  push @file,$x;
  print @file,"\n";
  return;
}


sub File_genbank{
 
  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my $newline=0;
  my @file;
  my $newspace=0;
  my $count;
  
  if(!defined($flag)){
    print 'The following is the C.elegans partial sequence in Genbank format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
    
    print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
    
    print 'LOCUS       nx       ',$end-$start,br;
    print 'DEFINITION  nx | XXXX | $chromosome C.elegans partial sequence from # ',$start, ' to ' ,$end, br;
    print 'ORIGIN',br,'       1  ',;
  }else{
    push (@file,"LOCUS       nx       ");
    push (@file,$end-$start);
    push (@file,"\n");
    push (@file,"DEFINITION  nx | xxxx |");
    push (@file,$chromosome);
    push (@file," C.elegans partial sequence from # ");
    push (@file,$start);
    push (@file," to ");
    push (@file,$end);
    push (@file,"\n");
    push (@file,"ORIGIN\n");
    push (@file,"       1  ");
  }

  # IMPORTANT NOTE: THIS IS PROBABLY GENERATING INCORRECT DATA!!!!!!!!!!
  my @x = split //,$x;
  for ($count=0; $count<@x; $count++){
    if ($newline==50){
      $newline=0;
      if(!defined($flag)){
	print br;
      }else{push(@file,"\n")};
      my $loc_cnt = $count;$loc_cnt++;
      my $l=""; my $xx = $loc_cnt;  while($xx <10000000){ $l .=" "; $xx *= 10;}
      if(!defined($flag)){
	print $l.$loc_cnt,'&nbsp;&nbsp;';
      }else{push(@file,$l.$loc_cnt."  ")}
    } 
    $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
    if(!defined($flag)){
      if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ print '&nbsp;'; }
      print $x[$count];
    }else{
      if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ push (@file," "); }
      push(@file,$x[$count])
    };
    $newline++;
  }
print @file;
return;
}

sub File_nbrf{

  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift,shift);
  my @file;
  if(!defined($flag)){
 print 'The following is the C.elegans partial sequence in NBRF format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
    
    print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
  print '>DL;nx',br;
  print 'nx | xxxx | $chromosome C.elegans partial sequence from # ',$start, ' to ' ,$end, br,'&nbsp;';
}else{

  push (@file,">DL;nx\n");
  push (@file,"nx | xxxx |");
  push (@file,$chromosome);
  push (@file," C.elegans partial sequence from # ");
  push (@file,$start);
  push (@file," to ");
  push (@file,$end);
  push (@file,"\n ");
  
}
  # IMPORTANT NOTE: THIS IS PROBABLY GENERATING INCORRECT DATA!!!!!!!!!!
  my  @x = split //,$x;
  my $newline=0;
  my $newspace=0;
  my $count;

  for ($count=0; $count<@x; $count++){
    if ($newline==50){
      $newline=0;
      if(!defined($flag)){
	print br,'&nbsp;';
      }else {push (@file,"\n");
	     push (@file," ")};
      my $loc_cnt = $count;$loc_cnt++;
    } 
    $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
    if(!defined($flag)){
      if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ print '&nbsp;'; }
      print $x[$count];
    }else{
      if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ push (@file," ");}
      push (@file,$x[$count]);
    }
    $newline++;
  }
  if($newline!=1) { 
    if(!defined($flag)){
      print br,'//';
    }else{push (@file,"\n");
	  push (@file,"//");
	}
  } else { 
    if(!defined($flag)){
      print '//';
    }else{push (@file, "//");
	};
  }
 print @file;
  return;
}

sub File_embl{

  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file;
  if(!defined($flag)){
  print 'The following is the C.elegans partial sequence in EMBL format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
  
  print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
  
  print 'ID   nx',br;
  print 'DE   nx | xxxx | $chromosome C.elegans partial sequence from # ',$start, ' to ' ,$end, br;
  print 'SQ            ',$end-$start,' bp',br,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
}else{

  push (@file,"ID   nx\n");
  push (@file,"DE   nx | xxxx |");
  push (@file,$chromosome);
  push (@file," C.elegans partial sequence from # ");
  push (@file,$start);
  push (@file," to ");
  push (@file,$end);
  push (@file,"\n ");
  push (@file,"SQ            ");
  push (@file,$end-$start);
  push (@file," bp\n");
  push (@file,"     ");

}
  # IMPORTANT NOTE: THIS IS PROBABLY GENERATING INCORRECT DATA!!!!!!!!!!
  my  @x = split //,$x;
  my  $newline=0;
  my  $newspace=0;
  my $count;  
  for ($count=0; $count<@x; $count++){
    if ($newline==50){
      $newline=0;
   if(!defined($flag)){
     print br,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
   }else {push(@file,"\n");
	  push(@file,"     ");
	}
      my $loc_cnt = $count;$loc_cnt++;
    } 
    $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
  if(!defined($flag)){
    if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ print '&nbsp;'; }
    print $x[$count];
  }else{
  if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ push (@file," "); }
    push (@file, $x[$count]);
}
    $newline++;
  }

  if($newline!=1) { 
    if(!defined($flag)){
      print br,'//';
    }else{push (@file,"\n");
	  push (@file,"//");
	}
  } else { 
    if(!defined($flag)){
      print '//';
    }else{push (@file,"//")};
  }
 print @file;
  return;
}



sub File_gcg {

  my ($start,$end,$chromosome,$x)=(shift,shift,shift,shift,shift);
  my @file;
  

  print 'The following is the C.elegans partial sequence in GCG format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
  
  print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
  
  print 'nx | xxxx | $chromosome C.elegans partial sequence from # ',$start, ' to ' ,$end, br;
  print '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;nx  Length: ',$end-$start,'&nbsp;&nbsp;(today) Check: 8038 ..',br;
  print '            1  ',;

  # IMPORTANT NOTE: THIS IS PROBABLY GENERATING INCORRECT DATA!!!!!!!!!!
  my @x = split //,$x;
  my  $newline=0;
  my $newspace=0;
  my $count;
  for ($count=0; $count<@x; $count++){
    if ($newline==50){
      $newline=0;
      print br,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
      my $loc_cnt = $count;$loc_cnt++;
      my $l=""; my $xx = $loc_cnt;  while($xx <10000000){ $l .=" "; $xx *= 10;}
      
      print $l.$loc_cnt,'&nbsp;&nbsp;';
    } 
    $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
    if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ print '&nbsp;'; }
    print $x[$count];
    $newline++;
  }
  if($newline!=1) { 
    print br,'//';
  } else { 
    print '//';
  }
 print @file;
  return;
}



sub File_strider{

  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file;
  if(!defined($flag)){

  print 'The following is the C.elegans partial sequence in Strider format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
  
  print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
  
  print '; ### from DNA Strider ;-)',br;
  print '; DNA sequence nx | xxxx | $chromosome, C.elegans partial sequence from  ',$start, ' to ' ,$end, br;
  print ';',br;
}else{

  push (@file,"; ### from DNA Strider ;-)\n");
  push (@file,"DNA sequence nx | xxxx |");
  push (@file,$chromosome);
  push (@file," C.elegans partial sequence from # ");
  push (@file,$start);
  push (@file," to ");
  push (@file,$end);
  push (@file,"\n");
  push (@file,";\n");
}
  # IMPORTANT NOTE: THIS IS PROBABLY GENERATING INCORRECT DATA!!!!!!!!!!
  my  @x = split //,$x;
  my  $newline=0;
  my $count;
  for ($count=0; $count<@x; $count++){
    $newline++;
    if ($newline==50){
      $newline=0;
  if(!defined($flag)){
      print br;
    }else{push (@file,"\n")};
    }else{
      $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
  if(!defined($flag)){
      print $x[$count];
    }else{push(@file, $x[$count]);
	}
    }
  }
  if(!defined($flag)){
  print br,"//";
}else{push (@file,"\n//")};
 print @file;
  return;
}

sub File_fitch{

  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file;  
  if(!defined($flag)){
    print 'The following is the C.elegans partial sequence in Fitch format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
    
    print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
    print 'nx | xxxx | $chromosome C.elegans partial sequence from # ',$start, ' to ' ,$end, br,'&nbsp;';
  }else{
    
    push (@file,"nx | xxxx |");
    push (@file,$chromosome);
    push (@file," C.elegans partial sequence from # ");
    push (@file,$start);
    push (@file," to ");
    push (@file,$end);
    push (@file,"\n ");
}

  # IMPORTANT NOTE: THIS IS PROBABLY GENERATING INCORRECT DATA!!!!!!!!!!
  my  @x = split //,$x;
  my  $newline=0;
  my  $newspace=0;
  my $count;  
  for ($count=0; $count<@x; $count++){
    if ($newline==60){
      $newline=0;
      if(!defined($flag)){
	print br,'&nbsp;';
      }else{
	push (@file,"\n ")};
      my $loc_cnt = $count;$loc_cnt++;
    } 
    $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
    if(!defined($flag)){
      if (($newline==3)||($newline==6)||($newline==9)||($newline==12)||($newline==15)||($newline==18)||($newline==21)||($newline==24)||($newline==27)||($newline==30)||($newline==33)||($newline==36)||($newline==39)||($newline==42)||($newline==45)||($newline==48)||($newline==51)||($newline==54)||($newline==57)||($newline==60)){ print '&nbsp;'; }
      print $x[$count];
    }else{
      if (($newline==3)||($newline==6)||($newline==9)||($newline==12)||($newline==15)||($newline==18)||($newline==21)||($newline==24)||($newline==27)||($newline==30)||($newline==33)||($newline==36)||($newline==39)||($newline==42)||($newline==45)||($newline==48)||($newline==51)||($newline==54)||($newline==57)||($newline==60)){ push (@file," ")};
      push (@file,$x[$count]);
      
    }
    $newline++;
  }
 print @file;
  return;
}


sub File_phylip32{

  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file;
   if(!defined($flag)){
  print 'The following is the C.elegans partial sequence in Phylip 32 format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
  
  print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
  
  print $end-$start,' YF',br;
  print 'nx           ';
}else{
  push (@file,$end-$start);
  push (@file," YF\n");
  push (@file,"nx           ");
}
  # IMPORTANT NOTE: THIS IS PROBABLY GENERATING INCORRECT DATA!!!!!!!!!!
  my @x = split //,$x;
  my $newline=0;
  my $newspace=0;
  my $count;
  for ($count=0; $count<@x; $count++){
    if ($newline==50){
      $newline=0;
      if(!defined($flag)){
	print br,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
      }else {push (@file,"\n             ")};
      my $loc_cnt = $count;$loc_cnt++;
    } 
    $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
    if(!defined($flag)){
      if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ print '&nbsp;'; }
      print $x[$count];
    }else{
      if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ push(@file," ")}
      push (@file, $x[$count]);
    }
    $newline++;
  }
 print @file;
  return;
}

sub File_phylip{
  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file;
    if(!defined($flag)){
  print 'The following is the C.elegans partial sequence in Phylip format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
  
  print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
 
  print '1 ',$end-$start,br;
  print 'nx           ';
  
}else{
  push (@file, "1 ");
  push (@file,$end-$start);
  push (@file,"\n");
  push (@file, "nx           ");
}
  # IMPORTANT NOTE: THIS IS PROBABLY GENERATING INCORRECT DATA!!!!!!!!!!
  my  @x = split //,$x;
  my  $newline=0;
  my  $newspace=0;
  my  $count;
  for ($count=0; $count<@x; $count++){
    if ($newline==50){
      $newline=0;
      if(!defined($flag)){
     print br,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
      my $loc_cnt = $count;$loc_cnt++;
      print br,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
    }else{
      push(@file,"\n             ");
      my $loc_cnt = $count;$loc_cnt++;
      push(@file,"\n             ");
    }
      
    } 
    $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
    if(!defined($flag)){
      if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ print '&nbsp;'; }
      print $x[$count];
    }else{
      if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ push (@file," "); }
      push (@file, $x[$count]);
    }
    $newline++;
  }
 print @file;
  return;
}

sub File_plain{
  
  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file;
  if(!defined($flag)){
    print 'The following is the C.elegans partial sequence in Plain format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
    
    print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
  }
  my @x = split //,$x;
  my $newline=0;
  my $count;
  for ($count=0; $count<@x; $count++){
    $newline++;
    if ($newline==81){
      $newline=0;
      if(!defined($flag)){
	print br;
      }else{
	push (@file,"\n");
      }
    }else{
      $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
      if(!defined($flag)){
	print $x[$count];
      }else{push(@file,$x[$count])};
    }
  }
 print @file;
  return;
}


sub File_codata{

  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file;
    if(!defined($flag)){
  print 'The following is the C.elegans partial sequence in PIR/CODATA format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
  
  print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
  
  print '\\\\\\',br;
  print 'ENTRY               nx',br;
  print 'TITLE               nx | XXXX | $chromosome C.elegans partial sequence from # ',$start, ' to ' ,$end, br;
  print 'SEQUENCE',br;
  print '                  5         10        15        20        25        30  ',br;
  print '       1  ';  
}else{
  push (@file,"\\\\\\\n");
  push (@file,"ENTRY               nx\n");
  push (@file,"TITLE               nx | xxxx |");
  push (@file,$chromosome);
  push (@file," C.elegans partial sequence from # ");
  push (@file,$start);
  push (@file," to ");
  push (@file,$end);
  push (@file,"\n ");
  push (@file,"SEQUENCE\n");
  push (@file,"                  5         10        15        20        25        30  \n");
  push (@file,"       1  ");
}
  # IMPORTANT NOTE: THIS IS PROBABLY GENERATING INCORRECT DATA!!!!!!!!!!
  my @x = split //,$x;
  my $newline=0;
  my $newspace=0;
  my $count;  
  for ($count=0; $count<@x; $count++){
    if ($newline==31){
      $newline=0;
      if(!defined($flag)){
	print br;
      }else{push (@file,"\n")};
      my $loc_cnt = $count;$loc_cnt++;
      my $l=""; my $xx = $loc_cnt;  while($xx <10000000){ $l .=" "; $xx *= 10;}
      if(!defined($flag)){
	print $l.$loc_cnt,'&nbsp;&nbsp;';
      }else{push (@file,$l.$loc_cnt);
	    push (@file,"  ");
	  }
    } 
    $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
    if(!defined($flag)){
      print $x[$count],'&nbsp;';
    }else{
      my @file;
      push (@file,$x[$count]);
      push (@file," ");
    }
    $newline++;
  }
  if($newline!=1) { 
 if(!defined($flag)){
    print br,'///';
  }else{push (@file,"///")};
  } else { 
  if($newline!=1) { 
    print '///';
  }else{
push (@file,"///");
}
  }
 print @file;
  return;
}


sub File_msf{

  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file;
   if(!defined($flag)){
  print 'The following is the C.elegans partial sequence in MSF format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
  
  print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
  
  print '/urs/tmp/aaaa24944  MSF: ',$end-$start,' Type:N January 01, 1776  12:00',br;
  print br,'&nbsp;',br;
  print 'Name: nx        len:  ',$end-$start,'  Check:    8038  Weight:  1.00',br,'&nbsp;',br;
  print '      nx  ';  
}else{
  push (@file,"/urs/tmp/aaaa24944  MSF: ");
  push (@file,$end-$start);
  push (@file," Type:N January 01, 1776  12:00\n\n");
  push (@file,"Name: nx        len:  ");
  push (@file,$end-$start);
  push (@file,"  Check:    8038  Weight:  1.00\n\n");
  push (@file,"      nx  ");

}
  # IMPORTANT NOTE: THIS IS PROBABLY GENERATING INCORRECT DATA!!!!!!!!!!
  my  @x = split //,$x;
  my $newline=0;
  my $newspace=0;
  my $count;
  for ($count=0; $count<@x; $count++){
   if ($newline==51){
     $newline=0;
     if(!defined($flag)){
       print br;
       print '&nbsp;';
       print br;
       print '      nx  ';
     }else{
       push (@file,"\n\n      nx  ")};  
   } 
   $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
 if(!defined($flag)){
   if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ print '&nbsp;'; }
   print $x[$count];
 }else{
  if (($newline==10)||($newline==20)||($newline==30)||($newline==40)){ push (@file," ");
								     }
   push (@file, $x[$count]);
}

   $newline++;  
 }
  if($newline!=1) { 
    if(!defined($flag)){
      print br,'///';
    }else{push (@file,"///");
	}
  } else { 
    if(!defined($flag)){
      print '///';
    }else{
      push (@file,"///");
    }
  }
 print @file;
  return;
}

sub File_asn{

  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file;
 if(!defined($flag)){
  print 'The following is the C.elegans partial sequence in ASN format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
  
  print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
  print 'Bioseq-set ::={',br;
  print 'Seq-set {',br;
  print '  seq {',br;
  print '    id { local id 1 },',br;
  print '    descr { title "nx | xxx | ',$chromosome,' C.elegans partial sequence from #',$start,' to ',$end,'" },',br;
  print '    inst {',br;
  print '       repr raw,mol dna,length ',$end-$start,', topology linear,',br;
  print '       seq-data',br;
  print '         iupacna "';
}else{
  push (@file,"Seq-set {\n");
  push (@file,"  seq {\n");
  push (@file,"    id { local id 1 },\n");
  push (@file,"    descr { title \"nx | xxx | ',$chromosome,' C.elegans partial sequence from #',$start,' to ',$end,'\" },\n"),
  push (@file,"    inst {\n");
  push (@file,"       repr raw,mol dna,length ',$end-$start,', topology linear,\n");
  push (@file,"       seq-data\n");
  push (@file,"         iupacna \"");
 
}
  # IMPORTANT NOTE: THIS IS PROBABLY GENERATING INCORRECT DATA!!!!!!!!!!
  my  @x = split //,$x;
  my  $newline=0;
  my  $pillo=0;
  my  $count;
  for ($count=0; $count<@x; $count++){
    $newline++;
    $pillo++;
    if ($pillo==52){
      $newline=1;
 if(!defined($flag)){
      print br;
    }else{push (@file,"\n")};
    }
    
    if ($newline==70){
      $newline=0;
 if(!defined($flag)){
      print br;
    }else{push (@file,"\n")};
    }else{
      $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
 if(!defined($flag)){
      print $x[$count];
    }else{push (@file,$x[$count])};
    }
  }
   if(!defined($flag)){
  print '"',br;
  print '       } } ,',br;
  print '} } ,';  
}else{
push (@file,"\"\n       } } ,\n} } ,")}; 
 print @file;
 return; 
}

sub File_nexus{
  
  my ($start,$end,$chromosome,$x,$flag)=(shift,shift,shift,shift,shift);
  my @file; 
 if(!defined($flag)){
    print 'The following is the C.elegans partial sequence in Paup/NEXUS format from position ',b($start),' to position  ',b($end),' on ',b($chromosome),' (total: ',b($end-$start),' bp).',br,br;
    
    print ('<table width="659"  bgcolor="#f4f4f4" cellpadding=4 cellspacing=0 border><tr><td><pre class=dna>');
    print '>nx | xxxx | ';
    print $chromosome,' C.elegans partial sequence from # ',$start, ' to ' ,$end, br;
  }else{
    push (@file,">nx | xxxx |");
    push (@file,$chromosome);
    push (@file," C.elegans partial sequence from # ");
    push (@file,$start);
    push (@file," to ");
    push (@file,$end);
    push (@file,"\n");
  }
  my @x = split //,$x;
  my $newline=0;
  my $count;
  for ($count=0; $count<@x; $count++){
    $newline++;
    if ($newline==51){
      $newline=0;
      if(!defined($flag)){
	print br;
      }else{
	push (@file,"\n")};
    }else{
      $x[$count] =~ tr/a-z/A-Z/;$x[$count]=~s/s+//g;
      if(!defined($flag)){
	print $x[$count];
      }else{push (@file,$x[$count])};
    }
  }
 print @file;
  return;
}
exit;

sub do_save {
    my ($save,$start,$end,$chromosome,$x) = @_;

    my $format = param('format');
    my $trip="_";
    my $filename = "$start$trip$end$trip$chromosome.$format";
    my $code = \&{"File_$format"};

    print header( -type=>'application/octet-stream',
		  -Content_disposition=>qq(attachment; filename="$filename"),
		  -Content_length=>length($save));
    $code->($start,$end,$chromosome,$x,1);
    exit;
}




