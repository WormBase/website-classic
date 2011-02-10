package ElegansOligos;

use File::Temp qw(tempfile);

use constant EGREP => 'egrep';

sub new {
  my $class      = shift;
  my $oligo_file = shift || '/usr/local/ftp/pub/wormbase/DNA_DUMPS/unpacked/oligo.db';
  return bless {oligo_index=>$oligo_file},$class;
}

# return list in form ([chromosome,start,strand],...)
sub find {
  my $self  = shift;
  my $oligo = lc shift;
  my $reverse = reverse $oligo;
  $reverse =~ tr/gatc/ctag/;

  return $self->egrep($oligo,$reverse);
}

sub egrep {
  my $self = shift;
  my $db   = $self->{oligo_file};
  my ($forward,$reverse) = @_;
  my ($fh,$filename) = tempfile('oligos-XXXXXX',DIR=>'/usr/tmp');
  print $fh $forward,"\n";
  print $fh $reverse,"\n";
  close $fh;

  my @results;
  open (G,"${\EGREP} -i -f $filename $self->{oligo_index} |") or die "Can't grep: $!";
  while (<G>) {
    chomp;
    my ($ref,$offset,$dna) = split ':';
    foreach (find_sub($forward,\$dna)) {
      push @results,[$ref,$_+$offset+1,+1];
    }
    foreach (find_sub($reverse,\$dna)) {
      push @results,[$ref,$_+$offset+1,-1];
    }
  }
  unlink $filename if defined $filename;
  @results;
}

sub find_sub {
  my ($oligo,$dnaref) = @_;
  my $o = 0;
  my @result;
  while ((my $index = index($$dnaref,$oligo,$o)) >= 0) {
    $o = $index + 1;
    push @result,$index;
  }
  @result;
}


1;
