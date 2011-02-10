#!/lab/bin/perl -w

###############################################################################
# Name: wormpep_lib.pm
# Purpose: module for the wormpep get_SPids project
# Requires: -
# Usage: by other program as module
#
# Written by: Fiona Cunningham
# Date: July 2002
# Version: 2.0.0.0 
###############################################################################

use strict;
package wormpep_getids;

use Bio::DB::SwissProt;
use Bio::SeqIO;
use Data::Dumper;
my $db = new Bio::DB::SwissProt(-servertype => 'expasy',
				-hostlocation => 'us');

###############################################################################
# New,  constructor.
###############################################################################

sub new {
 my $name = shift;         
 my $class = ref($name) || $name;                   # package name      
 my $this = {};
 bless $this,$class; 
 return $this;
}
#------------------------------------------------------------------------------



###############################################################################
# SUBROUTINE: Get annotations
###############################################################################
sub getannot
  {
    my $this = shift;
    my ($annot, $id) = @_;
    my @embl;
    my $pdb;
    my $pdb_orth;      # stores the orthologue displayed in PDB
    
    # Foreach cross-link
    foreach my $link ( $annot->get_Annotations('dblink') )
      {
	my $primary_id = $link->primary_id;
	my $dbase = $link->database;
	my $optional_id = $link->optional_id;
	
	# if the db is EMBL and if the protein_ids match, store EMBL id
	if ($dbase){
	  my $embl_in= 0;

	  if ($dbase eq "EMBL")
	    {
	      foreach (@embl)     { if   ($primary_id eq $_)   {$embl_in=1;}  }
	      if ($embl_in ==0)   { push (@embl, $primary_id);                }
	    }

	  # if the db is HSSP
	  elsif ($dbase eq "HSSP")
	    {
	      $pdb = $optional_id;
	      if ($primary_id ne $id)  {$pdb_orth = $primary_id;}
	    }
	  
#	  if ($dbase eq "WormPep") {
#	    if ($optional_id ne $protein){
#	      print ERRORS 
#		"Error:in SW:$id, WormPep:$optional_id for $protein\n";
#	      $counter_SW_error++;
#	    }
#	  }
	} #end if $dbase
	
	else    # if no $dbase
	  {print STDERR "no db SW $id\n"; 
	   print ERRORS "no db for SW $id\n";}
	
	# Print out all the annotations
#	printf "Annotation db:%s, id=%s, optional_id=%s\n",
#	$link->database, $link->primary_id, $link->optional_id;
      } # end foreach $link
    
    my @pdb = ($pdb, $pdb_orth);    
    return (\@embl, \@pdb);
  } # end of subroutine
#------------------------------------------------------------------------------



###############################################################################
# SUBROUTINE: print out information for .ace file
###############################################################################
sub print_ace
  {    
    my $this = shift;
    my ($protein, $swall, $embl_ref, $pdb, $genes_ref) = @_;

    print "Protein : WP:".$protein."\n";
    
    if ($swall)
      {	print "Database SWALL SW:".$swall." ".$swall."\n";  }

    if ($embl_ref)
      {	foreach (@$embl_ref){print "Database EMBL EMBL:".$_." ".$_."\n";} }

    if (($pdb->[0])and ($pdb->[0] ne ""))
      {	   
	my ($pdb_acc, $pdb_orth) = @$pdb;	
	print "Database PDB PDB:".$pdb_acc." ".$pdb_acc."\n"; 
      
	if ($pdb_orth)
	  { print "Database PDB_orthologue SW:".$pdb_orth." ".$pdb_orth."\n"; }
      }
    
    foreach (@$genes_ref)
      {print "Corresponding_DNA $_ \n";}
    
    print "\n";
  } # end of sub
#-----------------------------------------------------------------------------
1;
