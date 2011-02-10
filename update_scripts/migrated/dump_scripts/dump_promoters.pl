#!/usr/bin/perl

use strict;
use Ace::Sequence;

use constant UPSTREAM => 2_500;  # how many bases upstream to do

warn "connecting...\n";
my $database = shift || 'sace://localhost:2005';
my $db = Ace->connect($database) or die "Can't connect: ",Ace->error,"\n";

warn "finding predicted genes...\n";
my @genes = $db->fetch(Predicted_Gene=>'*');

warn "found ",scalar(@genes)," predicted genes\n";

# create a sequence from each one and find the closest upstream transcript
for my $g (@genes) {
  my $s = Ace::Sequence->new(-seq    => $g,
			     -offset => -UPSTREAM(),
			     -length => UPSTREAM() 
			    ) 
    or die "Can't open sequence segment $g: ",Ace->error,"\n";

  my $dna = $s->dna;
  
  # find nearest upstream transcript
  if (my @foreign_sequences = 
      grep { $_->info =~ /\.t?\d+[a-z]?$/ and $_->info ne $g } $s->features('Sequence')) {
    my ($rightmost) = sort { $b->end <=> $a->end } @foreign_sequences;
    substr($dna,0,$rightmost->end) = '';  #truncate
  }

  print ">$g\n";
  $dna =~ s/(.{1,60})/$1\n/g;
  print $dna;
}
