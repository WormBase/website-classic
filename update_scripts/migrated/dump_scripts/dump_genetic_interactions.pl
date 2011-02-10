#!/usr/bin/perl

use strict;
use Ace;

my $usage = "$0 (<acedb_dir> | <acedb_host>:<port>) [gene_list_file]";

my ($database, $file) = @ARGV;
$database or die "Usage: $usage\n";

use constant NA => 'N/A';

my $DB;
if ($database =~ /:/) {
        my ($host, $port) = split(":", $database);
        $DB = Ace->connect( -host => $host, -port => $port)
                or die "Cannot connect to host: $host, port: $port\n";
        } else {
                $DB = Ace->connect( -path => $database)
                or die "Cannot connect to database (directory): $database\n";
        }

print '# ' . join(' ',qw/WBInteractionID Gene1-WBID Gene1-Molecular_name Gene1-CGC_name Gene2-WBID 
Gene2-Molecular_name Gene2-CGC_name Interactio_type Brief_citation/) . "\n";

my @interactions = $DB->fetch(Interaction=>'*');
foreach my $interaction (@interactions) {
   print STDERR $interaction,"\n";
   my $reference = eval { $interaction->Paper->Brief_citation };

   my $interaction_type;
   my @cols = ($interaction);
   foreach ($interaction->Interactor) {
      my ($interactor,$type) = $_->row;
      $interaction_type = $type if $type ne '';  # Ugh.
      my $molecular_name = $interactor->Molecular_name || NA;
      my $cgc_name       = $interactor->CGC_name       || NA;
      push (@cols,$interactor,$molecular_name,$cgc_name)
    }
   push @cols,$interaction_type,$reference;
   print join("\t",@cols) . "\n";
}

exit 0;
