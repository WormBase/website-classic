#!/usr/bin/perl

#
# Convert WormBase GFF2 to GFF3
#

use warnings;
use strict;

use Text::ParseWords qw(quotewords);
use Getopt::Long;
use Data::Dumper;
use Carp;
use Digest::MD5 qw(md5);

# - Superceded -
# This URL corresponds to sofa.ontology file of SOFA Release 2 (the release 2
# file is labeled as revision 1.32, but is identical to 1.28, revision 1.32
# is inaccessible through the public CVS)
# our $DEFAULT_SOFA = qq[GET 'http://song.cvs.sourceforge.net/*checkout*/song/ontology/sofa.ontology?revision=1.28' |];

# Default SOFA file
# SOFA Release 2.1 is available. Also switching to sofa.obo (instead
# of sofa.ontology)
our $DEFAULT_SOFA =
  qq[GET 'http://song.cvs.sourceforge.net/*checkout*/song/ontology/sofa.obo?revision=1.54' |];

my $usage = qq($0 [-sofa <SOFA file>] [-sort] -species <elegans|briggsae> -gff <gff file>);

my $sofa;
my $sort;
my $species;
my $gff;

GetOptions(
    'gff=s'     => \$gff,
    'sofa=s'    => \$sofa,
    'species=s' => \$species,
    'sort'      => \$sort,
  )
  or die $usage;

die $usage unless $gff;
die "GFF file ($gff) cannot have gff3 extension!"
    if $gff =~ /\.gff3$/i;

$sofa ||= $DEFAULT_SOFA;
our $DEFAULT_SOFA_TERMS = parse_sofa($sofa);

die $usage if (!$species || $species !~ /^(elegans|briggsae)$/);

# Open file handles for various repositories
my $file = $gff;

my $gff3 = $file;
$gff3 =~ s/\.[^\.]+$//;
$gff3 .= '.gff3';

open(FILE, "<$file") or croak("Cannot read file ($file): $!");
open(NOT_PARSED, ">$file.not_parsed")
  or croak("Cannot write file ($file.not_parsed): $!");
open(TMP_GFF, ">$file.gff3.TMP") or croak("Cannot write file ($file.gff3.TMP): $!");
open(GFF, ">$gff3") or croak("Cannot write file ($gff3): $!");
open(LOG, ">$file.log")  or croak("Cannot write file ($file.log): $!");
open(DISCARD, ">$file.discard")
  or croak("Cannot write file ($file.not_needed): $!");
open(NO_TERM, ">$file.no_term")
  or croak("Cannot write file ($file.no_term): $!");
open(DUPLICATE, ">$file.duplicate")
  or croak("Cannot write file ($file.duplicate): $!");

# Global vars for filehandles
our $NOT_PARSED = \*NOT_PARSED;
our $TMP_GFF    = \*TMP_GFF;
our $GFF        = \*GFF;
our $LOG        = \*LOG;
our $DISCARD    = \*DISCARD;
our $NO_TERM    = \*NO_TERM;
our $DUPLICATE  = \*DUPLICATE;

# Containers
our %GENE;
our %TRANSCRIPT;
our @CDS;

# Lookup tables (all practically 1-to-1)
our %TRANSCRIPT2GENE; # many-to-1
our %TRANSCRIPT2CDS;  # many-to-1
our %GENE2TRANSCRIPT; # 1-to-many
our %CDS2TRANSCRIPT;  # 1-to-many
our %CDS2WORMPEP;     # 1-to-1
our %CDS2BRIGPEP;     # 1-to-1

our %PSEUDOGENES_BY_EXON; # Index
our %PSEUDOGENES_BY_BLOCK; # Index

# Lookup tables for attributes
our %TRANSCRIPT_ATTRIBUTES;
our %CDS_ATTRIBUTES;

# Target id tracker
our $MAX_TARGET_ID_NUMBER = 0;
our %TARGET_IDS;

# Duplicate line tracker
our %PREPROCESS_MD5_LIST;
our %CDS_MD5_LIST;

# Sofa terms
my %SOFA_TERMS = (
    Clone_left_end                        => 'clone_insert_start',
    Clone_right_end                       => 'clone_insert_end',
    coding_exon                           => 'exon',
    complex_change_in_nucleotide_sequence => 'complex_substitution',
    miRNA_primary_transcript              => 'miRNA',
    misc_feature                          => 'region',
    rRNA_primary_transcript               => 'rRNA',
    scRNA_primary_transcript              => 'scRNA',
    SL1_acceptor_site                     => 'trans_splice_acceptor_site',
    SL2_acceptor_site                     => 'trans_splice_acceptor_site',
    snoRNA_primary_transcript             => 'snoRNA',
    snRNA_primary_transcript              => 'snRNA',
    tRNA_primary_transcript               => 'tRNA',
    Pseudogene                            => 'pseudogene',
    Sequence                              => 'region',
    rflp_polymorphism                     => 'RFLP_fragment',
);

# Feature list
our %TRANSCRIPT_INDEX_FEATURES = map { $_ => 1 } qw(
  Transcript:Coding_transcript
  Transcript:ncRNA
  Transcript:snlRNA
  miRNA_primary_transcript:miRNA
  ncRNA_primary_transcript:ncRNA
  nc_primary_transcript:Non_coding_transcript
  protein_coding_primary_transcript:Coding_transcript
  rRNA_primary_transcript:rRNA
  scRNA_primary_transcript:scRNA
  snoRNA_primary_transcript:snoRNA
  snRNA_primary_transcript:snRNA
  tRNA_primary_transcript:tRNA
  tRNA_primary_transcript:tRNAscan-SE-1.23
);

# Feature list
our %CDS_INDEX_FEATURES = map { $_ => 1 } qw(
  CDS:curated
  CDS:Genefinder
  CDS:GeneMarkHMM
  CDS:history
  CDS:mSplicer_orf
  CDS:mSplicer_transcript
  CDS:twinscan
);

# Feature list (make an mRNA & a CDS for each of these)
our %GENE_FEATURES = map { $_ => 1 } qw(
  coding_exon:Coding_transcript
  intron:Coding_transcript
  five_prime_UTR:Coding_transcript
  three_prime_UTR:Coding_transcript
);

# Feature list (convert into a CDS)
our %PREDICTED_CDS_FEATURES = map { $_ => 1 } qw(
  coding_exon:Genefinder
  coding_exon:GeneMarkHMM
  coding_exon:history
  coding_exon:mSplicer_orf
  coding_exon:mSplicer_transcript
  coding_exon:twinscan
);

# Feature list (make only a Transcript for each of these)
our %NCRNA_FEATURES = map { $_ => 1 } qw(
  exon:miRNA
  exon:ncRNA
  intron:ncRNA  
  exon:Non_coding_transcript
  intron:Non_coding_transcript
  exon:rRNA
  exon:scRNA
  exon:snoRNA
  exon:snRNA
  exon:snlRNA
  exon:tRNA
  exon:tRNAscan-SE-1.23
);

# Feature list
our %ONLY_MRNA_FEATURES = map { $_ => 1 } qw(
  ncRNA:RNAz
);

# Feature list
our %PSEUDOGENE_FEATURES = map { $_ => 1 } qw(
  exon:Pseudogene
  Pseudogene:Pseudogene
  exon:history
  Pseudogene:history
);

# Feature list
our %REGULAR_FEATURES = map { $_ => 1 } qw(
  binding_site:miRanda
  binding_site:PicTar
  cDNA_match:BLAT_mRNA_BEST
  cDNA_match:BLAT_mRNA_OTHER
  Clone_left_end:misc_feature
  Clone_right_end:misc_feature
  complex_change_in_nucleotide_sequence:Allele
  complex_substitution:misc_feature
  deletion:Allele
  EST_match:BLAT_EST_BEST
  EST_match:BLAT_EST_OTHER
  experimental_result_region:cDNA_for_RNAi
  experimental_result_region:Expr_profile
  expressed_sequence_match:BLAT_OST_BEST
  expressed_sequence_match:BLAT_OST_OTHER
  gene:landmark
  insertion:Allele
  inverted_repeat:inverted
  misc_feature:binding_site
  nucleotide_match:BLAT_BAC_END
  nucleotide_match:BLAT_briggsae_est
  nucleotide_match:BLAT_elegans_est
  nucleotide_match:BLAT_elegans_mrna
  nucleotide_match:BLAT_elegans_ost
  nucleotide_match:BLAT_EST_BEST
  nucleotide_match:BLAT_EST_OTHER
  nucleotide_match:BLAT_mRNA_BEST
  nucleotide_match:BLAT_mRNA_OTHER
  nucleotide_match:BLAT_ncRNA_BEST
  nucleotide_match:BLAT_ncRNA_OTHER
  nucleotide_match:BLAT_NEMATODE
  nucleotide_match:BLAT_OST_BEST
  nucleotide_match:BLAT_OST_OTHER
  nucleotide_match:BLAT_TC1_BEST
  nucleotide_match:BLAT_TC1_OTHER
  nucleotide_match:BLAT_WASHU
  nucleotide_match:TEC_RED
  nucleotide_match:waba_coding
  nucleotide_match:waba_strong
  nucleotide_match:waba_weak
  nucleotide_match:wublastx
  oligo:misc_feature
  operon:operon
  PCR_product:GenePair_STS
  PCR_product:Orfeome
  PCR_product:Promoterome
  polyA_signal_sequence:polyA_signal_sequence
  polyA_site:polyA_site
  polymorphism:predicted
  protein_match:wublastx
  reagent:Expr_pattern
  reagent:Oligo_set
  region:Genbank
  region:Genomic_canonical
  region:Link
  region:Vancouver_fosmid
  repeat_region:RepeatMasker
  rflp_polymorphism:predicted       
  RNAi_reagent:RNAi_primary
  RNAi_reagent:RNAi_secondary
  SAGE_tag:SAGE_tag
  SAGE_tag:SAGE_tag_genomic_unique
  SAGE_tag:SAGE_tag_most_three_prime
  SAGE_tag:SAGE_tag_unambiguously_mapped
  Sequence:contig  
  Sequence:Genomic_canonical       
  sequence_variant:Allele
  sequence_variant:misc_feature
  SL1_acceptor_site:SL1
  SL2_acceptor_site:SL2
  SNP:Allele
  substitution:Allele
  tandem_repeat:tandem
  translated_nucleotide_match:BLAT_NEMATODE
  translated_nucleotide_match:BLAT_NEMBASE
  translated_nucleotide_match:BLAT_WASHU
  translated_nucleotide_match:mass_spec_genome
  transposable_element_insertion_site:Allele
  transposable_element_insertion_site:Mos_insertion_allele
  transposable_element:Transposon       
  transposable_element:Transposon_CDS
);

# Feature list
our %DISCARD_FEATURES = map { $_ => 1 } qw(
  coding_exon:curated
  coding_exon:Transposon_CDS
  exon:Coding_transcript
  exon:curated
  exon:Genefinder
  exon:GeneMarkHMM
  exon:mSplicer_orf
  exon:mSplicer_transcript
  exon:Transposon
  exon:Transposon_CDS
  exon:twinscan
  gene:curated
  gene:gene
  intron:.
  intron:curated
  intron:Transposon
  intron:Transposon_CDS
  intron:Genefinder
  intron:history
  intron:twinscan
  intron:Pseudogene
  processed_transcript:gene
  Sequence:.
  Transcript:history
);

# Keys to clean
my %KEYS_TO_CONVERT = (
    'miRanda:binding_site'                       => 'binding_site:miRanda',
    'PicTar:binding_site'                        => 'binding_site:PicTar',
    'ALLELE:.'                                   => 'sequence_variant:misc_feature',
    'misc_feature:Deletion_and_insertion allele' => 'complex_substitution:misc_feature',
    'oligo:.'                                    => 'oligo:misc_feature',
    'RNAz:ncRNA'                                 => 'ncRNA:RNAz',
    'Clone_left_end:.'                           => 'Clone_left_end:misc_feature',
    'Clone_right_end:.'                          => 'Clone_right_end:misc_feature',
);

# Keys to clean if briggsae [*** briggsae exception ***]
if ($species eq 'briggsae') {
    $KEYS_TO_CONVERT{'coding_exon:curated'} = 'coding_exon:Coding_transcript';
    $KEYS_TO_CONVERT{'intron:curated'}      = 'intron:Coding_transcript';
}

# Keys to add gene
my %KEYS_TO_ADD_GENE =  map { $_ => 1 } qw(
  tRNA_primary_transcript:tRNAscan-SE-1.23
  ncRNA:RNAz
);

# Keys to add gene/cds
my %KEYS_TO_ADD_GENE_CDS =  map { $_ => 1 } qw(
  protein_coding_primary_transcript:Coding_transcript
);

# Order of reserved tags
our %TAG_ORDER = (
    'ID'            => 10,
    'Parent'        => 9,
    'Alias'         => 8,
    'Name'          => 7,
    'Target'        => 6,
    'Gap'           => 5,
    'Derives_from'  => 4,
    'Note'          => 3,
    'Dbxref'        => 2,
    'Ontology_term' => 1,
);

# List of reference sequences (seq_ids) and their last position 
# (to be used by sequence-region directive)
our %SEQUENCE_REGION_ENDS;

# Chromosome names
our %CHROMOSOME_NAMES = ( I             => 1,
                          II            => 2, 
                          III           => 3, 
                          IV            => 4, 
                          V             => 5, 
                          X             => 6, 
                          MtDNA         => 7,
                          chrI          => 8,
                          chrI_random   => 9,
                          chrII         => 10,
                          chrII_random  => 11,
                          chrIII        => 12,
                          chrIII_random => 13,
                          chrIV         => 14,
                          chrIV_random  => 15,
                          chrV          => 16,
                          chrV_random   => 17,
                          chrX          => 18,
                          chrUn         => 19,
                          );

# Read file
my $line_counter = 0;
while (my $line = <FILE>) {
    chomp $line;

    $line_counter++;
    print STDERR "Line: $line_counter " . time . "\n" 
        if $line_counter%100000 == 0;
    
    # No need for directives, comments, empty lines
    if ($line =~ /^#/ || !$line) {
        print DISCARD "$line\n";
        next;
    }    
    
    # Check duplicates
    my $digest = md5($line);
    if ($PREPROCESS_MD5_LIST{$digest}) {
        print $DUPLICATE "$line\n";
        next;
    }
    else {
        $PREPROCESS_MD5_LIST{$digest} = 1;
    }

    # Cleaning
    my $feature = parse_line($line);
    if (!defined $feature) {
        print $NOT_PARSED "$line\n";
        next;
    }

    # Cleaning
    if ($feature->{start} == 0) {
        $feature->{start}++;
        $feature->{end}++;
        print $LOG "zero-based feaure shifted: $line\n";
    }

    my $ref        = $feature->{ref};
    my $source     = $feature->{source};
    my $method     = $feature->{method};
    my $start      = $feature->{start};
    my $end        = $feature->{end};
    my $score      = $feature->{score};
    my $strand     = $feature->{strand};
    my $phase      = $feature->{phase};
    my $attributes = $feature->{attributes};

    my $key = "$method:$source";

    # Cleaning    
    if (!$ref) {
        print $NOT_PARSED "no-ref: $line\n";
        next;
    }    

    # Cleaning
    if ($KEYS_TO_CONVERT{$key}) {
        my ($new_method, $new_source) = split(':', $KEYS_TO_CONVERT{$key});
        $feature->{method} = $new_method;
        $feature->{source} = $new_source;

        $method = $feature->{method};
        $source = $feature->{source};

        $key = "$method:$source";
    }

    # Cleaning
    if ($KEYS_TO_ADD_GENE{$key}) {
        my $transcript = $feature->{attributes}->{Transcript};
        if (!$transcript) {
            print $NOT_PARSED "No Transcript for $key: $line\n";
            next;
        }    

        my $gene = $feature->{attributes}->{Gene};
        if ($gene) {
            print $NOT_PARSED "Gene exists for $key: $line\n";
            next;
        }    
        
        $feature->{attributes}->{Gene} = $transcript;
    }        

    # Cleaning
    if ($KEYS_TO_ADD_GENE_CDS{$key}) {
        my $transcript = $feature->{attributes}->{Transcript};
        if (!$transcript) {
            print $NOT_PARSED "No Transcript for $key: $line\n";
            next;
        }    

        my $gene_cds = $feature->{attributes}->{Gene} || $feature->{attributes}->{CDS};
        if ($gene_cds) {
            print $NOT_PARSED "Gene/CDS exists for $key: $line\n";
            next;
        }    
        
        my ($cds) = $transcript =~ /^([^\.]+\.\d+[a-z]*)/;
        $feature->{attributes}->{CDS} = $cds;

        my ($gene) = $transcript =~ /^([^\.]+\.\d+)/;
        $feature->{attributes}->{Gene} = $gene;
    }        

    # Use this feature to generate lookup tables for coding genes
    if ($TRANSCRIPT_INDEX_FEATURES{$key} || $CDS_INDEX_FEATURES{$key}) {
        my $gene       = $attributes->{Gene};
        my $transcript = $attributes->{Transcript};
        my $cds        = $attributes->{CDS};
        my $wormpep    = $attributes->{WormPep};
        my $brigpep    = $attributes->{Brigpep};
        
        # Sanity check
        if (($TRANSCRIPT_INDEX_FEATURES{$key} && !$transcript)
            ||
            ($CDS_INDEX_FEATURES{$key} && !$cds)) {
            print $LOG "Invalid index: $line\n";
        }    

        # Remove attributes that have been accounted for
        foreach my $attribute (qw(Gene Transcript CDS WormPep Brigpep)) {
            delete $attributes->{$attribute} if $attributes->{$attribute};
        }
        
        # Record remaining attributes, consider type of feature
        foreach my $attribute (keys %{$attributes}) {
            my $value = $attributes->{$attribute};
            
            if ($TRANSCRIPT_INDEX_FEATURES{$key}) {
                $TRANSCRIPT_ATTRIBUTES{$transcript}{$attribute} = $value;
            }
            if ($CDS_INDEX_FEATURES{$key}) {
                $CDS_ATTRIBUTES{$cds}{$attribute} = $value;
            }
        }
        
        # Make indexes
        $TRANSCRIPT2GENE{$transcript} = $gene
          if ($transcript && $gene);
        $TRANSCRIPT2CDS{$transcript} = $cds
          if ($transcript && $cds);
        $CDS2WORMPEP{$cds}  = $wormpep
          if ($cds && $wormpep);
        $CDS2BRIGPEP{$cds}  = $brigpep
          if ($cds && $brigpep);

        print $DISCARD $line . "\n";
        next;
    }

    elsif ($GENE_FEATURES{$key}) {
        my $transcript = $attributes->{Transcript};
        print $LOG "No Transcript: $line\n" unless $transcript;
        delete $attributes->{Transcript};
        
        # [*** briggsae exception ***]
        if (!$transcript && $species eq 'briggsae' && $attributes->{CDS}) {
            $transcript = $attributes->{CDS};
            print $LOG "Added Transcript from CDS: $line\n";
        }    

        # Preserve original feature as an exon, link it to Transcript
        $attributes->{Parent} = "Transcript:$transcript" if $transcript;
        
        # Create the Transcript
        if ($transcript) {
            $TRANSCRIPT{$transcript}{ref}    = $ref;
            $TRANSCRIPT{$transcript}{source} = $source;
            $TRANSCRIPT{$transcript}{method} = 'mRNA';
            $TRANSCRIPT{$transcript}{start}  = $start
              if !exists $TRANSCRIPT{$transcript}{start}
              or $TRANSCRIPT{$transcript}{start} > $start;
            $TRANSCRIPT{$transcript}{end} = $end
              if !exists $TRANSCRIPT{$transcript}{end}
              or $TRANSCRIPT{$transcript}{end} < $end;
            $TRANSCRIPT{$transcript}{score}      = $score;
            $TRANSCRIPT{$transcript}{strand}     = $strand;
            $TRANSCRIPT{$transcript}{phase}      = '.';
            $TRANSCRIPT{$transcript}{attributes} =
              {ID => "Transcript:$transcript"};
        }
        
        # Make a copy of the feature a CDS (only for coding_exon)
        if ($method eq 'coding_exon') {
            my $cds = $attributes->{CDS};
            print $LOG "No CDS: $line\n" unless $cds;
            delete $attributes->{CDS};
            
            my %cds_attributes = %{$attributes};
            delete $cds_attributes{Parent};
            $cds_attributes{ID} = "CDS:$cds";

            my $cds_feature = {
                ref        => $ref,
                source     => $source,
                method     => 'CDS',
                start      => $start,
                end        => $end,
                score      => $score,
                strand     => $strand,
                phase      => $phase,
                attributes => \%cds_attributes,
            };
            
            # Notify when no phase
            print $LOG "No phase for cds: $line\n" 
                if (!defined $phase || $phase eq '.');

            push @CDS, $cds_feature;
        }
    }

    elsif ($PREDICTED_CDS_FEATURES{$key}) {
        my $cds = $attributes->{CDS} || $attributes->{Transcript};
        delete $attributes->{CDS};
        delete $attributes->{Transcript};
                
        # Discard when no CDS
        if (!$cds) {
            print $NOT_PARSED "no-cds: $line\n"; 
            next;
        }

        # Discard when no phase
        if (!defined $phase || $phase eq '.') {
            print $NOT_PARSED "no-phase-for-cds: $line\n"; 
            next;
        }
        
        # Convert this into a CDS feature
        $attributes->{ID}  = "CDS:$cds";
        $feature->{method} = 'CDS';
        $method            = $feature->{method};

#         # Create a placeholder mRNA - create parent
#         $attributes->{Parent} = "Transcript:$cds";
# 
#         # For each coding_exon, create a CDS part
#         if ($method eq 'coding_exon') {
#             # Discard when no phase
#             if (!defined $phase || $phase eq '.') {
#                 print $NOT_PARSED "no-phase-for-cds: $line\n"; 
#                 next;
#             }
# 
#             # Create a CDS feature
#             my $cds_feature = {
#                 ref         => $ref,
#                 source      => $source,
#                 method      => 'CDS',
#                 start       => $start,
#                 end         => $end,
#                 score       => $score,
#                 strand      => $strand,
#                 phase       => $phase,
#                 attributes  => {%$attributes},
#             };
#             $cds_feature->{attributes}->{ID}     = "CDS:$cds";
#             $cds_feature->{attributes}->{Parent} = "Transcript:$cds";
# 
#             push @CDS, $cds_feature;
#         }
#         
#         # Create a placeholder mRNA - create the mRNA feature
#         $TRANSCRIPT{$cds}{ref}    = $ref;
#         $TRANSCRIPT{$cds}{source} = $source;
#         $TRANSCRIPT{$cds}{method} = 'mRNA';
#         $TRANSCRIPT{$cds}{start}  = $start
#           if !exists $TRANSCRIPT{$cds}{start}
#           or $TRANSCRIPT{$cds}{start} > $start;
#         $TRANSCRIPT{$cds}{end} = $end
#           if !exists $TRANSCRIPT{$cds}{end}
#           or $TRANSCRIPT{$cds}{end} < $end;
#         $TRANSCRIPT{$cds}{score}      = $score;
#         $TRANSCRIPT{$cds}{strand}     = $strand;
#         $TRANSCRIPT{$cds}{phase}      = $phase;
#         $TRANSCRIPT{$cds}{attributes} =
#           { ID => "Transcript:$cds", 
#             placeholder_transcript => 1
#            };
#     
#         # Populate indexes
#         $TRANSCRIPT2GENE{$cds} = $cds;
#         $TRANSCRIPT2CDS{$cds}  = $cds;
    }

    elsif ($NCRNA_FEATURES{$key}) {
        my $transcript = $attributes->{Transcript};
        print $LOG "No Transcript: $line\n" unless $transcript;
        delete $attributes->{Transcript};

        # Preserve original feature as an exon, link it to Transcript
        $attributes->{Parent} = "Transcript:$transcript";
        
        # Create the Transcript
        $TRANSCRIPT{$transcript}{ref}    = $ref;
        $TRANSCRIPT{$transcript}{source} = $source;
        $TRANSCRIPT{$transcript}{method} = 'ncRNA';
        $TRANSCRIPT{$transcript}{start}  = $start
          if !exists $TRANSCRIPT{$transcript}{start}
          or $TRANSCRIPT{$transcript}{start} > $start;
        $TRANSCRIPT{$transcript}{end} = $end
          if !exists $TRANSCRIPT{$transcript}{end}
          or $TRANSCRIPT{$transcript}{end} < $end;
        $TRANSCRIPT{$transcript}{score}      = $score;
        $TRANSCRIPT{$transcript}{strand}     = $strand;
        $TRANSCRIPT{$transcript}{phase}      = $phase;
        $TRANSCRIPT{$transcript}{attributes} =
          {ID => "Transcript:$transcript"};
    }

    elsif ($ONLY_MRNA_FEATURES{$key}) {
        my $transcript = $attributes->{Transcript};
        delete $attributes->{Transcript} if exists $attributes->{Transcript};

        my $gene = $attributes->{Gene};
        delete $attributes->{Gene} if exists $attributes->{Gene};
        
        # Exception to indexing
        if ($transcript && $gene) {
            $TRANSCRIPT2GENE{$transcript} = $gene;
        }
        else {
            print $NOT_PARSED "ERROR: Incomplete info: $line\n";
            next;
        }    

        print $LOG "No transcript: $line\n" unless $transcript;

        print $LOG "Transcript exists: $line\n" if $TRANSCRIPT{$transcript};

        $attributes->{ID} = "Transcript:$transcript" if $transcript;

        my @alias;
        foreach my $tag (qw(Alias Gene)) {
            if ($attributes->{$tag}) {
                push @alias, $attributes->{$tag};
                delete $attributes->{$tag};
            }
        }

        $attributes->{Alias} = join(',', @alias) if @alias;

        $TRANSCRIPT{$transcript}{ref}        = $ref;
        $TRANSCRIPT{$transcript}{source}     = $source;
        $TRANSCRIPT{$transcript}{method}     = $method;
        $TRANSCRIPT{$transcript}{start}      = $start;
        $TRANSCRIPT{$transcript}{end}        = $end;
        $TRANSCRIPT{$transcript}{score}      = $score;
        $TRANSCRIPT{$transcript}{strand}     = $strand;
        $TRANSCRIPT{$transcript}{phase}      = $phase;
        $TRANSCRIPT{$transcript}{attributes} = $attributes;

        next;
    }

    elsif ($REGULAR_FEATURES{$key}) {

        # DO NOT DO ANYTHING
    }

    elsif ($PSEUDOGENE_FEATURES{$key}) {
        my $pseudogene = $attributes->{Pseudogene};
        delete $attributes->{Pseudogene};

        # Discard when no pseudogene
        if (!$pseudogene) {
            print $NOT_PARSED "no-pseudogene: $line\n"; 
            next;
        }
        
        my $id = "Pseudogene:$pseudogene";

        if ($method eq 'exon') {
            $feature->{attributes}->{ID} = $id;
            $feature->{method} = 'pseudogene';
            $method            = $feature->{method};
            
            $PSEUDOGENES_BY_EXON{$id}{start} = $start if
                !$PSEUDOGENES_BY_EXON{$id}{start} 
                or $start < $PSEUDOGENES_BY_EXON{$id}{start};
            $PSEUDOGENES_BY_EXON{$id}{end} = $end if
                !$PSEUDOGENES_BY_EXON{$id}{end} 
                or $end > $PSEUDOGENES_BY_EXON{$id}{end};
        }

        elsif ($method eq 'Pseudogene') {
            $PSEUDOGENES_BY_BLOCK{$id}{start} = $start if
                !$PSEUDOGENES_BY_BLOCK{$id}{start} 
                or $start < $PSEUDOGENES_BY_BLOCK{$id}{start};
            $PSEUDOGENES_BY_BLOCK{$id}{end} = $end if
                !$PSEUDOGENES_BY_BLOCK{$id}{end} 
                or $end > $PSEUDOGENES_BY_BLOCK{$id}{end};
            print $DISCARD "$line\n";
            next;
#            $feature->{method}                   = 'region';
#            $feature->{attributes}->{ID}         = $id;
#            $feature->{attributes}->{pseudogene} = 1;
        }
    }

    elsif ($DISCARD_FEATURES{$key}) {
        print $DISCARD "$line\n";
        next;
    }

    else {
        print $NOT_PARSED "not-listed: $line\n";
        next;
    }

    if ($SOFA_TERMS{$method}) {
        $feature->{method} = $SOFA_TERMS{$method};
    }

    elsif ($DEFAULT_SOFA_TERMS->{$method}) {

        # OK;
    }
    else {
        print $NO_TERM "$line\n";
        next;
    }

    # Dump feature if it passes the filters
    dump_feature($feature);
}

# Check if all pseudogene "gene models" have been dumped
foreach my $id (keys %PSEUDOGENES_BY_EXON) {
    if (!$PSEUDOGENES_BY_BLOCK{$id}) {
        print $LOG "Pseudogene has gene model but not block feature: $id\n";
    }
}

foreach my $id (keys %PSEUDOGENES_BY_BLOCK) {
    if (!$PSEUDOGENES_BY_EXON{$id}) {
        print $LOG "Pseudogene has block feature but not gene model: $id\n";
    }
    if ($PSEUDOGENES_BY_EXON{$id}{start} != $PSEUDOGENES_BY_EXON{$id}{start}
        or
        $PSEUDOGENES_BY_EXON{$id}{end} != $PSEUDOGENES_BY_EXON{$id}{end}) {
        print $LOG "Pseudogene block feature and not gene model coordinates do not match: $id\n";
    }            
}

# Build 1-to-many indexes
foreach my $transcript (keys %TRANSCRIPT2GENE) {
    my $gene = $TRANSCRIPT2GENE{$transcript};
    
    push @{$GENE2TRANSCRIPT{$gene}}, $transcript;
}

foreach my $transcript (keys %TRANSCRIPT2CDS) {
    my $cds = $TRANSCRIPT2CDS{$transcript};
    
    push @{$CDS2TRANSCRIPT{$cds}}, $transcript;
}

# Dump transcripts & prepare genes
foreach my $transcript (sort keys %TRANSCRIPT) {
    my $gene = $TRANSCRIPT2GENE{$transcript};
    print $LOG "No Gene for Transcript: $transcript\n" unless $gene;

    my $cds = $TRANSCRIPT2CDS{$transcript};
    print $LOG "No CDS for Transcript: $transcript\n" 
        if (!$cds && $TRANSCRIPT{$transcript}{method} ne 'ncRNA');

    my $wormpep = $CDS2WORMPEP{$cds} if $cds;
    print $LOG "No Wormpep for Transcript: $transcript; CDS: $cds\n"
        if ($species eq 'elegans' && $cds && !$wormpep);

    my $brigpep = $CDS2BRIGPEP{$cds} if $cds;
    print $LOG "No Brigpep for Transcript: $transcript; CDS: $cds\n"
        if ($species eq 'briggsae' && $cds && !$brigpep);

    # Add attributes
    my $add_attributes = $TRANSCRIPT_ATTRIBUTES{$transcript};
    if ($add_attributes) {
        foreach my $add_attribute (keys %$add_attributes) {
            if ($TRANSCRIPT{$transcript}{attributes}{$add_attribute}) {
                print $LOG "replacing attribute ($add_attribute) for transcript ($transcript)!\n";
            }
            $TRANSCRIPT{$transcript}{attributes}{$add_attribute} 
                = $add_attributes->{$add_attribute};
        }
    }            
    
    $TRANSCRIPT{$transcript}{attributes}{Parent}  = "Gene:$gene" if $gene;
    $TRANSCRIPT{$transcript}{attributes}{CDS}     = "$cds"       if $cds;
    $TRANSCRIPT{$transcript}{attributes}{WormPep} = "$wormpep"   if $wormpep;
    $TRANSCRIPT{$transcript}{attributes}{Brigpep} = "$brigpep"   if $brigpep;
        
    if ($gene) {
        $GENE{$gene}{ref}    = $TRANSCRIPT{$transcript}{ref};
        $GENE{$gene}{source} = $TRANSCRIPT{$transcript}{source};
        $GENE{$gene}{method} = 'gene';
        $GENE{$gene}{start}  = $TRANSCRIPT{$transcript}{start}
          if !exists $GENE{$gene}{start}
          or $GENE{$gene}{start} > $TRANSCRIPT{$transcript}{start};
        $GENE{$gene}{end} = $TRANSCRIPT{$transcript}{end}
          if !exists $GENE{$gene}{end}
          or $GENE{$gene}{end} < $TRANSCRIPT{$transcript}{end};
        $GENE{$gene}{score}      = $TRANSCRIPT{$transcript}{score};
        $GENE{$gene}{strand}     = $TRANSCRIPT{$transcript}{strand};
        $GENE{$gene}{phase}      = '.';
        $GENE{$gene}{attributes} = {ID => "Gene:$gene"};
        if ($TRANSCRIPT{$transcript}{attributes}{placeholder_transcript}) {
            $GENE{$gene}{attributes}{placeholder_gene} = 1;
        }    
    }

    my $method = $TRANSCRIPT{$transcript}{method};
    if ($SOFA_TERMS{$method}) {
        $TRANSCRIPT{$transcript}{method} = $SOFA_TERMS{$method};
    }
    elsif ($DEFAULT_SOFA_TERMS->{$method}) {

        # OK;
    }
    else {
        print $NO_TERM "transcript:$transcript\n";
        next;
    }

    dump_feature($TRANSCRIPT{$transcript});
}

# Dump genes
foreach my $gene (sort keys %GENE) {
    dump_feature($GENE{$gene});
}

# Dump CDS parts
foreach my $cds_feature (@CDS) {
    my $cds_id = $cds_feature->{attributes}->{ID};
    $cds_id =~ s/^[^:]+://;

    if ($species eq 'elegans') {
        if ($CDS2WORMPEP{$cds_id}) {
            $cds_feature->{attributes}->{WormPep} = $CDS2WORMPEP{$cds_id};
        }
        else {
            print $LOG "No WormPep for CDS: $cds_id\n";
        }
    }    

    if ($species eq 'briggsae') {
        if ($CDS2BRIGPEP{$cds_id}) {
            $cds_feature->{attributes}->{Brigpep} = $CDS2BRIGPEP{$cds_id};
        }
        else {
            print $LOG "No Brigpep for CDS: $cds_id\n";
        }
    }    

    # Add attributes
    my $add_attributes = $CDS_ATTRIBUTES{$cds_id};
    if ($add_attributes) {
        foreach my $add_attribute (keys %$add_attributes) {
            if ($cds_feature->{attributes}{$add_attribute}) {
                print $LOG "replacing attribute ($add_attribute) for cds ($cds_id)!\n";
            }
            $cds_feature->{attributes}->{$add_attribute} 
                = $add_attributes->{$add_attribute};
        }
    }

    my @transcript = @{$CDS2TRANSCRIPT{$cds_id}} if $CDS2TRANSCRIPT{$cds_id};
    my $transcript = join(',', map {"Transcript:$_"} @transcript);
    if ($transcript) {
        $cds_feature->{attributes}->{Parent} = "$transcript";
    }
    else {
        print $LOG "No Parent for CDS: $cds_id\n";
    }
    
    dump_feature($cds_feature);
}            

# Add header
print $GFF "##gff-version 3\n";
foreach my $ref (sort {$CHROMOSOME_NAMES{$a} <=> $CHROMOSOME_NAMES{$b}}
                 keys %SEQUENCE_REGION_ENDS) {
  print $GFF qq[##sequence-region $ref 1 $SEQUENCE_REGION_ENDS{$ref}\n];
}      

foreach my $ref (sort {$CHROMOSOME_NAMES{$a} <=> $CHROMOSOME_NAMES{$b}}
                 keys %SEQUENCE_REGION_ENDS) {
  print $GFF join("\t", $ref, 'Reference', 'chromosome', 1, $SEQUENCE_REGION_ENDS{$ref}, '.', '+', '.', qq[ID=$ref;Name=$ref]) . "\n";
}      

# Close all filehandles
close $NOT_PARSED;
close $TMP_GFF;
close $GFF;
close $LOG;
close $DISCARD;
close $NO_TERM;
close $DUPLICATE;

# Append file
my $cmd = $sort ? qq[sort -k1,1 -k3,3 -k2,2 -k4,4n -T /tmp $file.gff3.TMP >> $gff3]
                : qq[cat $file.gff3.TMP >> $gff3];
system($cmd) and croak("Cannot sort file ($cmd)!");

# print Dumper(\%TRANSCRIPT_ATTRIBUTES);
# print Dumper(\%CDS_ATTRIBUTES);

# [END]

sub dump_feature {
    my ($feature) = @_;

    # Cleaning
    if (!scalar(keys %{$feature->{attributes}})) {
        $feature->{attributes}->{placeholder_attribute} = 1;
    }    

    my $ref        = $feature->{ref};
    my $source     = $feature->{source};
    my $method     = $feature->{method};
    my $start      = $feature->{start};
    my $end        = $feature->{end};
    my $score      = $feature->{score};
    my $strand     = $feature->{strand};
    my $phase      = $feature->{phase};
    my $attributes = $feature->{attributes};

    my $reserved_attributes;
    my $other_attributes;
    foreach my $tag (keys %{$attributes}) {
        if ($TAG_ORDER{$tag}) {
            $reserved_attributes->{$tag} = $attributes->{$tag};
        }
        else {
            $other_attributes->{lc($tag)} = $attributes->{$tag};
        }
    }

    my @reserved_attributes = map { "$_=" . $reserved_attributes->{$_} }
      sort { $TAG_ORDER{$b} <=> $TAG_ORDER{$b} } keys %{$reserved_attributes};

    my @other_attributes = map { "$_=" . $other_attributes->{$_} }
      sort keys %{$other_attributes};

    my $attributes_string =
      join(';', @reserved_attributes, @other_attributes);

    my $feature_string = join(
        "\t",   $ref,    $source, $method, $start, $end,
        $score, $strand, $phase,  $attributes_string
    );

    # Record sequence region end
    if (!$SEQUENCE_REGION_ENDS{$ref}) {
        $SEQUENCE_REGION_ENDS{$ref} = 1;
    }  
    if ($end > $SEQUENCE_REGION_ENDS{$ref}) {
        $SEQUENCE_REGION_ENDS{$ref} = $end;
    }  

    if ($feature->{method} eq 'CDS') {
        my $cds_signature = md5($feature_string);
        if ($CDS_MD5_LIST{$cds_signature}) {
            $feature_string = undef;
        }    
        
        $CDS_MD5_LIST{$cds_signature} = 1;
    }
        
    print $TMP_GFF $feature_string . "\n" if defined $feature_string;
    
    return 1;
}

sub parse_line {
    my ($line) = @_;

    my ($ref,   $source, $method, $start, $end,
        $score, $strand, $phase,  $attributes
      )
      = split("\t", $line);

    # feature_signature id needed for Target ids
    my $feature_signature = join(':', $ref, $source, $method, $strand);

    $attributes = parse_attributes($attributes, $feature_signature);

    if (!defined $attributes) {
        return undef;
    }

    my $feature = {
        ref        => $ref,
        source     => $source,
        method     => $method,
        start      => $start,
        end        => $end,
        score      => $score,
        strand     => $strand,
        phase      => $phase,
        attributes => $attributes,
    };

    return $feature;
}

sub parse_attributes {
    my ($attributes, $feature_signature) = @_;

    my %attributes;

    return \%attributes unless $attributes;

    # Format Target
    if ($attributes =~ /^Target/) {
        $attributes =~ s/Target "([^\"]+)" ([\d-]+) ([\d-]+)\s*\;*\s*//;

        my ($target_sequence, $target_start, $target_end) = ($1, $2, $3);

        unless ($target_sequence && defined $target_start && defined $target_end) {
            print $NOT_PARSED "unparseable-target: ";
            return undef;
        }

        my $target_strand = '+';

        if ($target_start < 0 or $target_end < 0) {
            print $NOT_PARSED "negative-target: ";
            return undef;
        }

        if ($target_end < $target_start) {
            $target_strand = '-';
            ($target_start, $target_end) = ($target_end, $target_start);
        }

        $attributes{Target} =
          "$target_sequence $target_start $target_end $target_strand";

        $attributes =~ s/Target[^;]//;

        my $target_signature =
          join(':', $feature_signature, $target_sequence, $target_strand);

        my $target_id;
        if ($TARGET_IDS{$target_signature}) {
            $target_id = $TARGET_IDS{$target_signature};
        }
        else {
            $MAX_TARGET_ID_NUMBER++;
            $target_id = 'Target:' . sprintf('%.6u', $MAX_TARGET_ID_NUMBER);
            $TARGET_IDS{$target_signature} = $target_id;
        }

        $attributes{ID} = $target_id;
    }

    # Clean text - temporary
    if ($attributes =~ s/;\s*; .+//) {
        print $LOG "Discarded after double semicolon: $attributes\n";
    }    

    # Clean text
    $attributes =~ s/[\s;]+$//;

    # Clean free-text attribute in briggsae gff
    $attributes =~ s/ (orthologous to [^\;\s]+ by [^\;]+) /Note "$1"/;
    
    # Escape semi-colon
    $attributes =~ s/(\"[^\";]*;[^\";]*\"[^\";]*);/$1 %3B/g;

    # Escape comma
    $attributes =~ s/,/%2C/g;

    # Add Transcript for RNAz predictions
    $attributes =~ s/(RNAz-\d+)/Transcript $1/;

    # Fill empty fields
    $attributes =~ s/;\s*(\S+)\s*;/; $1 1 ;/g;
    $attributes =~ s/;\s*(\S+)\s*;/; $1 1 ;/g;

    # Fill empty fields
    $attributes =~ s/^\s*(\S+)\s*;/$1 1 ;/g;
    $attributes =~ s/;\s*(\S+)\s*$/; $1 1/g;
    $attributes =~ s/^\s*(\S+)\s*$/$1 1/g;

    my @tokens = quotewords('\s*;\s*|\s+', 0, $attributes);

    while (@tokens) {
        my $tag   = shift @tokens;
        my $value = escape(shift @tokens);

        $attributes{$tag} =
          defined $attributes{$tag}
          ? $attributes{$tag} . ",$value"
          : $value;
    }

    return \%attributes;
}

sub escape {
    my $toencode = shift;
    return $toencode unless defined $toencode;
    $toencode = unescape($toencode);    # Make safe
#    $toencode =~ s/([^a-zA-Z0-9_. :+-\*])/uc sprintf("%%%02x",ord($1))/eg;
    $toencode =~ s/([,;=\t])/uc sprintf("%%%02x",ord($1))/eg;
    $toencode;
}

sub unescape {
    my $string = shift;
    return $string unless defined $string;
    $string =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    return $string;
}

sub parse_sofa {
    my ($file) = @_;

    my $mode = 'Placeholder';

    open(FILE, $file) or die "Cannot open file ($file): $!";

    my %terms;

    while (my $line = <FILE>) {
        chomp $line;
        next unless $line;

        if ($line =~ /^\[([^\[\]]+)\]/) {
            $mode = $1;
            if (   $mode ne 'Term'
                && $mode ne 'Typedef'
                && $mode ne 'Placeholder') {
                die "Cannot parse sofa file ($line)";
            }
        }

        if ($mode eq 'Term' and $line =~ /^name:\s+(.+)/) {
            $terms{$1} = 1;
        }
    }

    close FILE;

    if (scalar(keys %terms) < 30)
    {    # Something *most likely* went wrong in acquiring/processing sofa
        die "Cannot retrieve/parse SOFA file!";
    }

    return \%terms;
}
