#!/usr/bin/perl

# This script maps translated features to genomic coordinates
use strict;
use Bio::DB::GFF;
use Getopt::Long;
use Ace;
use Ace::Sequence;


# GFF Constants
use constant SOURCE       => 'translated_feature';
use constant METHOD       => 'motif_segment';
use constant SCORE        => '.';
use constant PHASE        => '.';

# Top-level feature for aggregation
use constant TOP_SOURCE   => 'translated_feature';
use constant TOP_METHOD   => 'Motif';


$|++;

my ($acedb,$host,$port,$help,$debug,$generate_gff,$format,$test);
GetOptions ('acedb=s'       => \$acedb,
            'host=s'        => \$host,
            'port=s'        => \$port,
            'help=s'        => \$help,
            'debug=s'       => \$debug,
            'test=i'        => \$test,
	    'generate_gff=s'  => \$generate_gff,
            'format=s'      => \$format,
           );

if ($help) {
  die <<END;
 Usage: interpolate_pmap_to_gmap.pl [options]

  Options:
  -acedb    Full path to acedb database to use (/usr/local/acedb/elegans)
    OR
  -host     Hostname of aceserver
  -port     Port of aceserver

  -debug    Boolean true to log debugging information
  -test     integer of number of tests to run

  -generate_gff boolean true to generate the gff output (true)
  -format    one of flat (a single span per motif) or segmented

END
}

$generate_gff ||= 'true';
$format       ||= 'segmented';


# Connect to ace and fetch the database version
print STDERR "\nConnecting to acedb: " . (($host) ? "$host:$port\n" : "$acedb\n");
$acedb        ||= '/usr/local/acedb/elegans';
my $DB = ($host)
  ? Ace->connect(-host=>$host,-port=>$port)
  : Ace->connect(-path=>$acedb);

my $version = $DB->status->{database}{version};

open GFF,">$version.motifs.gff" if $generate_gff;
open DEBUG,">$version.motifs.debug" if $debug;
open CONFIRM,">$version.motifs.protein_confirmation";

# We'll need the GFF database as well.
my $GFF = Bio::DB::GFF->new(-adaptor     => 'dbi::mysqlace',
			    -dsn         => "dbi:mysql:database=elegans;host=localhost",
			    -user        => 'root',
			    -pass        => 'kentwashere',
#			    -pass        => 'root',
			    -aggregators => [qw(processed_transcript{coding_exon/CDS})],
			   ) or die "$!";


#my @proteins = $DB->fetch(-query=>qq{find Protein "WP:CE28375"});  # + strand
#my @proteins = $DB->fetch(-query=>qq{find Protein "WP:CE28239"});  # - strand
#my @proteins = $DB->fetch(-query=>qq{find Protein "WP:CE00363"});  # - strand
my $i = $DB->fetch_many(Wormpep=>'*');
my $count;
## foreach my $protein (@proteins) {
# Track proteins with motifs that are split by exons
while (my $prot = $i->next) {
  exit if ($test && $count == $test);
  my $protein = $DB->fetch(Protein=>$prot);
  my (@cds) = $protein->Corresponding_CDS;
  my $cds;
  foreach (@cds) {
    next if /.*\:wp.*/;
    $cds = $_;
  }

  $count++;
  if ($count % 10 == 0) {
    print STDERR "Analyzing $protein: $count...";
    print STDERR -t STDOUT && !$ENV{EMACS} ? "\r" : "\n";
  }
  if ($debug) {
    print DEBUG "++++++++++++++++++\n";
    print DEBUG "Analyzing $protein\n";
    print DEBUG "++++++++++++++++++\n";
    print DEBUG "PARSING EXONS...\n";
    print DEBUG join("\t",qw/exon start stop abs_start abs_stop length modulus/),"\n";
  }
  
  print CONFIRM "++++++++++++++++++\n";
  print CONFIRM "Analyzing $protein\n";
  print CONFIRM "++++++++++++++++++\n";

  my %motifs = fetch_motifs($protein);

  my ($strand,$chrom,@exons) = fetch_exons($cds);

  # Calculate the genomic coordinates of each AA (by codon)
  my %aa2nt;
  my ($exon,$nt_carry,$codon_count,$previous_start);
  foreach (@exons) {
    $exon++;
    my $start = $_->abs_start;
    my $stop  = $_->abs_stop;

    my $modulus;
    if ($strand eq '-') {
      $modulus = (($start - $stop + $nt_carry + 1) % 3);
      if ($debug eq 'protein') {
	print DEBUG join("\t",$exon,$_->start,$_->stop,$start,$stop,($start - $stop),$modulus),"\n";
      }
      if ($nt_carry == 1) {
	$aa2nt{++$codon_count} = { start  => $previous_start,
				   middle  => $start,
				   end     => $start - 1,
				   exon    => [$exon - 1, $exon]};
	
	# Adjust the starting position
	$start = $start - 2;
      } elsif ($nt_carry == 2) {
	$aa2nt{++$codon_count} = { start  => $previous_start,
				   middle  => $previous_start - 1,
				   end     => $start,
				   exon    => [$exon - 1, $exon]};
	$start = $start - 1;
      }

      for (my $i=$start;$i>=($stop + $modulus);$i-=3) {
	$aa2nt{++$codon_count} = {
				  start  => $i,
				  middle => $i - 1,
				  end    => $i - 2,
				  exon   => [ $exon ],
				 };
      }
      $previous_start = ($stop + $modulus) - 1;
    } else {
      $modulus = (($stop - $start + $nt_carry + 1) % 3);
      if ($debug) {
	print DEBUG join("\t",$exon,$_->start,$_->stop,$start,$stop,($start - $stop),$modulus),"\n";
      }
      if ($nt_carry == 1) {
	$aa2nt{++$codon_count} = { start  => $previous_start,
				   middle => $start,
				   end    => $start + 1,
				   exon   => [$exon - 1, $exon]};
	
	# Adjust the starting position
	$start = $start + 2;
      } elsif ($nt_carry == 2) {
	$aa2nt{++$codon_count} = { start  => $previous_start,
				   middle => $previous_start + 1,
				   end    => $start,
				   exon   => [$exon - 1, $exon]};
	$start = $start + 1;
      }

      for (my $i=$start;$i<=($stop - $modulus);$i+=3) {
	$aa2nt{++$codon_count} = {
				  start  => $i,
				  middle => $i + 1,
				  end    => $i + 2,
				  exon   => [ $exon ],
				 };
      }
      $previous_start = ($stop - $modulus) + 1;
    }
    $nt_carry = $modulus;
  }

  # Confirm that the extracted nucleotide positions correspond to the spliced sequence;
  confirm($cds,$strand,$chrom,%aa2nt) if $debug;

  if ($debug) {
    print DEBUG "Codon positions by amino acid...\n";
    print DEBUG join("\t",qw/aa start_nt middle_nt end_nt exons_spanned/),"\n";
    foreach my $aa (sort {$a <=> $b} keys %aa2nt) {
      my %h = %{$aa2nt{$aa}};
      print DEBUG join("\t",$aa,$h{start},$h{middle},$h{end},@{$h{exon}}),"\n";
    }
  }

  my $protein_seq = strip_fasta($protein->asPeptide);
  print CONFIRM "\tTotal curated   aa : " . (length $protein_seq),"\n";
  print CONFIRM "\tTotal predicted aa : " . ((scalar keys %aa2nt) - 1),"\n";

  # Now, for each motif, fetch the genomic coordinates of the span
  print DEBUG "Fetching motif positions...\n";
  print DEBUG join("\t,",qw/ID motif_start motif_stop msg/),"\n";
  foreach my $type (keys %motifs) {
    my $id;
    foreach my $motif (@{$motifs{$type}}) {
      $id++;
      my ($motif_start,$motif_stop,$desc) = @{$motif};

      my $first_codon_start = $aa2nt{$motif_start}->{start};
      my $first_codon_end   = $aa2nt{$motif_start}->{end};
      my @first_codon_exons = eval { @{$aa2nt{$motif_start}->{exon}} };

      # Kludge in case I haven't fetched a full length product!
      unless ($first_codon_start && @first_codon_exons) {
	warn "incorrect protein length retrieved: $protein";
	next;
      }

      my $last_codon_start  = $aa2nt{$motif_stop}->{start};
      my $last_codon_end    = $aa2nt{$motif_stop}->{end};
      my @last_codon_exons  = eval { @{$aa2nt{$motif_stop}->{exon}} };

      # Kludge in case I haven't fetched a full length product!
      unless ($last_codon_end && @last_codon_exons) {
	warn "incorrect protein length retrieved $protein";
	next;
      }

      # Does the motif extend across an exon boundary?
      my %exons_spanned = map { $_ => 1; } @first_codon_exons,@last_codon_exons;
      my $exons_covered = join('-',sort {$a <=> $b } keys %exons_spanned);
      print DEBUG join("\t",$id,$motif_start,$motif_stop),"\n" if $debug;
      my %data = ( chrom   => $chrom,
		   protein  => $protein,
		   cds      => $cds,
		   type     => $type,
		   start    => $first_codon_start,
		   stop     => $last_codon_end,
		   aa_start => $motif_start,
		   aa_stop  => $motif_stop,
		   strand   => $strand,
		   score    => '',
		   id       => $id,
		   exons_covered => $exons_covered,
		   desc     => $desc,
		 );

      generate_gff(\%data,\%aa2nt) if $generate_gff;
    }
  }
}


sub generate_gff {
  my ($data,$aa2nt) = @_;
  my ($refseq,$protein,$cds,$type,$start,$stop,$mstart,$mstop,$strand,$score,$id,$exons_covered,$desc) =
    map { $data->{$_} } qw/chrom protein cds type start stop aa_start aa_stop strand score id exons_covered desc/;
  $strand ||= "+";
  $score  ||= SCORE;
  ($start,$stop) = ($stop,$start) if ($start > $stop);
  my $aarange = $mstart . '-' . $mstop;
  my $group  = qq{Motif "$protein-$type.$id"};
  $group =~ s/\:/_/g;
  my $full_group = qq{$group; Note "CDS:$cds" ; Note "Type:$type" ; Note "Range:$aarange" ; Note "Exons:$exons_covered"};
  $full_group .= qq{ ; Note "Description:$desc"} if $desc;
  if ($format eq 'segmented') {
    # Create a top-level entry to ensure aggregation
    print_gff($refseq,TOP_SOURCE,TOP_METHOD,$start,$stop,$score,$strand,PHASE,$full_group);
    print DEBUG "Creating segmented features...\n" if $debug;
    print DEBUG join("\t",qw/nt_start nt_middle nt_end current_start current_stop/),"\n" if $debug;
    # If the motif extends across multiple exons, create mulitple entries that can
    # be aggregated until a single feature
    if ((length $exons_covered) > 1) {  # Flag that this motif spans more than a single exon
      # if ($msg =~ /multiple/) {
      # Create an entry from mstop up to the end of the exon
      my $current_start = $aa2nt->{$mstart}->{start};
      my $current_stop  = $aa2nt->{$mstop}->{end};
      for (my $i=$mstart;$i<=$mstop;$i++) {
	my $nt_start  = $aa2nt->{$i}->{start};
	my $nt_middle = $aa2nt->{$i}->{middle};
	my $nt_end    = $aa2nt->{$i}->{end};
	if ($strand eq '-') {
	  print DEBUG join("\t",$nt_start,$nt_middle,$nt_end,$current_start,$current_stop),"\n" if $debug;
	  if (($nt_start - $nt_middle == 1) && ($nt_middle - $nt_end == 1)) {
	    if ($current_stop - $nt_start > 1) {
	      print_gff($refseq,SOURCE,METHOD,$current_start,$current_stop,$score,$strand,PHASE,$group);
	      $current_start = $nt_start;   # preserve current start for next iteration
	      $current_stop  = $aa2nt->{$mstop}->{end};
	      next;
	    }

	    $current_stop = $nt_end;
	    if ($i == $mstop) {   # The end of the motif, we are done
	      print_gff($refseq,SOURCE,METHOD,$current_start,$nt_end,$score,$strand,PHASE,$group);
	    }
	    next;
	  }
	  if ($nt_start - $nt_middle > 1) {
	    print_gff($refseq,SOURCE,METHOD,$current_start,$nt_start,$score,$strand,PHASE,$group);
	    $current_stop  = $aa2nt->{$mstop}->{end};
	    $current_start = $nt_middle;   # preserve current start for next iteration
	    next;
	  }
	  if ($nt_middle - $nt_end > 1) {
	    print_gff($refseq,SOURCE,METHOD,$current_start,$nt_middle,$score,$strand,PHASE,$group);
	    $current_stop  = $aa2nt->{$mstop}->{end};
	    $current_start = $nt_end;      # preserve current start for next iteration
	    next;
	  }
	  # Plus strand....
	} else {
	  print DEBUG join("\t",$nt_start,$nt_middle,$nt_end,$current_start,$current_stop),"\n" if $debug;
	  # warn join("\t",$nt_start,$nt_middle,$nt_end,$current_start,$current_stop),"\n";
	  if (($nt_end - $nt_middle == 1) && ($nt_middle - $nt_start == 1)) {
	    if ($nt_start - $current_stop > 1) {  # We've jumped ahead to the next exon
	      print_gff($refseq,SOURCE,METHOD,$current_start,$current_stop,$score,$strand,PHASE,$group);
	      $current_start = $nt_start;   # preserve current start for next iteration
	      $current_stop  = $aa2nt->{$mstop}->{end};
	      next;
	    }

	    $current_stop = $nt_end;
	    if ($i == $mstop) {   # The end of the motif, we are done
	      print_gff($refseq,SOURCE,METHOD,$current_start,$nt_end,$score,$strand,PHASE,$group);
	    }
	    next;
	  }
	  
	  if ($nt_middle - $nt_start > 1) {
	    print_gff($refseq,SOURCE,METHOD,$current_start,$nt_start,$score,$strand,PHASE,$group);
	    $current_stop  = $aa2nt->{$mstop}->{end};
	    $current_start = $nt_middle;   # preserve current start for next iteration
	    next;
	  }
	  if ($nt_end - $nt_middle > 1) {
	    print_gff($refseq,SOURCE,METHOD,$current_start,$nt_middle,$score,$strand,PHASE,$group);
	    $current_stop  = $aa2nt->{$mstop}->{end};
	    $current_start = $nt_end;      # preserve current start for next iteration
	    next;
	  }
	}
      }
    } else {
      print_gff($refseq,SOURCE,METHOD,$start,$stop,$score,$strand,PHASE,$group);
    }
    # NOT CREATING SEGMENTED FEATURES
  } else {
    print_gff($refseq,SOURCE,METHOD,$start,$stop,$score,$strand,PHASE,$full_group);
  }
}

sub print_gff {
  my ($ref,$source,$method,$start,$stop,@rest) = @_;
  ($start,$stop) = ($stop,$start) if ($start > $stop);
  print GFF join("\t",$ref,$source,$method,$start,$stop,@rest),"\n";
}



sub confirm {
  my ($cds,$strand,$chrom,%aa2nt) = @_;

  # Fetch the experimental splice
  my $spliced = $cds->asDNA;
  my $predicted_spliced;
  foreach my $aa (sort {$a <=> $b} keys %aa2nt) {
    my %h = %{$aa2nt{$aa}};
    my $start  = fetch_nt($chrom,$h{start});
    my $middle = fetch_nt($chrom,$h{middle});
    my $stop   = fetch_nt($chrom,$h{end});
    my $codon = "$start$middle$stop";
    $codon = complement($codon) if ($strand eq '-');
    $predicted_spliced .= $codon;
  }

  $spliced = strip_fasta($spliced);
  print CONFIRM "Spliced   : " . (length $spliced) . "\n";
  print CONFIRM "Predicted : " . (length $predicted_spliced) . "\n";

  if ((length $spliced) != (length $predicted_spliced)) {
    print CONFIRM "Spliced length != predicted spliced length\n";
    die;
  }

  if ($spliced ne $predicted_spliced) {
    print CONFIRM "Spliced sequence ne predicted spliced sequence\n";
    die;
  }
}


sub fetch_nt {
  my ($chrom,$pos) = @_;
  my $seg = $GFF->segment(-name=>$chrom,-start=>$pos,-stop=>$pos);
  my $dna = $seg->dna;
  return $dna;
}

sub complement {
  my $codon = shift;
  $codon =~ tr/ACGTacgt/TGCAtgca/;
  return $codon;
}

sub strip_fasta {
  my $seq = shift;
  my @lines = split("\n",$seq);
  my $clean;
  foreach (@lines) {
    next if /^>/;
    s/\n//g;
    $clean .= $_;
  }
  $clean ||= $seq;
  return $clean;
}

## Structural motifs (this returns a list of feature types)
# I should also grab the score when appropriate
sub fetch_motifs {
  my $protein = shift;
  my %motifs;

  # Structural features
  my @features = $protein->Feature;
  # Visit each of the features, pushing into an array based on its name
  foreach my $type (@features) {
    my %positions = map {$_ => $_->right(1)} $type->col;
    foreach my $start (keys %positions) {
      push (@{$motifs{$type}},[$start,$positions{$start}]);
    }
  }

  # Now deal with the Motif_homol features
  my @motif_homol = $protein->Motif_homol;
  foreach my $feature (@motif_homol) {
    my $title = eval {$feature->Title};
    my $type  = $feature->right or next;
    next if $type =~ /INTERPRO/;
    my @coord = $feature->right->col;
    my $name  = $title ? "$title ($feature)" : $feature;
    my ($start,$stop);
    for my $segment (@coord) {
      ($start,$stop) = $segment->right->row;
      $start = int $start;
      $stop  = int $stop;
      push (@{$motifs{$type}},[$start,$stop,$name]);
    }
  }
  return %motifs;
}

sub fetch_exons {
  my $cds = shift;
  my ($seq_obj) = $GFF->segment(CDS => $cds);
#  my @exons     = grep { $_->name eq $cds } $seq_obj->features('exon:curated') if $seq_obj;
  my ($gene)     = grep { $_->name eq $cds } $seq_obj->features('processed_transcript') if $seq_obj;
  my @exons = grep { $_->name eq $cds } $gene->features('coding_exon:curated') if $seq_obj;
  my @sorted = sort { $a->start <=> $b->start } @exons;
  my $strand;
  if ($sorted[0] ne '') {
    if ($sorted[0]->abs_start > $sorted[0]->abs_stop) {
      $strand = '-';
    }
  }
  # Return the chromosome as well
  my $ref = $seq_obj->sourceseq;
  return ($strand,$ref,@sorted);
}
