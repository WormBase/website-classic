#!/usr/bin/perl

use strict;
use warnings;
use Carp;

use Cwd;
use File::Copy;
use HTTP::Request;
use LWP::UserAgent;
use Data::Dumper;
use Bio::SeqIO;
use XML::Simple;
use File::Temp qw(tempfile);
use Getopt::Long;
use Time::Format qw(%time);
use Tie::IxHash;
use Config::General;

# Application specific key
our $KEY = 'COMPILE3DDATA';

# Loaded wormpep and wormcds files
our %WB_PROT  = ();
our %WB_CDS   = ();
our %CDS2PROT = ();

my $usage = qq[$0 -root <abs path to analysis root dir> 
     ( -new -release_id <release_id> -config <config file> -idx_ace ( initial | <ace file to be used as index> )  
     [-verbose] | -continue  )];

my $cmd = join(' ', $0, @ARGV);
my $cwd = getcwd();

my $root;
my $release_id;
my $config;
my $idx_ace;
my $new;
my $continue;
my $verbose;

GetOptions(
    'root=s'       => \$root,
    'release_id=s' => \$release_id,
    'config=s'     => \$config,
    'idx_ace=s'    => \$idx_ace,
    'new'          => \$new,
    'continue'     => \$continue,
    'verbose'      => \$verbose,
) or die("Usage: $usage\n");

# Check params
!$root and die("Usage: $usage\n");
if ($new) {
    (!$release_id or !$config) and die("Usage: $usage\n");
    $continue and die("Usage: $usage\n");
}
if ($continue) {
    ($release_id or $config or $idx_ace or $verbose)
      and die("Usage: $usage\n");
}

$root =~ /^\// or croak("Abs path is required for root!");

if ($continue) {
    tie my %cfg, "Tie::IxHash";
    my $cfg = Config::General->new(
        -ConfigFile      => "$root/params.conf",
        -InterPolateVars => 1,
        -Tie             => "Tie::IxHash"
    );
    %cfg = $cfg->getall();

    $config     = $cfg{config};
    $release_id = $cfg{release_id};
    $idx_ace    = $cfg{idx_ace};
    $verbose    = $cfg{verbose};
}

else {
    croak("Root directory exists ($root)!") if -e $root;
    mkdir($root) or croak("Cannot create directory: $root!");

    open(CONF, ">$root/params.conf")
      or croak("Cannot write file ($root/params.conf): $!");
    print CONF "config $config\n";
    print CONF "release_id $release_id\n";
    print CONF "idx_ace $idx_ace\n";
    print CONF "verbose $verbose\n";
}

$release_id =~ /^\d+$/ or croak("Invalid release id ($release_id)!");

# Global params
our $ROOT       = $root;
our $CONFIG     = $config;
our $RELEASE_ID = $release_id;
our $IDX_ACE    = $idx_ace;
our $STATUS     = "$root/status.txt";
system("touch $STATUS");
our $LOG = "$root/log.txt";

# Initialize log
lg('#' x 39, ' [START] ', '#' x 39);
lg();
lg("Starting ...");
lg("Current working directory: $cwd");
lg("Usage: $usage");
lg("Command line: $cmd");
lg();

# Run all steps
my @steps = @{cfg('STEPS')};
run_all_steps(@steps);

# End log
lg('#' x 40, ' [END] ', '#' x 40);

# [END]

sub create_dirs {
    my $step_id = 'create_dirs';

    check_if_complete($step_id) and return 1;

    lg('Creating directory hierarchy ...');

    my @dirs = @{cfg('DIR_HIERARCHY')};
    foreach my $dir (@dirs) {
        lg("Creating directory: $dir");
        mkdir($dir) or die_n("Cannot create directory ($dir): $!");
    }

    mark_as_complete($step_id) or return;

    lg('Created!');

    return 1;
}

sub get_idx_ace {
    my $step_id = 'get_idx_ace';

    check_if_complete($step_id) and return 1;

    lg('Getting index ace file ...');

    my $idx_ace = $IDX_ACE;

    if ($idx_ace eq 'initial') {
        lg( 'This is an initial run, will not download/use an index ace file for id assignment!'
        );
    }

    else {
        copy($idx_ace, cfg('IDX_ACE_FILE_LOCAL'))
          or die_n("Cannot copy index ace file ($idx_ace) - $!!");
    }

    mark_as_complete($step_id) or return;

    lg('index ace file acquired!');

    return 1;
}

sub download {
    my ($source) = @_;

    my $step_id = join(':', 'download', $source);

    check_if_complete($step_id) and return 1;

    lg('Downloading file(s) ...');

    my $ua = LWP::UserAgent->new;

    # $ua->agent("COMPILE3DDATA");

    my %downloads = @{cfg($source)};

    foreach my $url (keys %downloads) {
        my $local_file = $downloads{$url};

        lg("URL: $url");
        lg("LOCAL: $local_file");

        my $html;

        my $method;
        if    ($url =~ s/^POST://) { $method = 'POST'; }
        elsif ($url =~ s/^GET://)  { $method = 'GET'; }
        else                       { $method = 'GET'; }

        my ($url_no_content) = $url =~ /^([^\?]+)/;
        my ($content)        = $url =~ /\?(.+)/;

        my $req = HTTP::Request->new($method => $url_no_content);
        $req->content_type('application/x-www-form-urlencoded');
        $req->content($content);

        my $res = $ua->request($req);

        if ($res->is_success) { $html = $res->content; }
        else { die_n("Couldn't get url ($url): " . $res->status_line); }

        open(OUT, ">$local_file")
          or die_n("Cannot write local file ($local_file): $!");
        print OUT $html;
        close OUT;

        unless ($local_file =~ /\.gz$/) {
            _append_date($local_file)
              or die_n("Cannot append date to file ($local_file)");
        }
    }

    mark_as_complete($step_id) or return;

    lg('Download complete!');

    return 1;
}

sub process_wormpep {
    my $step_id = 'process_wormpep';

    check_if_complete($step_id) and return 1;

    lg('Processing wormpep package ...');

    my $pkg = cfg('WB_WORMPEP_TAR_FILE_LOCAL');

    my $current_wd = getcwd();
    my ($remote_wd, $file_name) = _parse_file_name($pkg);

    chdir($remote_wd)
      or die_n("Cannor chdir to package directory ($remote_wd): $!");

    system "gunzip -c $pkg | tar xf -"
      and die_n("gunzip/tar failure: code $?");

    chdir($current_wd)
      or
      die_n("Cannor chdir to previous working directory ($current_wd): $!");

    my $prot_file = cfg("WB_PROT_FASTA_FILE");

    die_n(
        "An error occured unpacking wormpep package, protein file doesn't seem to be where it is designated to be ($prot_file)!"
    ) unless -e $prot_file;

    my $prot_link = cfg("WB_PROT_FASTA_LINK");

    system("ln -s $prot_file $prot_link")
      and die_n("Unable to create soft link ($prot_link -> $prot_file)!");

    mark_as_complete($step_id) or return;

    lg('Wormpep processing complete!');

    return 1;
}

sub _load_table_file {
    my ($file) = @_;

    # Load into a hash
    lg("Loading table ($file) into memory ...");
    open(TABLE, "<$file") or die_n("Cannot read file ($file): $!");

    # >C03B1.1        CE03903                 Predicted       SW:Q11108       AAA81745.1
    # >C03B1.10       CE03911                 Predicted       SW:Q11116       AAA81741.1
    # >C03B1.12       CE03912 lmp-1           Confirmed       SW:Q11117       AAA81746.1

    my %cds2prot;
    while (<TABLE>) {
        next unless /^>/;
        s/^>//;
        my ($cds, $prot) = split(/\s+/);
        $cds2prot{$cds} = $prot;
    }

    close TABLE;

    lg("Table file ($file) loaded!");

    return \%cds2prot;
}

sub write_blat_results {
    my ($ref_blat_map, $out) = @_;

    # Load wb table into memory
    my $wb_table = cfg('WB_TABLE_FILE');
    %CDS2PROT = %{_load_table_file($wb_table)} unless %CDS2PROT;

    # Open "processed" file for output
    open(PROCESSED, ">$out") or die_n("Cannot write file ($out): $!");
    print PROCESSED join(
        "\t", 'source', 'id', 'assigned_proteins', 'prot_identity',
        'corresponding_cds', 'status', 'date_status_updated',
        'date_downloaded',   'prot_seq'
    ) . "\n";

    # Open nomatch file for output
    open(NOMATCH, ">$out.nomatch.fa")
      or die_n("Cannot write file ($out.nomatch.fa): $!");

    # Open nomatch_detail file for output
    open(NOMATCH_DETAIL, ">$out.nomatch.detail")
      or die_n("Cannot write file ($out.nomatch.detail): $!");

    foreach my $id (keys %{$ref_blat_map}) {
        my $source = $ref_blat_map->{$id}{attributes}{source};
        my $status = $ref_blat_map->{$id}{attributes}{status};
        my $date_status_updated =
          $ref_blat_map->{$id}{attributes}{date_status_updated};
        my $date_downloaded =
          $ref_blat_map->{$id}{attributes}{date_downloaded};
        my $prot_seq = $ref_blat_map->{$id}{attributes}{prot_seq};

        my @assigned_proteins;

        my @corresponding_cds =
          exists $ref_blat_map->{$id}{hits}
          ? @{$ref_blat_map->{$id}{hits}}
          : ();
        foreach my $corresponding_cds (@corresponding_cds) {
            my ($corresponding_protein, $prot_identity) = ($CDS2PROT{$1}, $2)
              if $corresponding_cds =~ s/^([^\(\)]+)\((.*)\)/$1/;
            die_n(
                "Cannot assign a corresponding protein for $corresponding_cds!"
                  . $CDS2PROT{$corresponding_cds} . "\n")
              unless $corresponding_protein;
            push(
                @assigned_proteins,
                "$corresponding_protein,$prot_identity,$corresponding_cds"
            );
        }

        my $assigned_proteins = join(':', @assigned_proteins);

        print PROCESSED join(
            "\t", $source, $id, $assigned_proteins, $status,
            $date_status_updated, $date_downloaded, $prot_seq
        ) . "\n";

        if (!@assigned_proteins) {
            print NOMATCH ">$id\n" . $ref_blat_map->{$id}{seq} . "\n";
            my @nohits =
              exists $ref_blat_map->{$id}{nohits}
              ? @{$ref_blat_map->{$id}{nohits}}
              : ();

            my %parsed_nohits;

            my %type_sort = (
                IDENTICAL => 3,
                OVERLAPS  => 2,
                MISMATCH  => 1
            );

            foreach my $nohit (@nohits) {
                my ($corresponding_protein, $prot_identity) =
                  ($CDS2PROT{$1}, $2)
                  if $nohit =~ /^([^\(\)]+)\((.*)\)/;
                die_n("Cannot assign a corresponding protein for $nohit!")
                  unless $corresponding_protein;
                my ($identity_percent, $q_len, $q_start, $q_end, $s_len,
                    $s_start,          $s_end, $type
                ) = split(" ", $prot_identity);
                $parsed_nohits{$corresponding_protein}{identity_percent} =
                  $identity_percent;
                $parsed_nohits{$corresponding_protein}{type} =
                  $type_sort{$type};
                $parsed_nohits{$corresponding_protein}{prot_identity} =
                  $prot_identity;
            }

            my @ordered_nohits =
              map { $_ . ":" . $parsed_nohits{$_}{prot_identity} }
              sort {
                $parsed_nohits{$b}{identity_percent} <=> $parsed_nohits{$a}
                  {identity_percent}
                  || $parsed_nohits{$b}{type} <=> $parsed_nohits{$a}{type}
              }
              keys %parsed_nohits;
            my $top_nohit = shift @ordered_nohits || '';

            print NOMATCH_DETAIL join("\t", $id, $status, $top_nohit) . "\n";
        }
    }

    close PROCESSED;
    close NOMATCH;

    return 1;
}

sub process_pdb {
    my $step_id = 'process_pdb';

    check_if_complete($step_id) and return 1;

    lg('Processing PDB file(s) ...');

    my $wb_prot = cfg('WB_PROT_FASTA_FILE');

    my $out = cfg('PROCESSED_DATA_DIR') . '/PDB';

    # Open nomatch file for output
    open(FASTA, ">${out}.fa") or die_n("Cannot write file (${out}.fa): $!");

    # Open nonprot file for output (Specieal case for PDB, file can contain nucleic acid sequences)
    open(NONPROT, ">${out}.noprot.fa")
      or die_n("Cannot write file (${out}.noprot.fa): $!");

    # Selecting Caenorhabditis ids
    my $idx = cfg('PDB_SRC_IDX_FILE_LOCAL');
    my %ids;
    open(IN, "<$idx") or die_n("Cannot read file ($idx): $!");
    while (<IN>) {
        if (/Caenorhabditis/i) {
            chomp;
            my ($id, $species) = split(/\t/, $_);
            $ids{uc($id)} = $species;
        }
    }

    # Extract and compare sequences from PDB fasta file
    lg('Comparing sequences ...');
    my $txt = cfg('PDB_SEQRES_TXT_FILE_LOCAL');
    my $io = Bio::SeqIO->new(-file => "$txt", -format => 'fasta')
      or die_n("Cannot parse fasta file ($txt)");

    my $date_downloaded = _read_date($txt)
      or die_n("Cannot parse download date ($txt)");

    my %attributes;
    my %unique_ids;

    while (my $s = $io->next_seq) {
        my $id           = uc($s->display_id);
        my $truncated_id = $id;
        $truncated_id =~ s/_.*$//;

        # Incorporate source into id
        $id = 'PDB_' . $id;

        # Unique'ify id
        $unique_ids{$id}++;
        if ($unique_ids{$id} > 1) {
            $id .= "-m" . $unique_ids{$id};
        }

        next
          unless
            defined $ids{$truncated_id};   # Skip non-Caenorhabditis sequences

        # >1ttu_A mol:protein length:477     Lin-12 and Glp-1 Transcriptional Regulator
        # >1ttu_B mol:nucleic length:15     5'- D(TpTpApCpTpGpTpGpGpGpApApApGpA)-3'

        my $description = $s->desc;

        my ($molecule_type) = $description =~ /mol:(\S+)/;

        my $prot_seq = uc($s->seq);
        my $species  = $ids{$truncated_id};

        $attributes{$id} = {
            source              => 'PDB',
            status              => 'In_pdb',
            date_status_updated => '',
            date_downloaded     => $date_downloaded,
            prot_seq            => $prot_seq
        };

        if ($molecule_type =~ /protein/i) {
            print FASTA ">$id $description\n$prot_seq\n";
        }
        else {
            delete $attributes{$id};
            print NONPROT ">$id $description\n$prot_seq\n";
        }    # Place non-protein sequences separately and remove attributes
    }

    close IN;
    close NONPROT;
    close FASTA;

    # Run BLAT against Wormpep
    my $ref_blat_map = _map_by_blat("${out}.fa", $wb_prot);

    # Assign file specific attributes
    foreach my $id (keys %attributes) {
        $ref_blat_map->{$id}{attributes} = $attributes{$id};
    }

    # Write BLAT results
    write_blat_results($ref_blat_map, "$out.PROCESSED");

    lg('Sequence comparison complete ...');

    mark_as_complete($step_id) or return;

    lg('PDB file processing complete!');

    return 1;
}

sub process_targetdb {
    my $step_id = 'process_targetdb';

    check_if_complete($step_id) and return 1;

    lg('Processing TARGETDB file ...');

    my $wb_prot = cfg('WB_PROT_FASTA_FILE');

    my $out = cfg('PROCESSED_DATA_DIR') . '/TARGETDB';

    # Open nomatch file for output
    open(FASTA, ">${out}.fa") or die_n("Cannot write file (${out}.fa): $!");

    # Load TARGETDB XML file into memory
    lg('Comparing sequences ...');
    my $xml_file = cfg('TARGETDB_XML_FILE_LOCAL');
    my $xml      = XML::Simple->new();
    my $doc      = $xml->XMLin(
        $xml_file, keyattr => [], forcearray => ['status'],
        suppressempty => undef
      )   # WARNING: You have to give keyattr an empty list to prevent folding
      or die_n("Cannot parse XML file ($xml_file)")
      ;    # Otherwise usesd 'id' to fold on

    my $date_downloaded = _read_date($xml_file)
      or die_n("Cannot parse download date ($xml_file)");

    my %attributes;
    my %unique_ids;

    foreach my $target (@{$doc->{target}}) {
        my $id = $target->{id};

        my $organism =
          $target->{targetSequenceList}->{targetSequence}->{sourceOrganism};
        next unless $organism =~ /Caenorhabditis/i;

        my $lab = $target->{lab};

        #        my $name = $target->{name};

        my $prot_seq =
          $target->{targetSequenceList}->{targetSequence}->{sequence};
        $prot_seq =~ s/\s//g;
        $prot_seq = uc($prot_seq);

        my @status = @{$target->{status}};
        foreach (@status) {
            s/[^\w]/_/g;
            tr/[A-Z]/[a-z]/;
            s/^(.)/uc($1)/e;
        }

        my $date_status_updated = $target
          ->{date}; # Date does not require formatting, it is already compatible with DateType "YYYY-MM-DD"

        # Incorporate source into id
        $id =~ s/\s//g;
        my ($formatted_lab) = $lab =~ /^(\S+)/;
        $formatted_lab =~ s/_/-/g;
        $id = "TARGETDB-${formatted_lab}_${id}";

        # Unique'ify id
        $unique_ids{$id}++;
        if ($unique_ids{$id} > 1) {
            $id .= "-m" . $unique_ids{$id};
            lg("WARNING: Duplicate id unique'ified ($id)!");
        }

        $attributes{$id} = {
            source              => $lab,
            status              => join(':', @status),
            date_status_updated => $date_status_updated,
            date_downloaded     => $date_downloaded,
            prot_seq            => $prot_seq
        };

        print FASTA ">$id\n$prot_seq\n";
    }

    close FASTA;

    # Run BLAT
    my $ref_blat_map = _map_by_blat("${out}.fa", $wb_prot);

    # Assign file specific attributes
    foreach my $id (keys %attributes) {
        $ref_blat_map->{$id}{attributes} = $attributes{$id};
    }

    # Write BLAT results
    write_blat_results($ref_blat_map, "$out.PROCESSED");

    lg('Sequence comparison complete ...');

    mark_as_complete($step_id) or return;

    lg('TARGETDB file processing complete!');

    return 1;
}

sub merge_processed {
    my $step_id = 'merge_processed';

    check_if_complete($step_id) and return 1;

    lg('Merging processed files ...');

    my @processed_files = glob(cfg('PROCESSED_DATA_DIR') . '/*.PROCESSED');

    lg(     'Will merge the following files: '
          . join(', ', @processed_files)
          . '!');

    my $out = cfg('MERGED_DATA_DIR') . '/MERGED.txt';

    # Open out file for output
    open(MERGED, ">$out") or die_n("Cannot write file ($out): $!");
    print MERGED join(
        "\t", 'source', 'id', 'assigned_proteins', 'status',
        'date_status_updated', 'date_downloaded', 'prot_seq'
    ) . "\n";

    #                        0         1     2                    3         4                      5                  6
    # Load each file into memory for sorting later
    my @all_processed;
    foreach my $file (@processed_files) {
        open(IN, "<$file") or die_n("Cannot read file ($file): $!");

        while (<IN>) {
            next if /^source/;
            chomp;
            my @data = split(/\t/, $_);
            push @all_processed, \@data;
        }
    }

    # Sort array
    my @sorted_all_processed = sort {
        $a->[6] cmp $b->[6]         # alpha on prot_seq
          || $a->[0] cmp $b->[0]    # alpha on source
    } @all_processed;

    # Write it out
    foreach (@sorted_all_processed) { print MERGED join("\t", @$_) . "\n"; }

    close MERGED;
    close IN;

    mark_as_complete($step_id) or return;

    lg('Merging complete!');

    return 1;
}

sub convert_to_ace {
    my $step_id = 'convert_to_ace';

    check_if_complete($step_id) and return 1;

    lg('Converting merged file to ace ...');

    my $merged_text = cfg('MERGED_DATA_DIR') . '/MERGED.txt';
    my $merged_ace  = cfg('ACE_FILE_DIR') . '/MERGED.ace';

    my $idx_ace            = $IDX_ACE;
    my $idx_ace_file_local = cfg('IDX_ACE_FILE_LOCAL');

    my $release_id = $RELEASE_ID;

    my ($idx_ace_ref, $max_id) =
      $idx_ace eq 'initial' ? ({}, 0) : _parse_idx_ace($idx_ace_file_local);
    my %idx_ace = %$idx_ace_ref;

    my %merged_text;
    open(IN, "<$merged_text") or die_n("Cannot read file ($merged_text): $!");

    open(OUT, ">$merged_ace") or die_n("Cannot write file ($merged_ace): $!");

    while (<IN>) {
        next if /^source/;

        chomp;

        my ($source, $id, $assigned_proteins, $status, $date_status_updated,
            $date_downloaded, $prot_seq
        ) = split("\t", $_);

        # Strip out source name and unique id incorporated into the identifier
        $id =~ s/^[^\_]+\_//;
        $id =~ s/-m\d{+}$//;

        # uc peptide
        $prot_seq = uc($prot_seq);

        my $wbstructure_id;
        if ($idx_ace{$source}{$id}{$prot_seq}) {
            $wbstructure_id = $idx_ace{$source}{$id}{$prot_seq};
        }    # Skip if does not exist
        else {
            $max_id++;
            $wbstructure_id = 'WBStructure' . sprintf('%06s', $max_id);
            $idx_ace{$source}{$id} = $wbstructure_id;
            lg("New id assigned ($wbstructure_id) for source:$source id:$id!"
            );
        }

        print OUT qq[Peptide : "$wbstructure_id"\n];
        print OUT qq[$prot_seq\n];
        print OUT qq[\n];

        print OUT qq[Structure_data : "$wbstructure_id"\n];
        print OUT qq[DB_info Database "$source" Native_Id $id\n];
        print OUT qq[Sequence Protein "$wbstructure_id"\n];

        my @assigned_proteins = split(':', $assigned_proteins);
        foreach (@assigned_proteins) {
            my ($prot, $identity, $cds) = split(',', $_);

            $identity =~ s/ \S+$//;        # Remove type
            $identity =~ s/ \(\d+\)//g;    # Remove length
            print OUT qq[Pep_homol WP:$prot blat_structure $identity\n];
        }

        my @status = split(':', $status);
        foreach my $i (0 .. $#status) {
            if   ($i == 0) { print OUT qq[Status $status[$i]\n]; }
            else           { print OUT qq[       $status[$i]\n]; }
        }

        print OUT qq[Status_updated $date_status_updated\n];
        print OUT qq[Evidence Date_last_updated $date_downloaded\n]
          ;                                # in Evidence hash
        print OUT qq[Wormpep_release $release_id\n];
        print OUT qq[\n];
    }

    close IN;
    close OUT;

    mark_as_complete($step_id) or return;

    lg('Converted to ace!');

    return 1;
}

sub _parse_idx_ace {
    my ($file) = @_;

    my %idx_ace;
    my $max_num = 0;

    open(IN, "<$file") or die_n("Cannot read file ($file): $!");

    my $current_wbstructure_id;
    my $current_peptide;
    my $current_database;
    my $current_native_id;

    my $is_peptide = 0;

    while (<IN>) {
        if ($_ =~ /Peptide : \"([^\"]+)\"/) {
            $is_peptide = 1;
            if ($current_wbstructure_id) {
                my $wbstructure_id = $1;

                die_n(
                    "Invalid data quartet ($current_wbstructure_id, $current_database, $current_native_id, $current_peptide)!"
                  )
                  unless ($current_database
                    and $current_native_id
                    and $current_peptide);

                if (exists $idx_ace{$current_database}{$current_native_id}
                    {$current_peptide}) {
                    lg( "WARNING: Cannot resolve uniqueness of [$current_wbstructure_id], skipping!"
                    );
                    $idx_ace{$current_database}{$current_native_id}
                      {$current_peptide} = '';
                }
                else {
                    $idx_ace{$current_database}{$current_native_id}
                      {$current_peptide} = $current_wbstructure_id;
                }

                my ($current_num) = $current_wbstructure_id =~ /(\d+)/;
                $max_num = $current_num if $current_num > $max_num;
                (   $current_wbstructure_id, $current_database,
                    $current_native_id,      $current_peptide
                ) = ($wbstructure_id, '', '' . '');
            }

            else {
                $current_wbstructure_id = $1;
            }
        }

        elsif ($_ =~ /DB_info Database \"([^\"]+)\" Native_Id (\S+)/) {
            ($current_database, $current_native_id) = ($1, $2);
            $is_peptide = 0;
        }

        elsif ($is_peptide) {
            chomp;
            my $peptide = $_;
            $peptide = uc($peptide);
            if ($peptide =~ /X/) {
                $peptide =~ s/X/M/g;
                lg( "WARNING: For index, X->M conversion performed ($current_wbstructure_id)!"
                );
            }
            $current_peptide = $peptide;

            $is_peptide = 0;
        }

        else {
            $is_peptide = 0;
        }
    }

    if ($current_wbstructure_id) {
        die_n(
            "Invalid data quartet ($current_wbstructure_id, $current_database, $current_native_id, $current_peptide)!"
          )
          unless ($current_database
            and $current_native_id
            and $current_peptide);

        if (exists $idx_ace{$current_database}{$current_native_id}
            {$current_peptide}) {
            lg( "WARNING: Cannot resolve uniqueness of [$current_wbstructure_id], skipping!"
            );
            $idx_ace{$current_database}{$current_native_id}
              {$current_peptide} = '';
        }
        else {
            $idx_ace{$current_database}{$current_native_id}
              {$current_peptide} = $current_wbstructure_id;
        }

        my ($current_num) = $current_wbstructure_id =~ /(\d+)/;
        $max_num = $current_num if $current_num > $max_num;
    }

    close IN;

    return (\%idx_ace, $max_num);
}

sub _append_date {
    my ($file) = @_;

    my $date = $time{"yyyy-mm-dd"};

    my $append_string =
      "KEY:$KEY DOWNLOADED:$date DESCRIPTION:Download date appended by application after download";

    if ($file =~ /\.xml$/) {
        $append_string = "\n<!-- $append_string -->\n\n";
    }
    else { $append_string = "\n# $append_string\n\n" }

    open(OUT, ">>$file") or die_n("Cannot append file ($file): $!");
    print OUT $append_string;
    close OUT;
    return 1;
}

sub _read_date {
    my ($file) = @_;

    my $date;

    open(IN, "<$file") or die_n("Cannot read file ($file): $!");
    if ($file =~ /\.xml$/) {
        while (<IN>) {
            next unless /^<!--/;
            if (/KEY:$KEY DOWNLOADED:([0-9\-]+)/) { $date = $1; last; }
        }
    }
    else {
        while (<IN>) {
            next unless /^\#/;
            if (/KEY:$KEY DOWNLOADED:([0-9\-]+)/) { $date = $1; last; }
        }
    }

    close IN;

    return $date;
}

sub _map_by_blat {
    my ($query, $database) = @_;

    my $threshold = cfg('BLAT_IDENTITY_PERCENT');

    my $out_file = "$query.psl";

    # Run BLAT
    my $cmd = cfg('BLAT_EXEC')
      . " $database $query -prot  -minIdentity=0 $out_file &> $out_file.STDERR";
    lg("Running BLAT ($cmd) ... ");
    system($cmd)
      and die_n(
        "BLAT run failed, please check STDERR file for more information!");

    # Load query file identifiers to memory (we will use it to check for ones that have not been matched)
    lg("Loading query identifiers ($query) into memory ...");

    my %query;    # Used below for storing matches as well

    my $io = Bio::SeqIO->new(-file => "$query", -format => 'fasta')
      or die_n("Cannot parse query file ($query)");
    while (my $s = $io->next_seq) {
        my $id  = $s->display_id;
        my $seq = uc($s->seq);
        die_n("Query file identifier duplication ($id)!")
          if exists $query{$id};
        $query{$id}{seq} = $seq;
    }

    # Parse BLAT output
    lg("Parsing BLAT output ...");
    open(PSL, "<$out_file")
      or die_n("Cannot read BLAT output file ($out_file): $!");

    open(BLAT, ">$out_file.parsed")
      or die_n("Cannot write parsed BLAT file ($out_file.all.parsed): $!");
    print BLAT
      "Query\tSubject\tIdentity Stats(identity_percent s_start s_end q_start q_end)\n";

    while (<PSL>) {
        next unless /^\d/;
        chomp;
        my @ary = split(/\s+/, $_);

        my $match   = $ary[0];
        my $q       = $ary[9];
        my $q_len   = $ary[10];
        my $q_start = $ary[11];
        my $q_end   = $ary[12];
        my $s       = $ary[13];
        my $s_len   = $ary[14];
        my $s_start = $ary[15];
        my $s_end   = $ary[16];

        my $min_length = $q_len < $s_len ? $q_len : $s_len;

        my $type = 'MISMATCH';
        if (   $match == abs($q_start - $q_end)
            && $match == abs($s_start - $s_end)) {
            if ($q_len == $s_len && $match == $q_len) { $type = 'IDENTICAL'; }
            else                                      { $type = 'OVERLAPS'; }
        }

        my $identity_percent = sprintf("%.2f", $match / $q_len * 100);

        my $identity_stats =
          "$identity_percent ($q_len) $q_start $q_end ($s_len) $s_start $s_end $type";

        print BLAT join("\t", $q, $s, $identity_stats) . "\n";

        my $container = $identity_percent >= $threshold ? 'hits' : 'nohits';
        push @{$query{$q}{$container}}, "$s($identity_stats)";
    }

    close PSL;
    close BLAT;

    return \%query;
}

# ADMINISTRATIVE SUBS

sub lg {
    my (@message) = @_;

    my $timestamp = '[' . $time{"dd-Mon-yy hh:mm:ss"} . ']';

    open(LOG, ">>$LOG") or croak("Cannot write file ($LOG): $!");
    print LOG join(' ', $timestamp, @message) . "\n";
    print join(' ', $timestamp, @message) . "\n";
    close LOG;
}

sub cfg {
    my ($key) = @_;

    tie my %cfg, "Tie::IxHash";
    my $cfg = Config::General->new(
        -ConfigFile => $CONFIG, -InterPolateVars => 1,
        -Tie        => "Tie::IxHash"
    );
    %cfg = $cfg->getall();

    my $value = $cfg{$key};

    if (ref $value eq 'ARRAY') {
        foreach (@$value) {
            $_ = _modify($_);
        }
    }

    else {
        $value = _modify($value);
    }

    return $value;
}

sub _modify {
    my ($value) = @_;

    $value =~ s/\[ROOT_DIR\]/$ROOT/g;
    $value =~ s/\[RELEASE_ID\]/$RELEASE_ID/g;
    $value =~ s/\[TIME_STAMP\]/_get_date_stamp()/eg;

    return $value;
}

sub die_n {
    my (@message) = @_;

    lg(@message, ' - Exiting!');

    exit 1;
}

sub check_if_complete {
    my ($step_id) = @_;

    tie my %cfg, "Tie::IxHash";
    my $cfg = Config::General->new(
        -ConfigFile      => $STATUS,
        -InterPolateVars => 1,
        -Tie             => "Tie::IxHash"
    );
    %cfg = $cfg->getall();

    if ($cfg{$step_id}) {
        lg( "WARNING: This step ($step_id) has been completed before, skipping ..."
        );
        return 1;
    }
    else {
        lg( "This step ($step_id) has *NOT* been completed before, proceeding ..."
        );
        return;
    }
}

sub mark_as_complete {
    my ($step_id) = @_;

    tie my %cfg, "Tie::IxHash";
    my $cfg = new Config::General(
        -ConfigFile => $STATUS, -InterPolateVars => 1,
        -Tie        => "Tie::IxHash"
    );
    %cfg = $cfg->getall();

    $cfg{$step_id} = 1;

    Config::General::SaveConfig($STATUS, \%cfg);

    return 1;
}

sub run_all_steps {
    my (@steps) = @_;

    lg("The following steps are going to be performed:");

    foreach my $step (@steps) {
        lg("  STEP $step");
    }

    lg();

    foreach my $step (@steps) {
        my ($sub, @args) = split(':', $step);
        no strict 'refs';
        &{$sub}(@args)
          or die_n(
            "Cannot perform step ($step), please check log file for details and re-start"
          );
        lg();
    }
}

sub _get_date_stamp {
    return $time{'yymmdd_HHmmss'};
}

sub _parse_file_name {
    my ($file_name) = @_;

    my $i = $file_name;

    $i =~ s/\/+/\//g;
    $i =~ s/^\s+//;
    $i =~ s/\s+$//;

    # If only root directory
    if ($i eq '/') { return ('/', ''); }

    # If only file_name
    if ($i !~ /\//) { return ('.', $i); }

    $i =~ s/\/$//;
    if ($i =~ s/\/([^\/]+)$//) { return ($i, $1) }

    die_n("Cannot parse file name ($file_name)");
}

# Author: Payan Canaran (canaran@cshl.edu)
# compile_3d_data script
# Copyright (c) 2004-2007 Cold Spring Harbor Laboratory
# $Id: compile_3d_data.pl,v 1.1.1.1 2010-01-25 15:40:08 tharris Exp $
