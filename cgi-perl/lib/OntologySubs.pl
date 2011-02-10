#!/usr/bin/perl

use CGI qw(:standard *table *TR *iframe);
sub print_ontology {

my ($object) = @_;
my $object_id = $object->name;
my %ontology2ace = (
		'GO_term' => 'go',
		'Phenotype' => 'po',
		'Anatomy_term' => 'ao');
my $class = $ontology2ace{$object->class};
my $scr = '/db/ontology/browse_tree?query='.$object_id.';query_type=term_id;ontology='.$class.';details=on;children=on;expand=1';
my $frame = div({-class => 'white'},iframe({-name => 'browser', 
											-src=> $scr, 
											-width => 950, 
											-height => 300}));
my $end_frame = "\<\/iframe\>";

return ($frame,$end_frame);

}

1;

