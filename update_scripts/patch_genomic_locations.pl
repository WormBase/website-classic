#!/usr/bin/perl -w

=head1 NAME

patch_genomic_locations.pl

=head1 SYNOPSIS

 patch_genomic_locations.pl -type <elegans_pep|elegans_est>
                            -datasource <datasource> -username <username> -password <password>                         
                            -file <file>

=head1 DESCRIPTION

Adds genomic locations to identifiers in a FASTA file.

=head1 USAGE

 patch_genomic_locations.pl -type <elegans_pep|elegans_est>
                            -datasource <datasource> -username <username> -password <password>                         
                            -file <file>

 -type          : (Required) type of identifiers in the FASTA file (elegans_pep, elegans_est)
 -datasource    : (Required) Datasource for source GFF file
 -username      : Username for source GFF file
 -password      : Password for source GFF file
 -file          : (Required) Source fasta file

=cut

#our %TYPES = (

use strict;
use Getopt::Long;
use Bio::DB::GFF;
use Bio::SeqIO;
use Carp;
use Data::Dumper;

# Usage
my $usage = qq[$0 -type <elegans_pep|elegans_est>
                            -datasource <datasource> -username <username> -password <password>                         
                            -file <file>];

# Parse command-line params
my $type;
my $datasource;
my $username;
my $password;
my $file;

my $result = GetOptions("type=s"      => \$type,
                        "datasource=s" => \$datasource,
                        "username=s"   => \$username,
                        "password=s"   => \$password,
                        "file=s"       => \$file,                       
                        ) or croak("Usage: $usage\n");

# Check command-line params
if (!$type or !$datasource) {
    croak("Usage: $usage\n");
}
if ($type ne "elegans_pep"
    &&
    $type ne "elegans_est"
    ) {
    croak("Usage: $usage\n");
}

$datasource = "dbi:mysql:dbname=$datasource" if $datasource !~ /:/;
my $file_out = "${file}.out";

# Prepare all handles
my $db = Bio::DB::GFF->new(-adaptor  => 'dbi::mysqlopt',
                           -dsn      => $datasource,
                           -username => $username,
                           -password => $password,
                           ) or croak("Cannot connect to database!");

my $seq_in  = Bio::SeqIO->new(-file => "$file", '-format' => 'Fasta');
my $seq_out = Bio::SeqIO->new(-file => ">$file_out", '-format' => 'Fasta');

# Prepare source index - this is a section in which the type of sequence source matters
my @gff_types;
if ($type eq "elegans_pep") { # This is WormPep
    @gff_types = qw[Transcript:Coding_transcript];
}  
elsif ($type eq "elegans_est") { # This is EST_Elegans
    @gff_types = qw[cDNA_match:BLAT_mRNA_BEST
                    EST_match:BLAT_EST_BEST
                    expressed_sequence_match:BLAT_OST_BEST
                    ];
#                translated_nucleotide_match:BLAT_NEMATODE
#                EST_match:BLAT_EST_OTHER

}  
else {
    croak("Unknown type ($type)!");  
}

my %index;
foreach my $gff_type (@gff_types) {
    my $io = $db->get_seq_stream(-types => [$gff_type]);
    while (my $feature = $io->next_seq) {
        my $display_id = $feature->display_id;
        my $ref        = $feature->ref;
        my $start      = $feature->start;
        my $end        = $feature->end;
        my $strand     = $feature->strand;

        if ($type eq "elegans_pep") {
            $display_id =~ s/^([^\.]+\.[^\.]+)\.[^\.]+$/$1/; # For protein sequences, remove isoform info
        }  

        if (exists $index{$display_id}) {
            if ($index{$display_id}{ref} ne $ref) {
                print STDERR "WARNING: Discarding duplicate id (id:$display_id ref:$ref start:$start end:$end type:$type)!\n";
                next;
            } 
            if ($start < $index{$display_id}{start}) {
                $index{$display_id}{start} = $start;
            }
            if ($end > $index{$display_id}{end}) {
                $index{$display_id}{end} = $end;
            }
        }

        else {
            $index{$display_id} = { ref     => $ref,
                                    start   => $start,
                                    end     => $end
                                   };
        }  
    }
}  

# Modify file  
while (my $seq = $seq_in->next_seq) {
	my $display_id = $seq->display_id;
	my $description = $seq->desc;

    if ($index{$display_id}) {
        my $ref   = $index{$display_id}{ref};
        my $start = $index{$display_id}{start};
        my $end   = $index{$display_id}{end};

        my $location_string = qq[/map=$ref/$start,$end]; # For consitentcy with Elegans db, do not switch coordinates for negative strand elements
        $seq->desc("$description " . $location_string);
    }

    else {
        print STDERR "WARNING: Cannot capture location info for sequence ($display_id)!\n";
    }  

    $seq_out->write_seq($seq);
}

=head1 SEE ALSO

=head1 AUTHOR

Payan Canaran <canaran@cshl.edu>

=head1 VERSION

$Id: patch_genomic_locations.pl,v 1.1.1.1 2010-01-25 15:36:09 tharris Exp $

=head1 CREDITS

=head1 COPYRIGHT AND LICENSE

Copyright 2006 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
