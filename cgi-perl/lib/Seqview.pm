#Seqview is a sequence viewer to replace hunter.cgi and sequence
#2001-02-21, Allen Day

package Seqview;
use strict 'vars';

use vars     qw/@ISA @EXPORT/;
require      Exporter;
@ISA       = Exporter;
@EXPORT    = qw/MakeSeqImage MakeSeqImagemap MakeSeqImageAndMap MakeSeqDump MakeSeqObject/;

use lib './';
use CGI   qw/:standard/;
use Ace::Browser::AceSubs qw/:DEFAULT/;
# use Ace::Sequence;
use Bio::Graphics::Panel;
use ElegansSubs qw(FindPosition OpenDBGFF);
use Ace::Browser::GeneSubs 'ENTREZ';
use CSS;

my $CSS;  # cached data

############
# EXPORTED #
############
sub MakeSeqImage             { _make_image_and_map(0,@_); }
sub MakeSeqImagemap          { _make_image_and_map(1,@_); }
sub MakeSeqImageAndMap       { _make_image_and_map(2,@_); }

sub MakeSeqObject {
  my($obj, $start, $stop, $abs) = @_ or die "not enough parameters to fetch_searchterm";

  my @param  = (-name=>$obj);
  push @param,(-start=>$start,-stop=>$stop) if defined($start)      && defined($stop) &&
                                                       $start ne '' &&         $stop ne '';

  my $db = OpenDBGFF(OpenDatabase());

  my ($seq) = $db->segment(@param);
  if ($abs) {
    $seq->absolute($abs);
    ($seq) = $db->segment(-name=>$seq->refseq,-start=>$seq->stop,-stop=>$seq->start)
      if $seq->start > $seq->stop;
  }
  return wantarray ? ($seq, $seq->start, $seq->stop, $seq->refseq) : $seq;
}

sub MakeSeqDump {
  my ($dump, $seq_obj, $start, $stop, $chromosome, $features, $servers) = @_;
  my $out;

  print header(-type=>'text/html');
  print '<pre>';

  if($dump eq 'FastA'){
    $out = $seq_obj->dna;
    if($out =~ />/){
      $out =~ s/(.+?)([tagc]+)/$2/;
    }
    $out =~ s/(.{80})/$1\n/g;
    $out = '>'.$chromosome.' '.$start.'-'.$stop."\n".$out;
  }

  elsif($dump eq 'GFF'){
    $out = $seq_obj->gff;
  }

  print $out;
  print '</pre>';
}

###################################################

sub _make_image_and_map {
  my ($map,$seq_obj, $features, $servers, $options) = @_;

  my $width = $options->{width};
  $width ||=  Configuration->Dasview_width;
  my $est_labels = $options->{est_labels};
  my %pairs;

  my $stylesheet = Configuration->Stylesheet;
  my $stylesheet_path = Apache->request->lookup_uri($stylesheet)->filename;
  $CSS ||= CSS->new(
		    -source  => $stylesheet_path,
		    -adaptor => 'AceGraphics',
		    -debug   => 0
		   );



  #give some default features
  $features = Configuration->Dasview_default unless $features && @$features;
  $servers  = [ qw/WormBase/                      ] unless($servers);  #and servers if none chosen

  my %fs = map {$_=>1} @$features;
  my $ss = join ' ', @$servers;

  # this gets associative array that maps human-readable name to database name
  my $feature_components = Configuration->Dasview_features;

  # invert it
  my %feature_labels;
  while (my($label,$value) = each %{$feature_components}) {
    for my $type (@$value) {
      $feature_labels{$type} = $label;
    }
  }

  my @to_load;
  foreach (keys %fs) {
    my @components = @{$feature_components->{$_}};
    push @to_load,@components;
  }

  my (@forward,@reverse,%similarity,%other);

  my @features = $seq_obj->features(@to_load);

  # nasty special case for tRNAs
  @features = grep {$_->info !~ /\.t\d+$/} @features unless $fs{tRNAs};

  foreach (@features) {

    my $type = $_->source ? join(':',$_->method,$_->source) : $_->method;
    my $label = $feature_labels{$type} || $_->method;

    # first we handle all the special cases
    if ($_->type =~ /^transcript/) {
      push @forward,$_ if $_->strand > 0;
      push @reverse,$_ if $_->strand < 0;
      next;
    }

    if ($_->type =~ /^alignment/) { # special case for 5', 3' reads
      push @{$similarity{$label}},$_;
      next;
    }

    # then we handle the semi-automatic ones
    push @{$other{$label}},$_;
  }

  my $panel = Bio::Graphics::Panel->new(-segment => $seq_obj,
					-width   => $width,
					-keycolor => 'moccasin',
					-grid => 1,
				       );

  # all the rest comes from configuration
  for my $label (@{Configuration->Dasview_featurelist}) {
    next unless $fs{$label};

    if ($label =~ /Predicted genes/i) {

      my $labelf = @forward <= 10;
      my $labelr = @reverse <= 10;

      $panel->add_track($seq_obj   => 'arrow',
			-double => 1,
			-bump =>1,
			-tick=>2,
			-grid => 'lightcyan',
		       );

      $panel->add_track(\@forward,
			%{$CSS->style('.transcriptf')},
			-glyph    => 'transcript2',
			-label    => $labelf,
			-description => $labelf,
		       );

      $panel->add_track(\@reverse,
			%{$CSS->style('.transcriptr')},
			-glyph    => 'transcript2',
			-label       => $labelr,
			-description => $labelr,
		       );
      next;
    }

    # turn label into a style
    my $style = ".$label";
    $style =~ s/\s/-/g;

    # handle similarities a bit specially differently
    if (my $set = $similarity{$label}) {
      my %pairs;
      for my $a (@$set) {
	(my $base = $a) =~ s/\.[35]$//;
	push @{$pairs{$base}},$a;
      }
      my $tally = keys %pairs;
      my $do_label = $tally <= 10;
      my $do_bump  = $tally <= 100;
      my $track = $panel->add_track(-glyph =>'segments',
				    -label => $do_label,
				    %{$CSS->style($style)||{}},
				    -bump => $do_bump,
				    -connector => 'solid',
				   );
      $track->add_group($_) foreach values %pairs;
    }

    elsif ($other{$label}) {

      my $do_label = @{$other{$label}} <= 10;
      my $do_bump  = @{$other{$label}} <= 50;
      $panel->add_track($other{$label},
			-glyph => 'generic',
			-key   => $label,
			-label => $do_label,
			%{$CSS->style($style)||{}},
			-bump => $do_bump,
			-connector => 'solid',
		       );
    }
  }


  # requested printing of map
  if ($map == 0) {
    my $gd    = $panel->gd;
    if ($gd->can('png')) {
      print header(-type=>'image/png');
      print $gd->png;
    } else {
      print header(-type=>'image/gif');
      print $gd->gif;
    }
  }

  # requested printing of imagemap
  if ($map == 1 or $map == 2){
      my $boxes = $panel->boxes;

      print qq(<map name="hmap">\n);

      # use the scale as a centering mechanism
      my $ruler = shift @$boxes;
      make_centering_map($ruler);

      foreach (@$boxes){
	  my $alt   = make_alt($_->[0]);
	  my $href  = make_href($_->[0]);
	  print qq(<AREA SHAPE="RECT" COORDS="$_->[1],$_->[2],$_->[3],$_->[4]" 
                         HREF="$href" ALT="$alt" TITLE="$alt">\n);
      }
      print "</map>\n";
  }
  if ($map == 2) {
    my $gd =  $panel->gd;
    return ($panel->width,$panel->height,$gd);
  } else {
    return ($panel->width,$panel->height);
  }
}

sub make_centering_map {
  my $ruler = shift;
  return if $ruler->[3]-$ruler->[1] == 0;

  my $offset = $ruler->[0]->start;
  my $scale  = $ruler->[0]->length/($ruler->[3]-$ruler->[1]);

  # divide into ten intervals
  my $portion = ($ruler->[3]-$ruler->[1])/10;
  my $url = url(-relative=>1,-path_info=>1);
  my $chrom = $ruler->[0]->refseq;

  for my $i (0..19) {
    my $x1 = $portion * $i;
    my $x2 = $portion * ($i+1);
    # put the middle of the sequence range into
    # the middle of the picture
    my $middle = $offset + $scale * ($x1+$x2)/2;
    my $start  = int($middle - $ruler->[0]->length/2);
    my $stop   = int($start + $ruler->[0]->length - 1);
    my $href = "$url?chromosome=$chrom;start=$start;stop=$stop";
    print qq(<AREA SHAPE="RECT" COORDS="$x1,$ruler->[2],$x2,$ruler->[4]" HREF="$href" ALT="center" TITLE="center">\n);
  }
}

sub make_href {
  my $feature = shift;
  return Object2URL($feature->info) unless $feature->source eq 'Genomic_canonical';
  my $gb = $feature->info->Database(3);
  return Object2URL($feature->info) unless $gb;
  return ENTREZ . $gb;
}

sub make_alt {
  my $feature = shift;
  my $object = $feature->info;
  my $type  = $object->class;

  my $class = $object->class;
  $class = 'Briggsae'   if defined($feature->source_tag) && $feature->source_tag =~ /briggsae/i;
  $class = 'Transcript' if $feature->isa('Ace::Sequence::Transcript');
  my $label = "$class:$object";

  if ($feature->type eq 'GappedAlignment') {
    my @segments = $feature->merged_segments;
    $label .= ' ' . join ',',map {$_->start . '/' . $_->end} @segments;
  } elsif ($feature->source eq 'Genomic_canonical') {
    my $gb = $feature->info->Database(3);
    $label = "Genbank $gb (Wormbase $object)" if $gb;
    $label .= " start=" . $feature->start;
    $label .= " end="   . $feature->end;
  }  else {
    $label .= " start=" . $feature->start unless $feature->start == -99_999_999; # bogus value
    $label .= " end="   . $feature->end   unless $feature->end   ==  99_999_999; # bogus value
  }
  return $label;
}


1;
