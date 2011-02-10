#!/usr/bin/perl
# File: dump_brief_ids.pl
# Dumps out brief descriptions of each gene

use Ace;
use Getopt::Long;
use strict;

my ($host,$port,$database,$no_entry,$format);
GetOptions(
	   "host=s"      => \$host,
	   "port=i"      => \$port,
	   "database=s"  => \$database,
	   "no_entry=s"  => \$no_entry,
	   "format=s"    => \$format,
	  );

(($host && $port) || $database) || die <<USAGE;

Usage: dump_brief_ids.pl [options]

   --host      hostname for acedb server
   --port      port number (for specified host)
   --database  full path to database (opened via tace)
   --no_entry  message to display if entry is empty
                      (defaults to "none available")
   --format    record || tab (defaults to tab)

USAGE

my $separator = "=\n";
$no_entry  ||= "none available";
$format    ||= 'tab';

my $db;
if ($host && $port) {
  $db = Ace->connect(-host=>$host,-port=>$port);
} elsif ($database) {
  $db = Ace->connect($database) || die "Couldn't open database";
}

my $i = $db->fetch_many(Gene=>'*');
while (my $gene = $i->next) {
  my $name = $gene->Public_name || 'not known';
  my $molecular_name = $gene->Molecular_name || 'not known';
  next unless $gene->Species eq 'Caenorhabditis elegans';

  # Fetch each and any of the possible brief identifications
  my $concise  = $gene->Concise_description     || $no_entry;
#  my $brief    = $gene->Brief_description       || $no_entry;
  my $prov     = $gene->Provisional_description || $no_entry;
  my $detailed = $gene->Detailed_description    || $no_entry;
#  print "$gene" . ($name ? " ($name)\n" : "\n");
  if ($format eq 'record') {
    print join("\n",$gene,$name,$molecular_name);
    print rewrap("Concise description: $concise\n");
    #  print rewrap("Brief description: $brief\n");
    print rewrap("Provisional description: $prov\n");
    print rewrap("Detailed description: $detailed\n");
    print $separator;
  } else {
    print join("\t",$gene,$name,$molecular_name,$concise,$prov,$detailed),"\n";
  }
}



sub rewrap {
  my $text = shift;
  $text =~ s/^\n+//gs;
  $text =~ s/\n+$//gs;
  my @words = split(/\s/,$text);
  my ($para,$line);
  foreach (@words) {
    $line .= "$_ ";
    next if length ($line) < 80;
    $para .= "$line\n";
    $line = undef;
  }
  $para .= "$line\n" if ($line);
  return $para;
}
