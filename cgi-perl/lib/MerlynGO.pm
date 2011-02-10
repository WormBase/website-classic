package MerlynGO;

# $Id: MerlynGO.pm,v 1.1.1.1 2010-01-25 15:36:06 tharris Exp $
# This package is used by Randal Schwart'z GO browser

use strict;

use lib ".";

use Ace;
use Ace::Browser::AceSubs qw(OpenDatabase AceError);
use Cache::FileCache;
require Exporter;
*import = \*Exporter::import;

use vars qw(@EXPORT); @EXPORT = ();

my $cache = Cache::FileCache->new
  ({namespace => 'GOterm',
    username => 'nobody',
    default_expires_in => '3 weeks',
    auto_purge_interval => '3 weeks',
   });

{
  my $db;			# database handle - cannot be cached

  push @EXPORT, 'db';
  sub db {
    return $db if $db and $db->status->{directory};
    $db = OpenDatabase() || AceError("Couldn't open database.");
  }
}

{
  my %name_to_node;		# object cache - cannot be memoized
  my $timeout_interval = 60;	# constant
  my $timeout = time + $timeout_interval; # "flush the cache" sentinel

  push @EXPORT, 'node_to_name';
  sub node_to_name {
    ($timeout, %name_to_node) = time + $timeout_interval if $timeout < time;
    my $node = shift;
    my $name = eval {$node->name} || $node;
    $name_to_node{$name} = $node;
    $name;
  }

  push @EXPORT, 'name_to_node';
  sub name_to_node {
    ($timeout, %name_to_node) = time + $timeout_interval if $timeout < time;
    my $name = shift;
    $name_to_node{$name} ||= db->fetch(GO_term => $name);
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

push @EXPORT, 'root_names';
sub root_names {
  cache_one_or_many_names_at
    ("root_names",
     sub { db->fetch(-query => 'find GO_term !Parent', -fill => 1)});
}

push @EXPORT, 'find_terms';
sub find_terms {
  my $term = shift;
  $term =~ tr/"//d;
  cache_one_or_many_names_at
    ("find_terms $term",
     sub { db->fetch(-query => 'find GO_term where term = "'.shift().'"') },
     $term);
}

push @EXPORT, 'i_parents';
sub i_parents {
  cache_one_or_many_names_at
    ("i_parents $_[0]",
     sub { (name_to_node shift)->Instance_of }, $_[0]);
}

push @EXPORT, 'c_parents';
sub c_parents {
  cache_one_or_many_names_at
    ("c_parents $_[0]",
     sub { (name_to_node shift)->Component_of }, $_[0]);
}

push @EXPORT, 'i_children';
sub i_children {
  cache_one_or_many_names_at
    ("i_children $_[0]",
     sub { (name_to_node shift)->Instance }, $_[0]);
}

push @EXPORT, 'c_children';
sub c_children {
  cache_one_or_many_names_at
    ("c_children $_[0]",
     sub { (name_to_node shift)->Component }, $_[0]);
}

push @EXPORT, 'a_term';
sub a_term {
  cache_one_or_many_names_at
    ("a_term $_[0]",
     sub { (name_to_node shift)->Term }, $_[0]);
}

push @EXPORT, 'a_association';
sub a_association {
  cache_one_or_many_names_at
    ("a_association $_[0]",
     sub {
       my $term = name_to_node(shift());
       my %attributes;
       my @descendents  = $term->Descendent(-fill=>'Attributes_of');
       for my $term (@descendents) {
	 next unless $term;
	 my @attributes = $term->Attributes_of;

	 for my $attr (@attributes) {
	    my @associations = $term->get($attr);

	   for my $a (@associations) {
	     my $key = join $;,($a->class,$a->name);
	     $attributes{$attr}{$key}++;
	   }

	 }

       }
       $attributes{total} += keys %{$attributes{$_}} foreach keys %attributes;
       \%attributes;
     },
     $_[0]);
}

1;
