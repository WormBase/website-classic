#!/usr/bin/perl
# dump out the genome into a series of files
# assumes that the link groups will be named CHROMOSOME_*

use Ace;
use strict;

use CGI qw/-noDebug :html :html3 *table/;
use Getopt::Long;
use vars qw/$HOST $PORT $PATH $MAX $DIR $DB/;
use vars qw/$SEGMENTS $GAPS $UNFINISHED $LOCI $CDS1 $CDS2 $BP/; # tallies

#use constant HOME          => 'http://www.wormbase.org';
use constant HOME          => '';    # relative addressing throughout
use constant BASE          => HOME . '/chromosomes';            # where the chromosome files live
use constant CGI_BASE      => HOME . '/db';
use constant MAILTO        => 'webmaster@wormbase.org';

use constant STYLESHEET    => HOME . '/stylesheets/wormbase.css';           # where stylesheet is relative to base
use constant SEQUENCE_LINK => CGI_BASE . '/seq/sequence?name=';
use constant DOWNLOAD      => CGI_BASE . '/misc/download_sequence?name=';
use constant GENE          => CGI_BASE . '/gene/locus?name=';
use constant NCBI          => 'http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=n&form=6&Dopt=g&uid=';
use constant SANGER        => HOME . '/mirrored_data/';
use constant SEARCH        => CGI_BASE . '/searches';
use constant DATE          => scalar localtime;

GetOptions(
	   'host=s'  => \$HOST,
	   'port=i'  => \$PORT,
	   'path=s'  => \$PATH,
	   'max=i'   => \$MAX,
	   'dir=s'   => \$DIR,
	  ) || die <<USAGE;
Usage: $0 [chromosome list]
  Dump out a genome into a series of tables suitable for AceBrowser
  displays.

 Options:
          -host  <host>    database host
          -port  <port>    database port
          -path  <path>    local database path
          -max   <int>     max length of each table (megabases)
          -dir   <dirctry> directory to dump into
USAGE
;

$HOST ||= $ENV{ACEDB_HOST} || 'localhost';
$PORT ||= $ENV{ACEDB_PORT} || 2005;
$DIR  ||= '.';
$MAX  ||= 2 unless defined $MAX;
$MAX  *= 1_000_000; # megabases to basepairs

$DB = $PATH ? Ace->connect(-path=>$PATH) : Ace->connect(-host=>$HOST,-port=>$PORT);
die "Can't connect to database ",Ace->error,"\n" unless $DB;

# change to dump directory
chdir ($DIR) or die "Can't change dir to $DIR: $!";
# loop through chromosomes
my @links;
@ARGV = qw/I II III IV V X/ unless @ARGV;

while (my $chr = shift) {

  my $superlink = $DB->fetch('Sequence'=>"CHROMOSOME_$chr") || $DB->fetch('Sequence'=>$chr);
  warn "not found: $chr\n" unless $superlink;
  push (@links,$superlink);
}

foreach (@links) {
  dump_sequence(\@links,$_);
}

# print summary
my $FINISHED = $SEGMENTS-$UNFINISHED-$GAPS;
print STDOUT scalar(localtime),"\n",<<END;
SEGMENTS PROCESSED = $SEGMENTS
FINISHED           = $FINISHED
UNFINISHED         = $UNFINISHED
GAPS               = $GAPS
PREDICTED CDS (1)  = $CDS1
PREDICTED CDS (2)  = $CDS2
ASSIGNED LOCI      = $LOCI
TOTAL BP           = $BP
END
;
  
sub dump_sequence {
  my $list = shift;
  my $link = shift;
  warn "dumping $link\n";

  my @seqs = linearize($link);

  # sort the sequences into two piles
  # @seqs holds just the genomic sequences
  my @genomic = grep $_->{'status'} ne 'cds', @seqs;  

  # @genes holds just genes that are attached to links/superlinks
  my @genes = grep $_->{'status'} eq 'cds', @seqs;

  # bump up the gene count in the main list
  distribute_genes(\@genomic,\@genes);

  # sort the list into a convenient set of bitesize pieces
  my (@chunks,$dna_length);
  if ($MAX) {
    foreach my $seq (@genomic) {
      my $page = int($seq->{'start'}/$MAX);
      push @{$chunks[$page]},$seq;
    }
  } else {
    @chunks = (\@seqs);
  }
  
  # create the navigation bar
  my @row;
  for my $group (@$list) {
    (my $label = $group) =~ s/^CHROMOSOME_//;
    if ($group ne $link) {
      push (@row,a({-href => "${group}a.html"},$label));
    } else {
      push (@row,font({-color=>'red'},$label));
    }
  }

  my $navbar = table(TR(th({-class=>'datatitle'},'Chromosome:'),td({-class=>'databody'},\@row)));

  for (my $i=0; $i<@chunks; $i++) {
    dump_table($navbar, "$link", $i, \@chunks);
  }

  symlink "${link}a.html","$link.html";

  # bump up the total number of base pairs processed
  $BP += $genomic[$#genomic]->{'end'} if @genomic;
}

# recursive function sorts and linearizes a complex
# set of sequence overlaps
sub linearize {
  my ($seq,$offset,$length) = @_;
  $offset ||= 1; 

  # If we're at a terminal sequence (a gap, a CDS or a clone with DNA)
  # then we just fetch its info and quit
  if (is_gap($seq) || $seq->DNA || $seq->CDS ) {
    return get_info($seq,$offset,$offset+$length-1);
  }

  # otherwise we sort the parts and call ourselves recursively,
  # giving the correct offset for this thing
  my @subseq = sort {$a->right <=> $b->right} $seq->get('Subsequence');

  my @result;
  foreach my $s (@subseq) {
    unless ($s->right){
      warn "$s is missing start!";
      next;
    }
    my ($st,$en) = $s->right->row;
    ($st,$en) = ($en,$st) if $st > $en; # flip
    push @result,linearize($s->fetch,$offset + $st - 1,$en - $st + 1);
  }

  return sort {$a->{start} <=> $b->{start}} @result;
}

# takes a sequence object and turns it into a hash ref
# containing the following fields:
# name start end genbank status cds_count position genes
sub get_info {
  my ($seq,$start,$end) = @_;
  my %h;  # will hold info
  $h{'name'}        = $seq->name;

  @h{qw/start end/} = ($start,$end);

  $h{'status'}      = 'finished' if $seq->Finished(0);
  $h{'status'}    ||= 'gap' if is_gap($seq);
  $h{'status'}    ||= 'cds' if $seq->CDS(0);
  $h{'status'}    ||= 'unfinished';

  $h{'genbank'}     = $seq->AC_number;
  if ( !$h{'genbank'} && (my $db_info = $seq->get('DB_Info')) ) {
    $h{'genbank'} = $db_info->at('Database[3]');
  }

  my @cds         = $DB->fetch(-query=>"find Sequence \"$seq\"; >Subsequence; CDS");
  $CDS2 += $h{'cds_count'} = @cds;

  $h{'position'}  = get_interpolated_position($seq);

  my %genes;
  # pre-WS116
  #  foreach ($seq->Locus_genomic_seq) {
  foreach ($seq->Locus) {
    $genes{$_}++;
  }
  # my @loci = $DB->fetch(-query=>"find Sequence \"$seq\"; >Subsequence; >Locus_genomic_seq");
  my @loci = $DB->fetch(-query=>"find Sequence \"$seq\"; >Subsequence; >Locus");

  foreach (@loci) {
    $genes{$_}++;
  }

  $h{'genes'}     = [keys %genes] if %genes;

  return \%h;
}

# distribute the genes among the sequences
# probably very slow the way I'm doing it
sub distribute_genes {
  my ($genomic,$genes) = @_;

  foreach my $gene (@$genes) {

    # find the extent of this gene
    my ($start,$end) = @{$gene}{'start','end'};
    my ($first,$last);
    for (my $i=0; $i<@$genomic; $i++) {
      next if $genomic->[$i]->{'end'}   < $start; # too far to the left
      last if $genomic->[$i]->{'start'} > $end;   # too far to the right
      $first ||= $i;
      $last    = $i;
    }
    next unless $first && $last;
    my $fragment = 1/($last-$first+1);  # divide into parts
    foreach (@{$genomic}[$first..$last]) {
      $_->{cds_count} += $fragment;
    }
  }
}

sub dump_table {
  my ($navbar,$title,$index,$chunks) = @_;

  # bookeeping
  my @list = @{$chunks->[$index]};
  my ($start,$end) = ($list[0]->{'start'},$list[$#list]->{'end'});

  # mini navigation bar for the various pages of the table
  my @cells;
  my @subscripts = ('a'..'z')[0..$#$chunks];

  for (my $i=0; $i<@$chunks; $i++) {
    my ($s,$e) = ($chunks->[$i]->[0]->{start},$chunks->[$i]->[$#{$chunks->[$i]}]->{end});
    add_commas($s,$e);
    my $label = "$s - $e";
    push @cells, 
         ($i != $index) ? a({-href=>"$title$subscripts[$i].html"},$label)
	                : font({-color=>'red'},$label);
  }

  my $pages = h3('Segment') . ol(li(\@cells));

  # start the HTML page
  my $subscript = $subscripts[$index];
  local *FH;
  open (FH,">${title}$subscript.html") || die "Can't open ${title}$subscript.html: $!\n";
  select FH;

  print start_html(
		   -Title => $title,
		   -Style => {-src => STYLESHEET},
#		   -xbase => BASE . "${title}$subscript.html",
		   ),"\n";

  (my $heading = $title) =~ s/CHROMOSOME_/Chromosome: /;
  (my $sanger_dna = $title) =~ s/CHROMOSOME_(.+)/CHROMOSOME_$1.dna.gz/;
  (my $sanger_gff = $title) =~ s/CHROMOSOME_(.+)/CHROMOSOME_$1.gff.gz/;

  print $navbar,"\n";
  add_commas($start,$end);
  print h1("$heading ($start - $end)"),"\n";
  print $pages,"\n";
  
  print
    p("See",a({-href=>'key'},'below'),'for table key.',br,
      'Download complete',
      a({-href=>SANGER . $sanger_dna},'DNA'),
      'or',
      a({-href=>SANGER . $sanger_gff},'feature table'),
      'from the Sanger Centre.');
  
  print start_table({-cellspacing=>0, -border=>1}),"\n";
  # pull out data
  print TR({-class=>'datatitle'},
	   th([
	       a({-href=>'#segment'},'Segment'),
	       a({-href=>'#length'},'Length'),
	       a({-href=>'#name'},'Name'),
	       a({-href=>'#genbank'},'Genbank'),
	       a({-href=>'#status'},'Status'),
	       a({-href=>'#cds'},'# CDS'),
	       a({-href=>'#gpos'},'Genetic Pos',),
	       a({-href=>'#loci'},'Loci')
	      ]));
  print TR({-class=>'datatitle'},td(a({-href=>"$title$subscripts[$index-1].html"},'Previous page')))
    unless $index == 0; 

  foreach my $seq (@list) {
    my ($name,$start,$end,$genbank,$status,$cds,$position,$genes) = 
      @{$seq}{qw(name start end genbank status cds_count position genes)};

    # run tallies now
    $SEGMENTS++;
    $GAPS++        if  $status eq 'gap';
    $UNFINISHED++  if  $status eq 'unfinished';
    $LOCI          += @$genes if $genes;
    $CDS1          += $cds;  # this one will have roundoff error

    my $length = $end - $start + 1;
    my ($seq_link,$ncbi,$span);
    $seq_link =            a({-href => SEQUENCE_LINK . $name,-name => $name},   $name);

    unless ($status eq 'gap') {
      $ncbi     = $genbank ? a({-href => NCBI . $genbank},         $genbank) : '&nbsp;';
      $span     =            a({-href => DOWNLOAD . $name},"$start-$end");
      $genes    = join(' ', 
		       map { a({-href => GENE.$_},$_) } @$genes);
      $genes ||= '&nbsp;';
    }

    # note: this changes argument list in-place
    add_commas($start,$end);

    # anything that isn't set here becomes a <BR> in order to maintain
    # consistent colors across table rows
    $span     ||= '&nbsp;'; 
    $length   ||= '&nbsp;'; 
    $status   ||= '&nbsp;'; 
    $genes    ||= '&nbsp;'; 
    $position ||= '&nbsp;';
    $ncbi     ||= '&nbsp;';
    $length   ||= '&nbsp;';

#    my %opts;
#    %opts = (-Class=>'unfinished') if $status eq 'unfinished';
#    %opts = (-Class=>'gap')        if $status eq 'gap';

    print TR({-class=>'databody'},          #\%opts,
	     td([$span,
		 $length,
		 $seq_link,
		 $ncbi,
		 $status,
		 ($cds=~/\./) ? sprintf("&nbsp;%2.1f",$cds) : "&nbsp;$cds",
		 $position,
		 $genes])),"\n";
  }

  print TR({-class=>'datatitle'},
	   td(a({-href=>"$title$subscripts[$index+1].html"},'Next page')))
    if $index < $#$chunks;

  print end_table,"\n";
  
  print_bottom();
  print end_html;
  close FH;
}

sub add_commas {
  foreach (@_) {
    $_ = reverse $_;
    s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    $_ = reverse $_;
  }
}

sub is_gap {
  return $_[0] =~ /(\b|_)E?GAP\d*(\b|_)/i
}

sub get_interpolated_position {
  my $obj = shift;
  my $f;

  if (($f) = $obj->get('Interpolated_gmap')) {
    my ($chromosome,$position) = $f->row;
    return $position;
  }

  return;
}

sub print_bottom {
  print
    h2('Explanations and Caveats'),"\n",
    p('The',cite('C. elegans'),'genome was sequenced by determining the overlap of a set',
      'of 20,000 cosmids, finding a minimal tiling path for the cosmids, and then submitting',
      'them to shotgun sequencing.  The organization of the sequence segments shown in this',
      'table reflects this sequencing scheme. Each segment is related to the cosmid from which',
      'its sequence was derived, although the relationship is not quite one to one.'),"\n",
    p('This summary table was dumped from the ACEDB database on',
      scalar(localtime),'. The data was still partly in flux at this point; a few clones had not',
      'been finished and certain pieces of information, for example GenBank/EMBL accession numbers',
      'were missing.'),"\n";

  print
    h2(a({-name=>"key"},'Table Key')),
    dl(
       dt(a({-name=>"segment"},b('Segment'))),
       dd('Position of the subsequence, expressed in base pairs.',
	  'Positions are not exactly the same as the ends of sequenced clones',
	  'as they have been adjusted somewhat in order to minimize overlaps',
	  'between adjacent clones, and in some cases to avoid introducing',
	  'breaks within known or predicted genes.'),"\n",

       dt(a({-name=>"length"},b('Length'))),
       dd('Size of the segment expressed in base pairs.',
	  'Selecting this link will download the segment\'s DNA',
	  'in FASTN format.'),"\n",

       dt(a({-name=>'name'},b('Name'))),
       dd('Name of the sequence segment; usually the same as the clone name.',
	  'Selecting this link will display a page that provides more detailed',
	  'information about the sequence.'),"\n",

       dt(a({-name=>'Genbank'},b('Genbank'))),
       dd('Genbank/EMBL accession number, if submitted.'),"\n",

       dt(a({-name=>"status"},b('Status'))),
       dd('Sequencing status.  Sequences may be',
	  cite('finished'),'or',cite('unfinished.'),
	  'There may also be a',cite('gap'),
	  'indicating that a segment was unclonable or unsequencable.',
	  'Most gaps are of known size as indicated by the length column.'),"\n",

       dt(a({-name=>"cds"},b('# CDS'))),
       dd('Number of confirmed and predicted coding regions on this sequence.',
	  '"Fractional" genes arise when a gene spans two or more segments.'),"\n",

       dt(a({-name=>'gpos'},b('Genetic Pos'))),
       dd('Approximate position on the genetic map, expressed in cM.',
	  'These positions are estimated by linear interpolation from',
	  'the positions of genetic loci known to be present on the sequence,',
	  'and their accuracy depends on multiple factors.'),"\n",

       dt(a({-name=>"loci"},b('Loci'))),
       dd('Genetic loci that have been identified on this sequence.'),"\n",
      );
}
