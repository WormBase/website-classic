#!/usr/bin/perl

# standard_urls.pl
# This support script serves to dynamically select an XSLT
# based on URL parameters
# Author:  T. Harris - midway between JFK and SFO.

use strict;
use XML::Sablotron;
use XML::Simple;
use lib '/usr/local/wormbase/html/standard_urls/perl';
use BuildFilename qw/build_filename/;
use Data::Dumper;
use CGI 'param','header','path_info';
use Carp 'croak';
use vars qw/$operation $species $release $config
  $XML $SITE_ROOT $XSLT_ROOT $SPECIES_INDEX $SPECIES_DETAIL $RELEASE_DETAIL/;


# Edit this variable to reflect the full path to install directory
use constant INSTALL_ROOT => '/usr/local/wormbase/html/standard_urls';


#################################################
# No user configurable options below this point #
#################################################

# Parse the standard_urls.xml file for config options
$XML    = INSTALL_ROOT . '/standard_urls.xml';
$config = XMLin($XML);

$SITE_ROOT = $config->{mod}->{install_path};
$XSLT_ROOT      = $SITE_ROOT . '/xsl';
$SPECIES_INDEX  = $XSLT_ROOT . '/' . 'species_index.xsl';
$SPECIES_DETAIL = $XSLT_ROOT . '/' . 'species_detail.xsl';
$RELEASE_DETAIL = $XSLT_ROOT . '/' . 'release_detail.xsl';

use constant BUFFER         => $ENV{TMP} || $ENV{TMPDIR} || '/tmp' || '/var/tmp';    # Where temporary files are written during XSLT
use constant MIME_DEFAULT   => 'application/x-fasta';
use constant DEBUG          => 0;

my %OPERATIONS = map { $_ => 1 } qw/dna rna mrna ncrna protein feature/;

if (DEBUG) {
  print Dumper($config);
  my $current = get_current('C_elegans');
  print $current;
}

($species,$release,$operation) = get_params();


my $parser = XML::Sablotron->new();
my $sit    = XML::Sablotron::Situation->new();

my $result;
if (!$species) {
  my $out = BUFFER . "/standard_urls.html";
  $parser->process($sit,"file:$SPECIES_INDEX",
		   "file:$XML",
		   "arg:$out");
  $result = $parser->getResultArg("arg:$out");
} elsif ($species && !$release) {
  my $out = BUFFER . "/standard_urls.html";
  $parser->addParam($sit,'selected_species',$species);
  $parser->addParam($sit,'selected_release',$release);
  $parser->process($sit,"file:$SPECIES_DETAIL",
		   "file:$XML",
		   "arg:$out");
  $result = $parser->getResultArg("arg:$out");
} elsif ($species && $release && !$operation) {
  my $out = BUFFER . "/$species-$release.html";
  $parser->addParam($sit,'selected_species',$species);
  $parser->addParam($sit,'selected_release',$release);
  $parser->process($sit,
		   "file:$RELEASE_DETAIL",
		   "file:$XML",
		   "arg:$out");
  $result = $parser->getResultArg("arg:$out");
}

if ($result) {
  print header('text/html'),$result;
  exit;
}

# The contents of this subroutine and the accompanying module should
# be customized for your MOD!
if ($species && $release && $operation) {
    my $suffix = ($operation eq 'feature') ? 'gff3' : 'fa';

  my $filename = "$species-$release-$operation.$suffix";
  $filename    =~ s/\s/_/g;

  print header(-type       => 'application/octet-stream',
	       -attachment => $filename,
	      );

#  $release = get_current($species) if ($release eq 'current');
  my $result = dump_file($species,$release,$operation);

  unless ($result) {
    print "Sorry. Your request could not be completed. Please report this error to " . $config->{mod}->{admin_contact};
  }
  exit 0;
}

###################
##     SUBS      ##
###################
sub get_params {
  my $path = path_info();

  # Phase I URLs are of the form
  # /genome/Binomial_name/release/[dna|mrna|ncrna|protein|feature]
  # /genome will be absent from the path if configured via Apache
  my ($junk,$root,$species,$release,$operation) = split("\/",$path);

  if ($operation && !defined $OPERATIONS{$operation}) {
    croak "Invalid operation $operation; choose one of " . join(" ",keys %OPERATIONS);
  }

  $release = get_current($species) if ($release eq 'current');
  return ($species,$release,$operation);
}



sub dump_file {
  my ($short_name,$release,$operation) = @_;
  my $species = shortname2species($short_name);
  my $file = build_filename($config->{mod}->{file_root},$species,$release,$operation);

  # This is pretty simple minded...
  # Need to dynamically zip/unzip, tar, untar, etc.
  #  system("gunzip -c $file");
  open IN,$file;
  while(<IN>) {
    print $_;
  }
}


sub shortname2species {
  my $species = shift;
  ($species) = $species =~ /\w{1}_(.*)/;
  return $species;
}

sub get_current {
  my $species = shift;
  my @species = @{$config->{species}};
  foreach (@species) {
    next unless $_->{short_name} eq $species;
    my @releases;
    if (ref $_->{release} eq 'ARRAY') {
      @releases = @{$_->{release}};
    } else {
      my %release = %{$_->{release}};
      push @releases,\%release;
    }
    my $most_recent = $releases[-1]->{version};
    return $most_recent;
  }
}
