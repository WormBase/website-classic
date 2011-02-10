package CGIsubs;

$URIROOT="http://www.wormbase.org/cisortho/";

use Exporter;
@ISA=('Exporter');
@EXPORT=qw(&PrintPage);
use CGI qw(:standard :pretty);

sub PrintPage{
 	my ($out,$html,$secs)=@_;
 	local *OUT;
 	unlink $out;
 	warn "Can't open $out" unless (open OUT,'>'.$out);
	#print OUT &header();

	$head = ($secs > 0) ? &meta({-http_equiv=>'refresh', -content=>"$secs"}) : '';

	print OUT
	  start_html(-title=>'Results Page: ',
				 -dtd=>['-//W3C//DTD XHTML 1.0 Strict//EN',
						'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'],
				 -style=>{-src=>$URIROOT."cisortho.css"},
				 -head=>$head);

	print OUT "$html\n";
	print OUT "<table><tr><td><hr></td></tr></table>\n";
	print OUT "</body>\n</html>\n";
	close OUT;
}

1;
