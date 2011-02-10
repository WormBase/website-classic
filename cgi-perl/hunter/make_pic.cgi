#!/opt/bin/perl -w

# make_pic.cgi by Marco Mangone (mang1);
# this program create on-line map positions on a chromosome
# require chromosome.png so do not forget to copy on the same directory
# this program is part of hunter.cgi, so put it on the same directory

use lib '../lib';
use GD;
use CGI qw/:standard :html3 escape/;
use CGI::Carp qw/fatalsToBrowser/;
use Ace 1.51;
use Ace::Sequence;
use Ace::Browser::AceSubs;
use strict;


#acquire the parameters
my $chromosome =  param('chromosome'); 
my $start= param ('start');
my $end= param ('end');

my $strand=0;

#resize the scale of the picture
my $chr_length=0;
if ($chromosome eq "Chromosome_I"){
  $chr_length = 13467562
}
elsif   ($chromosome eq "Chromosome_II") {
  $chr_length = 15116321
}
elsif   ($chromosome eq "Chromosome_III"){
  $chr_length = 12476799
}
elsif   ($chromosome eq "Chromosome_IV"){
  $chr_length  = 15919001
}
elsif   ($chromosome eq "Chromosome_V"){
  $chr_length   = 20666302
}
elsif   ($chromosome eq "Chromosome_X") {
  $chr_length   = 17432311
}

# start Ace
my $DB = OpenDatabase() || AceError("Couldn't open database.");

my $length = ($end-$start);

my $results = Ace::Sequence->new(-seq=>$chromosome,-db=>$DB,
			      -offset=>$start,-length=>$length,
			     );

my $features = $results->feature_list;
my @clones =$results->features('Sequence:curated');

my $versus = $results->length;

my $totale=@clones;

# start the picture
print header($GD::VERSION > 1.19 ? 'image/png' : 'image/gif');

open (GIF,$GD::VERSION > 1.19 ? "chromosome.png" : "chromosome.gif") || die;
my $myImage = $GD::VERSION > 1.19 ? GD::Image->newFromPng(\*GIF) : GD::Image->newFromGif(\*GIF) || die;
close GIF;
my $white;
my $red;
my $black;

$white = $myImage->colorAllocate(255,255,255);
$red = $myImage->colorAllocate(255,0,0);
$black = $myImage->colorAllocate(0,0,0);
$myImage->transparent($white);
$myImage->string(gdSmallFont,550,3,$chromosome,$red);
$myImage->string(gdSmallFont,3,90,$start,$black);
$myImage->string(gdSmallFont,608,90,$end,$black);


# put in order all the clones found in this gap
my %list;
my $i;
my $absstart = $results->start;
for ($i=0; $i<$totale; $i++)
  { 
  
    my $num1 = $clones[$i]->start;
    my $num2 = $clones[$i]->end;
    my $tmp = $clones[$i]->info;

    $tmp =~ /\.(\d+)$/;
    my $tmp2 = $1;
    $list{$tmp}->{val} = $tmp2;
    $list{$tmp}->{num} = [];
    push(@{$list{$tmp}->{num}},$num1);
    push(@{$list{$tmp}->{num}},$num2);
  }
my @kys = keys %list;
@kys = sort{$list{$a}->{num}->[0] <=> $list{$b}->{num}->[0]} @kys;

# $a is the number near each arrow
$a=0;

my $sopra=0;
my $ii=0;
my $rainbow=0;
my $ttt=@kys;
my $start_position=0;
my $end_position=0;
foreach(@kys){
  my $acc = $_;
  my $num1 = $list{$acc}->{num}->[0];
  my $num2 = $list{$acc}->{num}->[1];
  $a++;

  my $values = $DB->fetch(-class=>'Sequence',
			  -name=>$acc);
  
  
  my $remark= $values->get('Brief_identification'=>1);     
  
  
  my $seq = Ace::Sequence->new(-class=>'Sequence',
			       -db=>$DB,
			       -seq=>$acc);
  
  my    $strand = $seq->strand;
  
  $rainbow= $rainbow+103;
  
  if ($rainbow==254){
    $rainbow=0;
  }
  my $color=$myImage->colorAllocate(($rainbow/2),$rainbow/2,($rainbow));
  
  my       $start_position1 = (($num1-$absstart)*658)/$length;
  my       $end_position1   = (($num2-$absstart)*658)/$length;

  if ($start_position1<=0){
    $start_position=0;
  }
  if ($start_position1>0){
    $start_position=$start_position1;
  }
  if ($end_position1<613){
    $end_position=$end_position1;
  }
  if ($end_position1>=613){
    $end_position=613;
  }
  
  # verify same line in a range of 4 pixels
    if (($sopra>$start_position-4)||($sopra>$end_position+4)){
      $ii=$ii+10;
      $sopra = $end_position;
    }else{
      $sopra = $end_position;
    }
    
  #number upon picture start and commenty if $ttt<3
  my $p = $strand eq '-' ? $end_position : $start_position;
  if ($ttt<3){
    if (defined($remark)){
      my $printed_value="$a ($remark)";
      $myImage->string(gdSmallFont,$p+30,55-$ii,$printed_value,$color);
    }else{
      my $printed_value="$a (pred. cod. region)";
      $myImage->string(gdSmallFont,$p+30,55-$ii,$printed_value,$color);
    }
  }
    else{
      my $printed_value="$a";
      $myImage->string(gdSmallFont,$p+30,55-$ii,$printed_value,$color);
    }
  #draw the line that connect 2 points
    $myImage->line($start_position+30,70-$ii,$end_position+30,70-$ii,$color);
  
  # ...the arrows depends from the direction of the clones....    
  
  if ($strand eq "-"){
    #draw first up arrow part
    $myImage->line($end_position+30,70-$ii,$end_position+40,68-$ii,$color);
    #draw second leg 
    $myImage->line($end_position+30,70-$ii,$end_position+30,90,$color);
    #draw the first leg
    $myImage->line($start_position+30,70-$ii,$start_position+30,90,$color);
    #draw the second down arrow part
    $myImage->line($end_position+30,70-$ii,$end_position+40,72-$ii,$color)
      unless $start_position1 > 613;
  
  }elsif($num1>$num2){
    
    #draw first up arrow part
    $myImage->line($start_position+30,70-$ii,$start_position+40,68-$ii,$color);
    #draw second leg 
    $myImage->line($start_position+30,70-$ii,$start_position+30,90,$color);
    #draw the first leg
    $myImage->line($end_position+30,70-$ii,$end_position+30,90,$color);
    #draw the second down arrow part
    $myImage->line($start_position+30,70-$ii,$start_position+40,72-$ii,$color)
      unless $end_position1 > 613;
  }else{
    #draw first leg
    $myImage->line($end_position+30,70-$ii,$end_position+20,68-$ii,$color);
    #draw second leg
    $myImage->line($end_position+30,70-$ii,$end_position+20,72-$ii,$color);
    #draw the connection with the chromosome
    $myImage->line($start_position+30,70-$ii,$start_position+30,90,$color)
      unless $start_position1 < 0;
    #draw the second connection with the chromosome
    $myImage->line($end_position+30,70-$ii,$end_position+30,90,$color)
      unless $end_position1 > 613;
  }
  
}

# finally print the image 
print $GD::VERSION > 1.19 ? $myImage->png : $myImage->gif;



