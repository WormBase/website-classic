#!/usr/bin/perl
use strict;
use File::Copy 'move', 'copy';


use constant SUP => '/usr/local/ftp/pub/wormbase/genomes/briggsae/genome_feature_tables/GFF2/supplementary.gff.gz';
use constant GFF_HOME => '/usr/local/ftp/pub/wormbase/genomes/briggsae/genome_feature_tables/GFF2/';
use constant ELEGANS  => '/usr/local/ftp/pub/wormbase/genomes/elegans/genome_feature_tables/GFF2/';

my $release = shift || die "Usage: ./process_briggsae_gff.pl WSXXX\n";
$release =~ s/WS//i;
my $elegans_gff = ELEGANS . "elegansWS$release.gff.gz";

$ENV{TMP} ||= $ENV{TMPDIR}
          ||  $ENV{TEMP} 
          || -d ('/usr/tmp') ? '/usr/tmp' : -d ('/tmp') ? '/tmp' : die 'NO TEMP DIR';


my $GFF = "/usr/local/ftp/pub/wormbase/acedb/WS$release/CHROMOSOMES/briggff${release}";

opendir IN, $GFF;
my @gff_files = map {"$GFF/$_"} grep {/gff/} readdir IN;
closedir IN;
push @gff_files, SUP;

my $temp_dir = "$ENV{TMP}/briggWS$release";
mkdir $temp_dir unless -d $temp_dir;
chdir $temp_dir or die $!;

# grab the C. elegans waba and reverse it
system "zcat $elegans_gff |grep waba |/usr/local/wormbase/bin/invert_target.pl >$ENV{TMP}/waba$$";

# filter and consolidate
for (@gff_files, "$ENV{TMP}/waba$$") {
  my $sup = 1 if /supplementary/;
  open OUT, ">>$temp_dir/WS$release.gff";
  my $file = $_;
  $_ = "zcat $_ |" if /gz$/;
  open IN, $_;

  while (my $line = <IN>) {
    next if $line =~ /Link/;
    next if $line =~ /Genomic_canonical/ && !$sup;
    next if $line =~ /waba/ && !/waba/;
    $line  =~ s/similarity/nucleotide_match/;
    $line =~ s/Sequence\s+("\S+?")/Sequence $1;Name $1/;
    $line =~ s/elegans_CHROMOSOME_//;
    print OUT $line;
  } 

}

system "gzip -f ${temp_dir}/WS$release.gff";
move ("$temp_dir/WS$release.gff.gz", GFF_HOME."briggsae_WS$release.gff.gz");
chdir(GFF_HOME) or die $!;
unlink ("current.gff.gz");
system "ln -s briggsae_WS$release.gff.gz current.gff.gz";
print  GFF_HOME."current.gff.gz";
#unlink("$ENV{TMP}/waba$$");
exit;


