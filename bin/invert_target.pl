#!/usr/bin/perl -w                                                                                                                                                    
use strict;

while (<>) {
    chomp;
    next unless /waba/;
    my ($ref,$source,$method,$start,$end,$score,$strand,$phase,$target) = split "\t";
    $target =~ s/\"|\S+://g;
    my (undef,$targ,$t_start,$t_end) = split /\s+/, $target;

    $strand = '+';
    if ($t_start > $t_end) { 
			  ($start,$end)     = ($end,$start);
			  ($t_start,$t_end) = ($t_end,$t_start);
		      }

    print join("\t",($targ,$source,$method,$t_start,$t_end,$score,$strand,$phase,
		     qq(Target "Sequence:$ref" $start $end))),"\n";
}
