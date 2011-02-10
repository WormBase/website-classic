#!/usr/bin/perl
use CGI qw/url self_url/;
my $query= new CGI;
print $query->header;
print "hello people in my head\n";
print "Content-type: text/plain; charset=iso-8859-1\n\n";
print url(-absolute=>1,-path_info=>1),"\n";
foreach $var (sort(keys(%ENV))) {
    $val = $ENV{$var};
    $val =~ s|\n|\\n|g;
    $val =~ s|"|\\"|g;
    print "${var}=\"${val}\n";
        print "<br>";
}

