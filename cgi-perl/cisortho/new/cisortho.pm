package cisortho;

use lib '/home/henry/usr/lib/perl5/site_perl/5.8.8';

#use SQL::DB qw(define_tables count max);
use Data::Dumper;
use PApp::SQL;
use DBI;
use strict;

#these routines will act as the client to call another
#JSON::RPC server

 
use base qw(JSON::RPC::Procedure); # Perl 5.6 or more than



sub echo : Public(a:str) {    # new version style. called by clients
 	my ($s, $obj) = @_;	
	return 'a result: ' . $obj->{a};	
}

sub sum : Public(a, b) { # sets value into object member a, b.
	my ($s, $obj) = @_;
	# return a scalar value or a hashref or an arryaref.
	return $obj->{a} + $obj->{b} - 5;
}

sub shout : Private {
    return "I'm shouting!";
}

sub a_private_method : Private {
	# ... can't be called by client
}

sub sum_old_style {  # old version style. taken as Public
	my ($s, @arg) = @_;
    return $arg[0] + $arg[1];
}


#@sources = DBI->data_sources('mysql');
#print Dumper \@sources;

sub forward_query : Public(query:str) {
	my ($s, $obj) = @_;

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


1;
