#!/usr/bin/perl
# file: dump_nucleotide.pl
# Dumps out a nucleotide file in FASTA format containing all
# the genomic segments.  Used for BLAST search script.

# This script often returns 3328.
# Bitshifted, this is system error 13, or permission denied.
# Is this a memory issue?
#      - ace logs look fine...
#      - dumped blast filt looks fine...
# Is this an issue with ace not releasing file descriptors?

use Ace;
# use Ace::Sequence;

# big memory structure!
#my %CACHE;

#my $return = system('ulimit -S -n 400');

my $database = shift;
my $out_file = shift;

# connect to database
if ($database) {
    $db = Ace->connect($database) || die "Couldn't open database";
} else {
    $db = Ace->connect(-host=>'localhost',-port=>2005) || die "Couldn't open database";
}

# find all genomic sequences that contain DNA
@sequences = $db->fetch(Genome_Sequence => '*');
die "Couldn't get any genome sequences" unless @sequences;

# iterate through them
my $debug_counter;

open (OUT, ">$out_file") or die "Cannot write file ($out_file): $!\n";
my $c;
foreach my $s (@sequences) {
	exit if $c++ == 10;
  # pull out interesting fields
  # the DNA
  next unless my $dna = $s->asDNA;
  $dna =~ s/>.*\n//;
  $dna =~ s/\n//g;

  # pull out identified or tentative genes
  # This isn't completely correct - some genes are not listed
  # under CDS_Child (nor were they listed under Subsequence).
  # Pre WS116
  # my @genes = $s->Subsequence;  # predicted/actual genes
  my @genes = $s->CDS_Child;  # predicted/actual genes
  my (%id,%tentative,$pruned);
  foreach (@genes) {
    # Ignore other additions to CDS_Child
    next if $_->Method eq 'Genefinder';
    $pruned++;
    my $gene = $_->fetch;
    $id{$gene->Brief_identification(1)}++ if $gene->Brief_identification;
#    $tentative{$gene->DB_remark(1)}++    if $gene->DB_remark;
    next if $gene->Brief_identification;

    next unless my $protein = $gene->Corresponding_protein;
    $protein = $protein->fetch;
    my $remark = $protein->Description(1) || $protein->Gene_name(1);
    $tentative{$remark}++ if $remark;
  }
  my @tentative = grep($_ && !$id{$_},keys %tentative);
  my @id        = keys %id;
  my ($gbk) = eval { $s->AC_number };
  #  my ($map) = $s->Clone->Map if $s->Clone;
  my $map;

  if (my ($start,$stop,$ref) = find_position($s)) {
    $map = "$ref/$start,$stop";
  }

  # memory problems
  #    if (my $seq = Ace::Sequence->new($s)) {
  #	$seq->absolute(1);
  #	$map = $seq->asString;
  #    }
$debug_counter++;
print STDERR "$debug_counter - [$s] ... \n";
  # print OUT a fasta file
  print OUT ">$s";
  print OUT " /gb=$gbk" if $gbk;
  print OUT " /cds=",$pruned;
  foreach (@id) {
    tr/\n/ /;  # no newlines!
    print OUT " /id=$_";
  }
  foreach (@tentative) {
    tr/\n/ /;  # no newlines!
    print OUT " /tentative_id=$_";
  }
  print OUT " /map=$map" if $map;
  print OUT "\n";
  $dna =~ s/(.{80})/$1\n/g;
  print OUT $dna,"\n";
#$debug_counter++;
#last if $debug_counter >1;
}
close OUT;
# I'm surprised that this works.
# exit evaluates the expression and exits with that value
# In this case, it evaluates 0, which is always false and so should
# never return 0.
#exit 0;
# It seems like either of these would make more sense.
#exit 0 if 1;
#exit;
1;#my $a = 1;

1;


sub find_position {
  my $s = shift;
  my ($abs_offset,$length,$prev) = (1,0);
  
  for ($prev=$s, my $o = get_source($s); $o; $prev=$o,$o = get_source($o)) {
    my @subs = $o->get('Subsequence');
    my ($seq) = grep $prev eq $_,@subs;
    $length ||= $seq->right(2) - $seq->right(1) + 1;
    $abs_offset += $seq->right-1;    # offset to beginning of sequence
  }
  return ($abs_offset,$abs_offset+$length-1,$prev);
}

sub get_source {
    my $s = shift;
#    return $CACHE{$s} ||= $s->Source;
    return $s->Source;
}

