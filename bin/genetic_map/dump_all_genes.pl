#!/usr/bin/perl

# Dump out all markers into a flat file for subsequent processing

use Ace;
use Bio::DB::GFF;
use Getopt::Long;
use lib '/usr/local/wormbase/bin/genetic_map';
use GMap;
use strict;

$|++;
open KLUDGE,">kludge.txt";

#use constant SCALING_FACTOR => 10000;
use constant SCALING_FACTOR => 1000000;

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
	    'version=s'    => \$version,
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
			    -dsn         => "dbi:mysql:database=elegans_$version;host=localhost",
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
  dump_confidence_intervals($chrom);
  dump_variations($chrom);
  dump_rearrangements($chrom);
  dump_clones($chrom);

  # Artificially create a sequence segment corresponding to the
  # maximal features that we have found
  my @sorted = sort { $a->[3] <=> $b->[3] } @{$rows->{$chrom}};
  my $start = $sorted[0]->[3];
  my $stop  = $sorted[-1]->[4];
  print join("\t",$chrom,'Sequence','Sequence',$start,$stop,'.','.','.',qq{Sequence "$chrom"}),"\n";

  foreach (@sorted) {
    print join("\t",@$_),"\n";
  }
}

# Scale values as appropriate for the DB
sub scale {
    my $value = shift;

# debugging scaling: problem with Bio::DB::GFF
#    $value = $value * SCALING_FACTOR;
#    my $scaled = sprintf("%8.0f",$value);
#    warn "$value $scaled\n";
#    return $scaled;


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
  my %seen;
  foreach (@genes,@interpolated) {
    next if $seen{$_}++;
    next unless $_->Species eq 'Caenorhabditis elegans';
    my $segment = eval { $gff->segment(CDS=>$_) };
    my ($start,$stop,$strand);
    if ($segment) {
      $segment->absolute(1);
      $start          = $segment->start;
      $stop           = $segment->stop;
      $strand         = $segment->strand;
    }
    my $public_name    = $_->Public_name;
    my $molecular_name = $_->Molecular_name;
    my $cgc_name       = $_->CGC_name;
    my ($chrom,$map,)  = get_map_position($_);
    print STDERR "$_; $chrom:$map ; CGC: $cgc_name; MOL: $molecular_name; $start..$stop $strand\n";
    next if kludge($_,$map);
    ($molecular_name) = $molecular_name =~ /(.*.\d+)/;
    
    # Three possible types
    # 1. Molecular genes interpolated onto the genetic map (mol_name eq public_name)
    # 2. Genetic markers that do not yet exist on pmap (cgc_name && !mol_name)
    # 3. Genetic markers that exist on pmap too (cgc_name && mol_name);
    my $method;
    if ($_->Molecular_name eq $public_name && !$cgc_name) {
      $method = 'interpolated_gmap_position';
    } elsif ($cgc_name && !$molecular_name) {
      $method = 'experimental_gmap_position';
    } elsif ($cgc_name && $molecular_name) {
      $method = 'cloned_mutant';
    } else {   # molecular_name but no cgc_name
      $method = 'interpolated_gmap_position';
    }
    
    push @markers,{ chrom          => $chrom,
		    molecular_name => $molecular_name, # || 'not known',
		    cgc_name       => $cgc_name, #       || 'none assigned',
		    start          => $start,
		    #		    stop           => $stop + 1,  # FUDGE FACTOR: 0 length features are ignored by DB....
		    stop           => $stop,
		    strand         => $strand,
		    gmap           => $map,
		    method         => $method,
		    name           => $_,
		  };
    
    $count++;
    if ($count % 10 == 0) {
      print STDERR "Processing gene $count...";
      print STDERR -t STDOUT && !$ENV{EMACS} ? "\r" : "\r";
    }
  }
  
  foreach (sort { $a->{start} <=> $b->{start} } @markers) {
    #    next if $_[8] eq 'interpolated';   # Ignore interpolated markers for now
    my $scaled = scale($_->{gmap});
    my $display_gmap = format_for_display($_->{gmap});
    
    if (defined $landmarks{$_->{cgc_name}}) {
      push @{$rows->{$chrom}},[$_->{chrom},'landmark','gene',
			       $scaled,$scaled+1,'.','.','.',"Locus " . $_->{cgc_name}];
    }
    
#    my $group = ALLMARKERS_GROUP . qq( "$_->{name}"); 
    my $group = ALLMARKERS_GROUP;
    if ($_->{method} eq 'interpolated_gmap_position' || $_->{method} eq 'cloned_mutant') {
	$group .= qq( "$_->{cgc_name}");
    } else {
	$group .= qq( "$_->{molecular_name}");
    }
    
    
    # Add some notes to facilitate the markers search
    # There is some redundancy here because I want to be able to use
    # names as both search aliases (ie Note "") as well as named parameter style
    my @notes;
    #      my @tmp = $_->{molecular_name} if $_->{molecular_name};
    #      push @tmp,$_->{cgc_name} if $_->{cgc_name};
    #      my $notes = join(' ; ',@tmp);
    #      push @notes,('Note "' . $notes . '"') if $notes;
    
    my $display_gmap = format_for_display($_->{gmap});
    
    # Make entries searchable by including a note field
    my @note_field;
    push @note_field,$_->{molecular_name} if $_->{molecular_name};
    push @note_field,$_->{cgc_name} if $_->{cgc_name};
    my $notes = ('Note "' . join('; ',@note_field) . '"') if @note_field > 0;

# Format notes by name instead
#    push @notes,'Gene "' . $_->{name};
#    push @notes,'Note "' . $_->{molecular_name} . '"' if $_->{molecular_name};
#    push @notes,'Note "' . $_->{cgc_name} . '"' if $_->{cgc_name};
#
#    # Include some named attributes for ease of formatting
#    push @notes,'GMap_position "' . $display_gmap . '"';
#    push @notes,('PMap_range "' . $_->{chrom} . ':' . $_->{start} . '..' . $_->{stop} . '"')
#      if ($_->{method} eq 'interpolated_gmap_position' || $_->{method} eq 'cloned_mutant');
#    push @notes,('Sequence_name "' . $_->{molecular_name} . '"') if ($_->{molecular_name});
#    push @notes,('CGC_name "' . $_->{cgc_name} . '"') if ($_->{cgc_name});
#    my $notes = join(' ; ',@notes);

    push @{$rows->{$chrom}},[$_->{chrom},ALLMARKERS_SOURCE,$_->{method},
			     $scaled,$scaled+1,'.','.','.',$group . " ; $notes"];
  }
}


# Dump confidence intervals for all uncloned genes
sub dump_confidence_intervals {
  my $chrom = shift;
  print STDERR "Dumping confidence intervals on $chrom...\n";
  foreach my $feature (sort { $a->{gmap} <=> $b->{gmap} } @{$to_map->{$chrom}}) {
    my ($position,$fpmap_center,$fpmap_lower,$fpmap_upper,$lname,$lgmap,$lpmap,$rname,$rgmap,$rpmap);
    my $fname = $feature->{name};
    my $fgmap = $feature->{gmap};
    my $ftype = $feature->{type};
    my $ferror = $feature->{error};
    my $public = $fname->Public_name;

    # Print out confidence intervals for uncloned genes *only*
    # These will be used on the genetic map
    if ($ftype eq 'uncloned') {
      my $start = scale($fgmap - $ferror);
      my $stop  = scale($fgmap + $ferror);

      my $display_start = format_for_display($fgmap - $ferror);
      my $display_stop  = format_for_display($fgmap + $ferror);
      next if kludge($fname,$display_start);
      next if kludge($fname,$display_stop);

      my $group = CONFIDENCE_INTERVALS_GROUP . qq( "$fname" ; Note "$public");
      my $display_fgmap = format_for_display($fgmap);
      if ($ferror != 0) {
	my $display_ferror = format_for_display($ferror);
	$group .= qq( ; GMap_range "$display_fgmap cM (+/- $display_ferror cM)");
      } else {
	$group .= qq( ; GMap_range "$display_fgmap cM");
      }

      push @{$rows->{$chrom}},
	[$chrom,CONFIDENCE_INTERVALS_SOURCE,CONFIDENCE_INTERVALS_METHOD,
	 $start,$stop,'.','.','.',$group];
    }
  }
}



# Categories
# Predicted SNPs
# Confirmed SNPs
# Predicted Snip-SNPs
# Confirmed Snip-SNPs
sub dump_variations {
  my $chromosome  = shift;
  print STDERR "Dumping variations on $chromosome...\n";
  my %seen;
  my @variations   = grep {!$seen{$_}++ } $db->fetch(-query=>qq[find Variation SNP Map = "$chromosome"]);
  push @variations,
  grep { !$seen{$_}++ }
  $db->fetch(-query=>qq[find Variation SNP Interpolated_map_position = "$chromosome"]);
  
  # Pick up plain 'ole vanilla variations
  push @variations,
  grep { !$seen{$_}++ }
  $db->fetch(-query=>qq[find Variation Interpolated_map_position = "$chromosome"]);

  push @variations,
  grep { !$seen{$_}++ }
  $db->fetch(-query=>qq[find Variation Map = "$chromosome"]);
  
  # my @variations = $db->fetch(-query=>qq{find Variation SNP});
  foreach (@variations) {
#      next unless $_->Species =~ /elegans/;
      my ($chrom,$position,$note) = fetch_variation_position($_);
      next unless ($chrom && $position);
      next unless ($chrom eq $chromosome);
      next if kludge($_,$position);
      
      my $notes = format_for_display($position);
      $position = scale($position);
      
      my ($source,$method);
      if ($_->SNP(0)) {
	  $source = ($_->Confirmed_SNP(0)) ? 'verified' : 'predicted';
	  $method = ($_->RFLP)     ? 'rflp_polymorphism' : 'polymorphism';
      } else {
	  $method = 'allele';
	  $source = lc($_->Type_of_mutation) || 'molecular_change_unknown';
      }
      
      push @{$rows->{$chrom}},[$chrom,$source,$method,$position,$position+1,'.','.','.',
			       qq(Variation "$_" ; GMap_position "$notes")];
  }
  return @variations;
}


sub dump_rearrangements {
  my $chrom = shift;
  print STDERR "Dumping rearrangements on $chrom...\n";

  # Maybe users entered a chromosome
  my @rearg = $db->fetch(-query=>qq{find Rearrangement where Map="$chrom"});
  foreach (@rearg) {
    my ($type,$param)  = eval { $_->Type->row };
    $type = ($_ =~ /.*Df.*/) ? 'Deletion' : $type unless $type;
    my $genes_in  = $_->Gene_inside;
    my $genes_out = $_->Gene_outside;

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
	  next if kludge($_,$display_start);
	  next if kludge($_,$display_stop);

	  my $group = qq{Rearrangement "$_"};
	  my @notes = '; GMap_range "' . "$chr: $display_start..$display_stop" . '"';
	  push @notes,'Type "' . $param . '"' if ($param);
	  push @notes,'GMap_position "' . $display_start . '"' if $display_start;
	  $group .= join(' ; ',@notes);
	  push @{$rows->{$chr}},[$chr,
				 lc($type),
				 'rearrangement',
				 scale($start),
				 scale($stop),
				 '.',
				 '.',
				 '.',
				 $group,
				];

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

  # Get all the fosmids too
  push @clones,$db->fetch(-query=>qq{find Sequence Method="Vancouver_fosmid"});

  my %unique = map {$_ => $_} @clones,@all_contigs,$obj->Clone,$obj->Sequence;

  foreach (keys %unique) {
    my $component = $unique{$_};
    my ($start,$stop,$gmap_start,$gmap_stop);
    my $class = $component->class;
    if ($class eq 'Sequence') {
      # next;  # Debugging

      my ($chrom,$position,$type) = get_map_position($component);
      next if kludge($component,$position);
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
    $source = 'Vancouver_fosmid' if eval { $component->Method } eq 'Vancouver_fosmid';

    push @{$rows->{$chromosome}},
	[$chromosome,$source,'region',
	 $gmap_start,$gmap_stop,'.','.','.',qq($class "$component" ; GMap_range "$note")];
  }
}


sub fetch_variation_position {
  my $var = shift;
  my ($chrom,$position,$error);
  if ($var->Interpolated_map_position) {
    #   ($chrom,undef,$position) = $var->Interpolated_map_position(1)->row;
    ($chrom,$position) = $var->Interpolated_map_position(1)->row;
  } elsif ($var->Map) {
    ($chrom,undef,$position,undef,$error) = $var->Map(1)->row;
  }
  return ($chrom,$position,$error) if $chrom;
}

sub get_map_position {
  my $obj = shift;

  #  my ($chromosome,undef,$position,undef,$error) = eval{$_->Map(1)->row};
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
      ($chromosome,$position) = $obj->Interpolated_map_position(1)->row if $obj->class eq 'Variation';
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



# Kludge for some seriously wacked out values
sub kludge {
    my ($feat,$map) = @_;
    
    if ($map > 35 || $map < -35) {
	print KLUDGE "$feat $map\n";
	return 1;
    }
}
