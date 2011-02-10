#!/usr/bin/perl

use strict;
use Ace;
my $CLASS = 'Laboratory';

my $script = $0 =~ /([^\/]+)$/ ? $1 : '';

my $version    = shift;
my $acedb_path = shift;
$version or die <<END;
 Usage: $script [WSVERSION] [ACEDB PATH (optional)]
END
    
my $ace;
if ($acedb_path) {
    $ace = Ace->connect(-path => $acedb_path);
} else {
    $ace = Ace->connect(-port=>2005,-host=>'localhost');
}


my $emacs = $ENV{EMACS};
my $delim = $emacs ? "\n" : "\r";
my $count;

my $total = $ace->count($CLASS => '*');
print STDERR "Loading $total $CLASS...\n";

my $i = $ace->fetch_many(-class=>$CLASS,-name => '*',-filled=>1) or die $ace->error;
while (my $obj = $i->next) {
    print STDERR "loaded $count $CLASS$delim" if ++$count % 100 == 0;
    my $representative = eval  { $obj->Representative->Full_name };
    my $laboratory     = $obj;
    my $allele         = $obj->Allele_designation;
    my $mail           = $obj->Mail;
    print join("\t",$representative,$laboratory,$allele,$mail),"\n";    
}

warn "\nDone loading: loaded $count $CLASS objects...\n";

