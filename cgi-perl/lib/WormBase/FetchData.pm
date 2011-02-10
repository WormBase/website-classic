package WormBase::FetchData;

=pod

=head1 WormBase::FetchData

=head1 Synposis

  my $accessor = FetchData->new($DB);

  # Specific methods
  my @rnai = $accessor->fetch_rnai($gene);

  # General tags
  my @ids = $accessor->fetch_from_gene($gene,'CDS');

=head1 Description

This module provides generic subroutines for fetching composite
data fro
(that extends beyond simple tags).

In addition, it provides a variety of methods that can be used for
stepping through objects.

For example, the get_wormpep can retrieve the wormpep ID
if passed a Gene, CDS, or Transcript

=cut

use strict;
use lib '../';
use ElegansSubs qw/FindPosition/;
use Ace::Object;
use Ace::Sequence;

#require Exporter;
#use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use vars qw();
#@EXPORT_OK = qw//;
#@EXPORT    = qw//;

sub new {
  my ($self,$DB) = @_;
  my $this = bless {},$self;
  $this->{DB} = $DB;
  return $this;
}


=pod

The methods contained in this module facilitate quick retrieval of
standard datatypes from a variety of objects.  For example, you need
not know that the Brief_description is attached to ?CDS objects.
Instead, just call the fetch_brief_identification() method and pass it
a ?Gene, ?CDS, or ?Protein object.  The subroutine will handle
fetching the tag (including intermediate objects, if necessary) and
return the value as an array or array reference.

Some subroutines post process the data prior to returning it.

=head1 General Accessor Methods

=head2 $accessor->fetch_gene($object);

Intelligently retrieve ?Gene objects associated with ?CDS,
?Transcript, or ?Protein objects.  Redundantly, it will also return
itself if supplied with a ?Gene object so that the nature of the
initial object need not be known in advance. Returns an array (or
array reference if requested) of ?Gene objects.

For persistent queries of an individual class, the first fetch of that
class stores the results so they only need be fetched once.

=cut

sub fetch_gene {
  my ($self,$query) = @_;
  return unless $query;
  my @genes;
  unless (@genes = $self->already_fetched('genes')) {
    my %seen;
    if ($query->class eq 'Gene') {
      @genes = $query;
    } elsif ($query->class eq 'CDS') {
      @genes = $query->Gene;
    } elsif ($query->class eq 'Protein') {
      @genes = eval { $query->Corresponding_CDS->Gene };
    } elsif ($query->class eq 'Transcript') {
      @genes = grep {!$seen{$_}++} map {$_->Gene} $query->Corresponding_CDS;
    }
    push (@{$self->{genes}},@genes);
  }
  return wantarray ? @genes : \@genes;
}

=pod

=head2 $accessor->fetch_cds($object);

Intelligently retrieve ?CDS objects associated with ?Gene,
?Transcript, or ?Protein objects.  Redundantly, it will also return
itself if supplied with a ?CDS object so that the nature of the
initial object need not be known in advance. Returns an array (or
array reference if requested) of ?CDS objects.  For ?Gene objects,
this may be multiple ?CDSes.  For ?Protein objects, this is typically
a single CDS.

=cut

sub fetch_cds {
  my ($self,$query) = @_;
  # Check to see if the accessor has already fetched any CDS
  my @cds;
  unless (@cds = $self->already_fetched('cds')) {
    if ($query->class eq 'Gene') {
      @cds = $query->Corresponding_CDS;
    } elsif ($query->class eq 'CDS') {
      @cds = $query;
    } elsif ($query->class eq 'Protein' || $query->class eq 'Transcript') {
      @cds = $query->Corresponding_CDS;
    }
    push (@{$self->{cds}},@cds);
  }
  return wantarray ? @cds : \@cds;
}

=pod

=head2 $accessor->fetch_protein($object);

Intelligently retrieve ?CDS objects associated with ?Gene, ?CDS, or
?Transcript objects.  Redundantly, it will also return itself if
supplied with a ?Protein object so that the nature of the initial
object need not be known in advance. Returns an array (or array
reference if requested) of ?Protein objects.  For ?Gene objects, this
may be multiple ?Protein objects.

=cut

sub fetch_protein {
  my ($self,$query) = @_;
  # Check to see if the accessor has already fetched any proteins
  my @proteins;
  unless (@proteins = $self->already_fetched('proteins')) {
    my %seen;
    if ($query->class eq 'Gene') {
      @proteins = grep {!$seen{$_}++} map {$_->Corresponding_protein} $query->Corresponding_CDS;
    } elsif ($query->class eq 'CDS') {
      @proteins = grep {!$seen{$_}++} $query->Corresponding_protein;
    } elsif ($query->class eq 'Protein') {
      @proteins = $query;
    } elsif ($query->class eq 'Transcript') {
      @proteins = grep {!$seen{$_}++} map {$_->Corresponding_protein} $query->Corresponding_CDS;
    }
    push (@{$self->{proteins}},@proteins);
  }
  return wantarray ? @proteins : \@proteins;
}

=pod

=head2 $accessor->fetch_transcript($object);

Like the similarly named fetch_gene(),fetch_cds(), and fetch_protein()
methods, fetch_transcript() will retrieve ?Transcript objects
associated with ?Gene, ?CDS, or ?Protein objects.  Redundantly, it
will also return itself if supplied with a ?Transcript object so that
the nature of the initial object need not be known in advance. Returns
an array (or array reference if requested) of ?Transcript objects.  For
?Gene objects, this may be multiple ?Transcript objects.

=cut

sub fetch_transcript {
  my ($self,$query) = @_;
  # Check to see if the accessor has already fetched any transcripts
  my @transcripts;
  unless (@transcripts = $self->already_fetched('transcripts')) {
    my %seen;
    if ($query->class eq 'Gene') {
      @transcripts = grep {!$seen{$_}++} map {$_->Corresponding_transcript} $query->Corresponding_CDS;
    } elsif ($query->class eq 'CDS') {
      @transcripts = grep {!$seen{$_}++} $query->Corresponding_transcript;
    } elsif ($query->class eq 'Protein') {
      @transcripts = grep {!$seen{$_}++} map {$_->Corresponding_transcript} $query->Corresponding_CDS;
    } elsif ($query->class eq 'Transcript') {
      @transcripts = $query;
    }
    push (@{$self->{transcripts}},@transcripts);
  }
  return wantarray ? @transcripts : \@transcripts;
}


sub already_fetched {
  my ($self,$class) = @_;
  my @objects  = eval { @{$self->{$class}} };
  return if @objects == 0;
  return wantarray ? @objects : \@objects;
}

=pod

=head1 Specific Accessor Methods

=cut


# Fetch the genbank entry from the gene, if present
# IS THIS NOW ATTACHED TO ?GENE??
sub fetch_genbank {
  my ($self,$query,$genes) = @_;
  $genes ||= $self->fetch_gene($query);
  my $base = $genes->[0];
  return unless $base; # Return nothing if no base (genes) - 12JUl2004/PC
  my @other = $base->Other_sequence;
  my @genbank;
  foreach (@other) {
    push (@genbank,$_) unless ($_->Method ne 'NDB');
  }
  return \@genbank;
  # Fetching genbank from the CDS (old)
  #  $cds ||= $self->fetch_cds($query);
  #  my (@genbank,%seen);
  #  foreach (@$cds) {
  #    my @databases = $_->Database;
  #    foreach (@databases) {
  #      if (/^(NDB|embl)/i) {
  #	next if $seen{$_}++;
  #	push (@genbank,$_->right(2));
  #      }
  #    }
  #  }
  #  return \@genbank;
}

# Eugenes IDs are equivalent to CDSes
sub fetch_eugenes {
  my ($self,$query,$eugenes) = @_;
  $eugenes ||= $self->fetch_cds($query);
  return $eugenes;
}


sub fetch_wormpd {
  my ($self,$query,$genes) = @_;
  $genes ||= $self->fetch_gene($query);
  my $base = $genes->[0];
  return unless $base; # Return nothing if no base (genes) - 12JUl2004/PC
  # Use the locus first if it exists, else, use CDS identifier
  my @wormpd = $base->CGC_name || $base->Sequence_name;
  return \@wormpd;
}

sub fetch_genpep {
  my ($self,$query,$proteins) = @_;
  $proteins ||= $self->fetch_protein($query);
  my (@genpep,%seen);
  foreach (@$proteins) {
    my @db = $_->Database;
    foreach (@db) {
      next unless $_ eq 'SwissProt';
      my $genpep = $_->at('SwissProt_AC')->right;
      push (@genpep,$genpep) if ($genpep && !$seen{$genpep}++);
    }
  }
  return \@genpep;
}


sub fetch_swissprot {
  my ($self,$query,$proteins) = @_;
  $proteins ||= $self->fetch_protein($query);
  my (@swissprot,%seen);
  foreach (@$proteins) {
    my @db = $_->Database;
    foreach (@db) {
      next unless $_ eq 'SwissProt';
      my $genpep = $_->at('SwissProt_ID')->right;
      push (@swissprot,"SWALL:$genpep") if ($genpep && !$seen{$genpep}++);
    }
  }
  return \@swissprot;
}


sub fetch_status {
  my ($self,$query,$genes) = @_;
  $genes ||= $self->fetch_gene($query);
  my $base = $genes->[0];
  return unless $base; # Return nothing if no base (genes) - 12JUl2004/PC
  # Use the locus first if it exists, else, use CDS identifier
  my @status = ($base->Live(0)) ? 'live' : 'historical';
  return \@status;
}

sub fetch_go {
  my ($self,$query) = @_;
  
  # Go terms are strored separately for Genes and CDS's
  # In both classes, they are stored by the "GO_term" tag
  # Ones stored in the Gene object are manually curated
  
  my @gene_go;
  my @cds_go;

  if ($query->{class} eq 'CDS') {  
    @cds_go = $query->GO_term;
   }
   
  if ($query->{class} eq 'Gene') {
    @gene_go = $query->GO_term;

    my @cds = $query->Corresponding_CDS;
    foreach (@cds) {
        my @go = $_->GO_term;
        push @cds_go, @go if @go;
        }
    }

  my @full;
  
  foreach (sort {$a->Type cmp $b->Type } @gene_go) {
    my $term = $_->Term;
    my $type = $_->Type;
    push (@full,[$type,$term,'manual cur.',$_]);
    }

  my %cds_go;  
  foreach (sort {$a->Type cmp $b->Type } @cds_go) {
    my $term = $_->Term;
    my $type = $_->Type;
    $cds_go{$_} = [$type,$term,'automatic cur.',$_];
    }
  push @full, values %cds_go;  
    
  return \@full;
}


# Fetch the experimental and interpolated Gmap positions
sub fetch_gmap {
  my ($self,$query,$genes) = @_;
  $genes ||= $self->fetch_gene($query);
  my $base = $genes->[0];
  return unless $base; # Return nothing if no base (genes) - 12JUl2004/PC
  
  my $chromosome = $base->Map(1);
  my $gmap       = $base->Map(3);
  my @gmap;
  if ($gmap && $chromosome) {
    push @gmap,"$chromosome:$gmap";
  } else { # get the interpolated gmap position
    if (my $m = $base->get('Interpolated_map_position')) {
      my ($chromosome,$gmap) = $m->right->row;
      push @gmap,"$chromosome:$gmap";
    }
  }
  return \@gmap;
}


# Not working
sub fetch_pmap {
  my ($self,$query,$genes) = @_;
  $genes ||= $self->fetch_gene($query);
  my $base = $genes->[0];
  return unless $base; # Return nothing if no base (genes) - 12JUl2004/PC
  my ($begin,$end,$reference) = FindPosition($self->{DB},$base);
  $reference =~ /.*_+(.*)/;
  $reference = $1;
  my $string = "$reference: $begin-$end";
  my @data = ($string);
  # return wantarray ? [$string] : \[$string];
  return \@data;
}


sub fetch_motifs {
  my ($self,$query,$proteins) = @_;
  $proteins ||= $self->fetch_protein($query);
  my %seen;
  my @motifs = map {$_->Motif_homol} @$proteins;
  my @titles = grep {!$seen{$_}++} map {$_->Title} @motifs;
  return \@titles;
}

sub fetch_total_alleles {
  my ($self,$query,$genes) = @_;
  my $alleles = $self->fetch_from_gene($query,'Allele',$genes);
  return ([scalar @$alleles]);
}

sub fetch_rnai {
  my ($self,$query,$genes) = @_;
  $genes ||= $self->fetch_gene($query);
  my $base = $genes->[0];
  return unless $base; # Return nothing if no base (genes) - 12JUl2004/PC
  my @rnai = $base->RNAi_result;
  my @results;
  foreach my $rnai (@rnai) {
    my @phenes = $rnai->Phenotype;
    my $labhead = eval { $rnai->Laboratory->Representative->Last_name };
    foreach (@phenes) {
      push (@results,[$rnai,$labhead,$_]);
    }
  }
  return \@results;
}

sub fetch_paper {
  my ($self,$query,$genes) = @_;
  $genes ||= $self->fetch_gene($query);
  my $base = $genes->[0];
  return unless $base; 
  my @papers = $base->Reference;
  return \@papers;
}

sub fetch_homology_group {
  my ($self,$query,$genes) = @_;
  $genes ||= $self->fetch_gene($query);
  my $base = $genes->[0];
  return unless $base; 
  
  my @corresponding_cds = $base->Corresponding_CDS;
  return unless @corresponding_cds;
  
  my @corresponding_protein;
  foreach (@corresponding_cds) {
    push (@corresponding_protein, $_->Corresponding_protein);
    }
  return unless @corresponding_protein;
  
  my @homology_group;
  foreach (@corresponding_protein) {
    push (@homology_group, $_->Homology_group);
    }

  # Make list non-redundant
  my %homology_group;
  foreach (@homology_group) {
    my $name = scalar($_);
	$homology_group{$name} = $_;
	}
  my @non_redundant_list;
  foreach (sort keys %homology_group) {
    push (@non_redundant_list, $homology_group{$_});
	}
	
  return \@non_redundant_list;
}

# Under construction - PC
sub fetch_expr_pattern {
  my ($self,$query,$genes) = @_;
  $genes ||= $self->fetch_gene($query);
  my $base = $genes->[0];
  return unless $base; 
  
  my @expr_patterns = $base->Expr_pattern;

  return \@expr_patterns;
}


sub fetch_oligo_set {
  my ($self,$query,$genes) = @_;
  $genes ||= $self->fetch_gene($query);
  my $base = $genes->[0];
  return unless $base; 
  
  my @corresponding_cds = $base->Corresponding_CDS;
  return unless @corresponding_cds;
  
  my @oligo_set;
  foreach (@corresponding_cds) {
    push (@oligo_set, $_->Corresponding_oligo_set);
    }
  return unless @oligo_set;
  
  # Make list non-redundant
  my %oligo_set;
  foreach (@oligo_set) {
    my $name = scalar($_);
	$oligo_set{$name} = $_;
	}
  my @non_redundant_list;
  foreach (sort keys %oligo_set) {
    push (@non_redundant_list, $oligo_set{$_});
	}
	
  return \@non_redundant_list;
}


# # This could be greatly expanded to include
# # subcellular localization
# # reporter genes, etc
# sub fetch_expression {
#   my ($self,$query,$genes) = @_;
#   $genes ||= $self->fetch_gene($query);
#   my $base = $genes->[0];
#   return unless $base; # Return nothing if no base (genes) - 12JUl2004/PC
#   my @patterns = $base->Expr_pattern;
#   my @descriptions;
#   # Fetch the description of the pattern as well as its expression of
#   foreach (@patterns) {
#     push (@descriptions,[$_,$_->Pattern,($_->Gene || $_->CDS || $_->Clone || $_->Sequence || $_->Protein)]);
#   }
#   return \@descriptions;
# }

sub fetch_subcellular_localization {
  my ($self,$query,$genes) = @_;
  $genes ||= $self->fetch_gene($query);
  my $base = $genes->[0];
  return unless $base; # Return nothing if no base (genes) - 12JUl2004/PC
  my @patterns = $base->Expr_pattern;
  my @localizations;
  # Fetch the description of the pattern as well as its expression of
  foreach (@patterns) {
    push (@localizations,$_->Subcellular_localization) if ($_->Subcellular_localization);
  }
  return \@localizations;
}

# Sequence related subroutines
sub fetch_spliced_dna {
  my ($self,$query,$cds) = @_;
  $cds ||= $self->fetch_cds($query);
  my @seqs;
  foreach (@$cds) {
    my $spliced  = $_->asDNA;
    $spliced =~ s/^>.*//;
    $spliced =~ s/\n//g;
    push (@seqs,[$_,'spliced',$spliced]);
  }
  return \@seqs;
}

sub fetch_unspliced_dna {
  my ($self,$query,$cds) = @_;
  $cds ||= $self->fetch_cds($query);
  my @seqs;
  foreach (@$cds) {
    my $s   = Ace::Sequence->new($_);
    my $un  = $s->dna if $s;
    push (@seqs,[$_,'unspliced',$un]);
  }
  return \@seqs;
}

sub fetch_protein_seq {
  my ($self,$query,$proteins) = @_;
  $proteins ||= $self->fetch_protein($query);
  my (@seqs,%seen);
  foreach (@$proteins) {
    my $pro = $_->asPeptide;
    push (@seqs,[$_,'protein',$pro]);
  }
  return \@seqs;
}


=pod 

=head1 $accessor->fetch_from_cds($object,$tag);

IN PROGRESS.  It should be possible to generalize many of the methods
contained herein.  This of course would not apply to methods that
require post processing of the data.

This subroutine provides direct access to single level ?CDS object
tags. Passed a ?Gene, ?CDS, ?Transcript, or ?Protein object and the
name of the tag to recover, this soubroutine will return the contents
of that tag.  Returns a hash reference where keys are the name of the
?CDS and values are array references containing the contents of the
tag.  For top-level objects (like ?Gene), this subroutine may
potentially return multiple CDSes.

Optionally, an array reference of CDS objects can be passed to prevent
unneeded database acessions.

=cut

sub fetch_from_cds {
  my ($self,$object,$tag,$cds) = @_;
  $cds ||= $self->fetch_cds($object);
  my %seen;
  my @fetched = grep {!$seen{$_}++ } map {$_->$tag} @$cds;
  return wantarray ? @fetched : \@fetched;
}

sub fetch_from_gene {
  my ($self,$object,$tag,$genes) = @_;
  $genes ||= $self->fetch_gene($object);
  my %seen;
  my @fetched = grep {!$seen{$_}++ } map { eval { $_->$tag } } @$genes;
  return wantarray ? @fetched : \@fetched;
}


sub gene2cds {
  my $gene = shift;
}


sub cds2gene {
  my $cds = shift;

}





1;
