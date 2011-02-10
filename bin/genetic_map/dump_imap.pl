#!/usr/bin/perl

# Dump out all markers into a flat file for subsequent processing

use Ace;
use Bio::DB::GFF;
use Getopt::Long;
use lib '/usr/local/wormbase/bin/genetic_map';
use GMap;
use strict;

$|++;

use constant SCALING_FACTOR => 10000;
my $float                 = 4;  # Number of sig figs to use when positioning markers
my $display               = 2;  # Number of sig figs to use in Notes


my %landmarks = map { $_ => 1} qw/
    smg-2 lin-17 unc-57 bli-4 unc-13 eat-16 lin-11 unc-75
    unc-101 unc-59 bli-3 unc-11 dpy-5 unc-29 unc-54 sqt-2
    mab-9 lin-31 lin-4 lin-26 let-23 bli-1 rol-1 lin-42
    sup-9 bli-2 dpy-10 unc-4 sqt-1 sup-6 his-14 unc-52
    unc-45 par-2 let-805 unc-93 lon-1 unc-32 ced-9 pie-1
    unc-64 mec-12 pal-1 sma-3 mab-5 lin-12 tra-1 dpy-18
    nob-1 ced-2 dpy-13 fem-3 elt-1 unc-30 sup-24 hsp-1
    dpy-9 lin-1 unc-17 unc-5 smg-7 lin-45 unc-43 dpy-20
    unc-22 dpy-26 unc-26 tra-3 dpy-21 srh-36 hda-1 gcy-20
    rol-3 egl-8 egl-9 dpy-11 unc-51 sma-1 lag-2 unc-60
    sqt-3 let-418 unc-62 unc-76 unc-42 unc-68 mes-4 egl-17
    lin-18 unc-97 unc-6 unc-18 vab-3 sdc-2 unc-9 unc-84
    unc-3 lin-15A ace-1 sup-10 unc-1 dpy-3 lin-32 fox-1
    unc-2 lon-2 dpy-6 dpy-22 lin-2 unc-7/;

# GFF sources and methods
use constant CONFIDENCE_INTERVALS_SOURCE => 'confidence_interval';
use constant CONFIDENCE_INTERVALS_METHOD => 'calculated_genetic_range';
use constant CONFIDENCE_INTERVALS_GROUP  => 'Gene';

use constant ALLMARKERS_SOURCE => 'map_position';
use constant ALLMARKERS_GROUP  => 'Gene';

my ($acedb,$host,$port,$help,$debug,$version);
GetOptions ('acedb=s'    => \$acedb,
	    'host=s'     => \$host,
	    'port=s'     => \$port,
	    'help'       => \$help,
	    'debug'      => \$debug,
	    'version'    => \$version,
           );

if ($help) {
  die <<END;
 Usage: dump_all_genes.pl [options]

  Options:
  -acedb    Full path to acedb database to use OR
  -host     Hostname of aceserver
  -port     Port of aceserver

  -debug    boolean true for extra debugging information (>debug.out)
  -test     boolean true to run in brief test mode (10 items)

END
}

# Connect to ace and fetch the database version
print STDERR "\n\nConnecting to acedb: " . ($acedb) ? "$acedb\n" : "$host:$port\n";
my $db = ($acedb)
  ? Ace->connect(-path=>$acedb)
  : Ace->connect(-host=>$host,-port=>$port);

$version ||= $db->status->{database}{version};

my $gff = Bio::DB::GFF->new(-adaptor     => 'dbi::mysqlace',
			    -dsn         => "dbi:mysql:database=elegans;host=localhost",
			    -user        => 'root',
			    -pass        => 'kentwashere',
			   ) or die "$!";


my $factory = GMap->new();

my @chromosomes = qw/I II III IV V X/;
#my @chromosomes = qw/I/;
my $rows = {};

my %CHROM_LENGTHS = map { $_ => $factory->fetch_chromosome_length($gff,$_) } @chromosomes;

# Fetch all Gene markers with both a map position and a sequence
# association
my $pmap   = fetch_markers();
my $to_map = fetch_genes_lacking_pmap_coords();

my ($bp2gmap,$sorted_map) = build_pmap2gmap();

##################################################################
# sorting gmap positions of marker loci from left tip to right tip
##################################################################
open DEBUG,">/usr/local/wormbase/temporary_patches/${version}_patches/$version.gmap-to-pmap.debug.out" if $debug;
#open OUT,">/usr/local/wormbase/temporary_patches/${version}_patches/$version-genetic_map.gff";


# SPLITS
# Do those that have ONLY been used in three factor crosses
# Do those that have ONLY been used in two factor crosses

my @mapped;
foreach my $chrom (@chromosomes) {
  # Sort all markers on the chromosome according to their genetic map position
  my @sorted_markers = sort { $a->{start} <=> $b->{start} } @{$pmap->{$chrom}};

  # Maximal markers used for calculating the map
  my $left  = $sorted_markers[0];
  my $right = $sorted_markers[-1];

  # Calculate the total number of genetic units per chromosome
  # This isn't completely accurate...
  my $units = $right->{gmap} - $left->{gmap};

  # calculate the bp per genetic unit
  # This is used as the baseline for the interpolated map outside of the maximal markers
  my $bp_per_unit = $CHROM_LENGTHS{$chrom} / abs($units);
  print STDERR "Chrom $chrom: " . $left->{name} . ' (' . $left->{mean_pos} . '); '
    . $right->{name} . ' (' . $right->{mean_pos} . ")\n";
  print STDERR "\tTotal genetic units: $units ($bp_per_unit bp per unit)\n";

  dump_markers($chrom);
#  dump_confidence_intervals($chrom);
  dump_variations($chrom);
#  dump_rearrangements($chrom);
  dump_clones($chrom);
}

# Scale values as appropriate for the DB
sub scale {
    my $value = shift;
    return (sprintf("%8.${float}f",$value) * SCALING_FACTOR);
}

sub format_for_display {
    my $value = shift;
    return (sprintf("%2.${display}f",$value));
}

sub dump_markers {
  my $chrom = shift;
  my @genes = $db->fetch(-query=>qq[find Gene Map = "$chrom"]);
  my @interpolated = $db->fetch(-query=>qq[find Gene Interpolated_map_position = "$chrom"]);
  my @markers = ();
  my $count;
  foreach (@genes,@interpolated) {
    next unless $_->Species eq 'Caenorhabditis elegans';
    my $segment = $gff->segment(CDS=>$_);
    my ($start,$stop,$strand);
    my ($chrom,$map) = get_map_position($_);

    print "$_\tGENE\t$chrom:$map\n";
}
}

sub dump_variations {
  my $chromosome  = shift;
  print STDERR "Dumping variations on $chromosome...\n";
  my @variations   = $db->fetch(-query=>qq[find Variation SNP Map = "$chromosome"]);
  push (@variations,$db->fetch(-query=>qq[find Variation SNP Interpolated_map_position = "$chromosome"]));

  # my @variations = $db->fetch(-query=>qq{find Variation SNP});
  foreach (@variations) {
    #    my $is_rflp++     if ($_->RFLP);
    #    my $confirmed = $_->Confirmed_SNP;
    #    my $is_verified++ if ($_->Confirmed_SNP);


    my ($chrom,$position,$note) = fetch_variation_position($_);
    next unless ($chrom && $position);
    next unless ($chrom eq $chromosome);
    print join("\t",$_,'VARIATION',"$chrom:$position"),"\n";;
  }
}


sub dump_rearrangements {
  my $chrom = shift;
  print STDERR "Dumping rearrangements on $chrom...\n";

  # Maybe users entered a chromosome
  my @rearg = $db->fetch(-query=>qq{find Rearrangement where Map="$chrom"});
  foreach (@rearg) {
    if ($_->Map) {
      my @chr = $_->Map;
      foreach my $chr (@chr) {
	# Fetch the left and right ends
	my ($start,$stop);
	my $map_position = $chr->right;
	if ($map_position) {
	  foreach ($map_position->col) {
	    my ($tag,$position,$err) = $_->row;
	    $start = ($tag eq 'Left')  ? $position : $start;
	    $stop  = ($tag eq 'Right') ? $position : $stop;
	  }
	  my $display_start = format_for_display($start);
	  my $display_stop  = format_for_display($stop);


	}
      }
    }
  }
}


sub dump_clones {
  my $chromosome = shift;
  print STDERR "Dumping clones and contigs on $chromosome...\n";

  my $obj = $db->fetch(Map => "Sequence-$chromosome");

  # Fetch all the clones and sequences on this chromosome.
  # Over-ride clone objects with Sequence objects when appropriate
  my @clones;
  my @all_contigs = $obj->Contig;
  # Only fetch clones for the main contig
  foreach (@all_contigs) {
    push @clones,$_->Clone;
  }
  my %unique = map {$_ => $_} @clones,@all_contigs,$obj->Clone,$obj->Sequence;

  foreach (keys %unique) {
    my $component = $unique{$_};
    my ($start,$stop,$gmap_start,$gmap_stop);
    my $class = $component->class;
    if ($class eq 'Sequence') {
      # next;  # Debugging

      my ($chrom,$position,$type) = get_map_position($component);
      next if ($chrom && $chrom ne $chromosome);

      # Calculate interpolated positions
      # Should this just be Sequence instead of Clone?
      my $clone = $component->Clone;
      my (@segments) = $gff->segment( Clone    => $_ );
      
      (@segments) =  $gff->segment( Sequence => $component ) unless @segments;
      my $segment = $segments[0];  # Force to scalar
      if ($segment) {
	  $segment->absolute(1);
	  $start          = $segment->start;
	  $stop           = $segment->stop;
      }

      # Try using the precalculated interpolated position
      #      my $display = sprintf("%2.${display}f",$position);
      #      my $note = qq(Interpolated position: $display);
      #      $note   .= qq( ; Canonical for $canonical) if $canonical;
      #      $position = sprintf("%8.${float}f",$position) * FUDGE_FACTOR;
      #      push @{$rows->{$chromosome}},
      #      	[$chrom,'Genomic_canonical','region',$position,$position,'.','.','.',
      #                  qq(Clone "$component" ; Note "$note")];
    } else {
      # we are dealing with a clone that has no sequence coordinates
      # We need to fetch the fmap coords and interpolate them onto the
      # genetic map
      # Nasty scoping and variable names
      # Basically dealing with Clones in contig coords, chrom coords, and base pairs
      my ($fmap_start,$fmap_stop,$mean,$contig,$offset,$length,
	  $contig_range_start,$contig_range_stop,
	  $tag);

      # What is the extent of the Chromosome in fmap units?
      # And how many bp per fmap unit?
      my ($chrom_start,$chrom_stop) = $obj->Extent->row;

      my $bp    = $CHROM_LENGTHS{$chromosome};
      my $scale = $bp / ($chrom_stop - $chrom_start);

      # Some Clones might actually have positions on the chromosome
      # Let's try to fetch those first.
      # Have to parse the Map_position hash
      if (my $m = $component->Map) {
	my (@all) = $component->Position;
	foreach (@all) {
	  next unless ($_ eq 'Map');
	  my @tags = $_->right(2)->col;
	  my $right;
	  foreach (@tags) {
	    $offset = $_->right if $_ eq 'Left';
	    $right  = $_->right if $_ eq 'Right';
	  }
	  $length = $right - $offset;
	}
      } else {	
	# next; # Debugging
	($tag,$contig,$fmap_start,$fmap_stop) = $component->Position->row;
#	if (!$fmap_start || !$fmap_stop) {
#	  print STDERR "$component $component->class has no fmap coords\n";
#	  die;
#	}

	# Translate contig start and stop positions of the clone
	# into chromosome coordinates
	#      my ($contig_range_start,$contig_range_stop) = eval { $contig->Pmap->row };
	($contig_range_start,$contig_range_stop) = $contig->Pmap->row ;
	
	if ($contig_range_start > 0) {
	  print "$component $contig $fmap_start $fmap_stop\n";
	  die;
	}
	
	# Calculate the offset of the clone from the start of the contig
	# CAUTION - THIS MAY INTRODUCE AN OFF-BY-ONE SITUATION!
	$offset = $fmap_start - $contig_range_start;
	$length = ($fmap_stop - $fmap_start);
      }
      $start = int($offset  * $scale);
      $stop  = int(($offset + $length) * $scale);
      if (0) {
	print "Clone                  : $component\n";
	print "Contig coords          : $contig_range_start $contig_range_stop\n";
	print "Clone in contig coords : $fmap_start $fmap_stop\n";
	print "Clone offset, length   : $offset $length\n";
	print "Clone in base pairs    : $start $stop\n\n";
      }
      unless ($offset && $length && $start && $stop) {
	  warn "$component has no offset, length, start, stop";
	  next;
      }
    }

    $gmap_start = interpolate($start,$chromosome);
    $gmap_stop  = interpolate($stop,$chromosome);
    unless ($gmap_start && $gmap_start != 0 && $gmap_stop && $gmap_stop != 0) {
      warn "Couldn't fetch appropriate gmap coordinates for $component $start $stop";
      next;
    }

    my $canonical = join(', ',eval { $component->Canonical_for });
    # warn "$component $gmap_start $gmap_stop $start $stop";

    my $display_start = format_for_display($gmap_start);
    my $display_stop  = format_for_display($gmap_stop);
    my $note    = qq($display_start..$display_stop cM ($chromosome:$start..$stop));
#    $note      .= qq(; Canonical for $canonical) if $canonical;
    $gmap_start = scale($gmap_start);
    $gmap_stop  = scale($gmap_stop);

    my $source = $canonical ? 'canonical'
	: $class eq 'Contig' ? 'link'
	    : 'clone';

    push @{$rows->{$chromosome}},
	[$chromosome,$source,'region',
	 $gmap_start,$gmap_stop,'.','.','.',qq($class "$component" ; Note "$note")];
  }
}


sub fetch_variation_position {
  my $var = shift;
  my ($chrom,$position,$error);
  if ($var->Interpolated_map_position) {
    ($chrom,undef,$position) = $var->Interpolated_map_position(1)->row;
  } elsif ($var->Map) {
    ($chrom,undef,$position,undef,$error) = $var->Map(1)->row;
  }
  return ($chrom,$position,$error) if $chrom;
}

sub get_map_position {
  my $obj = shift;
  my ($chromosome,$type,$position);
  if ($obj->class eq 'Sequence' || $obj->class eq 'Clone') {
    ($chromosome) = $obj->Interpolated_map_position;
    $position     = $chromosome->right if $chromosome;
    return ($chromosome,$position,'interpolated_map_position') if $chromosome;
  } else {
    $chromosome = $obj->get(Map=>1);
    $position   = $obj->get(Map=>3);
    return ($chromosome,$position) if $chromosome;

    if (my $m = $obj->get('Interpolated_map_position')) {
      ($chromosome,$position) = $m->right->row;
      return ($chromosome,$position) if $chromosome;
    }
  }
}


# Fetch marker loci with both a gmap and pmap position
sub fetch_markers {
  print STDERR "Fetching markers with known genetic position...\n";
  my $pmap = {};
  my $total;
  my @loci = $db->fetch(-query=>qq{find Gene where Map AND (Species="Caenorhabditis elegans")});
  foreach (@loci) {
    my ($chrom,undef,$position,undef,$error) = eval{$_->Map(1)->row} or next;
    # Fetch the start and stop from GFF
    my $segment = $gff->segment(-class=>'Gene',-name=>$_) or next;;
    my $sourceseq = $segment->sourceseq;
    $segment->refseq($sourceseq);
    my $start   = $segment->abs_start;
    my $stop    = $segment->abs_stop;
    my $mean    = abs($start + $stop) / 2;
    push(@{$pmap->{$chrom}},{ name     => $_,
			      mean_pos => $mean,
			      gmap     => $position || '0.0000',
			      start    => $start,
			      stop     => $stop,
			      type     => 'marker'});
    $total++;
  }
  print STDERR "\ttotal genetic markers fetched: $total\n";
  return $pmap;
}

# Fetch all genes that lack pmap coordinates
# Will start here for simplicity
# This will only include genes that have two factor mapping data.
# Genes that only have three-factor data will not have a calculated position.
sub fetch_genes_lacking_pmap_coords {
  my $genes = {};
  print STDERR "Fetching genes lacking physical map coordinates...\n";
  my @genes = $db->fetch(-query=>qq{find Gene where Species="Caenorhabditis elegans" AND !Sequence_name});
  foreach (@genes) {
    next unless $_->Live(0);
    my ($chrom,undef,$position,undef,$error) = eval{$_->Map(1)->row};
    #   die "$chrom $_" unless ($chrom && $position && $error);
    #    print "$chrom $_\n";
    next unless $position && $chrom;
    $error    ||= 0;
    $position || '0.0000';
    push(@{$genes->{$chrom}},{ name   => $_,
			       gmap   => $position,
			       error  => $error,
			       upper  => $position + $error,
			       lower  => $position - $error,
			       type   => 'uncloned',
			     });
  }
  return $genes;
}






##### Subroutines modified from Michael Han for interpolating the PMap
##### onto the genetic map
sub build_pmap2gmap {
  my $gff_file = shift;
  $gff_file  ||= 'elegansWS151.gff';

  # Create a hash relating physical position to genetic position
  # of markers
  # hash->chromosomes->bp_coordinates->genetic_position
  my %bp2gmap; # gene -> phys_map
  #  my %gen_map = %{get_genetic_map()};
  #  open IN,$gff_file;
  #  while (<IN>){
  #    s/\"//g;
  #    my @a = split;
  #    next if !($a[1] eq 'gene' && $a[2] eq 'gene');
  #    my $gene_id = $a[9];
  #    next if ! $gen_map{$gene_id};
  #
  #    my $chrom = $a[0];
  #    # Create an average map position for this gene
  #    my $map_pos = ($a[3] + $a[4]) / 2;
  #    my $gen_pos = $gen_map{$gene_id};
  #
  #    $chrom=~s/CHROMOSOME_//;   # Not necessary for post-processed GFF
  #    # should be chromosome->map_pos->gen_pos
  #    $pmap2gmap{$chrom}->{$map_pos} = $gen_pos;
  #  }
  #  close IN;

  # Sort markers according to their physical map position
  my %sorted_map;
  foreach my $key ( keys %$pmap ) {
    foreach my $gene (sort { $a->{mean_pos} <=> $b->{mean_pos} } @{$pmap->{$key}}) {
      my $pos  = $gene->{mean_pos};
      push  @{$sorted_map{$key}},$pos;
      my $gmap = $gene->{gmap};
      $bp2gmap{$key}->{$pos} = $gmap;
    }
  }
  return (\%bp2gmap,\%sorted_map);
}

sub interpolate {
  my ($position,$chrom) = @_;
  my $last = 0;
  my $next = 0;
  return $bp2gmap->{$chrom}->{@{$sorted_map->{$chrom}}[0]} if $position < @{ $sorted_map->{$chrom} }[0];
  for ( my $i = 0 ; $i < scalar @{ $sorted_map->{$chrom} } ; $i++ ) {
    my $current  = @{ $sorted_map->{$chrom} }[$i];
    my $mlast    = $bp2gmap->{$chrom}->{$last};
    my $mcurrent = $bp2gmap->{$chrom}->{$current};

    #print "$last -> $mlast\t$current -> $mcurrent\n";
    $next = $current;
    if ( $position <= $current && $position >= $last ) {
      my $pdiff    = ( $last - $position ) / ( $current - $last ); # might wrong prefix
      my $mlast    = $bp2gmap->{$chrom}->{$last};
      my $mcurrent = $bp2gmap->{$chrom}->{$current};

      my $mpos = ( $mcurrent - $mlast ) * $pdiff + $mlast;
      return ($mpos);
    } elsif ($i == (scalar @{$sorted_map->{$chrom}} -1)&& $position >= $current) {
      # Last entries on the chromosome
      # Fuge factor - just return the lastmost genetic map point
      my $mcurrent = $bp2gmap->{$chrom}->{$current};
      return ($mcurrent);
#    } elsif ($last == 0 && $position <= $current) {
#      # First entries on the chromosome
#      # Fudge factor - just return the first genetic map point on the chrom
#      my $mlast    = $bp2gmap->{$chrom}->{$current};
#      return ($mlast);
    } else {
      $last = $current;
    }
  }

  # should be f(x)=dx/dy + x1
  # my $x1 = $last
  # my $y1 = $self->{'pmap'}->{$chr}->{$last};
  # my $x2 = $next
  # my $y2 = $self->{'pmap'}->{$chr}->{$next};
  #    my $f = sub { my $x = shift; return ( $x1 - $x2 ) / ( $y1 - $y2 ) + $x1 }
  return undef;
}
