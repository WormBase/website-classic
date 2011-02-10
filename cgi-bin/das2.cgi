#!/usr/bin/perl

# $Id: das2.cgi,v 1.1.1.1 2010-01-25 15:39:10 tharris Exp $

use lib '/home/lstein/projects/bioperl-live',
  '/home/lstein/projects/Generic-Genome-Browser/lib';

use strict;
use URI ();
use CGI qw(:standard unescape escape escapeHTML);
use Bio::Graphics::Browser;
use Bio::Graphics::Browser::Util;
use Text::Shellwords;

use constant CONFIG_FILE_DIRECTORY => '/usr/local/wormbase/conf/gbrowse.conf';
use constant GBROWSE_SCRIPT        => 'http://localhost/cgi-bin/gbrowse/';

my ($source,
    $version,
    $namespace,
    @args) = parse_request_list();

my $config = open_config(CONFIG_FILE_DIRECTORY)
  or error_exit(500=>'Could not read config files');

list_sources($config)  && exit 0 unless $source;

$config->source($source) || error_exit(401 => 'unknown data source');
list_versions($config) && exit 0 unless $version;

my $db = open_database() or error_exit(500=>'Could not open database');

CASE: {
  print_ok_header() && describe_datasource($config,@args)    && last CASE unless defined $namespace;
  print_ok_header() && list_types($config,@args)             && last CASE if $namespace  eq 'type';
  print_ok_header() && list_region($config,@args)            && last CASE if $namespace  eq 'region';
  print_ok_header() && list_sequence($config,@args)          && last CASE if $namespace  eq 'sequence';
  print_ok_header() && list_feature($config,@args)           && last CASE if $namespace  eq 'feature';
  error_exit(400 => 'Bad command');
}


exit 0;

sub describe_datasource {
  my $config = shift;
  my $source      = $config->source;
  my $description = $config->description($config->source);
  my $version     = 1;
  my $mtime       = $config->config->mtime;
  my $date        = localtime($mtime);

  print_xml_header();
  print_das_start('SOURCE_DETAILS');
  print <<END;
  <DESCRIPTION>$description</DESCRIPTION>
  <CREATE_TIME>$date</CREATE_TIME>
  <MODIFICATION_TIME>$date</MODIFICATION_TIME>
  <HTTP_METHODS>
    <METHOD name="GET">Get information about a resource</METHOD>
    <METHOD name="PUT">Create or update a resource</METHOD>
    <METHOD name="DELETE">Delete a resource</METHOD>
    <METHOD name="POST">Augments a resource with new data</METHOD>
  </HTTP_METHODS>
  <NAMESPACES>
    <NAMESPACE id="type">Feature types</NAMESPACE>
    <NAMESPACE id="feature">A genomic feature</NAMESPACE>
    <NAMESPACE id="sequence">A sequence or subsequence</NAMESPACE>
    <NAMESPACE id="region">A region or subregion</NAMESPACE>
  </NAMESPACES>
END
  print_das_end('SOURCE_DETAILS');
  1;
}

sub list_sources {
  my $config = shift;
  my @data_sources = $config->sources;
  print_ok_header();
  print_xml_header();
  print_das_start('SOURCES');
  for my $source (@data_sources) {
    my $description = $config->description($source);
    print <<END;
  <SOURCE id="$source" display_name="$description">
     <VERSION id="$source/1">$description</VERSION>
  </SOURCE>
END
  }
  print_das_end('SOURCES');
  1;
}

sub list_versions {
  my $config = shift;
  print_ok_header();
  print_xml_header();
  print_das_start('SOURCE',undef);
  my $description = $config->description($config->source);
  print <<END;
  <VERSION id="1">$description</VERSION>
END
  print_das_end('SOURCE');
  1;
}

sub list_types {
  my $config = shift;
  my ($type,@attribute) = @_;
  my $format = param('format');
  $format    ||= 'full';
  print_xml_header();
  print_types($config,$type,$format,@attribute);
  1;
}

sub list_region {
  my $config = shift;
  my ($seqid,$start,$end,$subtag) = @_;

  my $db = open_database;
  my @type_filter = param('type');
  @type_filter    = all_types($config) unless @type_filter;
  my $format      = param('format');
  $format       ||= 'DAS2XML';

  if (!defined $seqid && param('type')) {
    print_features($config,$db,$format,$subtag,\@type_filter);
  }
  elsif (defined $seqid) {
    my $class;
    if ($seqid =~ /^([^:]+):(.+)$/) {
      $class = $1;
      $seqid = $2;
    }
    my @argv = (-name  => $seqid) if defined $seqid;
    push @argv,(-class => $class) if defined $class;
    push @argv,(-start => $start) if defined $start;
    push @argv,(-end   => $end)   if defined $end;

    my $segment  = $db->segment(@argv);
    print_features($config,$segment,$format,$subtag,\@type_filter);
  } else {
    @type_filter = shellwords($config->setting(general => 'landmark features'));
    @type_filter = 'Component' unless @type_filter;
    print_features($config,$db,$format,$subtag,\@type_filter,'region_flag');
  }
}

sub list_sequence {
  my $config = shift;
  my ($seqid,$start,$end,$strand) = @_;
  my $db = open_database;
  ($start,$end) = ($end,$start) if $start > $end;
  ($start,$end) = ($end,$start) if defined $strand && $strand < 0;

  my $format = param('format') eq 'FASTA' ? 'FASTA' : 'DAS2XML';
  if (defined $seqid) {
    my $class;
    if ($seqid =~ /^([^:]+):(.+)$/) {
      $class = $1;
      $seqid = $2;
    }
    my @argv = (-name  => $seqid);
    push @argv,(-class => $class) if defined $class;
    push @argv,(-start => $start) if defined $start;
    push @argv,(-end   => $end)   if defined $end;

    print_xml_header();
    print_das_start('SEQUENCES',features_base(),format=>$format);
    my $dna  = $db->dna(@argv);
    print_dna($dna,$format,$seqid,$start,$end,$strand);
    print_das_end('SEQUENCES');
  } else {
    my @type_filter = shellwords($config->setting(general => 'landmark features'));
    @type_filter = 'Component' unless @type_filter;
    my @segments = $db->features(-type=>\@type_filter);
    print_sequence($format,\@segments);
  }
}

sub print_dna {
  my ($dna,$format,$seqid,$start,$end,$strand) = @_;
  $strand ||= 0;
  my $length = length $dna;
  $start = 1       unless defined $start;
  $end   = $length unless defined $end;
  my $name = "sequence/$seqid/$start/$end/$strand";
  my $type =   $dna=~/^[gatcn-]+$/i ? 'DNA'
             : $dna=~/^[gaucn-]+$/i ? 'RNA'
             : 'Protein';
  if ($format eq 'DAS2XML') {
    $dna =~ s/(.{1,80})/     $1\n/g;
    print <<END if $format eq 'DAS2XML';
   <SEQUENCE id="$name" length="$length" type="$type">
$dna   </SEQUENCE>
END
  } elsif ($format eq 'FASTA') {
    $dna =~ s/(.{1,80})/$1\n/g;
    my $base = features_base();
    print ">${base}${name}\n$dna";
  }
}

sub print_sequence {
  my $format = shift;
  my $segments = shift;
  print_xml_header();
  my $base = features_base();
  print_das_start('SEQUENCES',$base,format=>$format);
  for my $s (@$segments) {
    next unless $s;
    my $seqid = $s->seq_id;
    my $start = $s->start;
    my $end   = $s->end;
    my $dna    = lc $s->dna;
    print_dna($dna,$format,$seqid,$start,$end,0);
  }
  print_das_end('SEQUENCES');
}

sub print_types {
  my $config = shift;
  my ($desired_type,$format_style,$format_option) = @_;
  my %seenit;

  my @types = grep {!$seenit{$_}++ and 
		      defined $desired_type ? $desired_type eq $_ ? $_ : () : $_} all_types($config);
  my $c = $config->config;
  my $base = features_base('type');

  print_das_start('TYPES',$base,method_ontology=>"http://song.sourceforge.net/ontologies/sofa");

  my %default_style       = $config->config->default_style;
  $default_style{-link} ||= $config->setting(general=>'link');

  for my $type (@types) {
    next if defined $desired_type && $type ne $desired_type;

    my ($method,$source) = split ':',$type;
    my $label = $c->type2label($type);
    my %type_style = $c->style($label);
    my %style = (%default_style,map {ref $type_style{$_}?():($_=>$type_style{$_})} keys %type_style);
    delete $style{-feature};
    delete $style{-feature_low};
    delete $style{-link} if $style{-link} eq 'AUTO';
    my $key = escapeHTML($style{-key});

    print <<END;
  <TYPE id="$type" method="$method" source="$source" xml:base="$base$type/" label="$key">
END
  ;
    my $desc = escapeHTML($style{-citation} || $key || $label);
    if ($format_style eq 'full') {
      for my $option (keys %style) {
	(my $name = $option) =~ s/^-//;
	next if defined $format_option && $format_option ne $name;
	my $value = escapeHTML($style{$option});
	print <<END;
     <ATTRIBUTE id="$name" value="$value" />
END
;
    }
END
    } elsif ($format_style eq 'brief') {
      print <<END;
     $desc
END
;
    }
      print <<END;
  </TYPE>
END
  }
  print_das_end('TYPES');
  1;
}

sub list_feature {
  my $config = shift;
  my ($feature_type,$feature_id,$subtag) = @_;

  my $db = open_database;
  my $format      = param('format');
  $format       ||= 'DAS2XML';
  my $recurse     = !param('norecurse');

  if (defined $feature_id) {
    my $class;
    if ($feature_id =~ /^([^:]+):(.+)$/) {
      $class = $1;
      $feature_id = $2;
    }

    my @argv = (-name  => $feature_id);
    push @argv,(-class => $class) if defined $class;
    my @unfiltered_features = $db->get_feature_by_name(@argv);

    my @features = grep {$_->type eq $feature_type} @unfiltered_features;

    # hack for overly aggregated features
    @features = grep {$_->type eq $feature_type} map {$_->get_SeqFeatures} @unfiltered_features
      if !@features;

    # hack for non-unique feature IDs from old Bio::DB::GFF
    my $idx;
    if (!@features && $feature_id =~ /\((\d+)\)$/) {
      $idx = $1;
      $feature_id =~ s/\(\d+\)$//;
      @argv = (-name  => $feature_id);
      push @argv,(-class => $class) if defined $class;
      @features = sort {$a->start <=> $b->start} 
                  grep {$_->type eq $feature_type} 
                  map {$_->get_SeqFeatures} $db->get_feature_by_name(@argv);
      @features = $features[$idx-1] if @features;
    }

    print_xml_header();
    print_das_start('FEATURELIST',features_base('feature'),
		    format=>$format);
    if ($format eq 'DAS2XML') {
      print_das2xml($config,$_,'',$subtag,undef,$recurse,$idx) foreach @features;
    } else {
      print_gff3($config,$_,undef,$recurse) foreach @features;
    }
    print_das_end('FEATURELIST');
  }

  else {
    my @features = defined $feature_type ? ($feature_type)
                                         : all_types($config);
    print_features($config,$db,$format,undef,\@features);
  }
}

sub error_exit {
  my ($status,$warning) = @_;
  print header(-status        =>  "500 DAS protocol error",
	       -type          =>  'text/plain',
	       -X_DAS_Status  =>  "$status $warning",
	       -X_DAS_Version =>  'DAS/2',
	       -type           => 'text/html');
  print start_html('DAS protocol error'),
    h1('DAS protocol error'),
    p('A DAS protocol error has occurred.  The server reported',i($status,$warning),'.',
      'Please refer to',a({-href=>'http://www.biodas.org/das2'},'the DAS/2 spec'),
      'for information about what might have gone wrong.',
     ),
       hr(),
	 pre('$Id: das2.cgi,v 1.1.1.1 2010-01-25 15:39:10 tharris Exp $'); #'
  exit 0;
}

sub print_ok_header {
  print header(-type          => 'text/plain',
	       -X_DAS_Status  =>  200,
	       -X_DAS_Version =>  'DAS/2');
}

sub print_xml_header {
  print qq(<?xml version="1.0" standalone="yes"?>\n\n);
}

sub print_das_start {
  my $tag  = shift;
  my $base = shift;
  my %additional_attributes = @_;
  unless ($base) {
    $base = url(-path_info=>1);
    $base .= '/' unless $base=~ m!/$!;
  }
  my $additional = join "\n      ",map {qq($_="$additional_attributes{$_}")} keys %additional_attributes;
  $additional    = "\n      $additional" if $additional;
  print <<END;
<$tag
      xmlns="http://www.biodas.org/ns/das/2.00"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      xml:base="$base"$additional>
END
}

sub print_das_end {
  my $tag = shift;
  print "</$tag>\n";
}

sub parse_request_list {
  my $path = path_info;
  my @components = split '/',$path;
  shift @components;
  shift @components;
  return map {unescape($_)} @components;
}

sub print_regions {
  my ($segment,$format,$subtag,$type_filter) = @_;
  my $recurse = !param('norecurse');
  print_xml_header();
  print_das_start('REGIONLIST',features_base()."region/",format=>$format);
  if ($segment) {
    my $iterator = $segment->features(-types=>$type_filter,-iterator=>1);
    while (my $f = $iterator->next_feature) {
      if ($format eq 'DAS2XML') {
	print_das2xml($config,$f,undef,$subtag,'bad hack alert',$recurse);
      } else {
	print_gff3($config,$f,$recurse,'bad hack');
      }
    }
  }
  print_das_end('REGIONLIST');
}

sub print_features {
  my ($config,$segment,$format,$subtag,$type_filter,$region) = @_;
  my $recurse = !param('norecurse');
  print_xml_header();
  print_das_start('FEATURELIST',features_base().($region?'region/':'feature/'),format=>$format);
  if ($segment) {
    my $iterator = $segment->features(-types=>$type_filter,-iterator=>1);
    while (my $f = $iterator->next_feature) {
      if ($format eq 'GFF3') {
	print_gff3($config,$f,$region,$recurse);
      } elsif ($format eq 'DAS2XML') {
	print_das2xml($config,$f,undef,$subtag,$region,$recurse);
      }
    }
  }
  print_das_end('FEATURELIST');
}

sub all_types {
  my $config = shift;
  return map {$config->label2type($_)} $config->labels;
}

sub print_gff3 {
  my ($config,$feature,$region_hack,$recurse) = @_;
  my $gff3 = $feature->gff3_string($recurse);
  if (my $link = escape(make_link($config,$feature))) {
    $gff3 =~ s/$/;link=$link/m;
  }
  if ($region_hack) {
    $gff3  =~ s/ID=\w+://g;  # BAD HACK ALERT
  }
  print $gff3
}

sub print_das2xml {
  my ($config,$feature,$parent,$subpart,$region_hack,$recurse,$idx) = @_;
  $subpart = lc $subpart;  #forget about case sensitivity
  my $seqid = $feature->ref;
  my $start = $feature->start;
  my $end   = $feature->end;
  my $strand= $feature->strand;
  my $type  = $feature->type;
  my $name  = $feature->name;
  my $class = $feature->class;
  my $id    = $region_hack ? "$name" : "$type/$class:$name";
  my $method= $feature->method;
  my $source= $feature->source;
  my $score = $feature->score;
  my $phase = $feature->phase;
  my $target = $feature->target;
  my @notes  = $feature->notes;
  my $link   = make_link($config,$feature) unless $parent;

  # hack for nonunique features
  $id .= "($idx)" if $idx;

  $parent=$parent ? $parent->type . '/' . $parent->class . ':' . $parent->name
                  : '';
  my @attributes = $feature->attributes;

  print <<END;
  <FEATURE id="$id">
END
  ;
  if (!$subpart or $subpart eq 'location') {
    ($start,$end) = ($end,$start) if $start > $end;
    my $location  = "../sequence/$seqid";
    {
      last unless defined $start;
      $location    .= "/$start";
      last unless defined $end;
      $location    .= "/$end";
      last unless defined $strand;
      $location    .= "/$strand";
    }
    print <<END;
     <LOCATION id="$location" />
END
      ;
  }
  print <<END if !$subpart or $subpart eq 'type';
     <TYPE id="../type/$type" source="$source" method="$method" />
END
  ;
  print <<END if !$subpart or $subpart eq 'display_name';
     <DISPLAY_NAME>$name</DISPLAY_NAME>
END

  print <<END if length($parent) and !$subpart or $subpart eq 'parent';
     <PARENT id="$parent" />
END

  print <<END if length($phase) and !$subpart or $subpart eq 'phase';
     <PHASE>$phase</PHASE>
END

  print <<END if $score and !$subpart or $subpart eq 'score';
     <SCORE>$score</SCORE>
END
;
  if ($target) {
    my $tstart = $target->start;
    my $tend   = $target->end;
    my $location = "../sequence/$target";
    $location .= "/$tstart" if defined $tstart;
    $location .= "/$end"    if defined $end;
    print <<END;
     <TARGET id="$location" />
END
;
  }

  if (!$subpart or $subpart eq 'note') {
    print <<END foreach @notes
     <NOTE>$_</NOTE>
END
;
  }

  print <<END if $link && !$subpart or $subpart eq 'link';
     <LINK xlink:href="$link" />
END

  while (my ($tag,$value) = splice(@attributes,0,2)) {
    next if $subpart and $subpart ne $tag;
    $tag   = escape($tag);
    $value = escape($value);

    print <<END if lc $tag eq 'alias';
     <ALIAS>$value</ALIAS>
END
  ;
    next if lc $tag eq 'note';  # already handled
    print <<END if lc $tag eq 'dbxref';
     <DBXREF>$value</DBXREF>
END
  ;
    print <<END;
     <ATTRIBUTE att_type="$tag" value="$value" />
END
  }

  my @subseq = sort {$a->start<=>$b->start} $feature->get_SeqFeatures;
  print_subparts($feature) if !$subpart or $subpart eq 'subparts';

  print <<END;
  </FEATURE>
END

  if ($recurse and !$subpart and @subseq) {
    # another hack for the nonunique IDs in Bio::DB::GFF
    my (%idxes,%type_count);
    $type_count{$_->type,$_->class,$_->name}++  foreach @subseq;

    foreach (@subseq) {
      my $non_unique = $type_count{$_->type,$_->class,$_->name}>1;
      print_das2xml($config,$_,$feature,undef,$region_hack,$recurse,
		    $non_unique && $idxes{$_->type,$_->class,$_->name}++ +1);
    }
  }
}

sub features_base {
  my $subbit = shift;
  my $base= (join '/',url(-base=>1),(map {escape($_)} 'das',$source,$version));
  $base .= "/";
  $base .= "$subbit/" if defined $subbit;
  $base;
}

sub make_link {
  my ($config,$feature) = @_;
  my $link = $config->make_link($feature);
  return URI->new_abs($link,GBROWSE_SCRIPT);
}

sub print_subparts {
  my $f     = shift;
  my $spaces= shift || 0;
  my $pad = ' 'x$spaces;
  my @subparts = sort {$a->start<=>$b->start} $f->get_SeqFeatures;
  return unless @subparts;
  my $base = features_base('stylesheet');

  # hack for nonunique subpart names;
  my (%ids,%counts,%id_hack);
  foreach (@subparts) {
    my $s_id  = $_->type . '/' . $_->class . ':' . $_->name;
    $ids{$_} = $s_id;
    $counts{$s_id}++;
  }

  print <<END;
     <SUBPARTS xml:base="$base">
END
  ;
  
  for my $s (@subparts) {
    my $s_id  = $ids{$s};
    my $stype = $s->type;
    my @subsub = $s->get_SeqFeatures;

    # here is a bad bad hack for nonunique subpart names
    # used to support Bio::DB::GFF version 1
    if ($counts{$s_id}>1) {
      ++$id_hack{$s_id};
      $s_id .= "($id_hack{$s_id})";
    }

    if (@subsub) {
      print <<END;
	$pad<SUBPART id="$s_id" type="$stype">
END
  ;
      print_subparts($_,$spaces+=5) foreach @subsub;
      print <<END;
	$pad</SUBPART>
END
      } else {
	print <<END;
         $pad<SUBPART id="$s_id" type="$stype" />
END
;
      }

    }
  print <<END;
     $pad</SUBPARTS>
END
  ;
}
