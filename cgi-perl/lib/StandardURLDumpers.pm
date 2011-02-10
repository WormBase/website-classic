# -*- Mode: perl -*-
# $Id: StandardURLDumpers.pm,v 1.1.1.1 2010-01-25 15:36:06 tharris Exp $
# file: StandardURLDumpers.pm
# Dump FASTA files corresponding to genome, genes and proteome

package StandardURLDumpers;
use strict;

use base 'Exporter';
use vars qw(@EXPORT @EXPORT_OK);
@EXPORT_OK = qw(dump_genome dump_genes dump_proteins);

use Bio::DB::GFF;
use Bio::SeqIO;
use Carp 'croak';

my %config = (
	      'Caenorhabditis elegans' => {
		  db     => 'elegans',
		  aggregators=> ['processed_transcript{coding_exon,exon:three_prime_exon_noncoding_region,exon:five_prime_exon_noncoding_region,exon:three_prime_noncoding_exon,exon:five_prime_noncoding_exon/CDS}'],
		  genome => {
		      method => 'region:Link',
		      filter => q(^[IVX]+|MtDNA$),
		  },
	          genes => {
		      method => 'processed_transcript:curated',
		      filter => '.+',
		  },
	      },

	      'Caenorhabditis briggsae' => {
		  db     => 'briggsae',
		  aggregators=>['processed_transcript{coding_exon/CDS}'],
		  genome => {
		      method => 'supercontig',
		      filter => '.+',
		  },
		  genes => {
		      method => 'processed_transcript:hybrid',
		      filter => '.+',
		  },
	      },
	  );

my %species_table = ('Celegans'   => 'Caenorhabditis elegans',
		     'Cbriggsae'  => 'Caenorhabditis briggsae',
		     'Cjaponica'  => 'Caenorhabditis japonica',
		     'Cremanei'   => 'Caenorhabditis remanei',
		     'CB5161'     => 'Caenorhabditis sp CB5161',
		    );
my %reverse_species = reverse %species_table;

=head1 NAME

StandardURLDumpers -- Standard FASTA representations of nematode genome, genes and proteins

=head1 SYNOPSIS

    use StandardURLDumpers qw(dump_genome dump_genes dump_proteins);
    my $species = 'Caenorhabditis elegans';

    dump_genome($species);
    dump_genes($species,'spliced');
    dump_proteins($species);

=head1 DESCRIPTION

This package makes three functions available for dumping
FASTA-formatted representations of the nematode genome, proteome and
gene content.  The functions operate off GFF databases and use a
hard-coded internal hash structure for choosing the right GFF files,
aggregator incantations, and so on.

Each of these functions must be imported explicitly.  The $species
argument is one of:

	 Caenorhabditis elegans
	 Caenorhabditis briggsae

Support for other species will be added when appropriate.

=over 4

=item dump_genome($species [,\*FILEHANDLE])

Given the species print a FASTA file representing each of the top
level assembly units (chromosomes or supercontigs) to the FILEHANDLE,
or to STDOUT if not provided.

=item dump_genes($species [,$spliced [,\*FILEHANDLE]])

Given the species, print a FASTA file representing each of the
alternatively spliced transcripts.  The $spliced flag, if true, will
cause the spliced CDS regions to be printed.  The output will go to
FILEHANDLE if provided, STDOUT if not.

Minus strand genes are automatically reverse complemented so as to be
represented in the direction of transcription.  In unspliced
representations, the CDS region is capitalized.

=item dump_proteins($species [,\*FILEHANDLE])

Given the species, print a FASTA file representing each translated
protein in the genome.  Output goes to FILEHANDLE or to STDOUT by
default.

=back

=head1 SEE ALSO

L<Bio::DB::GFF>
L<ElegansSubs>

=head1 AUTHOR

Lincoln Stein E<lt>lstein@cshl.orgE<gt>.

Copyright (c) 2004 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

sub dump_genome {
    my $species  = _guess_species(shift);
    my $fh       = shift || \*STDOUT;
    my $db       = _open_database($species);
    my $out      = Bio::SeqIO->new(-format=>'fasta',-fh=>$fh);
    my $filter   = $config{$species}{genome}{filter};
    my $method   = $config{$species}{genome}{method};
    my @segments = grep {$_->display_id =~ /$filter/} $db->features($method);
    $out->write_seq($_) foreach @segments;
}

sub dump_genes {
    my $species = _guess_species(shift);
    my $spliced = shift;
    my $fh      = shift || \*STDOUT;
    my $db       = _open_database($species);
    my $out      = Bio::SeqIO->new(-format=>'fasta',-fh=>$fh);
    my $method   = $config{$species}{genes}{method};
    my $filter   = $config{$species}{genes}{filter};
    _dump_genes($db,$method,$filter,$spliced,0,$out);
}

sub dump_proteins {
    my $species = _guess_species(shift);
    my $fh      = shift || \*STDOUT;
    my $db       = _open_database($species);
    my $out      = Bio::SeqIO->new(-format=>'fasta',-fh=>$fh);
    my $method   = $config{$species}{genes}{method};
    my $filter   = $config{$species}{genes}{filter};
    _dump_genes($db,$method,$filter,1,1,$out);
}

sub _dump_genes {
    my $db                       = shift;
    my ($method,$filter,$splice,$translate,$out) = @_;

    # can't translate without splicing
    $splice ||= $translate;

    my $iterator = $db->get_seq_stream($method);
    while (my $s = $iterator->next_feature) {
	next unless $s->display_id =~ /$filter/;

	my %seen;
	my @notes     = grep {!$seen{$_}++} $s->notes;
	my $wormpep   = $s->attributes('WormPep');
	push @notes,"WormPep $wormpep" if defined $wormpep;
	my $notes     = join '; ',@notes;

	my @cds = $s->segments('coding_exon');

	my $seq = lc $s->seq;
	my $spliced_seq = '';

	for my $c (@cds) {
	    $c->ref($s);
	    my ($start,$end) = ($c->start,$c->end);
	    if ($splice) {
		$spliced_seq .= uc substr($seq,$start-1,$end-$start+1);
	    } else {
		substr($seq,$start-1,$end-$start+1) =~ tr/a-z/A-Z/;
	    }
	}

	my $bs = $splice ? $spliced_seq : $seq;
	next unless $bs;  # buggy data or buggy aggregator -not sure which
	if ($translate) {
	    my $ref = $s->abs_ref;
	    my $codon_table = $ref=~/mit/i ? 3 : 1;
	    $bs    = Bio::PrimarySeq->new($bs)->translate(undef,undef,undef,$codon_table)->seq;
	}

	$out->write_seq(Bio::Seq->new(-display_id=> $s->display_id,
				      -desc      => $notes,
				      -seq       => $bs));
    }
}



sub _open_database {
    my $species     = shift;
    my $db_name     = $config{$species}{db}                or croak "Invalid species $species";
    my $aggregators = $config{$species}{aggregators}       or croak "Invalid species $species";
    return Bio::DB::GFF->new(-dsn         => $db_name,
			     -aggregators => $aggregators) or croak "Couldn't open database $db_name";
}

sub _guess_species {
  my $species = shift;
  return 'Caenorhabditis elegans' unless $species;
  return $species                 if $reverse_species{$species};

  return $species_table{$species} if exists $species_table{$species};
  return $species_table{"C$species"} if exists $species_table{"C$species"};

  if ($species =~ /^C\.?\s*(\w+)/) {
      return $species_table{"C$1"} if exists $species_table{"C$1"};
  }
  croak "Couldn't turn $species into a recognized species";
}
