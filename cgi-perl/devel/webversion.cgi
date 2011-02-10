#!/usr/bin/perl -w
#print "Content-type: text/html\n\n";

use CGI qw( :standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use strict;
use warnings;

=head1 SYNOPSIS

 This is an example of a simple implementation of Bio::PrimerDesigner
 It is pure perl with no local installation of primer3
 The primer design parameters and where the DNA comes from is up to the
 implementer.  Your specific project will require program logic
 to get the DNA sequence, set design parameters, etc.

=cut

use lib "..//lib";
use Bio::PrimerDesigner;
use Getopt::Long;
use Pod::Usage;
use IO::File;

# Access a remote script that will run primer3
use constant METHOD => 'remote';
use constant URL    => 'http://mckay.cshl.edu/cgi-bin/primer_designer.cgi';

# Create Bio::PrimerDesigner object.
my $pd   =  Bio::PrimerDesigner->new(
    program     => 'primer3',
    method      => METHOD,
    url         => URL,
); # or die Bio::PrimerDesigner->error;

=head1 DESCRIPTION

The goal of the program is to design long range PCR primers to tile across large regions of the genome. The user can specify\
the ideal product size,primers should ideally produce products that are 5KB in length with 1KB overlap.  The primers themsel\
es should not land in regions of known repeats or SNPS.

=head1 METHOD


 The user should upload a fasta file of their region of interest with the repeats and SNP's masked out as n's (if desired).\
he new lines are removed, and a check is done to make sure the two sequences are the same length. The program then creates o\
e sequence with both the repeats and SNPs masked as lower case n's which is ready for further manipulation.


=cut



print header;
print start_html("test_form");
         
     
print <<END;

<h2>Long Range PCR Primer Design Program</h2> <br/><br/>
The goal of this program is to design long-range PCR primers to tile across large regions of the genome.<br/>  The user must 
specify the region of the genome the want to design primers for, the ideal PCR product size and the maximum prodcut size they want to 
allow before the program returns and error message. <br/><br/>
This program uses the human, March 2006 assembled sequences obtained from ftp://ftp.ncbi.nih.gov/genomes/H_sapiens/Assembled_chromosomes/ <br/>
Primers are designed using Primer3, and the best matches are printed out the screen.



END




print <<END;

<form action="webversion.cgi" method="GET">
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
#print "The chromosome I am interested in designing primers for is $chromosome\n\n";

$input[1] =~ /=(\d+)/;
my $start_position = $1;
#print "The start position is $start_position\n\n";

$input[2] =~ /=(\d+)/;
my $end_position = $1;
#print "The end position is $end_position\n\n";

$input[3] =~ /=(\d+)/;
my $ideal_size = $1;
#print "The ideal product size is $ideal_size\n\n";

$input[4] =~ /=(\d+)/;
my $max_size = $1;
#print "The maximum product size is $max_size\n\n";



# Opening the chromosome file.

open(DNA, "<", "$chromosome") || die "cannot open $chromosome : $!";

while (<DNA>) {
    chomp $_ ;
    $chromosome = $chromosome . $_;
}
    my $dna_length = length $chromosome;

 #   print "the length of the file is $dna_length";










#my $xl = IO::File->new(">> junk_xl.xls") or die "help $!";

#my ($dna);

#while (<REPEAT>) {
 #   chomp $_ ;
  #  $dna = $dna . $_;
#}
#while (<SNP>) {
 #   chomp $_;
  #  $snp_dna = $snp_dna . $_;
#}

# calculate length of repeat and snp dna

#my ($repeat_length, $snp_length);
#$repeat_length = length $repeat_dna;
#$snp_length = length $snp_dna;

#if ($repeat_length == $snp_length) {
 #   print " The snp_dna  and repeat_dna  have the same length.\n";
#} else { print "They snp_dna and repeat_dna  do not have the same length.\n";
        # die "Program Terminated !";
    # }

#my $merge_dna = $repeat_dna;
#while ($snp_dna =~ m/N/g) {
 #   substr($merge_dna, $-[0], 1) = 'X';
#}

# Change upper case to lower case.

#$merge_dna =~ tr/ACTGX/actgn/;



my $fragcount = 0;
my $lengthener = ($max_size - $ideal_size)/1000;


=head1 METHOD

The program cuts the DNA into fragments (size choosen by the user)  and sends them to the design primers subroutine.  If prim\
ers can be found they are printed to a file, if none are found, the fragments are extended 1000bp (500 on each end) and sent \
to the design primers sucroutine.  The fragments are allowed to lengthen until they reach a maximum size, specified by the us\
er. \n.  If no primers are found within the range,  a primer failed message is returned and those primers must be found manua\
lly using the online version of primer3.

=cut

# When we can't find a primer for a fragment, we want the program to look at a longer fragment and see if
# it can find a primer for it.  If it still can't find a primer, we want to look at a still longer fragment,
# and so on.  $lengthener is the factor by which we lengthen the fragment plugged into primer3.  For every
# increase of 1 of $lengthener, primer3 gets 1000 more base pairs.  The offset is also reduced, so that 500
# of the new base pairs are at the front of the fragment and 500 are at the end.


my %fragments;
for (my $offset = $start_position ; $offset < ($end_position) ; $offset = $offset + ($ideal_size - 1000)) {
    my $sub_sequence = substr($chromosome, $offset, $ideal_size);
    my $success = design_primers($offset,$sub_sequence);

    if ($success) {
        print "\nPrimer pairs (no lengthener) OK at offset $offset \n\t--------------------\n\n";
    }
    else {
        $lengthener = 1 ;
        while ($lengthener) {
             $offset = $offset - 500 ;
            my $sub_sequence = substr($chromosome, $offset, ($ideal_size + 1000 * $lengthener));
            my $success = design_primers($offset,$sub_sequence);

            if ($success) {
                print "\tOK\t Primer pairs listed above successfully created by lengthener ($lengthener) at offset $offset \n\
\n";
                $lengthener = 0;
  
           }

            else {
                $lengthener++;
                if ($lengthener == ((($max_size - $ideal_size)/1000)+1)) {
                    $lengthener = 0;
                    print "Lengthener failed at $offset \n";
                   # print "hit return to continue ";
                   # my $go = <STDIN>;
                 #print "Lengthener is " ,  $lengthener++, "\n";

               #print : "Primer3 failed at lengthner ($lengthener) at offset ($offset)";
            }
        }
    }
  }
}
my $chunk_number = 1;

my @chunks = sort {$a <=> $b} keys %fragments;

sub design_primers {
    my $offset = shift;
    my $dna    = shift;
    my $high_range = $ideal_size + 1000 * $lengthener;
    #my $xl_file = shift;


#foreach my $offset (@chunks) {
#    my $dna = $fragments{$offset};
    my $length = length $chromosome;
    my $seqID = "file_ID";

    my %params  =   (       
	            SEQUENCE                  => $chromosome,
                     PRIMER_PRODUCT_SIZE_RANGE => "$ideal_size-$high_range", # size of PCR product
                     TARGET                    => '$ideal_size/2, 1',   # center of PCR product
                     PRIMER_SEQUENCE_ID        => $seqID);


    # Design the primers.
   my $result = $pd->design( %params );

    # Did it work?
   # warn join("\n","Some sort of primer3 error\n", $pd->error, $result->raw_output) and next
    unless ($result && $result->left) {
        #warn "NO primers for $offset,$length\n";
        #next;
        return 0;
     }
#
    #print join("\t",qw/Left Right Left_start Right_end Score/), "\n";

    # Print the best 5 primer sets (NOTE: low scores are better)
    # Note: the primers are always 5'->3' and the right (reverse) primer is
    # already reverse-complemented!

   for ( 1 ) {
        my $left  = $result->left($_);
        my $right = $result->right($_);
        my $start = $result->startleft($_)  + $offset;;
        my $end   = $result->startright($_) + $offset;;
        my $score = $result->qual($_);
       

	print join("\t",$left,$right,$start,$end,$score), "\n";
    }
   # print "The five best primers for chunk $chunk_number are \n";
   # $chunk_number++;
    return 1;
}

#  print "\nthe raw primer3 output:\n", $result->raw_output;


    

