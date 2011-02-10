#!/usr/bin/perl

use strict;
use Ace;
my $class = 'Interaction';
my $DB = Ace->connect(-host=>'localhost',-port=>2005);

print "Ace connected\n";

my $aql_query = "select all class $class";
my @objects_full_list = $DB->aql($aql_query);
my @objects = @objects_full_list;

# my $objects = @objects_full_list[0 .. 10];
# foreach my $interaction (@$objects){

foreach my $object (@objects){
    eval{
	my $interaction = shift (@{$object});
	my $it = $interaction->Interaction_type;
	my $type = $it;
	my $rnai = $it->RNAi;
	my $effr = $it->Effector->right;
	my $effr_name = $effr->CGC_name;
	if (!($effr_name)){
		$effr_name = $effr->Sequence_name
	}
	my $effd = $it->Effected->right;
	my $effd_name = $effd->CGC_name;
	if (!($effd_name)){
		$effd_name = $effd->Sequence_name
	}
	my $phenotype = $it->Interaction_phenotype;
	
	print "$interaction\|$type\|$rnai\|$effr\|$effr_name\|$effd\|$effd_name\|$phenotype\n";
    }	
}
