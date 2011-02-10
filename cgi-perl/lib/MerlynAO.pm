package MerlynAO;

# $Id: MerlynAO.pm,v 1.1.1.1 2010-01-25 15:36:06 tharris Exp $
# This package is used by Randal Schwart'z GO browser.
# Humbly modified by T. Harris to support the Anatomy/Cell Ontology

use strict;

use lib ".";

use Ace;
use Ace::Browser::AceSubs qw(OpenDatabase AceError);
use Cache::FileCache;
require Exporter;
*import = \*Exporter::import;

use vars qw(@EXPORT $cache);
@EXPORT = (qw/
	   component_parents
	   instance_parents
	   component_children
	   instance_children
	   db
	   node_to_name
	   name_to_node
	   root_names
	   find_terms
	   a_term
	   a_association
	   total_descendents
	   isa_cell/);

$cache = Cache::FileCache->new
  ({namespace => 'AO',
    username => 'nobody',
    default_expires_in => '3 weeks',
    auto_purge_interval => '3 weeks',
   });

{
  my $db;			# database handle - cannot be cached

  sub db {
    return $db if $db and $db->status->{directory};
    $db = OpenDatabase() || AceError("Couldn't open database.");
  }
}

{
  my %name_to_node;		# object cache - cannot be memoized
  my $timeout_interval = 60;	# constant
  my $timeout = time + $timeout_interval; # "flush the cache" sentinel

  sub node_to_name {
    ($timeout, %name_to_node) = time + $timeout_interval if $timeout < time;
    my $node = shift;
    my $name = eval {$node->name} || $node;
    $name_to_node{$name} = $node;
    $name;
  }

  sub name_to_node {
    ($timeout, %name_to_node) = time + $timeout_interval if $timeout < time;
    my ($name,$class) = @_;
    my $flag = $class;
    $class ||= 'Anatomy_term';

    # Let's not cache empty return values of cell confirmations
    # This only occurs when I've passed a class...
    # Some queries (like hyp2) may return an array...
    # Right now, we fail to link these into cell.cgi
    if ($flag) {
      # The cell ontology uses dot nomenclature, but the cell entries do not
      $name =~ s/\.//g;
      my $fetched = db->fetch($class=>$name);
      $name_to_node{$name} = ($fetched) ? $fetched : undef;
    } else { # else is useless here...
      $name_to_node{$name} ||= db->fetch($class => $name);
    }
  }
}

sub one_or_many {
  wantarray ? @_ : $_[0];
}

sub nodes_to_names {
  map node_to_name($_), @_;
}

sub cache_one_or_many_names_at {
  my $cacheid = shift;		# prefix
  my $coderef = shift;		# given names, returns 0..n nodes
  ## warn "** cacheid = $cacheid, coderef = $coderef, rest = @_";
  my $cached = $cache->get($cacheid);
  if ($cached) {
    ## warn "** cache hit at $cacheid\n";
  } else {
    ## warn "** cache miss at $cacheid\n";
    $cached = [nodes_to_names($coderef->(@_))];
    $cache->set($cacheid, $cached);
  }
  one_or_many(@$cached);
}

sub root_names {
  cache_one_or_many_names_at
    ("root_names",
     sub { db->fetch(-query => 'find Anatomy_term !Parent', -fill => 1)});
}

sub find_terms {
  my $term = shift;
  $term =~ tr/"//d;
  cache_one_or_many_names_at
    ("find_terms $term",
     sub { db->fetch(-query => 'find Anatomy_term where term = "'.shift().'"') },
     $term);
}

# Configurable subroutines for component and instance children
# and parent relationships.  These will be used later to unveil
# other relationships that go beyond the GO.

# Parents
sub instance_parents {
  my ($term,$category) = @_;
  $category ||= 'PART_OF_p';
  my $result = name_to_node($term);
  cache_one_or_many_names_at
    ("instance_parents $term $category",
     sub { (name_to_node shift)->$category },$term);
}

# Cat one of IS_A_p
sub component_parents {
  my ($term,$category) = @_;
  $category ||= 'IS_A_p';
  cache_one_or_many_names_at
    ("component_parents $term $category",
     sub { (name_to_node shift)->$category }, $term);
}



# Children
sub instance_children {
  my ($term,$category) = @_;
  $category ||= 'PART_OF_c';
  cache_one_or_many_names_at
    ("instance_children $term $category",
     sub { (name_to_node shift)->$category }, $term);
}


# This is not correctly accounting for descendent_of relationships
sub component_children {
  my ($term,$category) = @_;
  $category ||= 'IS_A_c';
  cache_one_or_many_names_at
    ("component_children $term $category",
     sub { (name_to_node shift)->$category }, $term);
}

sub a_term {
  cache_one_or_many_names_at
    ("a_term $_[0]",
     sub { (name_to_node shift)->Term }, $_[0]);
}

#sub has_instance_children {
#  cache_one_or_many_names_at
#    ("a_term $_[0]",
#     sub { (name_to_node shift)->Term }, $_[0]);
#}


# This DOES NOT WORK
sub a_association {
  my $component = shift;
  cache_one_or_many_names_at
    ("a_association $component",
     sub {
       my $term = name_to_node($component);
       my %attributes;
        my @descendents = $term->Descendent(-fill=>'Attribute_of');
       for my $term (@descendents) {
	 next unless $term;
	 my @attributes = $term->Attribute_of;
	 for my $attr (@attributes) {
	   my @associations = $term->get($attr);
	   for my $a (@associations) {
	     my $key = join $;,($a->class,$a->name);
	     $attributes{$attr}{$key}++;
	   }
	 }
       }

       #$attributes{total} = scalar @descendents;
       $attributes{total} += keys %{$attributes{$_}} foreach keys %attributes;
       \%attributes;
     },
     $component);
}

sub total_descendents {
  my $term = shift;
#  my $descendents = eval { $term->Index->col };
  my $descendents = eval { $term->Descendent };
#  $descendents ||= 0;
  return $descendents;
}


# Have we reached a cell within the ontology?
sub isa_cell {
  my $component = shift;
  
  # Cache each of the independent calls to check if a component is a cell
  # Hyper-efficient - only requires a single load of P0
  my $cell = cache_one_or_many_names_at
    ("cell_definitions $component",
     sub { name_to_node($component,'Cell') });
  if ($cell ) {
    return $cell;
  } else {
    return undef;
  }
}



1;
