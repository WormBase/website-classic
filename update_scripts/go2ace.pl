#!/usr/bin/perl

# $Id: go2ace.pl,v 1.1.1.1 2010-01-25 15:36:09 tharris Exp $

# go2ace.pl sends .ace format to STDOUT for GO_term objects.
# It requires a directory containing following files:
#    GO.defs     GO definitions
#    *.ontology  One or more ontology files

my $dir = shift || '.';
"usage: go2ace.pl <directory>\n" if $dir =~ /^-/;
my $godefs = "$dir/GO.defs";

die "No GO.defs found in $dir.\n" unless -e $godefs;

opendir (D,$dir) or die "Can't open directory $dir: $!\n";
my @ontologies = map {"$dir/$_"} grep {/\.ontology$/} readdir(D);
closedir D;

die "No .ontology files found in $dir.\n" unless @ontologies;

my (%goids,%terms);

read_definitions("$dir/GO.defs",\%goids,\%terms);

for my $gofile (@ontologies) {

  open (ONT, "$gofile") or die "Couldn't open $gofile";
  my $type;

  #parse all the ontology files as t.tmp
  my @open = ();
  while(<ONT>){
    next if /^!/;	#skip the comments

    s/^(\s*?)(\S)(.+?) ; GO:(\d+)(.*)//;
    #1 depth spaces
    #2 relat
    #3 handle
    #4 goid
    #5 other goid
    my $spacer = $1;
    my $goid   = $4;
    my $depth = length($1);
    $open[$depth] = "GO:$4";

    $type ||= $3 unless $2 eq "\$";

    my $record = qq(GO_term : "GO:$4"\n);
    $record .= qq(Definition "$goids{$4}"\n) if $goids{$4};
    (my $term = $3) =~ s/\"/\\"/; #"
    $record .= qq(Term "$term"\n);
    $record .= qq($type\n) if $type;

    if($2 eq '<'){$record .= qq(Component_of "$open[$depth-1]"\n) ;}
    if($2 eq '%'){$record .= qq(Instance_of "$open[$depth-1]"\n);}

    my $other_terms = $5;

    while($other_terms =~ /([%<>]).+?(GO:\d+)/g){
      if($1 eq '<'){$record .= qq(Component_of "$2"\n) ;}
      if($1 eq '%'){$record .= qq(Instance_of "$2"\n);}
    }

    $record .= "Ancestor $_\n" foreach @open[0..@open-2];

    $record .= "\n";
    print $record;

    # synonym terms
    while ($other_terms =~ /, (GO:\d+)/g) {
         my $synonym = $1;
         $record =~ s/^GO_term : .+$/GO_term : "$synonym"/m;
         print $record;
      }
  }

  close(ONT);
}

sub read_definitions {
  my ($deffile,$goids,$terms) = @_;
  local $/ = "\n\n";	#change the input field separator

  open (F,$deffile) or die "Can't open $deffile: $!";
  while(<F>){
    s/^!.*\n//mg;
    my %h = /^([^:]+):\s+(.+)$/mg;
    my $goid = $h{goid};
    my $term = $h{term};
    my $def  = $h{definition};
    $def     =~ s/"/\\"/g;
    $goid =~ s/GO://;
    $goids->{$goid} = $def ;
    $terms->{$goid} = $term;
  }
  close F;
}
