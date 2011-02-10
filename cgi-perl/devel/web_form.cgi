#!/usr/bin/perl -w
use CGI qw(:standard);

print header;
print start_html("test_form");

print <<END;

The goal of this program is to design long-range PCR primers to tile across large regions of the genome.\n  The user must specify the region of the genome the want to design primers for, the ideal PCR product size and the maximum prodcut size they want to allow before the program returns and error message\n\n\n.

END




print <<END;

<form action="web_form.cgi" method="GET">
<br/> Enter the number or letter of the chromosome you wish to design primers for:
     <input type="text" name="chromosome" size=30> <br/>
Enter the start position of the region you are interested in amplifying:
    <input type="text" name="start_position" size=30> <br/>
Enter the end position of the region you are interested in amplifying:
    <input type="text" name="end_position" size=30> <br/>
Enter the ideal LR-PCR product size here:
    <input type="text" name="ideal_size" size=30> <br/>
Enter the maximum LR-PCR product size here:
    <input type="text" name="max_size" size=30><p>
<input type="submit"><p>
</form>

END



my @input = split(/&/,$ENV{'QUERY_STRING'} );

$input[0] =~ /=(\w+)/;
my $chromosome = $1;
print "The chromosome I am interested in designing primers for is $chromosome\n\n";

$input[1] =~ /=(\d+)/;
my $start_position = $1;
print "The start position is $start_position\n\n";

$input[2] =~ /=(\d+)/;
my $end_position = $1;
print "The end position is $end_position\n\n";

$input[3] =~ /=(\d+)/;
my $ideal_size = $1;
print "The ideal product size is $ideal_size\n\n";

$input[4] =~ /=(\d+)/;
my $max_size = $1;
print "The maximum product size is $max_size\n\n";

open(DNA, "<", "$chromosome") || die "cannot open $chromosome : $!";

while (<DNA>) {
    chomp $_ ;
    $chromosome = $chromosome . $_;
}
    my $dna_length = length $chromosome;

    print "the length of the file is $dna_length";












   
















   # my @values = split(/&/,$ENV{QUERY_STRING} );
    #if ($values[0]) {
	#($ideal_size, $data = split(/=/, $i) 
   # }
    #else {
	#($values[1]) 
	 # ($max_size,  $data = split(/=/, $i)
      # }


       
       
#    my @values = split(/&/,$ENV{QUERY_STRING} );
	#foreach my $i (@values) {
	 #   my($ideal_size, $data) = split(/=/, $i);
	  #  print "$ideal_size = $data<br>\n";


#print end_html;
