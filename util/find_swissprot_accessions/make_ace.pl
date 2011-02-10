#!/usr/lab/perl -w

###############################################################################
# Name: make_ace.pl
# Purpose: parse wormpepXX file to produce .ace file with of format
#   Protein : WP:CE04209
#             Database  SWALL SW  :Q10651 Q10651
#             Database  EMBL  EMBL:U00240 U00240
#             Database  EMBL  EMBL:U56966 U56966
#             Database  PDB   PDB :1MWP   1MWP
#             Corresponding_DNA  C42D8.8A         # wormbase gene
# Usage: $0 [worpep_input_file] [rejects_file.fa]
#
# Written by: Fiona Cunningham
# Date: 17th June 2002
# Version: 3.0.0.0
#          make all the SP, SW, and TR entries SW
#          change everything -> hash, use lib, check species
###############################################################################


use strict;
use lib ("/usr/local/wormbase/lib/");
use wormpep_getids; my $wormpep_getids = wormpep_getids->new();

use Bio::DB::SwissProt;
use Bio::SeqIO;
use Data::Dumper;
my $db = new Bio::DB::SwissProt(-servertype => 'expasy',
				-hostlocation => 'us');



###############################################################################
# Input
###############################################################################
if (!($ARGV[1]))
  {die "Usage: $0 [input: wormpepXX file] [output: rejects_file.fa] \n"; }

my $input = $ARGV[0];
open (INPUT, $input) or die "Error: Can't open input: $input file\n";

my $rejects =$ARGV[1];
open (REJECTS, ">".$rejects)|| die "Error: Can't open output: $rejects file\n";
#-----------------------------------------------------------------------------



###############################################################################
# Parse wormpep file
# Create a) hash with Wormpeps that have SW ids: %$each_line_ref;
#        b) hash with Wormpeps without SW ids:   %$no_SW_line_ref;
###############################################################################
my $each_line_ref;    
my $no_SW_line_ref;   
my $print_wormpep =0;

while (<INPUT>) {
  chomp;
  if (/>/){
    ($each_line_ref, $no_SW_line_ref) = 
      parse_wormpepXX($_, $each_line_ref, $no_SW_line_ref);
  }
}
close INPUT;
#------------------------------------------------------------------------------




###############################################################################
# NO SW ID
# For those with no SW id, check to see if their protein CE has a defined SW 
# under a different gene name
# Some genes encode the same WormPep protein (e.g. CE07075). 
# - Only some of these genes had an SW.  But as they have the same protein id,
#  the SW id was copied over
###############################################################################
($each_line_ref, $no_SW_line_ref)=check_for_SW($each_line_ref,$no_SW_line_ref);

# print in REJECTS seqs (in fa format) with no SW id
print_noSWs($no_SW_line_ref, $input);
#------------------------------------------------------------------------------



###############################################################################
# Foreach sequence entry in %$each_line_ref, connect to swiss prot and find
# EMBL id,  SW id,  PDB id
###############################################################################
foreach my $protein (sort keys %$each_line_ref)
  {
    # are the SW proteins for each ORF that codes $protein the same?
    # foreach orf that codes for the protein..    
    my $first_SW=$each_line_ref->{$protein}->[0]->[1];
    my @genes;     # stores all ORFs in wb in SW

    foreach my $orf (@{$each_line_ref->{$protein}})
      {    
	# if each ORF has a SW id
	if (($orf->[1] ne $first_SW) and ($orf->[1] ne "undef"))
	  { 
	    if ($first_SW eq "undef")
	      {$first_SW = $orf->[1]}
	    else 
	      {die "Die:SWids $orf->[1] $first_SW prot differ for $protein\n";}
	  }
	push (@genes, $orf->[0]);
      }

    my $embl; 
    my $pdb;

    # Connect to swiss-prot foreach wormpep gene, using $first_SW as the id
    my ($annot) = check_website($first_SW, $genes[0]);
    if ($annot){ 
      ($embl,$pdb) =$wormpep_getids->getannot($annot,$first_SW);
    }
    else{ 
      print REJECTS "Error:SW $first_SW access FAILED (for prot:$protein)\n";
    }
    
    $wormpep_getids->print_ace($protein, $first_SW, $embl, $pdb, \@genes);
  }  # end foreach protein


exit;

#-------------------------  END OF MAIN PROGRAM ------------------------------#





###############################################################################
# SUBROUTINES
###############################################################################
sub parse_wormpepXX
  {
    my ($fa_line, $each_line_ref, $no_SW_line_ref)=@_;
    
    if ($fa_line =~/
	>(\w+\.?\w+)             # $1 wb_orf
	\s+
	(CE\d{5})                # $2 $protein
	\s+
	(.*)/x)                  # $3, the rest
      {
	my $tmp_wbgene = $1;
	my $tmp_protein = $2;
	my $tmp_rest = $3;
	my $tmp_swall;
	my $tmp_protein_id;
	$print_wormpep =0;

	if ($tmp_rest =~s/TR:(\w+)//)              {$tmp_swall = $1;}
	elsif ($tmp_rest =~s/SW:(\w+)//)           {$tmp_swall = $1;}
	else {$tmp_swall = "undef";}
	
	if ($tmp_rest =~/protein_id:(\w+\.?\w+)/)  {$tmp_protein_id = $1;}
	else {$tmp_protein_id = "undef";}
	
	
	###################################################################
	# Data Manipulation: these gene's SW ids not listed in file
	#(for more explanation see edam:~/wormpep/fiona_notes/wormpep_proj.txt)
	# found by searching SwissProt
	###################################################################
	## same as Tr:o02619
	if ($tmp_protein eq "CE03252") {$tmp_swall = "P02306";}
	## wrong in wormpep file!!
	if ($tmp_protein eq "CE03253") {$tmp_swall = "Q9TW44";}  
	#------------------------------------------------------------------
	
	# each entry: $each_line_ref->{WBprotein}(WBgene_name, SWid)
	if ($tmp_swall eq "undef") { # if there is no SW id 
	  my @temp = ($tmp_wbgene, $tmp_protein_id);
	  push (@{$no_SW_line_ref->{$tmp_protein}},\@temp);
	  #print REJECTS "\n$fa_line"; 
	  $print_wormpep =1;
	}
	else {
	  my @temp = ($tmp_wbgene, $tmp_swall);
	  push (@{$each_line_ref->{$tmp_protein}},\@temp);
	}
      }
    else { print "Error: $fa_line\n";}
    
    return ($each_line_ref, $no_SW_line_ref);
  } # end of sub
#-----------------------------------------------------------------------------



###############################################################################
# SUBROUTINE: check_for_SW
# Is there a SW id for another gene that makes same protein?
###############################################################################
sub check_for_SW
{
  my ($each_line_ref, $no_SW_line_ref)= @_;
  my $sw;
 
  # Foreach protein in the 'no_SW_line_ref' hash
  foreach my $trouble_protein (sort keys %$no_SW_line_ref)
    {
      # Check to see if there is an entry in the %$each_line_ref hash 
      # (this hash only has entries with SW ids)
      if ($each_line_ref->{$trouble_protein})
	{
	  # If it has an entry, it will have the following SW id:
	  $sw = $each_line_ref->{$trouble_protein}[0]->[1];
	  
	  # So for each trouble protein with that Wormpep id, store the SW id
	  foreach my $orf (@{$no_SW_line_ref->{$trouble_protein}})    {
	    my @tmp = ($orf->[0], $sw);
	    
	    # Add the copied SW id, to the %$each_line_ref hash
	    push  (@{$each_line_ref->{$trouble_protein}},\@tmp);
	    #print REJECTS ">$orf->[0]\t$trouble_protein\t pro_id:$orf->[1]\n";
	  }
	  # Rm the Wormpep id from the %$no_SW_line_ref hash cos found an SW id
	  delete $no_SW_line_ref->{$trouble_protein};
	}
    }
  return ($each_line_ref,$no_SW_line_ref);
} # end of sub
#-----------------------------------------------------------------------------



###############################################################################
# SUBROUTINE: print out Wormpep seqs in fasta format 
###############################################################################
sub print_noSWs
  { 
    my ($no_SW_line_ref, $input) = @_;
    my $print_prot;                       # flag when should print out $_

    open (INPUT, $input) or die "Error: can't open $input\n";

    while (<INPUT>)
      {
	if (/>(\w+\.?\w+)             # $1 wb_orf
	    \s+
	    (CE\d{5})                # $2 $protein
	    \s+.*/x)
	  {
	    $print_prot =0;
	    my $protein = $2;	    
	    my $gene = $1;

	    if ($no_SW_line_ref->{$protein})
	      {print REJECTS "$_"; $print_prot=1;}
	  } # end of if 
	
	elsif ($print_prot ==1){print REJECTS $_;}
      }# end of while
    print REJECTS "\n";
    close INPUT;
  } # end of sub
#-----------------------------------------------------------------------------



###############################################################################
# SUBROUTINE: check_website
###############################################################################
sub check_website
  { 
    my ($id, $gene) = @_;
    my $annot;
    eval 
      {
	my $seq = $db->get_Seq_by_acc($id);  # get entry with this id
	if( $seq ) 
	  {$annot = $seq->annotation();}     # get the annotations  
	
	# Check it is elegans
	my $division = $seq->division();
	if ($division ne "CAEEL")            # either wrong spp or TrEMBL entry
	  {
	    # Check spp is elegans
	    my $species_ref = $seq->species();
	    my $species = $species_ref->binomial();
	   
	    if ($species ne "Caenorhabditis elegans")    # check spp is elegans
	      {print REJECTS ">$gene\t $id NOT C ELE\n"; $annot=0;}
	  }
     }; # end of eval

    return ($annot);  
} # end of sub
#------------------------------------------------------------------------------

