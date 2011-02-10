#!/usr/bin/perl
# The purpose of this script to to pre-load all of the images
# for the AO-term based expression viewer
use strict;
use Ace;
use GD;
use Image::GD::Thumbnail;

use constant HOST => 'brie3.cshl.edu';
use constant PORT => 2005;

# where the image and overlays are stored
use constant IMG_OVERLAYS  => '/usr/local/wormbase/html/images/expression/overlays';
use constant IMG_ASSEMBLED => '/usr/local/wormbase/html/images/expression/assembled';

# force or no force -- set to zero to overwrite existing images
use constant DO_NOT_FORCE  => 0;

# AO terms that trigger an expression
# overlay in the worm image
use constant OVERLAYS => ( 
			   #'WBbt:0004017' => 'cell',
			   'WBbt:0003681' => 'pharynx',
			   'WBbt:0005772' => 'intestine',
			   'WBbt:0005736' => 'excretory',
			   'WBbt:0005812' => 'excretory',
			   'WBbt:0005175' => 'gonads',
			   'WBbt:0005319' => 'spermatheca',
			   'WBbt:0006760' => 'uterus', 
			   'WBbt:0006749' => 'nervering',
			   #'WBbt:0006874' => 'nervering',
			   'WBbt:0005753' => 'seamcells',
			   'WBbt:0005733' => 'hypodermis',
			   'WBbt:0004697' => 'hmc',
			   'WBbt:0005798' => 'analsphincter',
			   'WBbt:0005773' => 'rectum',
			   'WBbt:0004292' => 'analdepressor',
			   'WBbt:0006748' => 'vulva',
			   'WBbt:0006751' => 'headneuron',
			   'WBbt:0003675' => 'bodymuscle',
			   'WBbt:0005813' => 'bodymuscle',
			   'WBbt:0006759' => 'tailneuron',
			   'WBbt:0005300' => 'ventralnervecord',
			   'WBbt:0004871' => 'ventralnervecord',
			   'WBbt:0004621' => 'ventralnervecord',
			   'WBbt:0004872' => 'ventralnervecord',
			   'WBbt:0004849' => 'vulvalmuscle',
			   'WBbt:0004850' => 'vulvalmuscle',
			   'WBbt:0004853' => 'vulvalmuscle',
			   'WBbt:0004854' => 'vulvalmuscle',
			   'WBbt:0005821' => 'vulvalmuscle',
			   'WBbt:0005829' => 'ventralnervecord',
			   'WBbt:0003888' => 'amphidneuron',
			   'WBbt:0003887' => 'amphidneuron',
			   'WBbt:0005394' => 'amphidneuron',
			   'WBbt:0005431' => 'phasmidneuron',
			   'WBbt:0005427' => 'phasmidneuron',
			   'WBbt:0005425' => 'phasmidneuron',
			   'WBbt:0006755' => 'phasmidneuron',
			   'WBbt:0006753' => 'phasmidneuron',
			   'WBbt:0006750' => 'dorsalnervecord',
			   'WBbt:0005342' => 'uterinemuscle',
			   'WBbt:0005364' => 'rectum',
			   'WBbt:0005799' => 'rectum',
			   'WBbt:0005800' => 'rectum',
			   'WBbt:0005828' => 'gonads',
			   'WBbt:0004506' => 'gonads',
			   'WBbt:0006768' => 'vulva',
			   'WBbt:0006764' => 'vulva',
			   'WBbt:0006762' => 'vulva',
			   'WBbt:0004607' => 'ventralnervecord',
			   #'WBbt:0005735' => 'neuron',
			   #'WBbt:0003679' => 'neuron',
			   'WBbt:0006761' => 'head',
			   'WBbt:0005739' => 'head',
			   'WBbt:0005741' => 'tail',
			   'WBbt:0003833' => 'intestinalmuscle',
			   'WBbt:0004757' => 'hsn',
			   'WBbt:0005751' => 'coelomocyte',
			   'WBbt:0006797' => 'gonads',
			   'WBbt:0004947' => 'can',
			   'WBbt:0003832' => 'avm',
			   'WBbt:0003811' => 'bdu',
			   'WBbt:0005278' => 'ventralnervecord',
			   'WBbt:0005793' => 'arcadecell',
			   'WBbt:0005107' => 'labialsensillum',
			   'WBbt:0005777' => 'excretoryduct'
);


# keep track of which patterns have been saved
# so we can re-use identical images
my %cached;

chdir(IMG_ASSEMBLED) or die $!;

my $db = Ace->connect( -host => HOST, -port => PORT );
my $it = $db->fetch_many('Expr_pattern');
my @ep;
while (my $ep = $it->next) {
  next unless non_embryonic($ep);
  my @terms = grep {is_not_embryo($_)} $ep->Anatomy_term; 
  
  print join ("\t",$ep,map{$_->Term.' '.$_->Definition} $ep->Anatomy_term), "\n";

  # abort unless there are AO terms
  @terms or next;
  my $image_file = system_name($ep);
  my $file_is_cached = is_cached($image_file);
  
  # abort if the image exists and we are not replacing
  if (DO_NOT_FORCE) {
      if ($file_is_cached) {
	  warn "Image $image_file has already been cached, skipping\n";
	  next;
      }
  }
  elsif ($file_is_cached) {
    unlink $image_file;
  }

  my %tissue = OVERLAYS;

  # This will abort if no AO term (or ancestor) in the
  # set has an image overlay
  my @all_terms =  map {$_,$_->Ancestor} @terms;
  my $OK;
  for my $t (@all_terms) {
      $OK++ and last if $tissue{$t};
  }
  next unless $OK;
  #print STDERR "drawing $image_file\r";
  img_render($ep,@terms);
}




# find which overlay organs to print based on ao terms
sub expressed_in {
  my @ao = @_;
  my ($overlay, $reject) = remove_redundant_ancestor(@ao);
  my %tissue;
  
  for my $ao (@ao) {
    my $tissue = $overlay->{$ao};
    
    if ($tissue) {
      $tissue{$tissue}++;
      next;
    }


    my @ancestors = grep {!defined $reject->{$_}} grep {$overlay->{$_}} $ao->Ancestor;

    my @tissues   = map  { $overlay->{$_->[0]} }    # overlay tissue
                    sort { $a->[1] <=> $b->[1] }    # sort ascending by num. descendents, keep lowest
                    map  { my @d = $_->Descendent; [$_,scalar(@d)] }  @ancestors;
    if (@tissues) {
      for my $t (@tissues) {
	# some are just too general
	next if $t =~ /cell|neuron/;
	$tissue{$t}++;
	last;
      }
    }
  }

  return keys %tissue;
}

sub img_cache {
  my $ep         = shift or die "an expression pattern object is required";
  my $img        = shift;

  my $system_name = system_name($ep);

  # Have we been sent a full-size image to cache?
  if ($img) {
    cache_image($img,$system_name);
  }

  return "$system_name cached\n";
}

sub system_name {
  my $ep    = shift;

  my $image_name = $ep->name;

  return $image_name . '.png';
}

sub is_cached {
  my $name = shift;

  # has an image already been rendered?
  my $exists = -e $name;
  my $empty  = -z $name;

  return 1 if $exists && !$empty;
  return 0;
}

sub cache_image {
  my ($img,$system_name) = @_;
  open IMG, ">$system_name" or die "$system_name $!";
  binmode IMG;
  print IMG $img->png;
  close IMG;
}

sub img_render {
  my ($ep,@ao) = @_;
  my @tissues     = expressed_in(@ao);
  print join("\t",$ep,@tissues), "\n";
  
  @tissues or return "No usable AO terms for $ep\n";

  my $expressed = join '|', @tissues;

  # don't need to cache multiple identical images,
  # so symbolic link to an existing image
  if ( my $image_file = $cached{$expressed} ) {
      my $symlink = $ep->name.".png";
      system "ln -s $image_file $symlink";
      #print "We already used $expressed\n";
      return img_cache($ep);
  }

  $cached{$expressed} = $ep->name .".png";

  my %img;
  my $files = IMG_OVERLAYS;
  
  for my $t (qw/white base/, @tissues) {
    my $file = "$files/celegans_$t\.png";
    die "file $file does not exist!\n" unless -e $file;
    $img{$t} =  GD::Image->newFromPng($file,1) or die;
  }
  
  my $composite_img = $img{base};
  #$composite_img->copy($img{base},0,0,0,0,$img{base}->width,$img{base}->height);
  
  for my $t (@tissues) {
    $composite_img->copy($img{$t},2,2,0,0,$img{$t}->width,$img{$t}->height);
  }
  
  #my $white = $composite_img->colorAllocate(255,255,255);
  #$composite_img->transparent($white);

  return img_cache($ep, $composite_img);
}


sub remove_redundant_ancestor {
  my @ao = @_;
  my %in_list = map {$_=>1} @ao;
  my %overlay = OVERLAYS;
  my %reject;

  for my $name (@ao) {
    next unless $overlay{$name};

    my $term = get_ao_term($name);

    # remove only parent terms whose relevant children have overlays                                                                                                                                             
    next unless grep {$_ ne $term} grep {$overlay{$_}} grep {$in_list{$_} }$term->Descendent;
    delete $overlay{$name};
    $reject{$name}++;
  }

  return \%overlay, \%reject;
}

sub get_ao_term {
  my $name = shift;
  return $name if ref $name;
  $db->fetch( -class => 'Anatomy_term',
              -name  => $name,
              -fill  => 1 );
}

sub non_embryonic {
  my $ep = shift;
  my @stages = $ep->Life_stage;
  @stages > 0  or return 1;
  return grep {!/embryo/} @stages;
}

sub is_not_embryo {
  my $ao = shift;
  my @ancestors = $ao->Ancestor;
  my $emb = grep {eval{$_->Definition =~ /embryo(nic)?/i}} ($ao,@ancestors);
  return $emb ? 0 : 1;;
}

1;
