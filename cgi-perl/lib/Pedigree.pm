package Pedigree;

use strict;

# The pedigree variables ares structured like this:
#
#                               $mom
#                                |
#                       -------------------
#                       |                 |
#                    $sibling         $primary_cell
#                       |                 |
#               --------------        --------------
#               |            |        |            |
#           $nieces[0]    $nieces[1]  $daughters[0]   $daughters[1]
#

sub walk {
  my ($self,$primary_cell) = @_;

  # Need to handle the case when we are already at the top
  my $mom = $primary_cell->get(Parent=>1);

  # Fetch the daughters of the primary cell, if they exist
  my @daughters = $primary_cell->get('Daughter' =>1);

  if ($mom) {
    $mom = (ref $mom) ? $mom->fetch : $mom;
  }

  # Fetch siblings if we have a mom,
  # ignoring the primary_cell
  my $sibling;
  if ($mom && $mom ne $primary_cell) {
    my @siblings      = grep {$_ ne $primary_cell} $mom->get('Daughter');
    $sibling = $siblings[0];
  }

  # Fetch the nieces and nephews
  my @nieces;
  if ($sibling) {
    $sibling = $sibling->fetch;
    @nieces = $sibling->get('Daughter' => 1);
  }

  return ($mom,$sibling,(@daughters) ? \@daughters : undef,(@nieces) ? \@nieces : undef);
}


1;
