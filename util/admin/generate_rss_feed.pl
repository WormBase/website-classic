#!/usr/bin/perl

=pod

=head1 generate_rss_feed.pl

=head2 DESCRIPTION

This script, intended to be run under cron, automatically maintains
the RSS feed for the WormBase sites.  It does this in one of two ways:
by parsing the index.html file for new items, or by reading a simple
plain text file for new entries.

The script accepts two positional arguments, one for specifying the
live versus development server, and a second parameter to specify the
source format of the entries.

The following commands will generate the news feeds on the development
and live servers respectively:

   $ ./generate_news_feed.pl development xml
   $ ./generate_news_feed.pl live xml

=head2 The news-entries.xml (or .txt) file

The preferred method to generate the news feed is to parse the
news_feed-entries.xml file rather than relying on parsing of the index.html
file.

    news_feed-entries.xml is located at:

    /usr/local/wormbase/conf/news-entries.xml

Documentation for formatting entries is contained in that file.

This approach lets us maintain a plain text running log of news-worthy
events on both the live and development server. It also lets us add
items to the feed on the live site that may not necessarily be
news-worthy enough for the index page.

=head2 Optionally parsing the index.html file (not recommended)

Passing a second true argument to the script will force it to try to
fetch new entries from the index.html file.  This is not
recommended. This option is only relevant for the live site.

  $ generate_rss_feed.pl live index

=cut

use strict;
use XML::RSS;
use Time::ParseDate;
use Date::Format;  # For converting stringified dates to RFC822

use constant ENTRIES_TEXT  => '/usr/local/wormbase/conf/news-entries.txt';
use constant ENTRIES_XML   => '/usr/local/wormbase/conf/news-entries.xml';

use constant INDEX      => '/usr/local/wormbase/html/index.html';
use constant LIVE_IMAGE => '/images/logo_small.jpg';
use constant DEV_IMAGE  => '/images/logo_dev.jpg';
use constant RSS        => '/usr/local/wormbase/html/news.rss';

# Flag to control parsing from the library
my $site = shift;
my $file = shift;


my $rss = new XML::RSS(version => '0.91');
#my $rss = new XML::RSS(version => '1.0');
my $time_template = '%a, %d %b %Y %T %Z';   # RFC 822 compliant time format

# Parse the current index.html file
my $items;
if ($file eq 'xml') {
  $items = parse_xml();
} elsif ($file eq 'txt') {
  $items = parse_text();
} else {
  $items = parse_index();
}

# Parse the existing RSS file so we can add new items reliably
# No longer necessary
#if (-e RSS) {
#  system('cp',RSS,RSS . '.old');
#  $rss->parsefile(RSS . '.old');
#}

# Add the primary channel
development_channel() if $site eq 'development';
live_channel()        if $site eq 'live';

# Compare potentially new items to current items
# my %current = map { $_->{title} => 1 } eval { @{$rss->{'items'}} };
foreach my $h (@{$items}) {
  my $title = $h->{title};
  my $date  = $h->{date};
  my $desc  = $h->{desc};
  my $link  = $h->{link};
  $link ||= $site eq 'live' ? 'http://www.wormbase.org/' : 'http://dev.wormbase.org/';

# Unnecessary, really.
#  # Does this item already exist on the RSS?
#  if (defined $current{$title}) {
#    warn "Item already listed in RSS! ($title)";
#    next;
#  }
#
#  # New item. Less than 15 items?  Go ahead and add it.
#  my $temp = pop(@{$rss->{'items'}}) if (@{$rss->{'items'}} == 15);

  $rss->add_item(title       => $title,
		 link        => $link,
		 description => $desc,
		 pubDate     => $date,
		 dc => {
			date     => $date,
			subject  => $site eq 'live' ? 'WormBase News' : 'WormBase Development Server News',
			creator  => 'Todd Harris (harris@cshl.org)',
		       },
		);
}

# output the RSS 0.9 or 0.91 file as RSS 1.0
open OUT,">" . RSS;
print OUT $rss->as_string;
close OUT;
system("rm -f " . RSS . '.old');




##############################
#       Begin Subs
##############################

##############################
# THIS IS NOW DEPRECATED IN FAVOR OF A PSEUDO-XML STYLED FILE
# Parse out items from the news_feed.txt file (preferable)
sub parse_file {
  my $items = [];
  open IN,ENTRIES_TEXT or die "Couldn't open the news feed items page: $!\n";
  my $items = [];
  $/ = "=\n";
  while (<IN>) {
    next if /^\#/;
    next if /^\=/; # Ignore the record seperator
    my @lines = split("\n");
    my %data;
    foreach (@lines) {
      my ($cat,@entry) = split("=",$_);
      my $entry = join('=',@entry);  # ugh
      $data{$cat} = $entry;
    }
    push (@{$items},{ title  => $data{TITLE},
		      link   => $data{LINK},
		      desc   => $data{DESC},
		      date   => $data{DATE} });
  }
  return $items;
}



# Try parsing out news items from the index.html file
sub parse_index {
  my $items = [];
  open IN,INDEX or die "Couldn't open the index page: $!\n";
  # Slurp up the news section
  $/ = '<!-- Begin News -->';
  while (<IN>) {
    next unless (/<li><b>/);  # skip the first block (everything preceeding the news)
    my @items = split("<!-- news item -->");
    foreach my $item (@items) {

      # There may be blank spaces before the news begins
      next unless ($item =~ /<\/b><br>/); # These are true news items

      # Skip everything after the end of the news
      next if $item =~ /<\!--\sEnd\sNews\s-->/;

      my @lines = split("\n",$item);
      shift @lines;  # Ending up with an empty entry line
      my $temp_title = shift @lines;

      # Parse out the date
      $temp_title =~ /<li><b>(\w+\s\d{1,2},\s\d{4}):\s(.*)<\/b><br>/;
      my $date  = $1;
      my $title = $2;

      # Join the lines together to create the description
      my $description;
      foreach my $line (@lines) {
	# remove leading whitespace
	$line =~ s/^\s*//g;
	$description .= " $line";
      }
      $description .= " [posted: $date]" if $date;

      push (@{$items},{ title => $title,
			desc  => $description,
			date  => $date });
    }
  }
  return $items;
}

# Parse a news_feed.txt file that is maintained in basic xml
sub parse_xml {
  $/ = '<item>';
  open IN,ENTRIES_XML;

  my @blocks;
  while (my $item = <IN>) {
    # The first entry will necessarily be empty
    next if $item =~ /BEGIN\sRSS\sENTRIES/;
    push(@blocks,$item);
  }

  my $c;
  # Read the blocks backwards
  foreach my $item (reverse @blocks) {
    $c++;
    my ($title) = ($item =~ /<title>(.*)<\/title>/s);
    my ($desc)  = ($item =~ /<description>(.*)<\/description>/s);
    my ($link)  = ($item =~ /<link>(.*)<\/link>/s);
    my ($date)  = ($item =~ /<date>(.*)<\/date>/s);
    my ($posted_by)  = ($item =~ /<posted_by>(.*)<\/posted_by>/s);

    # Translate the date into one that is properly formatted
    # This will no longer be necessary if people use the form submit
    #    $date =~ /(\d{1,2})\s(\w*)\s(\d{4})/;
    # my ($day,$month,$year) = ($1,$2,$3);
    # my $unformatted = "$year-$month-$day 00:00:00";
    # my $fmtime = time2str($time_template,parsedate($unformatted));

    $desc .= " [posted: $date by $posted_by]" if $date && $posted_by;
    $desc .= " [posted: $date]" if $date && !$posted_by;
    push (@{$items},{ title => $title,
		      link  => $link,
		      desc  => $desc,
		      date  => $date,
		      posted_by => $posted_by,
		    });

    last if $c == 25;  # Only need to parse 15 items (first being empty)
  }
  return $items;
}



sub development_channel {
  my $date = get_time_string();
  $rss->channel(title        => "WormBase Development Server",
		link         => "http://dev.wormbase.org/",
		description  => "Previewing new features and datasets for WormBase",
		stylesheet   => {type=>'text/css',href=>'http://dev.wormbase.org/stylesheets/news.css'},
		dc => {
		       date       => $date,
		       subject    => "The genome and biology of C. elegans",
		       creator    => 'harris@cshl.org',
		       publisher  => 'wormbase-help@wormbase.org',
		       rights     => 'Copyright 2004, The WormBase Consortium',
		       language   => 'en-us',
		      },
		syn => {
			updatePeriod     => "hourly",
			updateFrequency  => "1",
			updateBase       => "1901-01-01T00:00+00:00",
		       },
	       );

  $rss->image(
	      title  => "WormBase Development Server",
	      url    => "http://dev.wormbase.org" . DEV_IMAGE,
	      link   => "http://dev.wormbase.org/",
	      dc => {
		     creator  => "T. Boutell, T. Harris",
		    },
	     );
}


sub live_channel {
  my $date = get_time_string();
  $rss->channel(title        => "WormBase",
		link         => "http://www.wormbase.org/",
		description  => "The database of C. elegans and related nematodes",
		dc => {
		       date       => $date,
		       subject    => "The genome and biology of C. elegans",
		       creator    => 'harris@cshl.org',
		       publisher  => 'wormbase-help@wormbase.org',
		       rights     => 'Copyright 2004, The WormBase Consortium',
		       language   => 'en-us',
		      },
		syn => {
			updatePeriod     => "hourly",
			updateFrequency  => "1",
			updateBase       => "1901-01-01T00:00+00:00",
		       },
	       );

  $rss->image(
	      title  => "WormBase",
	      url    => "http://www.wormbase.org" . LIVE_IMAGE,
	      link   => "http://www.wormbase.org/",
	      dc => {
		     creator  => "T. Boutell, T. Harris",
		    },
	     );
}

sub get_time_string {
  my $time = localtime();
  my $fmtime = time2str($time_template,parsedate($time));
  return $fmtime;
}
