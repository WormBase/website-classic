#!/usr/bin/perl

# make_pic.cgi by Marco Mangone (mang1);
# this program create on-line map positions on a chromosome
# require chromosome.png so do not forget to copy on the same directory
# this program is part of hunter.cgi, so put it on the same directory

use lib '../lib';

use strict;
use File::stat;
use GD;
use CGI qw/:standard :html3 escape/;
use CGI::Carp qw/fatalsToBrowser/;
use Ace;
use Ace::Browser::AceSubs;
use lib '.';
use Pedigree;

$| = 1;

#acquire the parameters
my $cell =  param('cell');

# start Ace
my $DB = OpenDatabase() || AceError("Couldn't open database.");

my $primary_cell = $DB->fetch(-class=>'Cell',-name=>$cell);

if (!$primary_cell) {
  No_pedigree();
  exit 0;
}

my ($mom,$sibling,$daughters,$nieces) = Pedigree->walk($primary_cell);

my $baseimage = $GD::VERSION > 1.19 ? "pedigree.png" : "pedigree.gif";

#open (GIF,$baseimage) || die "oops";
my $myImage = GD::Image->new(314,231);
#close GIF;

# start the picture
print header($GD::VERSION > 1.19 ? 'image/png' : 'image/gif');

my $white = $myImage->colorAllocate(255,255,255);
my $red = $myImage->colorAllocate(255,0,0);
my $blue = $myImage->colorAllocate(0,48,238);
my $black = $myImage->colorAllocate(0,0,0);
$myImage->transparent($white);

# Draw a string for the PO, if it exists.
# This may be different when the primary cell is also mom...

# Is there a mom?
if ($mom) {
  # Draw a string for mom
  $myImage->string(gdSmallFont,145,30,$mom,$black);

  # F1: primary_cell
  $myImage->line(150,47,150,65,$blue);
  $myImage->line(150,65,225,65,$blue);
  $myImage->line(225,65,225,85,$blue);
  $myImage->string(gdSmallFont,215,93,$primary_cell,$red);
  
  # F1: sibling
  if ($sibling) {
    $myImage->line(150,47,150,65,$blue);
    $myImage->line(150,65,75,65,$blue);
    $myImage->line(75,65,75,85,$blue);
    $myImage->string(gdSmallFont,65,93,$sibling,$black);
  }

  # F2: Daughters
  if ($daughters) {
    if ($daughters->[0]){
      $myImage->line(225,110,225,130,$blue);
      $myImage->line(225,130,190,130,$blue);
      $myImage->line(190,130,190,150,$blue);
      $myImage->string(gdSmallFont,175,160,$daughters->[0],$black);
    }
    
    if ($daughters->[1]){
      $myImage->line(225,110,225,130,$blue);
      $myImage->line(225,130,260,130,$blue);
      $myImage->line(260,130,260,150,$blue);
      $myImage->string(gdSmallFont,246,160,$daughters->[1],$black);
    }
  }

  # F2: Nieces
  if ($nieces) {
    if ($nieces->[0]) {
      $myImage->line(75,110,75,130,$blue);
      $myImage->line(75,130,40,130,$blue);
      $myImage->line(40,130,40,150,$blue);
      $myImage->string(gdSmallFont,27,160,$nieces->[0],$black);
    }

    if ($nieces->[1]) {
      $myImage->line(75,110,75,130,$blue);
      $myImage->line(75,130,110,130,$blue);
      $myImage->line(110,130,110,150,$blue);
      $myImage->string(gdSmallFont,100,160,$nieces->[1],$black);
    }
  }


} else {
  # No mom. The primary cell is the root.  Ie PO
  $myImage->string(gdSmallFont,145,30,$primary_cell,$red);

  # F1: daughters
  if ($daughters) {
    if ($daughters->[0]) {
      $myImage->line(150,47,150,65,$blue);
      $myImage->line(150,65,225,65,$blue);
      $myImage->line(225,65,225,85,$blue);
      $myImage->string(gdSmallFont,215,93,$daughters->[0],$black);
      
      if ($daughters->[1]) {
	$myImage->line(150,47,150,65,$blue);
	$myImage->line(150,65,75,65,$blue);
	$myImage->line(75,65,75,85,$blue);
	$myImage->string(gdSmallFont,65,93,$daughters->[1],$black);
      }
    }
  }
}


print $GD::VERSION > 1.19 ? $myImage->png : $myImage->gif;

sub No_pedigree {
  print $GD::VERSION > 1.19 ? "Content-type: image/png\n\n" : "Content-type: image/gif\n\n";
  open (GIF,$GD::VERSION > 1.19 ? "no_pedigree.png" : "no_pedigree.gif") || die;
  my $myImage = $GD::VERSION > 1.19 ? GD::Image->newFromPng(\*GIF) : GD::Image->newFromGif(\*GIF) || die;
  close GIF;
  print $GD::VERSION > 1.19 ? $myImage->png : $myImage->gif;
}
