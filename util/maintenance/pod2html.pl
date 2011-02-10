#!/usr/bin/perl

# This is a simple directory crawler that creates new html docs from PODs
# Author: T. Harris
# 3/18/2004, on the cusp of spring

use strict;

my $BASE    = '/usr/local/wormbase';

# Directories that contain POD
my @POD     = (qw|/usr/local/wormbase/docs /usr/local/wormbase-admin/docs|);
my $HTML    = '/usr/local/wormbase/html/docs';
my $INSTALL = '/usr/local/wormbase/INSTALL.pod';

my %SEEN_FILES;
my %SEEN_DIRS;

foreach my $POD (@POD) {
  %SEEN_FILES = ();
  %SEEN_DIRS  = ();
  crawl([$POD]);
  html($POD);
  cleanup($POD);
}

install2html();

sub crawl {
  my ($DIRS) = shift;
  my @next_level;
  foreach my $dir (@$DIRS) {
    my $stripped = $dir;
    opendir DIR,$dir or die "Couldn't open the POD directory for processing\n";
    while (my $item = readdir(DIR)) {
      next if $item =~ /^\.|\#|CVS/;
      if (-d "$dir/$item") {
	push (@next_level,"$dir/$item");
	$SEEN_DIRS{"$dir/$item"};
      } else {
	next unless ($item =~ /pod$/);
	$SEEN_FILES{$item} = "$dir/$item";
      }
    }
  }
  crawl(\@next_level) if (@next_level);
}


sub html {
  my $POD = shift;
  # Recreate the pod directory structure under html/
  foreach my $dir (keys %SEEN_DIRS) {
    $dir =~ s/$POD\///;
    $dir = $HTML . "/$dir";
    system("mkdir -p $dir") and warn "Couldn't create $dir: $!";
  }

  foreach my $file (keys %SEEN_FILES) {
    my $input_path = $SEEN_FILES{$file};
    #  my $output = $file;
    my $output_path = $input_path;
    $output_path =~ s/$POD//;
    $output_path = $HTML . "$output_path";
    $output_path =~ s/\.pod/\.html/;
    warn "generating $output_path...\n";
    system("pod2html --infile=$input_path --outfile=$output_path");
  }
}


# Convert the install documentation to HTML
sub install2html {
  my $output_path = $HTML . "/INSTALL.html";
    warn "generating $output_path...\n";
  system("pod2html --infile=$INSTALL --outfile=$output_path");

  my $out = $BASE . '/INSTALL.html';
  warn "generating $out...\n";
  system("pod2html --infile=$INSTALL --outfile=$out");

  my $outtext = $BASE . '/INSTALL.txt';
  warn "generating $outtext...\n";
  system("pod2text $INSTALL $outtext");
}


sub cleanup {
  my $POD = shift;
  system("rm -rf $POD/pod2htm*");
  my $PWD = $ENV{PWD};
  system("rm -rf $PWD/pod2htmd* $PWD/pod2htmi*") and warn "Couldn't delete files: $!";
}
