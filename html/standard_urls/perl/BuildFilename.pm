package BuildFilename;

# This package constructs filenames for standard URLS.

use strict;
use base 'Exporter';
use vars qw(@EXPORT @EXPORT_OK);
@EXPORT_OK = qw(build_filename);


# These path values contain printf statements.  Partial paths will be
# appended automatically to the file_root value specified in your
# standard_urls.xml file.
my %FILES = (dna    => { path     => '%s/sequences/dna/%s.%s.dna.fa.gz',  # species/dna/species.RELEASE.dna.fa.gz
                       },
             protein => { path     => '%s/sequences/protein/wormpep%s.tar.gz',  }, # species/protein
             mrna    => { path     => '%s/sequences/mrna/elegans-mrna.%s.fa.gz', },
             ncrna   => { path     => '%s/sequences/ncrna/wormrna%s.tar.gz' },
             feature => { path     => '%s/genome_feature_tables/GFF3/%s.%s.gff3.gz',
                           mime     => 'application/x-gff3',
                         });

# Adjust filename constructions as appropriate for the paths above.
sub build_filename {
  my ($file_root,$species,$release,$operation) = @_;
  my $template = $FILES{$operation}->{path};
  $file_root .= '/' unless ($file_root =~ /\/$/);

  my $file;
  if ($operation eq 'dna') {
    $file = $file_root . sprintf($template,$species,$species,$release);
  } elsif ($operation eq 'mrna') {
      $file = $file_root . sprintf($template,$species,$release);
  } elsif ($operation eq 'feature') {
      $file = $file_root . sprintf($template,$species,$species,$release);
  } else {
      $release =~ s/WS//g;  # silliness - different naming schemes
      $file = $file_root . sprintf($template,$species,$release);
  }
#  print $file;
  return $file;
}


1;
