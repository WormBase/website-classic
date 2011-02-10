#!/usr/lab/perl-w 

###############################################################################
# Name: blat_hits.pl
# Purpose: Parses filtered blat output to find target names with identical hits           of the same length or 1 difference in length
#          Gets the EMBL, PDB id for these hits, outputs info in .ace format 
# Usage:  $0 [pslReps_input] [wormpep_file]
# Requires: lib/wormpep_lib.pm
#
# Written by: Fiona Cunningham
# Date: 26th June 2002
# Version: 3.0.0.0 
###############################################################################

use strict;
use lib ("/usr/local/wormbase/lib/");
use Bio::DB::SwissProt;
use Bio::SeqIO;
use Data::Dumper;
my $db = new Bio::DB::SwissProt(-servertype => 'expasy',
				-hostlocation => 'us');
use wormpep_getids; my $wormpep_getids = wormpep_getids->new();


###############################################################################
# Files
###############################################################################
if (not($ARGV[1]))
  {die "\n Usage: $0 [pslReps_input] [wormpep_file] \n";}

my $input = $ARGV[0];           # pslReps_output
my $wormpep_file = $ARGV[1];
#------------------------------------------------------------------------------



###############################################################################
# Make hash $results_ref with blat_hit data (SWids + geneids) &  wormpep_ids
###############################################################################
# 1) Get WormPep Ids
my $gene_protein_ref = get_protein_gene_pairs($wormpep_file);


# 2) Parse pslReps blat output file to find queries and their target hits
my $results_ref = parse_pslReps($input, $gene_protein_ref);
#-----------------------------------------------------------------------------



###############################################################################
# Check blat results
#  Structure  $results_ref->{$protein}->{$gene}=[[$SW, $length], [$SW,$length]]
#
# Create % with structure: $on_web->{"acc_info"}->{SWid} = $embl, $pdb;
#                    and : $on_web->{XX}->{SWid} = \@genes;
# where XX is G0 if hit has length 0 and is on website (G1 if length =1)
#             N1 if hit has length 1 and not on website (N0 if length =0)
###############################################################################
# 3) Select valid hits   4) Get info
foreach my $protein(sort keys %$results_ref)
  {
    my $on_web;    # stores info about SWid from the web
    
    foreach my $gene (sort keys %{$results_ref->{$protein}})      
      {
	foreach my $target_id (@{$results_ref->{$protein}->{$gene}})
	  {
	    my $id; 
	    my $sptr;
	    my $embl; 
	    my $pdb;
	    my $length = $target_id->[1];

	    if ($target_id->[0] =~ /(\w\w)\|(\w+)\|.*/)
	      {$id = $2; $sptr = $1;}
	    else {die "Die: couldn't extract id:$target_id->[0]\n";}

	    	    
	    # check to see if gene is on the website
	    my($on_web_key,$annot)=check_website($id, $gene, $length,$protein);

	    # add the gene to this array under G0, G1, N0, N1 
	    push (@{$on_web->{$on_web_key}->{$sptr.$id}}, $gene);

	    # search for this SW id in prev. rounds
	    if (!($on_web->{"acc_info"}->{$sptr.$id}))   # SW id undef 
	      {
		if($annot)  {
		  ($embl, $pdb) = $wormpep_getids->getannot($annot, $id);
		  push(@{$on_web->{"acc_info"}->{$sptr.$id}},$embl, $pdb);
		}
		else{ 
		  print STDERR 
		    "Error:SW$id access FAILED (gene:$gene prot:$protein)\n";
		}
	      }    
	  } # end foreach $target_id	
      } # end foreach $gene
    
    my $version;
    # Decide which hit to take:
    if ($on_web->{G0})     {$version = 'G0';} 
    elsif ($on_web->{G1})  {$version = 'G1';} 
    elsif ($on_web->{N0})  {$version = 'N0';} 
    else {print STDERR "no hit for $protein \n";}  
    
    my $found_sp_id=0;        # if find SP id, take that preferencially
    my $use_this_id;
    my $count_SPids=0;    my $count_TRids=0;

    foreach my $swid (keys %{$on_web->{$version}})      {
      if ($swid =~ /sp/)  {
	$found_sp_id=1;
	$use_this_id = $swid;
	$count_SPids++;
      }
    }  # end of foreach loop

    if ($found_sp_id ==0){
      foreach my $swid (keys %{$on_web->{$version}})
	{ $use_this_id = $swid; $count_TRids++; }
    } # end of $found_sp_id==0;
  
    if ($use_this_id){
      my @genes = @{$on_web->{$version}->{$use_this_id}};
      my $embl = $on_web->{"acc_info"}->{$use_this_id}->[0];
      my $pdb = $on_web->{"acc_info"}->{$use_this_id}->[1];
      
      my $id;
      if ($use_this_id =~/\w\w([A-Z]\w+)/) {$id = $1;}
      else {die "Die: couldn't get sw id from $use_this_id\n";}
      $wormpep_getids->print_ace($protein, $id, $embl, $pdb, \@genes);
    }

    if (($count_SPids >1) or ($count_TRids >1)){
      print STDERR"num SPids for each protein:$count_SPids,TR: $count_TRids\n";
    }
  } # end of foreach my $protein
 
exit;  
#---------------------------  END OF MAIN PROGRAM ----------------------------#



###############################################################################
# SUBROUTINE: 1) get wormpep ids
###############################################################################
sub get_protein_gene_pairs{
  my $wormpep_file = shift;
  open (WORMPEP, $wormpep_file) or die "Error: can't open $wormpep_file\n";
  
  my $gene_protein_ref;
  while (<WORMPEP>){
    if (/>/)
      {
	if (/>(\w+\.?\w+)             # $1 wb_orf
	    \s+
	    (CE\d{5})                # $2 $protein
	    \s+.*/x)
	  {$gene_protein_ref->{$1}=$2;}
      } # end of if $_ >
  }# end of while

  close WORMPEP; return ($gene_protein_ref);
} # end of sub
#------------------------------------------------------------------------------



###############################################################################
# SUBROUTINE: 2) parse pslReps output
##############################################################################
sub parse_pslReps
  { 
    my ($input, $gene_protein_ref) =@_;
    open(INFILE,$input) or die "Error: can't open $input\n";
    my $results_ref;
    
    while (<INFILE>)
      {
	if (/^\d/)           # if the line begins with \d
	  {
	    my @eachline = split (/\t/, $_);            # split on \t
	    my $qname = $eachline[9];
	    my $tname = $eachline[13];
	    my $mismatch = $eachline[1];
	    my $qsize = $eachline[10];
	    my $tsize = $eachline[14];
	    my $length = abs($qsize - $tsize);
	    
	    my $protein = $gene_protein_ref->{$qname}; 
	    
	    # check that the spp is elegans
	    my $elegans_id = 1;
	    if ($tname =~/sp\|\w+\|(.*)/){
	      if ($1 !~ /_CAEEL/){
		$elegans_id = 0;
		print REJECTS ">$qname\t $protein \t $tname NOT C ELE\n";}}

	    if (($elegans_id==1) and ($length <2) and ($mismatch==0)){
	      # Push hits into hash so all targets for query are printed tgh
	      my @tmp = ($tname, $length);
	      push (@{$results_ref->{$protein}->{$qname}}, \@tmp);
	    }
	    # else reject hit
	  } # end of if $_ =~
	#else {print "$_";}
      }
    close INFILE;
    return ($results_ref);
  } # end of sub
#------------------------------------------------------------------------------
 



###############################################################################
# SUBROUTINE:3) check website to see if gene is listed under that SW id
# if difference between query and target is 1 or less, check website
###############################################################################
sub check_website
  {
    my ($id, $gene, $length, $protein) = @_;
    my $found_gene_name = "N";            # checks for match N=no gene, G=gene
    my $annot;                          # annotation for the $id;
    
    eval {
      my $seq = $db->get_Seq_by_acc($id);         # get entry with this id
      
      if( $seq )	  {
	$annot = $seq->annotation();             # get the annotations  
	
	# Check that the gene name in SP is the same as wormpep, else error
	foreach my $gn ( $annot->get_Annotations('gene_name') ) 
	  {
	    if ($found_gene_name =="N")
	      { if($gn->value()=~/\D?($gene)\D?/) {$found_gene_name="G";}} 
	  }  # end of foreach gene
	
	# Check it is elegans
	my $division = $seq->division();
	if ($division ne "CAEEL")           # either wrong spp or TrEMBL entry
	  {
	    # Check spp is elegans
	    my $species_ref = $seq->species();
	    my $species = $species_ref->binomial();
	   
	    if ($species ne "Caenorhabditis elegans")   # check spp is elegans
	      {print ERRORS ">$gene\t $id NOT C ELE\n"; $annot=0;}
	  }
      } # end of if ($seq)
    }; # end of eval
    
    my $on_web_key = $found_gene_name.$length;
    return ($on_web_key, $annot);
  } # end of sub
#------------------------------------------------------------------------------




# ALGORITHM
# Blatout_hit_names_to_ace.pl

# 1) Get Wormpep ids
# - search thru the wormpep80 file to find gene- protein pairs
#   - store these in %gene_protein{$gene} = $protein

# 2) Parse blat output to get target names
#    - many queries (genes) have several targets (SW ids)
#      but only take ones with max difference of 1 in length and w/ no mismatch
#      => store in hash $results_ref
#      format: $results_ref{protein}{gene}= [@, @, @, @, @];  
#              where @ =($target_id, $differnence_in_length);

# 3) Find valid hits
# a) foreach $protein (%$results_ref)
#    i) for each SWid, check to see if there is an entry on website
#       - check to see if the gene is listed on the entry page
#       - store the SWid with G0, G1, N0, N1 and SWid in %on_web

#       - if $embl, $pdb for that $SWid have NOT already been obtained
#                - get $embl, $pdb and store them in %on_web

#        $on_web{G0}{SWid} = @genes
#        $on_web{acc_info}{SWid} = $embl, $pdb;
# b) - if there is a G0 SWid  - print that
#    - elsif there is a G1 SWid, print that
#    - elsif N0 SWid, print that

# - print all the ones with SP ids.  If there are none, print all with TR ids


# $id_info_ref{$SWid} = $length, @genes, @embl, $pdb, $pdb_orth,
# $protein, $swall, $embl_ref,$pdb, $pdb_orth, $genes_ref
