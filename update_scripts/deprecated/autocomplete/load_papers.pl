#!/usr/bin/perl

use strict;
use lib '../../cgi-perl/lib';
use WormBase::Autocomplete;
use Ace;

my $version    = shift;
my $acedb_path = shift;
$version or die <<END;
   load_papers.pl [WSVERSION] [ACEDB PATH (optional)]
END

my $a = WormBase::Autocomplete->new("autocomplete_$version");

my $ace;
if ($acedb_path) {
    $ace = Ace->connect(-path => $acedb_path);
} else {
    $ace = Ace->connect(-port=>2005,-host=>'localhost');
}

$a->disable_keys;

# dump papers
my $emacs = $ENV{EMACS};
my $delim = $emacs ? "\n" : "\r";
my $count;
my $i = $ace->fetch_many('Paper' => '*') or die $ace->error;
while (my $paper = $i->next) {
  print STDERR "loaded $count papers$delim" if ++$count % 100 == 0;
  my %unique;
  my @aliases;
  my @references = $paper->Gene;
  foreach ($paper->Gene) {
      push @aliases,$_->Public_name;
  }

  foreach ($paper->Allele) {
      push @aliases,$_;
  }

  foreach ($paper->Person) {
      push @aliases,$_->Standard_name || $_->Full_name;
  }

  push @aliases,grep {!$unique{$_}++} ($paper->name,$paper->PMID);
  
  my $title    = $paper->Title;
  my $abstract = eval{$paper->Abstract->right};
  $a->insert_entity('Paper',$paper,\@aliases,[[$title,$abstract]]);

  print STDERR "  " . join(';',@aliases) . $delim;;
}

exit 0;

