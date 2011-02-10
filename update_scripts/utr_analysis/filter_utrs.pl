#!/usr/bin/perl

# apply some sanity rules
# this runs on consolidated data set
use constant MAX_UTR => 5000;  # be very suspicious of any UTR larger than this length

my @data;
my $prev_group;

while (<>) {
  chomp;
  my ($group,$type,$ref,$start,$end) = split "\t";
  if (@data && $group ne $prev_group) {
    filter(@data);
    @data = ();
  }
  push @data,[$group,$type,$ref,$start,$end];
  $prev_group = $group;
}

filter(@data) if @data;

sub filter {
  my @data = @_;

  my ($cds_low,$cds_high);
  # find the CDS
  foreach (@data) {
    my ($group,$type,$ref,$start,$end) = @$_;
    if ($type eq 'CDS') {
      $cds_low  = $start < $end ? $start : $end;
      $cds_high = $start > $end ? $start : $end;
    }
  }

  foreach (@data) {
    my ($group,$type,$ref,$start,$end) = @$_;
    my $low  = $start < $end ? $start : $end;
    my $high = $start > $end ? $start : $end;
    next if  $cds_low - $low      > MAX_UTR;
    next if  $high    - $cds_high > MAX_UTR;
    print join("\t",@$_),"\n";
  }
  
}
