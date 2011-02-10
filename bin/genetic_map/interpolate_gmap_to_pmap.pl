#foreach my $chrom (qw(I II III IV V X)) {
#  # Sort all markers on the chromosome according to their genetic map position
#  my @sorted_markers = sort { $a->{gmap} <=> $b->{gmap} } @{$markers->{$chrom}};

  my %markers_by_pos;  # hash that relates markers to the position in the sorted array
  my $c = 0;
  foreach (@sorted_markers) {
    $markers_by_pos{$_->{name}} = $c;
    $c++;
  }

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

  # Maximal extents for the left and right sides
  my $minimal_left_gmap  = $left->{gmap};
  my $maximal_right_gmap = $right->{gmap};

  # Interpolate all the desired features into intervals
  my $leftmost_marker;
  foreach my $feature (sort { $a->{gmap} <=> $b->{gmap} } @{$to_map->{$chrom}},@{$markers->{$chrom}}) {
    my ($position,$fpmap_center,$fpmap_lower,$fpmap_upper,$lname,$lgmap,$lpmap,$rname,$rgmap,$rpmap);
    my $fname = $feature->{name};
    my $fgmap = $feature->{gmap};
    my $ftype = $feature->{type};
    my $ferror = $feature->{error};

    if ($ftype eq 'marker') {
      # Set the left edge to this marker for internal features
      $leftmost_marker = $feature;
      # Ignore those that are markers - no need to recalc a position!
      # next;
    }

    # First, deal with features that are before or after maximal markers
    # Will calculate map positions in relation to these markers
    if ($fgmap <= $minimal_left_gmap) {
      # Calculate the pmap position
      my $diff  = $minimal_left_gmap - $fgmap;
      $fpmap_center = $left->{mean_pos} - ($diff * $bp_per_unit);

      # This assumes that both positions are left of the marker
      #      $fpmap_lower = $left->{mean_pos} - (($minimal_left_gmap - $feature->{lower}) * $bp_per_unit);
      #      $fpmap_upper = $left->{mean_pos} - (($minimal_left_gmap - $feature->{upper}) * $bp_per_unit);
      $fpmap_lower = $fpmap_center - ($feature->{error} * $bp_per_unit);
      $fpmap_upper = $fpmap_center + ($feature->{error} * $bp_per_unit);

      # The "left" marker is really to the right
      $position = 'LEFT';
      $rname    = $left->{name};
      $rpmap    = $left->{mean_pos};
      $rgmap    = $left->{gmap};

      # Deal with features residing to the right of the maximal extent
    } elsif ($fgmap >= $maximal_right_gmap) {
      my $diff      = $fgmap - $maximal_right_gmap;
      $fpmap_center = $right->{mean_pos} + ($diff * $bp_per_unit);

      # Assuming both values are to the right of the maximal mean which might not be true
      # This approach will come in handy for interpolating three factor crosses.
      # $fpmap_lower  = $fmap_center - (abs(($feature->{lower} - $maximal_right_gmap)) * $bp_per_unit);
      # $fpmap_upper  = $right->{mean_pos} - (abs(($feature->{upper} - $maximal_right_gmap)) * $bp_per_unit);

      $fpmap_lower = $fpmap_center - ($feature->{error} * $bp_per_unit);
      $fpmap_upper = $fpmap_center + ($feature->{error} * $bp_per_unit);

      # The "right" marker is really to the left in these cases
      $position = 'RIGHT';
      $lname    = $right->{name};
      $lpmap    = $right->{mean_pos};
      $lgmap    = $right->{gmap};
    } else {
      # Calculate the interpolated position of markers flanked by two markers
      # What is the position of the current leftmost marker?
      my $pos = $markers_by_pos{$leftmost_marker->{name}};
      my $rightmost_marker = $sorted_markers[$pos+1];

      # What is the gmap range between these two markers?
      # Are we straddling the center of the chromosome?
      $lname  = $leftmost_marker->{name};
      $lgmap  = $leftmost_marker->{gmap} || '0';
      $lpmap  = $leftmost_marker->{mean_pos};

      $rname  = $rightmost_marker->{name};
      $rgmap  = $rightmost_marker->{gmap} || '0';
      $rpmap  = $rightmost_marker->{mean_pos};

      my $grange = $rgmap - $lgmap;
      my $prange = $rpmap - $lpmap;

      if ($grange == 0) { # No genetic difference between markers - set it equal to one of the markers
	$fpmap_center = $lpmap;
	#	$fpmap_lower = (($feature->{lower} - $lgmap) * $bp_per_unit) + $lpmap;
	#	$fpmap_upper = (($feature->{upper} - $lgmap) * $bp_per_unit) + $lpmap;
      } else {
	# Calculate the scale for this interval
	my $scale = $prange / $grange;
	# And then the difference between the current feature and the leftmost marker
	my $diff = $fgmap - $lgmap;
	$fpmap_center    = ($diff * $scale) + $lpmap;
	#	$fpmap_lower = (($feature->{lower} - $lgmap) * $bp_per_unit) + $lpmap;
	#	$fpmap_upper = (($feature->{upper} - $lgmap) * $bp_per_unit) + $lpmap;
      }

      $fpmap_lower = $fpmap_center - ($feature->{error} * $bp_per_unit);
      $fpmap_upper = $fpmap_center + ($feature->{error} * $bp_per_unit);

      # Simple error checking. The calculated pmap should be between the two markers
#      unless ($fpmap_center >= $lpmap && $fpmap_center <= $rpmap) {
#	die "Calculated gmap not in range: $lname $fname $rname - $lgmap $fgmap $rgmap\n";
#      }
      $position = 'INNER';
    }

    $fpmap_center = int $fpmap_center;
    $fpmap_lower  = int $fpmap_lower;
    $fpmap_upper  = int $fpmap_upper;

    $fgmap = sprintf("%8.4f",$fgmap);
    printf DEBUG ("%-6s %-4s %-15s %-15s %-15s %-10s %-10s %-10s %-9s %-9s %-9s\n",
		  $position,$chrom,
		  $lname || '-',$fname,$rname || '-',
		  $lpmap || '-',$fpmap_center,$rpmap || '-',
		  $lgmap || '-',$fgmap,$rgmap || '-') if $debug;

    # Generate the GFF file
    my ($status,$source);
    if ($ftype eq 'marker') {
      $fpmap_lower = $feature->{start};
      $fpmap_upper = $feature->{stop};
      $status = 'cloned';
      $source = 'absolute_pmap_position';
    } else {
      $status = 'uncloned';
      $source = 'interpolated_pmap_position';
    }

    my $public = $fname->Public_name;
    $ferror ||= '0.00';
    $ferror = sprintf("%2.2f",$ferror);

    # Adjust absurd coordinates
    $fpmap_lower = ($fpmap_lower < 1) ? 1 : $fpmap_lower;
    $fpmap_upper = ($fpmap_upper > $CHROM_LENGTHS{$chrom}) ? $CHROM_LENGTHS{$chrom} : $fpmap_upper;

    # Flip coords on the minus strand
    ($fpmap_lower,$fpmap_upper) = ($fpmap_upper,$fpmap_lower) if ($fpmap_upper < $fpmap_upper);
    print GFF join("\t",$chrom,$source,'gmap_span',$fpmap_lower,$fpmap_upper,'.','.','.',
		   qq(GMap $public ; Note "$fgmap cM (+/- $ferror cM)"; Note "$status")),"\n";
  }
}



sub fetch_two_point {
  my $two_point = {};
  print STDERR "Fetching genes lacking physical map coordinates...\n";
  my @map = $db->fetch(-query=>qq{find 2_point_data});
  foreach (@map) {
    my $pt1 = $_->Point_1;
    my $pt2 = $_->Point_2;
    my ($chrom,undef,$position,undef,$error) = eval{$pt1->Map(1)->row} or next;
    next unless $position;
    $position || '0.0000';
    push(@{$two_point->{$chrom}},{ name   => $_,
				   chrom  => $chrom,
				   gmap   => $position,
				   upper  => $position + $error,
				   lower  => $position - $error,
				   type   => 'two_point',
				 });
  }
  return $two_point;
}

# Fetch marker loci with both a gmap and pmap position
sub fetch_markers {
  print STDERR "Fetching markers with known genetic position...\n";
  my $markers = {};
  my $total;
  my @loci = $db->fetch(-query=>qq{find Gene where Map AND (Species="Caenorhabditis elegans")});
  foreach (@loci) {
    my ($chrom,undef,$position,undef,$error) = eval{$_->Map(1)->row} or next;
    # Fetch the start and stop from GFF
    my $segment = $dbgff->segment(-class=>'Gene',-name=>$_) or next;;
    my $sourceseq = $segment->sourceseq;
    $segment->refseq($sourceseq);
    my $start   = $segment->abs_start;
    my $stop    = $segment->abs_stop;
    my $mean    = abs($start + $stop) / 2;
    push(@{$markers->{$chrom}},{ name     => $_,
				 mean_pos => $mean,
				 gmap     => $position || '0.0000',
				 start    => $start,
				 stop     => $stop,
				 type     => 'marker'});
    $total++;
  }
  print STDERR "\ttotal genetic markers fetched: $total\n";
  return $markers;
}




###################################################
# get chrom length - as slight changes still occurs
###################################################
# TH: NOT UPDATED! These values are hard coded at the top of the script
sub get_chrom_lengths {
  my @dna_file = glob("/wormsrv2/autoace/CHROMOSOMES/CHROMOSOME_*.dna");
  my %chrom_length;
  foreach (@dna_file){
    my $line;
    my @line = `egrep "[atcg]" $_`;
    foreach (@line){chomp; $line .= $_}
    $_ =~ /.+CHROMOSOME_(\w+)\.dna/;
    my $chrom = $1;
    $chrom_length{$chrom} = length $line if $chrom ne "MtDNA";
  }
  foreach (sort keys %chrom_length){print INFO "$_ -> $chrom_length{$_} bp\n"}
}
