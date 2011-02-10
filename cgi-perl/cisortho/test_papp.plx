#!/usr/bin/perl -W

use lib '/home/henry/usr/lib/perl5/site_perl/5.8.8';
use Data::Dumper;
use PApp::SQL;
use DBI;
use strict;

use base qw(JSON::RPC::Procedure); # Perl 5.6 or more than

sub forward_query : Public(query:str) {
	my ($obj) = @_;

	#return "plain string from forward_query";

	my $q = $obj->{query};
	#return "before.";
 	#my $dbi = 'dbi:mysql:';
	#DBI->trace(1);
	#my $dbh = new DBI;

	#return "string after";

	my $dbh = DBI->connect("DBI:mysql:cisortho", 'henry', '', {}) ||
	  return "forward_query database returned error code: ". $DBI::errstr;
	
	#my $st = sql_exec $dbh, \my($a,$b,$c), $q;
	#"select distinct species, dna, gene from  limit 10";
	my $st2;
	#print Dumper $q;
	eval { $st2 = sql_exec $dbh, $q; };
	if ($@){
		return $@;
	}

	undef my @items;
	while (my @row = $st2->fetchrow_array){
		#warn "row: ", Dumper \@row;
		push @items, [@row];
	}

	#while ($st->fetch) {
	#	push @items, [$a,$b,$c];
	#}

	my $rc = $dbh->disconnect;
	if (! $rc) {
		return "Couldn't disconnect from database";
	}

	#warn Dumper \@items;
	#return scalar @items;
	return \@items;

}

print Dumper &forward_query({'query' => 'selec * from gene limit 5'});
