package ObjectHistory;

# Subroutines for tracking object history

use strict;
use lib '.';
use DB::History;
use XML::Simple;
use XML::RSS;
use Digest::MD5;
use Date::Calc qw/Delta_Days Add_Delta_YMD Date_to_Text Day_of_Week_to_Text Day_of_Week Month_to_Text/;
use Data::Dumper;
use vars qw/$updatedb $objects_rs $history_rs $md5/;

use constant UPDATEDB        => 'object_history';                # The history database
use constant DEBUG           => 0;
use constant BY_RELEASE_DATE => 1;
use constant RSS_ROOT        => '/usr/local/wormbase/website/legacy/html/rss';

#$updatedb = DB::History->connect('DBI:mysql:database='  .  UPDATEDB,'root','kentwashere')
#  or die "Couldn't connect to database";

# Define some resultsets
#$objects_rs = $updatedb->resultset('Objects');
#$history_rs = $updatedb->resultset('History');

$updatedb = '';

$md5 = Digest::MD5->new();

# The date the release hit the production server
# This should be stored somewhere else for easy updates
my %release2date = ( WS182 => '2007-10-17',
		     WS183 => '2007-11-12',
		     WS184 => '2007-12-02',
		     WS185 => '2007-12-23', 
		     WS186 => '2008-02-01',
		     WS187 => '2008-02-15',
		     WS188 => '2008-03-22',
		     WS189 => '2008-04-21',
		     WS190 => '2008-05-16',
		     WS191 => '2008-06-20',
		     WS192 => '2008-07-18',
		     WS193 => '2008-08-16',
		     WS194 => '2008-09-20',
		     WS195 => '2008-10-17',
		     WS196 => '2008-12-01',
		     WS197 => '2008-12-21',
		     WS198 => '2009-01-16',
	             WS199 => '2009-02-22',
		     WS200 => '2009-03-21',
		     WS201 => '2009-04-18',
		     WS202 => '2009-05-27',
		     WS203 => '2009-06-29',
		     WS204 => '2009-07-20',
		     WS205 => '2009-08-29',
		     WS206 => '2009-09-18',
		     WS207 => '2009-10-18',
		     WS208 => '2009-11-10',
		     WS209 => '2009-12-22',
		     WS210 => '2010-01-18',
 		    );

sub new {
  my ($class,$object,$version) = @_;
  my $this  = bless {},$class;
  $this->{ace_version} = $version;
  $this->{object}      = $object;
  return $this;
}
  
sub md5 {
  my $self = shift;
  return $self->{md5} if $self->{md5};
  $md5->new();
  my $seed = $self->seed();
  $md5->add($seed);
  my $signature = $md5->hexdigest;
  $self->{md5} = $signature;
  return $signature;
}


# DEPRECATED - not really using the md5 signatures any more
sub md5_has_changed { 
  my $self = shift;
  my $id = $self->objectid;
  my (@signatures) = $history_rs->search({oid => $id });
  print 'Histories are : ' . join('; ',@signatures) if DEBUG;  
  
  # TODO: Need to efficeintly fetch only the LAST / MOST RECENT signature
  my $previous_md5 = $signatures[-1];
  
  return 1 if !$previous_md5;  # i.e. we have never recorded an md5 for this guy.
  return 1 if $previous_md5 ne $self->md5;
  return 0;
}

# Insert an object (if it doesn't exist already) and its "history" into the database
sub store_history {
    my $self = shift;
    my $object = $self->object;
    my $class  = $object->class;
    
    # Store the current history for this object.
    # (since we arbitrarily set the initial modification date to 2007-01-01
    # the first history entry will have all changes dating back to 2007-01-01)
    if ($self->is_updated) {
	$history_rs->populate([{ oid         => $self->objectid,
				 version     => $self->version,
				 date        => $self->todays_date,
				 signature   => $self->md5,
				 notes       => $self->notes,
			     }]);
	
	print "WOW!  Found a new update via the timestamp parsing!\n" if DEBUG;
	
	# If an object has been updated, update its entry as well
	# with the modification date (today) and the ace version
	# Storing the modification date with the object is a 
	# denormalization for easy access.
	
	my $results = $objects_rs->search({oid   => $self->objectid });
	$results->update({last_modification_date => $self->todays_date,
			  ace_version            => $self->version });
	
	print "   WOW AGAIN! the note is: " .  $self->notes . "\n" if DEBUG;
    }
}

# Stash the object if we don't have it already
sub store_object {
  my $self = shift;
  my $object = $self->object;
  
  # When adding an object to the database,
  # arbitrarily set the initial modification
  # date to 2007-01-01.  This will make the first
  # history entry show all modifications from Jan-Nov 2007

  # The modification date will be updated during that first
  # iteration to the current date.
  my $modification_date = '2007-01-01';
  my ($result) = $objects_rs->populate([{ name      => $object,
					  class     => $object->class,
					  last_modification_date => $modification_date,
					  ace_version => $self->version,
					  signature => $self->md5 }]);
  my $id = $result->id;
  print "Just inserted a new object: $id\n" if DEBUG;
  return $id;
}


# Check for updates newer than object.last_modification_date
sub check_for_updates {
  my ($self,$how) = @_;
  
  # Short circuit. Does the last_modification_date version correspond
  # to the current version?  If so, we've already parsed the object
  # for possibly new timestamps.  Just return;

  # Putting this in place will block the very first entry from being
  # made when an object is first stored.
  #  my ($last_mod_date,$last_version) = $self->last_modification_date;
  #  return if ($self->version eq $last_version);

  # Parse the current XML representation for the object
  # and see if any timestamps are newer than the newest history entry
  if ($how eq 'parse_xml') {
    my $struct = XMLin($self->object->asXML());
    $self->_parse_structure($struct,1);

    # Parse the object itself via AcePerl
  } elsif ($how eq 'parse_object') {
      $self->_parse_object();
  } else {
      die "Please specify a method for identifying updates: parse_xml or parse_object...\n";
  }

  
#  $self->store_history();
}

sub get_recent_history {
  my ($self,$limit) = @_;

  my $id = $self->objectid;
  my @results = $history_rs->search(
				    { oid      => $id },				    
				    { order_by => 'date DESC',  
				      limit     => $limit }); 
  return \@results;
}


# Getter / accessor for updated items
sub notes {
  my ($self,$note) = @_;
  if ($note) {
    push @{$self->{notes}},$note;
    return;
  }
  
  # No note provided? We're trying to fetch them
  return join("<br>",@{$self->{notes}}) if defined $self->{notes};
}

sub version { return shift->{ace_version}; }

# The presence of notes means that the object has seen updates
sub is_updated {
  my $self = shift;
  return 1 if eval { @{$self->{notes}} > 0};
  return undef;
}

# Fetch the most recent time this object was updated.
# This is stored for convenience in the object table.
sub last_modification_date {
  my $self = shift;
  return ($self->{last_modification_date},$self->{ace_version}) 
    if $self->{last_modification_date};

  # Get the *last* history date
  my ($results) = $objects_rs->search({oid => $self->objectid});
  my $previous_date = $results->last_modification_date;
  $self->{last_modification_date} = $previous_date;
  my $last_version = $results->ace_version;
  $self->{last_modification_version} = $last_version;
  return ($previous_date,$last_version);
}

sub todays_date {
  my $self = shift;
  return $self->{todays_date} if $self->{todays_date};
  my $date = `date +%Y-%m-%d`;
  chomp $date;
  $self->{todays_date} = $date;
  return $date;
}

sub compare_timestamps {
  my ($self,$date) = @_;
  # Is this item newer than the last recorded entry?

  my ($ts_year,$ts_month,$ts_day) = $date =~ /(\d\d\d\d)-(\d\d)-(\d\d).*/;

  my ($last_year,$last_month,$last_day);
  if (BY_RELEASE_DATE) {
      
# New approach
# The last modification date is the date of the last release
# I need to store these somewhere
      # This should be dates{version - 1}
      # Or arbitraily something SIX weeks before the present (for the dev cycle, too)
#  my $last_modification_date = '2007-01-01';
#      my $today = $self->todays_date;
      # Today should be the PRODUCTION RELEASE DATE of the DB
      my $today = $self->release2date || $self->todays_date;
      my ($now_year,$now_month,$now_day) = split("-",$today);
      ($last_year,$last_month,$last_day) = Add_Delta_YMD($now_year,$now_month,$now_day,0,0,-42);
  } else {

# Original approach
      my ($last_modification_date,$last_version) = $self->last_modification_date;
      ($last_year,$last_month,$last_day) = split("-",$last_modification_date);
  }
  
  if (DEBUG) {
      print "last modification date: $last_year $last_month $last_day\n";
      print "current timestamp     : $ts_year $ts_month $ts_day\n";
      print "raw timestamp         : $date\n";
  }
  
  # Kludge for broken timestamps
  if ($ts_year && $ts_month && $ts_day) {
      my ($dd) = Delta_Days($last_year,$last_month,$last_day,$ts_year,$ts_month,$ts_day);
      
      print "DELTA DAYS: $dd\n" if DEBUG;
      return $dd;
  } else {
      # Should this be 0 (false) or something less than one?
      return 0;
  } 
}

sub _parse_structure {
  my ($self,$struct,$main) = @_;
  my $main   ||= 0;
  my $item;
  if (ref $struct eq "ARRAY") {
    for $item (sort @$struct) {
      $self->_parse_structure($item);
    }
  } elsif (ref $struct eq "HASH") {

    # Does this hash contain a timestamp?
    if (my $date = $struct->{timestamp}) {
      my $dd = $self->compare_timestamps($date);
      
      # Aha! Found a timestamp newer than the last mod date
      # Save all the siblings as a note for the update
      if ($dd > 0) {
	my @notes;
	for $item (sort keys %$struct) {
	  push @notes,"$item : $struct->{$item}";
	}
	$self->notes(join("; ",@notes));
      }
    }
    
    for $item (sort keys %$struct) {
      #      print $item," " if $main;
      $self->_parse_structure($struct->{$item});
      #      print $ret;
    }
  } else {
    #    print $struct,$ret;
  }
}

# Instead of relying on an XML dump, try generically parsing
# objects using AcePerl
sub _parse_object {
  my $self   = shift;
  my $object = $self->object; 
  my @tags = $object->tags;
  foreach my $tag (@tags) {
    my @subtags = eval { $object->at($tag)->col };
    foreach my $subtag (@subtags) {
      $self->_parse_subtags($tag,$subtag);
    }
  }
}

sub _parse_subtags {
  my ($self,$tag,$subtag) = @_;
  if ($subtag->class eq 'tag') {
      my @data = $subtag->col;
      foreach my $data (@data) {
	  my $ts = $data->timestamp;
	  my $dd = $self->compare_timestamps($ts);
	  
	  print "$tag $subtag $data $dd $ts\n" if DEBUG;
	  my $class = $data->class;
	  
	  # Aha! Found a timestamp newer than the last mod date
	  # Save all the siblings as a note for the update
	  if ($dd > 0) {
	      my $link;
	      if ($data->class eq 'tag') {
		  my $entry = $data->right;
		  if ($entry) {
		      my $entry_class = eval { $entry->class };
		      $link = "$data > ";
		      $link .= ($entry_class eq 'Text')
			  ? $entry
			  : qq{<a href="http://www.wormbase.org/db/get?name=$entry;class=$entry_class">$entry</a>};
		  }
	      } else {
		  $link = qq{<a href="http://www.wormbase.org/db/get?name=$data;class=$class">$data</a>};
	      }
	      $self->notes("$tag > $subtag > $link ($ts)");
	  }
      }
  } else {      
      my $ts    = $subtag->timestamp;
      my $dd    = $self->compare_timestamps($ts);            
      my $class = $subtag->class;
      
      # Aha! Found a timestamp newer than the last mod date
      # Save all the siblings as a note for the update
      if ($dd > 0) {
	  my $link = qq{<a href="http://www.wormbase.org/db/get?name=$subtag;class=$class">$subtag</a>};
	  $self->notes("$tag > $link ($ts)");
      }
  }
}

sub object { return shift->{object}; }

sub objectid {
  my $self = shift;
  return $self->{objectid} if $self->{objectid};
  my $name = $self->object;
  my ($results) = $objects_rs->search( { name => $name } );
  if ($results) {
    print "objectid: " . $results->oid . "\n" if DEBUG;
    $self->{objectid} = $results->oid;
    return $self->{objectid};
  }
  return undef;
}

# What should be used to create the md5?
sub seed {
  my $self = shift;
  my $object = $self->object;
  #my $seed = $object->asGIF();
  my $seed = $object->asXML(); 
  return $seed;
}



# Used to set up the last modifcation date ( - 6 weeks)
# The releasedate will also be used as the PubDate for the feedre
sub release2date {
    my $self = shift;
    my $version = $self->version;
    return $release2date{$version};
}

sub build_static_feed {
    my $self = shift;
    	
    $self->check_for_updates('parse_object');

    my $object = $self->object;
    my $class  = $object->class;
    
    # pubDate must be static as long as there are no new items
    my $date = $self->todays_date;
    #my $date = $self->release2date; 
    my ($y,$m,$d) = split('-',$date);

    my $pub_date = sprintf("%.3s, %02d %.3s %d 00:00:01 GMT",
			   Day_of_Week_to_Text(Day_of_Week($y,$m,$d)),$d,Month_to_Text($m),$y);
    
    # Last build date is the time the content was last updated.
    my ($ty,$tm,$td) = split('-',$self->release2date);
    my $last_build_date = sprintf("%.3s, %02d %.3s %d 00:00:01 GMT",
			   Day_of_Week_to_Text(Day_of_Week($ty,$tm,$td)),$td,Month_to_Text($tm),$ty);
#    $last_build_date = $pub_date;

    my $year = `date +%Y`;
    chomp $year;

    my %class2name = ( Gene      => \&gene_name,
		       Phenotype => \&phenotype_name,);
    
    my $coderef = $class2name{$class};
    my $name = ($coderef) ? $self->$coderef($object) : $object;
    my $permalink = "http://www.wormbase.org/db/get?name=$object;class=$class";
    my $rss = new XML::RSS (version => '2.0');
    $rss->channel(title          => "WormBase Updates: $class:$name",
		  link           => $permalink,
		  language       => 'en',
		  description    => "WormBase RSS feed for $class:$name",
		  copyright      => "Copyright 2000-$year The WormBase Consortium",
		  pubDate        => $pub_date,
		  lastBuildDate  => $last_build_date,
		  managingEditor => 'harris@cshl.edu',
		  webMaster      => 'harris@cshl.edu');
    
    my $path   = RSS_ROOT . "/$class";
    system("mkdir -p $path") unless (-e $path);
    
    my $file = "$path/$object.rss";
	 
    # If the file already exists, swap items in/out	
    if (-e $file) {
	$rss->parsefile("$file");
	pop(@{$rss->{items}}) if (@{$rss->{items}} == 3);
    }
    $rss->add_item(title       => "Changes to $class:$name in " . $self->version . ' (' . $self->release2date . ')',
		   description => $self->notes,
		   permalink   => $permalink,
		   pubDate     => $last_build_date,
		   );
    $rss->save($file);
}


sub gene_name {
    my ($self,$gene) = @_;
    my $name = $gene->Public_name ||
	$gene->CGC_name || $gene->Molecular_name || eval { $gene->Corresponding_CDS->Corresponding_protein } || $gene;
    return $name;
}

sub phenotype_name {
    my ($self,$phenotype) = @_;
    my $name = ($phenotype =~ /WBPheno.*/) ? $phenotype->Primary_name : $phenotype;
    $name =~ s/_/ /g;
    $name .= ' (' . $phenotype->Short_name . ')' if $phenotype->Short_name;
    return $name;
}


1;
