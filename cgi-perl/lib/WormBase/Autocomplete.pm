package WormBase::Autocomplete;
# $Id: Autocomplete.pm,v 1.2 2010-09-07 19:36:57 tharris Exp $

=head1 NAME

Autocomplete -- Autocompleter database for wormbase

=head1 SYNOPSIS

 my $auto     = WormBase::Autocomplete->new;

 # searching
 my $results  = $auto->lookup('Gene','unc',100);

 foreach (@$results) {
    my ($display_name,$canonical_name,$note) = @$_;
 }

 # initialization and loading 
 $auto->init;
 $auto->disable_keys;
 $auto->insert_entity('Gene','WBG000000001','sma-3',['sma-3','D10809.7','WBG000000001'],[['short note','long note']]);
 $auto->enable_keys;

=head1 DESCRIPTION

This is a utility module that manages the autocompletion database for Wormbase.

=head1 METHODS

=cut


use strict;
use DBI;

=head2 new()

 $auto = WormBase::Autocomplete->new($dsn,$user,$pass);

Connect to the DBI database located at $dsn, using the username and
password indicated. If no database is specified, default to
dbi:mysql:autocomplete on localhost.

Because of the use of full-text indexing, only Mysql databases
currently work with this.

=cut

sub new {
  my $class = shift;
  my $dsn   = shift || 'autocomplete';

  my ($user,$pass)  = @_;

  # For uses requiring auth, should pass user and pass
  $user ||= 'root';
  $pass ||= '3l3g@nz';

  # Suitable privs for CGI
#  $user ||= 'nobody';
#  $pass ||= undef;

  # Create the database if it doesn't already exist
#  my $temp = DBI->connect("DBI:mysql:database=test;host=localhost",
#			  $user, $pass);
#  $temp->func('createdb',$dsn,'admin');
#  $temp->disconnect();
  
  $dsn = 'dbi:mysql:' . $dsn;
  my $db    = DBI->connect($dsn,$user,$pass,{PrintError=>0}) 
    or die "Couldn't connect to autocomplete db: ",DBI->errstr;
  return bless {
		db             => $db
	       },ref $class || $class;
}

=head2 init()

  $auto->init()

Initialize the database, creating four tables:

=over 4

=item entities

Each row corresponds to a unique WormBase object with class 'wclass'
and database identifier 'wname'. The 'wid' field is a unique numeric
identifier. The optional fourth column, 'wdisplay', can be used to 
specify a public display name for over-riding a match, particularly
when searching via a meta tag.

=item aliases

Each row corresponds to an autocomplete name, which is not necessarily
unique. Columns are 'wid', the unique numeric ID for the entity, and
'walias', the non-unique alias that can be completed.

=item meta

Each row corresponds to an item related to an entity but that is not an
alias. For example, meta entries can be used to associate
alleles with genes, making it possible for users to find which gene
an allele belongs to.  Although alias entries can be used to a similar
effect, this will result in confusing behavior for the end user in autocomplete,
presenting meta items as objects of a given class.  Instead, the meta
table is not intended for class-specific autocomplete but for deeper searching
of the database. Columns are 'wid', the unique numeric ID for the entity, and
'wmeta', the non-unique meta item that can be searched.

=item notes

Each row corresponds to a full-text searchable note on an entity. The
'wnote' column is a short note that is intended for display in the
autocomplete box. The 'wlongnote' field can be searched on, but is not
displayed. Both are searchable.

Note that the init() method will erase whatever was in the database
before.

=cut

sub init {
  my $self = shift;
  my $db   = $self->db;
  foreach (qw(entities aliases notes)) {
    $db->do("drop table if exists $_");
  }
  $db->do(<<END) or die $db->errstr;
create table entities (
  wid         int(10) primary key auto_increment,
  wclass      varchar(20) not null,
  wname       varchar(50) not null,
  wdisplay    varchar(50),
  unique key  name(wclass,wname)
)
END

  $db->do(<<END) or die $db->errstr;
create table aliases (
  wid     int(10),
  walias  varchar(50) not null,
  key     (wid), 
  key     alias(walias)
)
END

  $db->do(<<END) or die $db->errstr;
create table notes (
  wid       int(10),
  wnote     text,
  wlongnote text,
  key      (wid),
  fulltext note(wnote,wlongnote)
)
END

  $db->do(<<END) or die $db->errstr;
create table meta (
  wid     int(10),
  wmeta   varchar(50) not null,
  key     (wid), 
  fulltext meta(wmeta)
)
END
}

#  key     meta(wmeta),

=head2 insert_entity()

 $auto->insert_entity($class,$wormbase_id,$display,$aliases,$notes,$meta);

Insert a WormBase object into the autocomplete database:

 $class        WormBase object class, such as Protein
 $wormbase_id  Wormbase object ID, such as WBG0000001
 $display      An optional primary display name for the entity. This can be used to
               override a matching alias or meta item hit.
 $aliases      An arrayref of all the aliases that this object is known as.
 $notes        An arrayref of [$short_note,$long_note] pairs. Typically you
               will either leave $long_note undef, or use an abbreviated form
               of $long_note as $short_note.
 $meta         An arrayref of meta items.

=cut

sub insert_entity {
  my $self = shift;
  my ($class,$name,$display,$aliases,$notes,$meta) = @_;
  $self->insert_primary->execute($class,$name,$display) or die $self->errstr;
  my $id = $self->db->{mysql_insertid};
  if ($aliases && ref $aliases eq 'ARRAY') {
    for my $a (@$aliases) {
      $self->insert_alias->execute($id,$a) or die $self->errstr;
    }
  }
  if ($notes && ref $notes eq 'ARRAY') {
    for my $a (@$notes) {
      my ($short,$long) = ref($a) eq 'ARRAY' ? @$a : $a;
      $self->insert_note->execute($id,$short,$long) or die $self->errstr;
    }
  }
  if ($meta && ref $meta eq 'ARRAY') {
    for my $a (@$meta) {
      $self->insert_meta->execute($id,$a) or die $self->errstr;
    }
  }
}

=head2 disable_keys(), enable_keys()

 $auto->disable_keys()
 $auto->enable_keys()

Typically you will want to disable_keys() before performing a series
of inserts and enable_keys() when you are finished. This will speed up
the rate of batch insertion. DESTROY calls enable_keys() for you, in
case you forget.

=cut

sub disable_keys { 
  my $self = shift;
  my $db   = $self->db;
  $self->{disabled}++;
  for my $t (qw(entities aliases notes meta)) {
    $db->do("alter table $t disable keys") or die $db->errstr;
  }
}

sub enable_keys {
  my $self = shift;
  return unless $self->{disabled};
  my $db   = $self->db;
  for my $t (qw(entities aliases notes meta)) {
    $db->do("alter table $t enable keys") or die $db->errstr;
  }
  delete $self->{disabled};
}


=head2 lookup()

 $results  = $auto->lookup($class,$partial_name,$max);

Look up a partial_name and return the matches.

 $class          Name of the object class to search in, or undef for all.
 $partial_name   A partial name or note search term, such as 'unc-'
 $max            Maximum number of entries to retrieve.

The result is an arrayref zero or more entries of the form
[$display_name,$canonical_name,$note,$public_name], where $display_name is the
autocompleted alias, $canonical_name is the WormBase ID, and $note is
a note associated with the entry (if any). $public_name is the public display
name, which may or may not correspond to the autocompleted alias.

=cut

sub lookup {
  my $self    = shift;
  my $class   = shift;
  my $keyword = shift;
  my $max     = shift;
  my $deep    = shift;
  my $limit   = defined $max ? "limit $max" : '';

  my $wclass = defined $class ? 'AND e.wclass=?' : '';
  my @args   = defined $class ? ($class,"$keyword%") : ("$keyword%");

  # two phases -- first look up aliases directly, second look up notes by text search
  my $sth = $self->db->prepare_cached(<<END) or die $self->errstr;
 select  a.walias,e.wname,n.wnote,e.wclass,e.wdisplay
 from   aliases as a, entities as e left join notes as n using (wid) 
 where  e.wid=a.wid
    $wclass
    and a.walias LIKE ?
 $limit
END
  $sth->execute(@args) or die $self->errstr;
  my $result1 = $sth->fetchall_arrayref;
  return $result1 if @$result1 && !$deep;

  # second phase -- use full text search
  # but we will skip this if the keyword looks like a gene
  # MySQL treats hypens as stop characters, resulting in spurious matches
  unless ($keyword =~ /\w{3,4}\-\d+/) {
      my @words  = split /\s+/,$keyword;	
      
      $sth = $self->db->prepare_cached(<<END) or die $self->errstr;
select a.walias,e.wname,n.wnote,e.wclass,e.wdisplay,match(n.wnote,n.wlongnote) against (?) as score
from  entities as e left join aliases as a using (wid), 
notes as n
where  e.wid=n.wid
$wclass
and match(n.wnote,n.wlongnote) against (?)
$limit
END
;
      @args = defined $class ? ($keyword,$class,$keyword) : ($keyword,$keyword);
      $sth->execute(@args) or die $self->errstr;
      my $results2 = $sth->fetchall_arrayref;
      push @$result1,@$results2;
#      return $sth->fetchall_arrayref;
  }
  return $result1 if @$result1;
  return [];
}

=head2 lookup_deep()
    
    $results  = $auto->lookup_deep($class,$partial_name,$max);

Do a deep search of the database with partial_name and return the 
matches. This method results in two searches of the database, the first
using the standard lookup() method of notes and aliases, and the second
of meta items.

 $class          Name of the object class to search in, or undef for all.
 $partial_name   A partial name or note search term, such as 'unc-'
 $max            Maximum number of entries to retrieve.

The result is an arrayref zero or more entries of the form
[$meta_hit|$alias_hit,$entity_canonical,$entity_display,$note],
where $meta_hit|$alias_hit is the matching alias or meta item, $entity_canonical
is the matching object, $entity_display is the public display name
of the object (if different), and $note is a note associated with the 
entity (if any).

=cut

sub lookup_deep {
  my $self    = shift;
  my $class   = shift;
  my $keyword = shift;
  my $max     = shift;
  my $limit   = defined $max ? "limit $max" : '';

  my $wclass = defined $class ? 'AND e.wclass=?' : '';
  my @args   = defined $class ? ($class,"$keyword%") : ("$keyword%");

  # two phases -- first the standard lookup(), second a meta query
  my $hits = $self->lookup($class,$keyword,$max,1);

  my $sth = $self->db->prepare_cached(<<END) or die $self->errstr;
select  DISTINCT m.wmeta,e.wname,n.wnote,e.wclass,e.wdisplay
from   meta as m, entities as e left join notes as n using (wid) 
 where  e.wid=m.wid
    $wclass
    and m.wmeta LIKE ?
 $limit
END
;

#  my $sth = $self->db->prepare_cached(<<END) or die $self->errstr;
#select  DISTINCT m.wmeta,e.wname,n.wnote,e.wclass,e.wdisplay
#from   meta as m, entities as e left join notes as n using (wid) 
# where  e.wid=m.wid
#    $wclass
#    and match(m.wmeta) against (?)
# $limit
#END
#;

  $sth->execute(@args) or die $self->errstr;
  my $related = $sth->fetchall_arrayref;

  if (0) {
      warn "TOTAL RELATED ============================: $class hits " . scalar @$hits;
      foreach (@$hits) {
	  warn join(",",@$_);
      }
      
      warn "TOTAL RELATED ============================: $class related " . scalar @$related;
      foreach (@$related) {
	  warn join(",",@$_);
      }
  }

  push @$hits,@$related if @$related;
  return $hits;
  
#  # second phase -- use full text search
#  my @words  = split /\s+/,$keyword;
#
#  $sth = $self->db->prepare_cached(<<END) or die $self->errstr;
#select a.walias,e.wname,n.wnote,match(n.wnote,n.wlongnote) against (?) as score
# from   entities as e left join aliases as a using (wid), 
#        notes as n
# where  e.wid=n.wid
#    $wclass
#    and match(n.wnote,n.wlongnote) against (?)
# $limit
#END
#;
#  @args = defined $class ? ($keyword,$class,$keyword) : ($keyword,$keyword);
#  $sth->execute(@args) or die $self->errstr;
#  return $sth->fetchall_arrayref;
}


=head2 db

 $db = $auto->db;

Return the DBI database handle associated with this instance.

=cut

sub db             { shift->{db}             }

=head2 db

 $error = $auto->errstr;

Return the DBI error string associated with the last request.

=cut

sub errstr         { shift->db->errstr       }

=head2 low-level routines

 $auto->insert_primary()
 $auto->insert_alias()
 $auto->insert_note()
 $auto->insert_meta()
 $auto->insert_longnote()

These methods all return cached statement handles for insert
operations. These statement handles are used by insert_entity().

=cut


sub insert_primary {
  my $self = shift;
  $self->db->prepare_cached('replace into entities (wclass,wname,wdisplay) values (?,?,?)') or die $self->errstr;
}

sub insert_alias {
  my $self = shift;
  $self->db->prepare('replace into aliases  (wid,walias) values (?,?)')   or die $self->errstr;
}
sub insert_note {
  my $self = shift;
  $self->db->prepare('replace into notes    (wid,wnote,wlongnote) values (?,?,?)')    or die $self->errstr;  
}
sub insert_meta {
  my $self = shift;
  $self->db->prepare('replace into meta  (wid,wmeta) values (?,?)')   or die $self->errstr;
}
sub insert_longnote {
  my $self = shift;
  $self->db->prepare('replace into notes    (wid,wlongnote) values (?,?)')    or die $self->errstr;  
}


sub DESTROY {
  shift->enable_keys;
}

1;


__END__

=head1 SEE ALSO

L<WormBase::AutocompleteLoad>,
L<autocompleter2>

=head1 AUTHOR

Lincoln Stein E<lt>lstein@cshl.orgE<gt>.

Copyright (c) 2006 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
