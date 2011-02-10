package pICalculator;
use Bio::Seq;

# pK values from the DTASelect program from Scripps
# [18]http://fields.scripps.edu/DTASelect
my $DTASelect_pK = { N_term   =>  8.0
                     ,K        => 10.0 # Lys
                     ,R        => 12.0 # Arg
                     ,H        =>  6.5 # His
                     ,D        =>  4.4 # Asp
                     ,E        =>  4.4 # Glu
                     ,C        =>  8.5 # Cys
                     ,Y        => 10.0 # Tyr
                     ,C_term   =>  3.1
                    };

# pK values from the iep program from EMBOSS
# [19]http://www.hgmp.mrc.ac.uk/Software/EMBOSS/
my $Emboss_pK    = { N_term   =>  8.6
                     ,K        => 10.8 # Lys
                     ,R        => 12.5 # Arg
                     ,H        =>  6.5 # His
                     ,D        =>  3.9 # Asp
                     ,E        =>  4.1 # Glu
                     ,C        =>  8.5 # Cys
                     ,Y        => 10.1 # Tyr
                     ,C_term   =>  3.6
                    };

sub new{
    my( $self, %opts ) = @_;
    my $this = bless {}, ref $self || $self;
    $this->seq( $opts{-seq} ) if exists $opts{-seq};
    $this->pKset( $opts{-pKset} || 'EMBOSS' );
    exists $opts{-places} ? $this->places( $opts{-places} ) : $this->places(2);
    return $this;
}

sub seq{
    my( $this, $seq ) = @_;
    unless( defined $seq && UNIVERSAL::isa($seq,'Bio::PrimarySeqI') ){
        die $seq . " is not a valid Bio::PrimarySeqI object\n";
    }
    $this->{-seq} = $seq;
    $this->{-count} = count_charged_residues( $seq );
    return $this->{-seq};
}

sub pKset{
    my ( $this, $pKset ) = @_;
    if( ref $pKset eq 'HASH' ){         # user defined pK values
        $this->{-pKset} = $pKset;
    }elsif( $pKset =~ /^emboss$/i ){    # from EMBOSS's iep program
        $this->{-pKset} = $Emboss_pK;
    }elsif( $pKset =~ /^dtaselect$/i ){ # from DTASelect (scripps)
        $this->{-pKset} = $DTASelect_pK;
    }else{                              # default to EMBOSS
        $this->{-pKset} = $Emboss_pK;
    }
    return $this->{-pKset};
}

sub places{
    my $this = shift;
    $this->{-places} = shift if @_;
    return $this->{-places};
}

sub iep{
    my $this = shift;
    return calculate_iep( $this->{-pKset}
                         ,$this->{-places}
                         ,$this->{-seq}
                         ,$this->{-count} 
                        );
}

sub charge_at_pH{
    my $this = shift;
    return calculate_charge_at_pH( shift, $this->{-pKset}, $this->{-count} );
}

sub count_charged_residues{
    my $seq = shift;
    my $sequence = $seq->seq;
    my $count;
    for ( qw( K R H D E C Y ) ){ # charged AA's
        $count->{$_}++ while $sequence =~ /$_/ig;
    }
    return $count;
}

sub calculate_iep{
    my( $pK, $places, $seq, $count ) = @_;
    my $pH = 7.0;
    my $step = 3.5;
    my $last_charge = 0.0;
    my $format = "%.${places}f";

    unless( defined $count ){
        $count = count_charged_residues($seq);
    }
    while(1){
        my $charge = calculate_charge_at_pH( $pH, $pK, $count );
        last if sprintf($format,$charge) == sprintf($format,$last_charge);
        $charge > 0 ? ( $pH += $step ) : ( $pH -= $step );
        $step /= 2.0; 
        $last_charge = $charge;
    }
    return sprintf( $format, $pH );
}

sub calculate_charge_at_pH{ 
# its the sum of all the partial charges for the 
# termini and all of the charged aa's!
    my( $pH, $pK, $count ) = @_;
    foreach (qw(K R H D E C Y)) {
      $count->{$_} ||= 0;
    }
    my $charge =               partial_charge( $pK->{N_term}, $pH )  # +ve
               + $count->{K} * partial_charge( $pK->{K}     , $pH )  #
               + $count->{R} * partial_charge( $pK->{R}     , $pH )  #
               + $count->{H} * partial_charge( $pK->{H}     , $pH )  #
               - $count->{D} * partial_charge( $pH, $pK->{D}      )  # -ve
               - $count->{E} * partial_charge( $pH, $pK->{E}      )  #
               - $count->{C} * partial_charge( $pH, $pK->{C}      )  #
               - $count->{Y} * partial_charge( $pH, $pK->{Y}      )  #
               -               partial_charge( $pH, $pK->{C_term} ); #
    return $charge;
}

# Concentration Ratio is 10**(pK - pH) for positive groups 
# and 10**(pH - pK) for negative groups
sub partial_charge{
    my $cr = 10 ** ( $_[0] - $_[1] );
    return $cr / ( $cr + 1 );
}

__END__

=head1 NAME

pICalculator

=head1 DESCRIPTION

Calculates the isoelectric point of a protein, the pH at which there is no 
overall charge on the protein.

Calculates the charge on a protein at a given pH.

=head1 SYNOPSIS

use pICalculator;

use Bio::SeqIO;

my $in  = Bio::SeqIO->new( -fh     => \*STDIN
                          ,-format => 'Fasta' );

my $calc = pICalculator->new(-places => 2);

while ( my $seq = $in->next_seq ) {

    $calc->seq( $seq );
    
    my $iep = $calc->iep;
    
    print sprintf( "%s\t%s\t%.2f\n"
                  ,$seq->id
                  ,$iep
                  ,$calc->charge_at_pH($iep)
                );

    for( my $i = 0; $i <= 14; $i += 0.5 ){

            print sprintf( "\tpH = %.2f\tCharge = %.2f\n"
                      ,$i
                      ,$calc->charge_at_pH($i)
                     );

    }   

}

=head1 CONSTRUCTOR

B<new>

$calc = pICalculator->new( [ [ -pKset => \%pKvalues ] 
                             [ -pKset => 'valid_string' ] 
                           ]
                          ,-seq    => $seq # Bio::Seq
                          ,-places => 2 
                         );

Constructs a new pICalculator. Arguments are a flattened hash. Valid =
keys are;

B<-pKset>        A reference to a hash with key value pairs for the pK =
values of

                 the charged amino acids. Required keys are;
                 
                 N_term   C_term   K   R   H   D   E   C   Y

B<-pKset>        A valid string ( 'DTASelect' or 'EMBOSS' ) that will =
specify an
                 
                 internal set of pK values to be used. The default is =
'EMBOSS'

B<-seq>          A Bio::Seq sequence to analyze

B<-places>       The number of decimal places to use in the isoelectric =
point

                 calculation. The default is 2.

=head1 METHODS

B<iep>           $calc->iep

Calculates the isoelectric point of the given protein. The value is =
returned.

B<charge_at_pH>  $calc->charge_at_pH(7)

Calculates the charge on the protein at a given pH.

B<seq>           $seq = $calc->seq( $seq )

Sets or returns the Bio::Seq used in the calculation.

B<pKSet>         $pkSet = $calc->pKSet( \%pKSet );

Sets or returns the hash or pK values used in the calculation.

=head1 SEE ALSO

 L<http://fields.scripps.edu/DTASelect/20010710-pI-Algorithm.pdf>
 L<http://www.hgmp.mrc.ac.uk/Software/EMBOSS/Apps/iep.html>
 L<http://us.expasy.org/tools/pi_tool.html>

=head1 BUGS

Please report them!

=head1 LIMITATIONS

There are various sources for the pK values of the amino acids. The set =
of pK 
values chosen will affect the pI reported.

The charge state of each residue is assumed to be independent of the =
others.

Protein modifications (such as a phosphate group) that have a charge =
are ignored

=head1 AUTHOR

Mark Southern ([23]mark_southern@merck.com)

From an algorithm by David Tabb found at 
L<http://fields.scripps.edu/DTASelect/20010710-pI-Algorithm.pdf>

=head1 COPYRIGHT

Copyright (c) 2002, Merck & Co. Inc. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see L<http://www.perl.com/perl/misc/Artistic.html>)

=cut
