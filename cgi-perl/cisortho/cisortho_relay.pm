package cisortho_relay;

use lib '/home/henry/usr/lib/perl5/site_perl/5.8.8';

use JSON::RPC::Client;
use Data::Dumper;

$client = new JSON::RPC::Client;

use base qw(JSON::RPC::Procedure); # Perl 5.6 or more than

sub relay : Public(method, params) {
	my ($s, $obj) = @_;
	#send an rpc call to a server
	my $url = 'http://www.wormbase.org/db/cisortho/server_back.cgi';
	
	$res = $client->call($url, $obj);
	
	
	if($res) {
		if ($res->is_error) {
			warn "Error : ", $res->error_message;
		}
		else {
			return $res->result;
		}
	}
	else {
		warn $client->status_line;
	}
	
}


1;
		
