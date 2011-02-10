package WormBase::AutocompleteLoad;
# $Id: AutocompleteLoad.pm,v 1.1.1.1 2010-01-25 15:36:06 tharris Exp $

=head1 NAME

AutocompleteLoad -- Loads the WormBase autocompleter database from
Acedb

=head1 SYNOPSIS

 my $load = AutocompleteLoad->new();

 # Load just the WormBase object IDs (very fast)
 $load->load_object_names('Protein');  # all proteins

 # Load WormBase object IDs as well as aliases embedded in the objects (slower)
 $load->load_class(-autocomplete_class => 'WormPep',
	 	   -query              => 'find Protein WormPep',
		   -aliases            => ['DB_info.Database[3]','Corresponding_CDS'],
                   -meta               => ['e345','EG1000'],
		   -fill               => 'DB_info');

=head1 DESCRIPTION

This is a utility module that helps populate the autocompleter
database from objects contained in Acedb.

=head1 METHODS

=cut

use strict;
use Bio::DB::GFF::Util::Rearrange 'rearrange';
use WormBase::Autocomplete;
use Ace;

=head2 new()

 $load = WormBase::AutocompleteLoad->new(@options)

Create a new loader. Arguments are name-value pairs:

 Name         Value                Default

 -ace_host    AceDB host             localhost
 -ace_port    AceDB port             2005
      OR
 -ace_path    AceDB path             path to acedb
 -auto_dsn    Autocomplete DSN       dbi:mysql:autocomplete
 -auto_user   Autocomplete db user   -current user-
 -auto_pass   Autocomplete db passwd -none-

=cut

sub new {
  my $class   = shift;
  my ($ace_host,$ace_port,$ace_path,$dsn,$user,$pass) =
    rearrange([qw(ACE_HOST ACE_PORT ACE_PATH AUTO_DSN AUTO_USER AUTO_PASS)],@_);
  $ace_host ||= 'localhost';
  $ace_port ||= 2005;
  my $ace;
  if ($ace_path) {
      $ace  = Ace->connect(-path => $ace_path) or die Ace->error;
  } else {
      $ace  = Ace->connect(-host=>$ace_host,-port=>$ace_port) or die Ace->error;
  }
  my $auto = WormBase::Autocomplete->new($dsn,$user,$pass);
  return bless {ace => $ace, auto=>$auto},ref $class || $class;
}

=head2 acedb()

 $acedb = $load->acedb;

Return the internal Ace accessor object created by new().

=cut

sub acedb  { shift->{ace}  }


=head2 autodb()

 $auto = $load->autodb;

Return the internal Autocomplete accessor object created by new().

=cut

sub autodb { shift->{auto} }

=head2 load_object_names()

 $load->load_object_names($class_name)

Call this method when you wish to load all objects of a particular AceDB
class into the autocomplete database using an autocomplete class name
identical to the Acedb class name and using object names equal to the
AceDB primary IDs. It is much faster than load_class() because it does
not create intermediate Ace::Object objects.

For example, this:

 $load->load_object_names('Sequence');

will load all Sequence objects into the autocomplete database with a
class of "Sequence" and using just their AceDB object names for the
autocompletion.

=cut

# special case for loading object names only -- faster
sub load_object_names {
  my $self = shift;
  my $class_name = shift;

  my $emacs = $ENV{EMACS};
  my $delim = $emacs ? "\n" : "\r";
  print STDERR "fetching all ${class_name}s...$delim";

  my $ace = $self->acedb;
  $ace->raw_query("find $class_name");
  my $result = $ace->raw_query("list");
  my @names  = $result =~ /^ (.+)/gm;

  my $count;

  my $autodb = $self->autodb;
  $autodb->disable_keys;
  for my $name (@names) {
    print STDERR "loaded $count ${class_name}s$delim" if ++$count % 100 == 0;
    $autodb->insert_entity($class_name,$name,undef,[$name]);
  }
  print STDERR "indexing...$delim";
  $autodb->enable_keys;

}

=head2 load_class()

 $load->load_class(@args);

This method provides greater control over what gets loaded into the
autocomplete database. Arguments are name/value pairs:

 Name                   Value

 -autocomplete_class    Class by which the objects will be known in
                         the autocomplete database (default: same as
                         -class).

 -class                 Class of objects to fetch from the AceDB database.

 -prefix                A prefix pattern for restricting the objects returned

 -query                 A query to pass to AceDB to get the desired objects
                         to index.

 -aliases               Arrayref containing a series of Acedb object
                         tags to query in order to get possible aliases 
                         for this object.

 -meta                  An optional array reference containing a series of
                        Acedb object tags to query for creating meta information
                        references for each object.

 -short_note            A tag where the short note is stored.

 -long_note             A tag where the long note is stored.

 -fill                  A tag for a portion of the AceDB tree to fill, or "1"
                         to fill the entire tree.

 -name_call             A callback routine for creating arbitrary aliases for
                         each object.

This method is responsible for fetching multiple objects from AceDB,
turning each object into a list of aliases, and loading the
autocomplete database.

The B<-autocomplete_class> option sets the class that will be
associated with the loaded objects. If not specified it will take on
the value of the B<-class> option.

B<-class> and B<-prefix> can be used together to create a simple "find
Class prefix*" query on the AceDB database. If the prefix is not
provided, then the query becomes "find Class *".

The B<-query> option is provided for the case in which a simple "find"
will not fetch the desired list of objects. It is any valid AceDB
query that returns a list of objects. If both B<-query> and B<-class>
are provided, the former takes precedence over the latter.

The B<-aliases> option is an arrayref containing a list of tags that
will be used to fetch aliases from each AceDB object. Two types of tag
are possible:

=over 4

=item 1. A word

A tag consisting of word characters only (no punctuation) will be
treated as an AceDB tag name and passed to the $aceobj->get()
method. For example, this code fragment will load Genes and use the
tags "CGC_name" and "Sequence_name" as aliases:

 $load->load_class(-class=>'Gene',-aliases=>['CGC_name','Sequence_name']);

=item 2. An acedb path

A tag containing punctuation characters is treated as a full AceDB tag
path and will be passed to the $aceobj->at() method. For example:

 $load->load_class(
		  -class=>'Y2H',
		  -aliases => ['Interactor.Bait[2]',
			       'Interactor.Target[2]'
			       ]
		 );

=back

The B<-meta> option is an arrayref containing a list of tags that
will be used to fetch meta from each AceDB object. This is information
related to an object but that does not fit the entity-alias relationship.
See the "alias" documentation above.

The B<-short_note> and B<-long_note> options each contains the name of
a B<single> tag to be used to fetch the short note and long note
respectively. Both types of note are used for searching, and can be
substantially long (for example, a paper abstract), but only the short
note is displayed in the autocomplete list.

The B<-fill> option is identical to the Ace->fetch() -fill option, and
has the same semantics.

The B<-name_call> method takes a coderef. The subroutine will be
invoked once for each retrieved Ace::Object and is expected to return
a list of aliases to attach to the object in the autocomplete
database. These will supplement, not replace, any aliases returned by
B<-aliases>. Example:

 $load->load_class(
		  -class=>'Strain',
		  -name_call=>\&get_genotype,
		  -fill=>1,
		  -short_note=>'Remark',
		 );

 sub get_genotype {
   my $object     = shift;
   my $geno       = $object->Genotype;
   my @genes      = $object->Gene;
   my @variations = $object->Variation;
   my @result = $geno;
   push @result,@genes;
   push @result,@variations;
   return @result;
 }

NOTE: a bug in AcePerl causes get_genotype to crash on the strains
AF16 and HK104. In real life, you will need to skip these two entries
without trying to fetch their contents.

=cut

sub load_class {
  my $self       = shift;
  my ($class_name,$autocomplete_class,$aliases,$short_note,$long_note,$prefix,$query,$filltag,$callback,$meta) =
    rearrange([qw(CLASS AUTOCOMPLETE_CLASS ALIASES SHORT_NOTE LONG_NOTE PREFIX QUERY FILL NAME_CALL META)],@_);

  $autocomplete_class ||= $class_name;

  die "please provide an autocomplete class name" unless $autocomplete_class;

  unless (ref $aliases && ref $aliases eq 'ARRAY') {
    $aliases = defined $aliases ? [$aliases] : []; # in case callback is provided
  }

  my $ace  = $self->acedb;
  my $auto = $self->autodb;

  my $emacs = $ENV{EMACS};
  my $delim = $emacs ? "\n" : "\r";
  my $count;

  $prefix ||= '';

  $auto->disable_keys;
  my @args;
  if (defined $query) {
    push @args,(-query=>$query);
  } else {
    push @args,(-class=>$class_name)  if $class_name;
    push @args,(-name =>"${prefix}*") if $prefix;
  }
  push @args,(-fill => $filltag) if $filltag;

  my $i = $ace->fetch_many(@args) or die $ace->error;

  while (my $obj = $i->next) {
    print STDERR "loaded $count ${autocomplete_class}s$delim" if ++$count % 100 == 0;
    my %unique;
    my @aliases = $obj->name;
    push @aliases,grep {defined && !$unique{$_}++} (map {/[.\[]/ ? $obj->at($_):$obj->get($_)} @$aliases);
    push @aliases,grep {defined && !$unique{$_}++} $callback->($obj) if $callback;
    my @notes;
    push @notes,$obj->get($short_note) if $short_note;
    push @notes,$obj->get($long_note)  if $long_note;
    my $notes = [\@notes] if @notes;
    $auto->insert_entity($autocomplete_class,$obj,\@aliases,$notes);
  }
  print STDERR "Indexing...\n";
  $auto->enable_keys;
}

1;

__END__

=head1 SEE ALSO

L<WormBase::Autocomplete>,
L<autocompleter2>

=head1 AUTHOR

Lincoln Stein E<lt>lstein@cshl.orgE<gt>.

Copyright (c) 2006 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
