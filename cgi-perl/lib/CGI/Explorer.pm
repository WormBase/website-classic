package CGI::Explorer;

use strict;
use CGI qw(:standard);
use Tree::DAG_Node;

sub new {
  my $class = shift;
  my %options = @_;

  my $hilite   = $options{-hilite};
  my $opm      = $options{-open}    || 'o';
  my $cpm      = $options{-close}   || 'c';
  my $spm      = $options{-search}  || 's';
  my $mOpen    = $options{-mopen}   || '/images/menu-images/menu_corner_minus.gif';
  my $mClosed  = $options{-mclosed} || '/images/menu-images/menu_corner_plus.gif';
  my $mTee     = $options{-mtee}    || '/images/menu-images/menu_tee.gif';
  my $mBar     = $options{-mbar}    || '/images/menu-images/menu_bar.gif';
  my $mCorner  = $options{-mcorner} || '/images/menu-images/menu_corner.gif';
  my $mLeaf    = $options{-mleaf}   || '/images/menu-images/menu_leaf.gif';
  my $mFill    = $options{-mfill}   || '/images/menu-images/menu_blank.gif';

  my $spawn    = $options{-relate}  || return "no -relate  provided";
#  my $nodes    = $options{-nodes}   || return "no -nodes   provided";
  my $label    = $options{-labels}  || return "no -label   provided";
  my $mother   = $options{-mothers} || return "no -mothers provided";

  my $root = build_tree($spawn,$label,$mother); #$nodes

  my %o = map {$_=>1} param($opm);
  my %c = map {$_=>1} param($cpm);
  my %h = map {$_=>1} @$hilite or ();

  bless my $self = {
	      'root'    => $root,
	      'opm'     => $opm,
	      'cpm'     => $cpm,
	      'spm'     => $spm,
	      'mOpen'   => $mOpen,
	      'mClose'  => $mClosed,
	      'mTee'    => $mTee,
	      'mBar'    => $mBar,
	      'mCorner' => $mCorner,
	      'mLeaf'   => $mLeaf,
	      'mFill'   => $mFill,
	      'opened'  => \%o,
	      'closed'  => \%c,
	      'hilited' => \%h,
	     }, $class;

  $self->process_args;

  return $self;
}

sub process_args {
  my $self = shift;
  if(param($self->{spm})){
    Delete($self->{opm});
    Delete($self->{cpm});
  }
  if(param($self->{opm}) or param($self->{cpm})){
    Delete($self->{spm});
  }
}

sub build_tree {
  my($spawn,$label,$mom) = @_; #$nodes
  my %seen;
  my $root;

  #add the mothers in lineage
  foreach my $mother (sort {$a cmp $b} keys %{$spawn}){
    my $mnode;
    if((ref $seen{$mother}) eq 'Tree::DAG_Node'){
      $mnode = $seen{$mother};
    } else {
      $mnode = Tree::DAG_Node->new;
      $mnode->name($mother);
      $mnode->attribute->{label}     = $label->{$mother};
      $mnode->attribute->{is_mother} = 1 if $mom->{$mother};
      $seen{$mother} = $mnode;
    }

    #add the daughters in lineage, as well as sisters
    foreach my $daughter (sort {$a cmp $b} keys %{$spawn->{$mother}}){
      my $dnode;

      if((ref $seen{$daughter}) eq 'Tree::DAG_Node'){
	$dnode = $seen{$daughter};
      } else {
	$dnode = Tree::DAG_Node->new;
	$dnode->name($daughter);
	$dnode->attribute->{label}     = $label->{$daughter};
	$dnode->attribute->{is_mother} = 1 if $mom->{$daughter};

	$seen{$daughter} = $dnode;
      }
      $mnode->add_daughter($dnode);
    }

    $mnode->set_daughters(map  {$_->[0]}
			  sort {$a->[1] cmp $b->[1]}
			  map  {[$_,$_->attribute->{label}]} $mnode->daughters
			 );

    $root = $mnode->root;
  }

  $root;
}

sub root {
  my $self = shift;
  return $self->{root};
}

sub node_close {
  my $self = shift;
  my $node = shift;
  return 0 unless $node;
  delete $self->{opened}->{$node};
  $self->{closed}->{$node} = 1;
  return 1;
}

sub node_open {
  my $self = shift;
  my $node = shift;
  return 0 unless $node;
  delete $self->{closed}->{$node};
  $self->{opened}->{$node} = 1;
  return 1;
}

sub draw {
  my $self = shift;
  my $root = $self->{root};

  if(param($self->{spm})){
    $self->{opened}->{$root->name} = 1;
  }

  foreach my $node ($root->descendants){
    if(($node->daughters) && (!($self->{closed}->{$node->name}))){
      $self->{opened}->{$node->name} = 1;
    }
  }

  my @open = ();
  print qq(<FONT SIZE="-2">);
  $self->print_level($root, \@open, 0);
  print qq(</FONT>);
}

sub print_level {
  my ($self, $node, $open, $end) = @_;
  my $depth = scalar($node->ancestors);

  my @daughters = $node->daughters;
  my $label     = $node->attribute->{label};
     $label    = font({-style=>'background-color: yellow'},$label) if $self->{hilited}->{$node->name};

  if($depth){ 
    for(2..$depth){
      print @$open[$_-1] ? img({-src=>$self->{mBar}, alt=>'|',-align=>'middle'}):
        img({-src=>$self->{mFill},-align=>'middle'});
    }
  }

     if($end eq 'first'      ){ print img({-src=>$self->{mTee},   -alt=>'|-',-align=>'middle'}); @$open[$depth] = 1; }
  elsif($end eq 'last'       ){ print img({-src=>$self->{mCorner},-alt=>'L' ,-align=>'middle'}); @$open[$depth] = 0; }
  elsif($depth and $depth > 0){ print img({-src=>$self->{mTee},   -alt=>'|-',-align=>'middle'});                     }

  if(@daughters)                      { print $self->toggle($node->name,$label), $label; }
  elsif($node->attribute->{is_mother}){ print $self->toggle($node->name,$label), $label; }
  else                                { print img({-src=>$self->{mLeaf},-alt=>"o",-align=>'middle'}), $label; }

  print br,"\n";

  return unless $self->{opened}->{$node->name};
  return if     $self->{closed}->{$node->name};
  return unless @daughters;

  #do last first in case there is only one daughter
  my $last  = pop   @daughters;
  my $first = shift @daughters;

  $self->print_level($first, $open, 'first') if $first;
  $self->print_level($_,     $open, 0      ) foreach @daughters;
  $self->print_level($last,  $open, 'last' );

  return 1;
}

sub toggle {
  my $self = shift;
  my ($tag,$label) = @_;
  my $img;

  # copy hashes into locals
  my %o    = %{$self->{opened}};
  my %c    = %{$self->{closed}};
  $label ||= $tag;

  if(exists $o{$tag}) {
     delete $o{$tag}; $c{$tag}++;
    $img = img({-src=>$self->{mOpen},-alt=>"-",-border=>'0',-align=>'middle'});
  } else {
     delete $c{$tag}; $o{$tag}++;
    $img =  img({-src=>$self->{mClose},-alt=>"+",-border=>'0',-align=>'middle'});
  }


  Delete($self->{opm});
  Delete($self->{cpm});
  Delete($self->{spm});
#  Delete_all();

  param(-name=>$self->{opm},-value=>[keys %o]) if keys %o;
  param(-name=>$self->{cpm},-value=>[keys %c]) if keys %c;

  my $url = url(-relative=>1,-path_info=>1,-query=>1);
     $url =~ s!^[^/]+/!!;
  return a({-href=>"$url\#$tag",-name=>$tag},$img)." ";
}


1;


=head1 NAME

  CGI::Explorer - Windows Explorer style tree browser

=head1 SYNOPSIS

  use CGI::Explorer;

  my $menu = Menu->new(-relate  => \%relate,  # a mother/daughter
		                              # relationship hash
	  	       -nodes   => \%nodes,   # a hash of all nodes
		       -labels  => \%labels,  # a hash of all labels
		       -mothers => \%mothers, # a hash of nodes with
                                              # daughters
		       -open    => 'o',       # reserved cgi param for
		                              # displaying tree
                       -close   => 'c',       # reserved cgi param for
                                              # displaying tree
                       -search  => 'name',    # used for searching the
                                              # tree
		       -hilite  => \@hilites, # nodes to be hilighted
		      );
  $menu->draw;                                #draw the menu

=head1 DESCRIPTION

  The CGI::Explorer class provides a graphic user interface to a tree
  structure.  Pass in a set of hashes that define the relationships of
  nodes in the tree to be drawn, and CGI::Explorer assembles the tree
  using the Tree::DAG_Node module.  The tree can be visualized/explored
  after calling the draw() method.

  Note that this modules depends on CGI and Tree::DAG_Node.pm.

=head1 METHODS

  This section describes the class and object methods for CGI::Explorer.

  Method            Description
  ------            -----------
  draw()            returns a representation of the tree as HTML code
  node_close($name) descendants of $name will no longer be drawn when draw()
                    is called
  node_open($name)  descendants of $name will be drawn when draw() is called
  root()            returns a Tree::DAG_Node object that is the root of the
                    tree.

=head2 CONSTRUCTORS

There is only one constructor, the new() method.  It creates a new
Explorer object.

new() is minimally called with 3 options as attribute/value pairs:

  Option         Value
  ------         -----
  -relate        reference to a hash of hashes, of format
                 $hash{mother_node}{daughter_node}.
  -mothers       reference to a hash of nodes that have daughters.
  -labels        reference to a hash of labels for all nodes.

Additional attribute/value pairs may be passed in as well:

  Option         Value                                  Default
  ------         -----                                  -------
  -open          CGI parameter reserved for tree        'o'
                 node management
  -close         CGI parameter reserved for tree        'c'
                 node management
  -search        CGI parameter reserved for tree        's'
                 management.  This parameter is used
                 to search for and expose nodes in 
                 the tree.
  -hilite        a list reference that contains names   none
                 of nodes to be highlighted
  -menu_open     A graphic for rendering the menu.      yes
  -menu_closed   ...                                    yes
  -menu_tee      ...                                    yes
  -menu_bar      ...                                    yes
  -menu_corner   ...                                    yes
  -menu_leaf     ...                                    yes
  -menu_fill     ...                                    yes

Default menu images are sought in the URL path:
localhost://images/menu-images/

new() will return an error message if one of the required parameters
is not defined.

=back

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<CGI>

=head1 AUTHOR

Allen Day <allen.day@cshl.org>

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

