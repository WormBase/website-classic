# -*- Mode: perl -*-
# $Id: ElegansSubs.pm,v 1.25 2011-01-26 17:27:34 tharris Exp $
# file: ElegansSubs.pm
# C. elegans browsing subroutines for use at Sanger & Montpellier

package ElegansSubs;
use strict 'vars';

use CGI qw(:standard *table *Tr *TR *td -no_xhtml center *center escape *div *iframe);
use CGI::Cache;
use CGI::Carp;
use Carp 'croak','cluck';
use Ace::Browser::AceSubs qw(AceHeader Style Url
			     Object2URL ObjectLink Configuration ResolveUrl
			     DB_Name AceMultipleChoices OpenDatabase
			     AceRedirect 
			    );
use Bio::DB::GFF;
use Ace::Browser::SearchSubs qw(AceSearchTable);
#use Ace::Browser::GeneSubs qw[NCBI PROTEOME PUBMED];
#use Ace::Browser::GeneSubs qw[PROTEOME];
use Digest::MD5 'md5_hex';
use File::Path 'mkpath';
use DBI;   # TEMPORARILY REQUIRED
use Date::Calc qw/Delta_Days Today_and_Now/;
use lib '.';
use WormBase::Util::Rearrange;
use WormBase::Autocomplete;

#my $WORMBASE_CACHE   = Configuration()->Wormbase . "/cache" if Configuration();
my $WORMBASE_CACHE = Configuration()->Cache if Configuration();
my $CACHE_SIZE     = Configuration()->Cache_size if Configuration();
$CACHE_SIZE ||= '100_000_000';
#use constant WORMBASE_PATH  => '/usr/local/wormbase';
#use constant WORMBASE_CACHE => WORMBASE_PATH . "/cache";

use vars qw/@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
  %DBGFF %BRIGGFF %GFFDB
    %PMAPGFF %GMAPGFF $SECTION $ROWS_PRINTED
    $PAGE_OPEN %GENE_SEARCH @RELEASE_DATES/;

require Exporter;
@ISA = Exporter;

@EXPORT = qw( OpenPageGetObject ClosePage
	      PrintTop PrintBottom PrintWarning DisplayInstructions PrintOne PrintMultiple AceError
	      OpenDBGFF OpenBrigGFF
	      OpenPmapGFF OpenGmapGFF HunterUrl AceImage
	      OpenGFFDB
	      StartDataTable EndDataTable StartSection EndSection SubSection StartCache
	      Tableize  MultipleChoices ObjectDisplay AppendImagePath GenerateWikiLink
	      best_phenotype_name
	      ParseHash
	      get_species
		  InlineImage
              get_PMID
	    );
@EXPORT_OK = qw(GetInterpolatedPosition PrintRefs
		FindPosition PrintExpressionPattern PrintRNAiPattern PrintExpressionMap
		GenBankLink TypeSelector Banner Header Footer
		DisplayInstructions OverlappingGenes PrintLongDescription
		CGC SEQUENCE_INFO GENE_INFO ABSTRACT_INFO ALLELE_INFO
		STRAIN_INFO MAP_REPORT MAP_DISPLAY SEQ_DISPLAY
                GetEvidence GetEvidenceNew PrintMicroarray overlapping_microarray MicroarrayPapers
		AddCommas
		GBrowseLink Best_BLAST_Table OverlappingPCR OverlappingOST OverlappingSAGE
		AlleleDescription MutantPhenotype StartCache EndCache ClearCache
		FetchGene Bestname generate_reactome_table FetchPeople DisplayMoreLink
		LinkToGlossary format_reference format_references ID2Species Species2URL
		AppendImagePath
		is_new
		days_since_update
		FetchCell
		filter_references
		filter_and_display_references
		GenerateWormBookLinks
		build_citation
		DisplayPhenotypes
		DisplayPhenotypeNots
		is_NOT_phene
		parse_year
		DisplayGeneOntologySearch
		autocomplete_field
		autocomplete_end
		FetchAnatomyTerm
		FetchObject
		inline_evidence
	    display_reactome_data
	    display_nemapath_data
	    FormatPhenotypeHash
            get_PMID
	);
%EXPORT_TAGS = ('biblio'  => [qw(CGC ABSTRACT_INFO PrintRefs)],
		'sequence'=> [qw(GetInterpolatedPosition PrintExpressionPattern
				 SEQUENCE_INFO SEQ_DISPLAY)],
		'locus'   => [qw(GENE_INFO ALLELE_INFO MAP_REPORT MAP_DISPLAY STRAIN_INFO AlleleDescription
				MutantPhenotype)]
		 );

# A list of release dates used to determine if something is "new".
# This is easier and faster than maintaining two database handles
# which might not be possible on systems with limited disk space.
# Perhaps this is best stored as a text file?
# The zeroth element should be the current live release,
# 1st the last live release.
# In the format DDMMYYYY
# Really on the zeroth element is ever used to determine the last release date
@RELEASE_DATES = (
		  { date => '03062006' , release => 'WS154'},
		  { date => '02102006' , release => 'WS153'},
		  );
 
# custom constants
use constant GENE_INFO       => 'gene';
use constant SEQUENCE_INFO   => 'sequence';
use constant ABSTRACT_INFO   => 'biblio';

# constants holding generic browsing URLS
use constant ALLELE_INFO     => 'tree?class=Allele';
use constant STRAIN_INFO     => 'tree?class=Strain';
use constant MAP_REPORT      => 'nearby_genes';
use constant MAP_DISPLAY     => 'pic?class=Locus';
use constant SEQ_DISPLAY     => 'sequence';

sub OpenPageGetObject {
  my $classes           = shift;
  my $alternative_title = shift;
  my $suppress_prompt   = shift;
  my $suppress_not_found = shift;
  my $classtofetch = param('class');
  my $class = !ref($classes)           ? $classes
             : ref $classes eq 'ARRAY' ? $classes->[0]
             : ref $classes eq 'HASH'  ? (keys(%$classes))[0]
	     : die "$classes is neither an array nor a hash";
  my $classname = ref $classes eq 'HASH' ? $classes->{$class} : $class;

  my $db = OpenDatabase();
  my $name  = param('name');
  $classtofetch ||= $class;

  my @objs =$db->fetch($classtofetch => $name) if $name;
  my $obj;

  if (@objs > 1 && !wantarray) {
    MultipleChoices(\@objs);
    return;
  }

  elsif (@objs == 1) {
    $obj = $objs[0];
    PrintTop($obj,$obj->class,"$alternative_title:$obj" || "$classname Display Page");
  }

  elsif ($name && !$suppress_not_found) {
    PrintTop("$name not found");
    PrintWarning(param('name'),$classname);
  }

  else {
      PrintTop($obj);
  }
  if (ref $classes && ref $classes eq 'ARRAY') {
    $classes = popup_menu(-name=>'class',-values=>$classes);
  }
  if (ref $classes && ref $classes eq 'HASH') {
    if (keys %$classes > 1) {
      $classes = popup_menu(-name=>'class',-values=>$classes);
    } else {
      $classes = $classname;
    }
  }
  unless ($suppress_prompt) {
    print
      start_form(-method => 'GET'),
	"Search for a $classes: ",
	  textfield(-name=>'name'),
	    end_form();
  }
  return wantarray ? @objs : $obj;
}

sub ClosePage {
  PrintBottom() ;
}

# boilerplate for the top of the page
sub PrintTop {
  my ($object,$class,$title,@additional_header_stuff) = @_;

  undef $SECTION;
  undef $ROWS_PRINTED;
  return if $Ace::Browser::AceSubs::TOP++;
  $title ||= $object unless ref $object;
  $class = $object->class if defined $object && ref($object);
  AceHeader();
  $title = defined($object) ? "$class Report for: $object" : $class ? "$class Report" : '' unless defined $title;
  
  # This SHOULD be absolute
  my $rss = qq(<link rel="alternate" type="application/rss+xml" title="RSS 2.0" href="/db/rss?name=$object;class=$class" />) if $object;
#  my $rss = qw|<link rel="alternate" type="application/rss+xml" title="RSS 2.0" href="/rss/$class/$object.rss" />| if defined $object;


  my $wormbase_js  = q(<script type="text/javascript" src="/js/wormbase.js"></script>);
  # This still needs some cleaning up, but custom JS libraries, etc loading can 
  # be controlled via @additional_header_stuff 
  print start_html (
		    '-Title'   => $title,
		    '-head'    => toggle_style() . $rss . $wormbase_js,
		    @additional_header_stuff,
		    );
  print Banner();
  print TypeSelector($object,$class) if defined $object && ref $object;
  print ElegansSubs::Header();
  print h1($title) if $title;
  $PAGE_OPEN++;
}

# boilerplate for the bottom of the page
sub PrintBottom {
  return unless $PAGE_OPEN;
  print p(),hr() if CGI->url(-absolute=>1) =~ /searches/;
  # ElegansSearchBar(); # unless CGI->url(-absolute=>1) =~ /searches/;
  print hr;

##  # Conditionally print the suggestion box.  Doesn't exist on the front page, etc
##  # This should be more broadly configurable in the update.
##  #  if (param('name')) {
##  #    SuggestionBox();
##  #    print hr;
##  #  }

  print ElegansSubs::Footer();
  if (0) {
    print table({-width=>'100%'},
		TR(
		   td({-class=>'small',-align=>'center'},a({-href=>"/db/misc/notifscript"},
							   'Notify me when this page changes'))
		  )
	       ) if param('name') && param('class');
  }
  undef $PAGE_OPEN;
}


## NOT CURRENTLY IN USE, BUT ALREADY MIGRATED.
## By Jove, I am going to use this!
##
## Amazon uses an iFrame for the suggestion box
## along with a javascript for automatic responses
##sub SuggestionBox {
##  my $url = url();
##  return if ($url =~ /etree|model/);
##  my @values  = qw/general_comment annotations_incorrect annotations_incomplete speed bug requested_feature/;
##  my %labels = (general_comment      => 'General comment',
##		annotations_incorrect => 'Annotations are incorrect',
##		annotations_incomplete => 'Annotations are incomplete',
##		speed        => 'The page takes too long to load',
##		bug          => 'The page has a software bug in it',
##		requested_feature => 'Request for a new feature');
##
##  print div({-class=>'feedback'},
##	    h2('Suggestion Box'),
##	    start_form({-action=>'/db/misc/submit_feedback'}),
##	    "We greatly value your feedback.  If you have found
##	    something incorrect, broken, or frustrating on this page,
##	    let us know so that we can improve the quality of
##	    annotation and the ease with which it is available.",
##
##	    br,br,
##	    b('Comments, questions, or feedback:'),
##	    div({-class=>'indent'},
##		table({-border=>0},
##		      TR(td({-colspan=>3},
##			    span({-class=>'smalldescription'},
##				 'Supplying your contact information
##				 is optional.  Doing so will enable us
##				 to contact you for further details
##				 and to let you know when your
##				 suggestions have been addressed.'))),
##		      TR(td({-rowspan=>4},
##			    textarea({-name=>'comments',-rows=>'7',-cols=>'60',-maxlength=>'10',-style=>'width:95%'})),
##			 td('Category' . i('(optional)') . ': '),
##			 td(popup_menu({-name=>'suggestions',
##					-values=>\@values,
##					-labels=>\%labels}))),
##		      TR(td('Submitted by:'),td(textfield({-name=>'submitted_by',-size=>'50'}))),
##		      TR(td('Institution:'),td(textfield({-name=>'institution',-size=>'50'}))),
##		      TR(td('Email Address:'),td(textfield({-name=>'submitted_email',-size=>'50'}))),
##		      TR(td({-colspan=>2},'&nbsp;'),td({align=>'right'},
##						       submit({-name=>'Submit Comments'}),reset(-name=>'Clear Form'))))),
##	    end_form());
##}

sub days_since_update {
    my ($tag,$want_string) = @_;
    return unless $tag;
    my ($curr_year,$curr_month,$curr_day,@rest) = Today_and_Now();
    my $stamp = $tag->timestamp();
    return undef unless $stamp;
    
    # Is the time stamp OLDER than the last release?
    my ($year,$month,$day) = $stamp =~ /(\d\d\d\d)\-(\d\d)\-(\d\d)_.*/;
    # The difference in days between the two values.
    # This will be negative if the two dates are not in chronological order
    my $dd = Delta_Days($year,$month,$day,$curr_year,$curr_month,$curr_day);
    
    if ($want_string) {
	# Check and see if this is also new since the last release
	my $is_new = _check_if_new($year,$month,$day);
	return _new_string($dd,$is_new);
    } else {
	return 1;
    }
}


# Is a provided time stamp newer than the LAST live release?
# Return boolean true if so.
sub is_new {
    my ($tag,$want_string) = @_;
    my $stamp = $tag->timestamp();
    return undef unless $stamp;
    
    # Is the time stamp OLDER than the last release?
    my ($year,$month,$day) = $stamp =~ /(\d\d\d\d)\-(\d\d)\-(\d\d)_.*/;
    my $is_new = _check_if_new($year,$month,$day);
    return undef unless $is_new;
    if ($want_string) {
	# sort of redundant use of variable here for sake of simplicity
	# in generating a return string.
	return _new_string($is_new,$is_new);
    } else {
	return 1;
    }
}


# Compare a split timestamp to the last release to determine if it is new
# returning the number of days since update if true
sub _check_if_new {
    my ($year,$month,$day) = @_;
    
    my $last = $RELEASE_DATES[1];
    my ($release)   = $last->{release};
    my ($old_date)  = $last->{date};
    my ($old_day,$old_month,$old_year) = $old_date =~ /(\d\d)(\d\d)(\d\d\d\d)/;
    
    # The difference in days, hours, minutes, and seconds between the two values.
    # All four values will be negative if the timestamp occured BEFORE the last release (ie is not new)
    my $dd = Delta_Days($old_year,$old_month,$old_day,$year,$month,$day);
    return undef if $dd < 0;
    return $dd;
}



sub _new_string {
    my ($dd,$is_new) = @_;
    if ($is_new) {
	return b("recently updated");
    } else {
	return "last updated $dd days ago";
    }
}


sub ObjectDisplay {
  my ($display,$object,$link_text) = @_;
  return unless defined $object;
  my $name  = CGI::escape($object->name);
  my $class = CGI::escape($object->class);
  my $args  = "name=$name;class=$class";
  my $url   = Url($display=>$args);
  $link_text = $object->name unless defined $link_text;
  return a({-href=>$url},CGI::escapeHTML($link_text));
}

sub search_table {
  my $suppress_boxes = shift;
  my $classlist = Configuration->Simple;
  my @classlist = @{$classlist}[map {2*$_} (0..@$classlist/2-1)];  # keep keys, preserving the order
  CGI::autoEscape(0);
  my $table =
    table(TR(
	     td('Search for:',
		popup_menu(-name=>'class',
			   -Values=>\@classlist,
			   -Labels=>{@$classlist},
			   -default=>'Any'),
		textfield(-name=>'query',-size=>30)),
	     td(submit(-name=>'Search'))
	    ),
	  $suppress_boxes ? () :
	  (
	   TR(td('&nbsp;'),
	      td(checkbox(-name=>'Long',-label=>'Detailed search')),
	      td(checkbox(-name=>'exact',-label=>'Exact match')))
	   )
	 );
  CGI::autoEscape(1);
  return $table;
}

sub ElegansSearchBar {
  return;  # don't do this any more
  print hr();
  AceSearchTable({-action => '/db/searches/basic'},
		 'Search WormBase',
		 table({-border=>0,-cellpadding=>0,-cellspacing=>0},
		       TR(
			  td(
			     search_table()
			    ),
			  th({-align=>"LEFT",-rowspan=>2,-class=>"searchtitle"},
			     a({-href=>"/downloads.html"},'Downloads & Summaries'),br(),
			     a({-href=>"http://athena.caltech.edu/~wen/userguide/index.html"},"User's Guide"),br(),
			     a({-href=>"/mailarch"},'Mailing Lists'),br(),
			     a({-href=>"/db/curate/base"},'Submit Data'),br(),
			     a({-href=>"/about/about_Celegans.html"},'About',i('C. elegans')),br(),
			     a({-href=>"/about/about_WormBase.html"},'About WormBase'),br(),
			    )
			 ),
		       TR(
			  th({-align=>'LEFT'},'Wormbase Mirror Sites:',
			  '[',
			  a({-href=>"http://www.wormbase.org/"},'CSHL (NY, USA)'),
			  '|',
			  a({-href=>"http://caltech.wormbase.org"},'Caltech (CA, USA)'),
			  '|',
			  a({-href=>"http://dev.wormbase.org"},'Development Site'),
			  ']'
			    )
			 )
		      )
		);
}

sub AceError {
    my $msg = shift;
    print CGI::font({-color=>'red'},$msg);
    PrintBottom();
    Apache->exit(0) if defined &Apache::exit;
    exit(0);
}

sub PrintWarning {
  my ($name,$class) = @_;
  print p(font({-color => 'red'},
	       "The $class named \"$name\" is not found in the database."));
}

# Where to find the NCBI/Genbank pages
sub GenBankLink {
  my $text = shift;
  # my $NCBI = Configuration->NCBI
  $text =~ s!([PN])ID:\s?[gG]?(\d+)
            !CGI::a({-href=>Configuration->Ncbi . "?db=\L$1\E&form=1&field=Sequence+ID&term=$2"},$&)
	    !xeg;
  $text;
}

## DEPRECATED
##sub GKLink {
##  my ($name,$id) = (shift,shift);
##  my $text = sprintf( GK_URL, $id, $name );
##  return $text;	
##}

# Generate a table of links to NemaPath EC portal

sub display_nemapath_data {
  my $GENE=shift;
  my ($Nema)= grep{$_ eq 'NemaPath' } $GENE->Database;
  return unless(defined $Nema); 
  my $url = $Nema->URL_constructor;
 # $url =~ s/\%s$//;
  my @ECs = map {  a({-href=>sprintf($url,$_)}, $_ ) } $Nema->right->col;
  return @ECs;

}
# Generate a table of links to Reactome from a list of proteins
sub generate_reactome_table {
  my @proteins = @_;
  my (@rows);
  foreach my $protein (@proteins) {
    my @db_entry = $protein->at('DB_info.Database');
    my ($reactome_name,$reactome_id);
    
    foreach (@db_entry) {
      next unless $_ eq 'Reactome';
      my @fields = $_->row;
      my $reactome_id = $fields[2];
      push @rows,a({-href=>sprintf($fields[0]->URL_constructor,$reactome_id)},$reactome_id);
  }
}
  return @rows;
  
    # I don't believe that this has actually been functional since circa 2004...
    # We don't have the actual human protein IDs in the database anymore...
    # Are we processing one or multiple proteins?  This is used by the protein page
    # add valid name/ID combination
#    if (@proteins == 1) {
#      push(@rows,TR(th({-class=>'datatitle',-colspan=>2},'Human Protein Matches from Genome KnowledgeBase')));
#      push(@rows,TR({-class=>'databody'},
#		    td({-align=>'LEFT'},
#		       'This protein is similar to ' 
#		       . sprintf(Configuration->Reactome,$reactome_id,$reactome_name) 
#		       . ' in the Reactome KnowledgeBase.')));
#    } else {
#      push @rows,TR(td({-align=>'LEFT', -class=>'databody'}, 
#		       'Protein ' . $protein 
#		       . ' is similar to ' 
#		       . sprintf(Configuration->Reactome,$reactome_id,$reactome_name) 
#		       . ' in the Reactome KnowledgeBase.'
#		      )) if ($reactome_name && $reactome_id);
#    }
#  }
#  return ((@rows == 0) ? undef : table({-border=>0,-width=>'100%'},@rows));
    
}


# open GFF database
sub OpenPmapGFF {
  my $db = shift;
  my $gff_args = Configuration->Pmapgff;
  my $key = join ';',@$gff_args;
  $PMAPGFF{$key} ||= Bio::DB::GFF->new(@$gff_args,$db ? (-acedb=>$db):());
  $PMAPGFF{$key}->freshen_ace if $PMAPGFF{$key};
  $PMAPGFF{$key};
}

sub OpenGmapGFF {
  my $db = shift;
  my $gff_args = Configuration->Gmapgff;
  my $key = join ';',@$gff_args;
  $GMAPGFF{$key} ||= Bio::DB::GFF->new(@$gff_args,$db ? (-acedb=>$db):());
  $GMAPGFF{$key}->freshen_ace if $GMAPGFF{$key};
  $GMAPGFF{$key};
}

# open GFF database
sub OpenDBGFF {
  my $db = shift;
  my $gff_args = Configuration->Dbgff;
  my $key = join ';',@$gff_args;
  $DBGFF{$key} ||= Bio::DB::GFF->new(@$gff_args,$db ? (-acedb=>$db):());
  $DBGFF{$key}->freshen_ace if $DBGFF{$key};
  $DBGFF{$key};
}

# open GFF database
sub OpenBrigGFF {
  my $db = shift;
  my $gff_args = Configuration->Briggff; 
  my $key      = join ';',@$gff_args;
  $BRIGGFF{$key} ||= Bio::DB::GFF->new(@$gff_args,$db ? (-acedb=>$db):());
  $BRIGGFF{$key}->freshen_ace if $BRIGGFF{$key};
  $BRIGGFF{$key};
}

# Generically open a GFF database
sub OpenGFFDB {
    my ($db,$species) = @_;
    $species ||= '/Caenorhabditis elegans/';  # Default to elegans

    # These are the symbolic names in elegans.pm
    my $config;
    if ($species =~ /briggsae/) {
	$config = 'Briggff';
    } elsif ($species =~ /remanei/) {
	$config = 'Remgff';
    } else {
	$config = 'Dbgff';
    }

    my $gff_args = Configuration->$config; 
    my $key      = join ';',@$gff_args;

    $GFFDB{$key} ||= Bio::DB::GFF->new(@$gff_args,$db ? (-acedb=>$db):());
    $GFFDB{$key}->freshen_ace if $GFFDB{$key};
    $GFFDB{$key};
}

# open GFF database
sub OpenDBGeneSearch {
#    my $ace = shift;
#    my $version = $ace->status->{database}{version};
    $GENE_SEARCH{dbh} ||= DBI->connect("dbi:mysql:gene_search" . ';host=localhost','nobody');
    return $GENE_SEARCH{dbh};
}





my @BANNERS_RIGHT;

sub Header {
  my $width = Configuration->Pagewidth;
  return br();
}

sub Footer {
    #don't show the ugly ace footer    
    my ($value) = ($ENV{SERVER_NAME} =~ /dev/) ? 2 : 1;

    my $hostname = get_hostname();
  return join '',
    "<!-- served from $hostname -->","\n",


    qq#
<script type="text/javascript">

    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-16257183-1']);
    _gaq.push(['_setDomainName', '.wormbase.org']);
    _gaq.push(['_trackPageview']);

    (function() {
	var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
	ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>#,
    Configuration()->My_footer,
      end_html();
}


sub get_hostname {
    my $hostname = `hostname` or die "Cannot determine hostname!\n";
    chomp $hostname;
    return $hostname;
}

sub get_species {
    my $object = shift;
    my $full_species = $object->Species;
    my ($genus,$species) = $full_species =~ /(\w).*\s(.*)/;
    return lc($genus) . '_' . $species;
}

# get the interpolated position of a sequence on the genetic map
# returns ($chromosome, $position)
# position is in genetic map coordinates
# Lots of cruft here from pre-WS124
sub GetInterpolatedPosition {
  my ($db,$obj) = @_;
  my ($full_name,$chromosome,$position);
  if ($obj){
      if ($obj->class eq 'CDS') {
	  # Is it a query
	  # wquery/genelist.def:Tag Locus_genomic_seq
	  # wquery/new_wormpep.def:Tag Locus_genomic_seq
	  # wquery/wormpep.table.def:Tag Locus_genomic_seq
	  # wquery/wormpepCE_DNA_Locus_OtherName.def:Tag Locus_genomic_seq
	  
	  # Fetch the interpolated map position if it exists...
	  # if (my $m = $obj->get('Interpolated_map_position')) {
	  if (my $m = eval {$obj->get('Interpolated_map_position') }) {
	  #my ($chromosome,$position,$error) = $obj->Interpolated_map_position(1)->row;
	      ($chromosome,$position) = $m->right->row;
	      return ($chromosome,$position) if $chromosome;
	  } elsif (my $l = $obj->Gene) {
	      return GetInterpolatedPosition($db,$l);
	  }
      } elsif ($obj->class eq 'Sequence') {
	  #my ($chromosome,$position,$error) = $obj->Interpolated_map_position(1)->row;
	  my $chromosome = $obj->get(Interpolated_map_position=>1);
	  my $position   = $obj->get(Interpolated_map_position=>2);
	  return ($chromosome,$position) if $chromosome;
      } else {
	  $chromosome = $obj->get(Map=>1);
	  $position   = $obj->get(Map=>3);
	  return ($chromosome,$position) if $chromosome;
	  if (my $m = $obj->get('Interpolated_map_position')) {	     
	      my ($chromosome,$position,$error) = $obj->Interpolated_map_position(1)->row unless $position;
	      ($chromosome,$position) = $m->right->row unless $position;
	      return ($chromosome,$position) if $chromosome;
	  }
      }
  }
  return;
}

# find position of a sequence in genome coordinates and return:
#     (start, end, reference sequence)
# the reference sequence will usually (but not always!) be a chromosome
sub FindPosition {
  my ($DB,$seq) = @_;
#  my $db = OpenDBGFF($DB) or return;
  my $db = OpenGFFDB($DB,$seq->Species);
  my $name  = "$seq";
  my $class = eval{$seq->class} || 'Sequence';
  my @s = $db->segment($class=>$name) or return;
  my @result;
  foreach (@s) {
    my $ref = $_->abs_ref;
    $ref = "CHROMOSOME_$ref" if $ref =~ /^[IVX]+$/;
    push @result,[$_->abs_start,$_->abs_end,$ref,$_->abs_ref];
  }
  return unless @result;
  return wantarray ? @{$result[0]} : \@result;
}

sub GBrowseLink {
  my $sequence = shift;
  my ($start,$stop,$refname,$ref) = FindPosition(OpenDatabase(),$sequence) or return;
  my ($s,$e) = ($start,$stop);
  AddCommas($s,$e);
  $start = int($start - 0.25*($stop-$start));
  $stop  = int($stop  + 0.25*($stop-$start));
#  if (Configuration->Use_gbrowse1) {
#  # Gbrowse 1
#      return a({-href=>"/db/seq/gbrowse/c_elegans?ref=$ref;start=$start;stop=$stop"},
#	       "$refname:$s..$e");
#  } else {
      # GBrowse2
      return a({-href=>"/db/gb2/gbrowse/c_elegans?ref=$ref;start=$start;stop=$stop"},
	       "$refname:$s..$e");
#  }
}

sub AddCommas {
  foreach (@_) {
    $_ = reverse $_;
    s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    $_ = reverse $_;
  }
}

sub PrintRefs {
    my ($obj,$refs) = @_;
    my $n = CGI::escape($obj->name);
    my $c = CGI::escape($obj->class);
    print hr,h4({-class=>'heading'},'Bibliography:');
    print p({-class=>'note'},'No bibliography available in Wormbase')
      unless $refs and @$refs;

    my @cgc = grep { $_->Journal_article || $_->Letter || $_->Review || $_->Retracted_publication || $_->Published_erratum} @$refs;
    my @wbg = grep { $_->Gazette_article } @$refs;
    my @wm = grep { $_->Meeting_abstract } @$refs;

    my @items;
    push (@items,a({-href=>Url(ABSTRACT_INFO,"name=$n&category=CGC&type=$c") },
		   "Papers in WormBase Bibliography (" . scalar(@cgc).")")) if @cgc;
    push (@items,a({-href=>Url(ABSTRACT_INFO,"name=$n&category=WBG&type=$c") },
		   "Worm Breeders Gazette Abstracts (" . scalar(@wbg) . ")")) if @wbg;
    push (@items,a({-href=>Url(ABSTRACT_INFO,"name=$n&category=WMA&type=$c") },
		   "Worm Meeting Abstracts (" . scalar(@wm) . ")")) if @wm;
    push @items,a({-href=>Configuration->Pubmed . $obj},"Search PubMed for references");
    print ul(
	     li(\@items),
	     );
}

sub PrintExpressionPattern {
  my $gene = shift;

  my @patterns  = $gene->Expr_pattern;

  my $class   = $gene->class;
  unless (@patterns) {
    if ($class eq 'Sequence' && (my $locus = $gene->Locus)) {
      @patterns = $locus->Expr_pattern;
    } elsif ($class eq 'Locus' && (my $seq = $gene->CDS)) {
      @patterns = $seq->Expr_pattern;
    }
  }

  unless(@patterns){
    SubSection('',
	       "Either no expression pattern has been described for this \L$class\E or it has not yet been entered into WormBase.");
    return;
  }

  my @text;
  for my $pattern (@patterns) {
    my $citation;
    if (my $reference = $pattern->Reference) {
      $citation = 'Reference: '.ObjectLink($reference);
    }
    my @assays = $pattern->Type->col if ($pattern->Type);
    push @text,join('',
		    ucfirst($pattern->Pattern),
		    $pattern->Subcellular_localization ?
		    p(b("Subcellular location: "),$pattern->Subcellular_localization,'.')
		    : "",
		    $pattern->Type ?  ( " (Assay: ". join('; ',@assays) . ").")  : '.',
		    ObjectLink($pattern,' [Details]'),br(),$citation
		   );
  }
  SubSection('',@text);
}

sub PrintRNAiPattern {
    my ($s,$params) = @_;
    my %patterns;

    my $extlink = 'none';
    if (param('name') =~ /^TH:/){
      my ($rnai) = param('name') =~ /.+?:(.+)/;
      $extlink = a({href=>Configuration->Hyman . $rnai},param('name'));
    }

    # map genes onto RNAi phenotype, regardless of what type of object we're passed
    print hr(),h3({-class=>'heading'},'RNAi Assays:');

    foreach (@$s) {
	if ($_->class eq 'RNAi') {
	    my $g = $_->Predicted_gene || $_;
	    $patterns{$g} = [$_];
	} else {
	    next unless my @r = $_->RNAi_result;
	    $patterns{$_} = \@r;
	}
    }

    unless (%patterns) {
    print blockquote({-class=>'databody'},
		     font({-class=>'note'},
			  'Either no RNAi data is known for this gene or it has not been entered into WormBase'));
      return;
    }

    print p("This is a summary of RNAi experiments that have been performed on this (predicted) gene."),"\n";

    print start_table({-border=>0});
    print TR({-class=>'datatitle'},
	     th[
		'Gene',
		'Experiment',
		'Date',
		'Author',
		'Laboratory',
#		'External Link'
		'Maternal Brood Size',
		'Embryonic Lethality',
		'Postembryonic Phenotype(s)',
		'Supporting Data',
		]);

    foreach my $seq (keys %patterns) {
	my $patterns = $patterns{$seq};
	foreach my $pattern (@$patterns) {

	    my $date = $pattern->Date;
	    $date =~ s/ 00:00:00$//;

	    my %seen;

	    # CAN BE SAFELY REMOVED AFTER OLD STYLE PHENES ARE GONE
	    # Of course, the whole search will then be broken, too!
	    my @phenotypes = $pattern->Phenotype;

	    my $maternal = 'Normal';
	    my $embryonic = 'Normal';
	    my @postembryonic;
	    foreach (@phenotypes) {

	      if ($_->Short_name eq 'Ste') {
		    my $quantity = $_->at('Quantity');
		    $maternal = $quantity ? 'Reduced to ' . join '-',$quantity->right->row
			: 'Sterile';
		} elsif ($_->Short_name eq 'Emb') {
		    my $quantity = $_->at('Quantity');
		    if ($quantity) {
			my ($low,$high) = $quantity->right->row;
			$embryonic = 'Lethal : '. ($low != $high ? "$low-$high%" : "$low%");
		    } else {
			$embryonic = 'Lethal';
		    }
		} else {
		  my @remarks     = $_->get('Remark');
		  my $remarks     = join '; ',@remarks;
		  push @postembryonic,($remarks ? ObjectLink($_,best_phenotype_name($_)) . " ($remarks)"
				       : ObjectLink($_,best_phenotype_name($_)));
	      }
	  }

	    my $postembryonic =  @postembryonic ? join br,sort @postembryonic : 'None';
	    my @remark = $pattern->Remark; #oops, need method call sometimes (??)
	    my @genes = $pattern->Predicted_gene;
	    my $pg = @genes ? join(' ',map { ObjectLink($_) } @genes)
                            : 'Identity of corresponding gene under review.';

	    # hack alert -- this needs to be cleaned up
	    my $experiment_link;
	    my $history = $pattern->History_name || $pattern;
	    if ($pattern->Laboratory eq 'KK') {
	      ($experiment_link = $history) =~ s/^KK://;
	      $experiment_link = a({-href=>Configuration->Rnaidb.$experiment_link},$history)
	    } elsif ($pattern->Laboratory eq 'TH'){
	      ($experiment_link = $history) =~ s/^TH://;
	      $experiment_link = a({-href=>Configuration->Hyman.$experiment_link},$history)
	    } else {
	      $experiment_link = a({-href=>Object2URL($pattern)},$history);
	    }

            my @support;
	    if (eval {$pattern->Movie}){
              @support = $pattern->Movie;
	    }

	    my $remark_count = 0;
	    my $support_count = 0;
	    my $author = ($pattern->Author)[0];
	    print TR({-class=>'databody'},
		     td([
			 $pg,
			 $experiment_link,
			 $date,
			 ($author ? ObjectLink($author,"$author et al") : ''),
			 join(' ',map { ObjectLink($_) } $pattern->Laboratory),
#			 $extlink,
			 $maternal,
			 $embryonic,
			 $postembryonic,
#			 'foo',
			 (@support ? join br,map {++$support_count .". ".a({-href=>Configuration->Movie.$_},$_->Remark).br} @support : '&nbsp;'),
			 ]));
	    print TR({-class=>'databody'},
		     th('&nbsp;'),
		     td({-colspan=>8},
			(@remark  ? map {++$remark_count  .". ".$_.br} @remark  : '&nbsp;')));

	  }
      }
    print end_table;
}

sub PrintExpressionMap {
  my $object = shift;
  my $seq;
  print hr(),h3({-class=>'heading'},'Expression Map:');

  if ($object->class eq 'Locus') {
    $seq = $object->CDS;
  } elsif ($object->class eq 'Sequence') {
    $seq = $object;
  }

  unless ($seq) {
    print blockquote({-class=>'databody'},
		     font({-class=>'note'},
			  'Either no expression map is known for this gene or it has not been entered into WormBase'));
    return;
  }

  # look for overlapping Expr_profiles
  my $ace = OpenDatabase()  or return;
  #my $gff = OpenDBGFF($ace) or return;
  my $gff = OpenGFFDB($ace,$seq->Species);

  my ($s)   = $gff->segment($seq->class,$seq->name);

  my @p = map {$_->info} $s->features('Expression:Expr_profile') if ($s);
  unless (@p) {
    print blockquote({-class=>'databody'},
		     font({-class=>'note'},
			  'Either no expression map is known for this gene or it has not been entered into WormBase'));
    return;
  }

  print p("This is a summary of the gene expression map analysis performed by",
	  "Kim",i("et al"),
	  a({-href=>'http://cmgm.stanford.edu/~kimlab/topomap/c._elegans_topomap.htm'},"Science, 293: 2087-2092. 2001")
	 );
  print start_table({-width=>'100%'});
  print TR(th({-class=>'datatitle'},
	      ['Expr Map','Expression Profile','Primer Pair','Gene','Mountain','X coordinate','Y coordinate'])),"\n";

  for my $profile (@p) {
    my $map = eval { $profile->Expr_map } or next;
    my ($x,$y) = ($map->X_coord,$map->Y_coord);
    print TR({-class=>'databody',-valign=>'TOP'},
	     td(ObjectLink($profile,img({-src=>"/db/gene/gene_in_profile?x=$x;y=$y;r=4;small=1",-width=>100,-height=>100,-border=>0}))),
	     td(ObjectLink($profile)),
	     td(ObjectLink($profile->PCR_product)),
	     td(ObjectLink($seq)),
	     td(a({-href=>Configuration->Kim_mountains},$map->Mountain)),
	     td($map->X_coord),
	     td($map->Y_coord)),"\n";
  }
  print end_table;
}

# Choose a set of displayers based on the type.
sub TypeSelector {
  my ($name,$class) = @_;
  my ($n,$c) = (CGI::escape("$name"),CGI::escape($class));
  my @rows;

  # add the special displays
  my @displays       = Configuration()->class2displays($class,$name);
  my @basic_displays = Configuration()->class2displays('default');
  @basic_displays    = SiteConfig->getConfig(DEFAULT_DATABASE)->class2displays('default')
    unless @basic_displays;

  my $display = url(-absolute=>1);


  foreach (@displays,@basic_displays) {
    my ($url,$icon,$label) = @{$_}{qw/url icon label/};
    next unless $url;
    
    # Hunter / gbrowse url is species specific
    # Have to fetch the object FIRST to know it's species. Ugh.
    if ($url =~ /seq\/gbrowse/ || $url =~ /gb2/) {
	my $db     = OpenDatabase(); 
	my $object = $db->fetch($class => $name);
	my $species = get_species($object);
	$url = sprintf($url,$species);
    }

    my $u = ResolveUrl($url,"name=$n;class=$c");
    $url =~ s/\#.*$//;
    my $active = $url !~ /$display(\?|$)/;
    my $cell = $active ? a({-href=>$u,-target=>'_top'},$label)
      : font({-color=>'red'},$label);
    push (@rows,td({-align=>'CENTER',-class=>'small'},$cell));
  }
    my $return = '<br clear="all">';
    $return .= table({-width=>'100%',-border=>'0', -class=>'searchtitle'},
		     Tr({-valign=>'bottom'},@rows));
    return $return;
}

sub Banner {
  my $db = shift;
  my $config = Configuration();
  my $dbname = DB_Name();

  #  warn $config,$dbname;
  return unless my $searches = $config->Searches;

  #  warn @$searches;
  local $^W = 0;

  my $banner_left  = $config->Banner_left;
  my $banner_right = $config->Banner_right;
  my $image_right  = $banner_right;

  my $classlist = Configuration->Simple;
  my @classlist = @{$classlist}[map {2*$_} (0..@$classlist/2-1)];  # keep keys, preserving the order

  my $page = CGI->url(-absolute=>1);
  my $homepage   = $page =~ m!^/index.html$!;
  $homepage++ if length $page == 0 || length $page == 1;
  my $searchpage = $page =~ m!^/db/searches! ||$page =~ m!^/gb2/gbrowse/!;

  $db ||= $Ace::Browser::AceSubs::DB{$dbname} || OpenDatabase();
  my $version = eval {$db->status->{database}{version}};

  my $javascript; 
if ( $page !~ /gbrowse/ ) {
  $javascript = <<END;
<script type="text/javascript">
  function c(p){location.href=p;return false;}
  var balloon  = new Balloon;
  balloon.maxWidth = 300;
  balloon.helpUrl  = "/db/misc/help";
</script>
END
}
else {
  $javascript = <<END;
<script type="text/javascript">
  function c(p){location.href=p;return false;}
</script>
END
}

#   my $banner_image =
#     table({-border=>0,-cellpadding=>0,-cellspacing=>1,-width=>'100%',-nowrap=>1},
# 	  TR({-class=>'white',-valign=>'top', -nowrap=>1},
# 	     td({-width=>'50%',-valign=>'MIDDLE',-align=>'LEFT'},
# 		($homepage||$searchpage)
# 		? h3("WormBase Release $version")
# 		:
# 		(
# 		 start_form(-action=>'/db/searches/basic'),
# 		 b('Find:',
# 		   textfield(-name=>'query',-size=>12)
# 		  ),
# 		 i(
# 		   popup_menu(-name=>'class',
# 			      -Values=>\@classlist,
# 			      -Labels=>{@$classlist},
# 			      -default=>'AnyGene')
# 		  ),
# 		 end_form(),
# 		)
# 	       ),
# 	     td({-align=>'right'},a({-href=>'/'},img({-src=>$image_right,-alt=>'WormBase Banner',-border=>0}))),
# 	    ))
#       , br({-clear=>'all'});

  my $system_message = '<div id="top-system-message" class="system-message">Try <a href="http://beta.wormbase.org">WormBase 2 (beta)</a>!</div><div class="system-message" ></div>';
  my $banner_image =  img({-src=>$image_right,-alt=>'WormBase Banner',-border=>0,-align=>'right'});

  if ($homepage || $searchpage) {
    $banner_image .= a({-href=>'/'},h3("WormBase Release $version"));

  } else {

    $banner_image .= 
	div({-id=>'mainSearch',-style=>'text-align:left'},
	    start_form(-action=>'/db/searches/basic'),
	    b('Find:'),
	    autocomplete_field('global'),   # build the global prompt
	    i(
	      popup_menu(-name=>'class',
			 -id => 'class_search_menu',
			 -Values=>\@classlist,
			 -Labels=>{@$classlist},
			 -default=>'AnyGene',
			 #-onChange=>"autoCompleteData.scriptQueryAppend = 'class='+this.value+';max='+autoComplete.maxResultsDisplayed"
			)
	     ),
	    end_form()
	   );
    #$banner_image .= autocomplete_end('global');
  }

  # next select the correct search script
  my @searches = @{$searches};
  my $self = url(-relative=>1);
  my $return_table = qq(<table border="0" cellpadding="4" cellspacing="1" width="100%">\n);
  my $rows    = int(sqrt(@searches));
  my $cols    = int(0.99+@searches/$rows);
  while ($cols <= 6) {
    $rows--;
    $cols    = int(0.99+@searches/$rows);
  }

  for (my $row=0; $row<$rows; $row++) {
    $return_table .= "<tr>\n";
    for (my $col=0;$col<$cols;$col++) {
      my $index = $col*$rows + $row;
      my $search = $searches[$index];
      my ($name,$url,$on,$off,$size) = @{$config->searches($search)}{qw/name url onimage offimage size/};
      (my $check_url = $url) =~ s/\?.*$//;
      my $active = $self ? $check_url =~ /$self$/ : $check_url eq '/';
      my $cell_color;
      my $cell_css;

      # Wonky hack for directing WormMart links on the dev site to the dev version of WormMart.
      if ($search eq 'wormmart') {
	  $url = Configuration->Wormmart_url;
#	  $url ||= 'http://www.wormbase.org/Multi/martview';
#	  $url ||= 'http://biomart.wormbase.org/biomart/martview';
#	  $url = 'http://biomart.wormbase.org/biomart/martview';
	  $url ||= 'http://caprica.caltech.edu:9002/biomart/martview';
      }

      if ($active) {
	$cell_color = '#b4cbdb';
	$cell_css = 'bactive';
      } else {
	$cell_color = '#5870a3';
	$cell_css = 'binactive';
      }

      # replace the url with a cookie, if one is defined
      my $cookie_name = "SEARCH_${dbname}_${_}";
      my $query_string = cookie($cookie_name) unless /blast/;
      $url .= "?$query_string;again=1" if $query_string;
      # Temporary fix to make sure that the header coming from the blat page points always back to blat2wormbase link
      # Ugh.  Don't adjust the URL for the WormMart link
      unless ($url =~ /martview/) {
	if ($ENV{SCRIPT_NAME} =~ /searches\/blat/) {
	  $url =~ s/^/Configuration->Blast2wormbase/e;
	}
      }

     
      # help items for the navigation bar are to be found in document_root/help/index.xml 
      my $help_name = $name;
      $help_name =~ s/^.+?>([^<]+)<.+$/$1/;

      # This will have to be updated as new navigation links are added
      my $tooltip = '';

      if ($help_name =~ /Genome|Synteny|Blast|Mart|Batch|Markers|Genetic|Submit|Searches/) {
	$tooltip = qq(onMouseOver="balloon.showTooltip(event,'$help_name')");
      }
      $return_table .= qq{<td bgcolor="$cell_color" align="center" style="cursor:pointer" nowrap onClick="c('$url')">
			  <a href="$url" class="$cell_css" $tooltip>$name</a></td>\n};
    }
    $return_table .= "</tr>\n";
  }

  my ($home_icon,$hbs)    = @{$config->Home_button};
  my ($home,$label) = @{$config->Home};

  $return_table .= "</table>"; 
  $return_table .= "<!-- End WormBase Header -->";

  my $warning = Configuration->Development ?  h4(font({-color=>'red'},'WormBase development site. Master is at <a href="http://www.wormbase.org">www.wormbase.org</a>'))
              : Configuration->Mirror      ?  h4(Configuration->Mirror,'. Master is at <a href="http://www.wormbase.org">www.wormbase.org</a>')
              : br({-clear => 'all'});

  return join '', "\n<!-- Begin WormBase Header -->\n",$javascript,$system_message,$return_table,$banner_image,$warning;
}



sub toggle_style {
  return <<'END';
<style type="text/css">
<!-- 
.el_hidden  {display:none}
.el_visible {display:inline}
.ctl_hidden {
 cursor:hand;
 display:none;
 }
.ctl_visible {
 cursor:hand;
 display:inline;
 }
.tctl      {  color:#3366FF }

 -->
</style>
<script src="/js/toggle.js" type="text/javascript"></script>
<script src="/js/x_cook.js" type="text/javascript"></script>
END
}

# subroutines only used in the search scripts
sub DisplayInstructions {
  my ($title,@instructions) = @_;

  my $images = Configuration->Random_picts;
  my $script = Configuration->Pic_script;
  my $cross   = Configuration->Cross_icon;

  #show the instruction paragraph <ul>
  print h1($title);
  print ul(li(\@instructions));
}

sub PrintOne {
  my $options = shift if ref($_[0]) && ref($_[0]) eq 'HASH';
  my $label = shift;
  my $obj   = shift;
  return unless $obj;
  print TR($options||{-valign=>'top'},
	   th({-class=>'databody',-align=>'LEFT'},"$label: "),
	   td({-class=>'databody'},ref($obj) && $obj->isClass && $obj->class !~ /Text/ ? ObjectLink($obj) : $obj)
	  );
}
sub PrintMultiple {
  local $^W = 0;  # get rid of uninit variable warnings

  my $options = shift if ref($_[0]) && ref($_[0]) eq 'HASH';
  my $label   = shift;
  my @a = @_;
  return unless @a;
  my $rowspan  = @a;
  my $first = shift @a;
  print TR($options||{-valign=>'top'},
	   th({-align=>'LEFT',-valign=>'top',-class=>'databody',-rowspan=>$rowspan},length $label>0 ? "$label: " : ''),
	   td({-class=>'databody'},eval{ref($first) && $first->isClass && $first->class !~ /Text/} ? ObjectLink($first)
                                                                                                   : $first)
	  );
  for my $obj (@a) {
    print TR({-class=>'databody'},
	     td(eval{ref($obj) && $obj->isClass && $obj->class !~ /Text/} ? ObjectLink($obj) : $obj)
	    );
  }
}


sub GenerateWikiLink {
    my ($tag,$url) = @_;
    return i("Read more about <b>$tag</b> on the "
	     . a({-href=>$url},' WormBaseWiki'));
}

# Provided with a paper object citing a WormBook chapter,
# return 2 links. If an optional "TERM" is provided -- containing
# a WormBase object cited in WormBook, returns the 3rd and 4th links below)
# 1. A link to WormBook itself
# 2. A link to the top of the current chapter
# 3. A link to a CGI that displays all occurrences of the term in the given chapter.
# 4. A link to a CGI that displays all occurrences of the term in WormBook.
sub GenerateWormBookLinks {
    my @p = @_;
    my ($obj,$term) = rearrange([qw/OBJ TERM/],@p);

    my $doi = $obj->Other_name;
    
    # Create a generic text link to WormBook
    my $wormbook = a({-href=>Configuration->WormBook},'WormBook');

    # Link to the chapter - Now just using "WormBook"
    my $chapter = a({-href=>Configuration->Doi . $doi},'WormBook');

    my ($occurrences_by_chapter,$total_occurrences);
    if ($term) {
	my $search_cgi = Configuration->Wormbook_search;
	
	# Something screwy with the WormBook cgi.  Have to link with a fragment of the DOI
	$doi =~ /.*wormbook\.(.*)/;
	my $doi_suffix = $1;
	$occurrences_by_chapter = a({-href=>sprintf($search_cgi,$term . '%20AND%20' . $doi_suffix)},
				    "Search WormBook for all occurrences of $term in this chapter.");
	$total_occurrences      = a({-href=>sprintf($search_cgi,$term)},
				    "for all occurrences of $term");
    }
    return ($wormbook,$chapter,$occurrences_by_chapter,$total_occurrences);
}


# UNFINISHED
# THIS SHOULD BE CALLED AUTOMATICALLY FROM TABLEIZE
# In the event that there are two many objects
# DisplayMore generates a link back to the page.
# When called from the link, it creates a new page
# displaying those objects
# eg
#   DisplayMoreLink(\@items,'Matching_cDNA');
sub DisplayMoreLink {
  my ($items,$class,$target,$link_text,$suppress_count,$url) = @_;
  $class ||= $items->[0]->class;
  my $class_label = $class;
  $class_label =~ s/_/ /;
  $target    ||= '_blank';
  $link_text ||= 'View All';
  my $count = scalar @$items;
  my $label = undef;  # Weird mod_perl issue here...
  $label    = " $count $class_label(s) found. " unless $suppress_count;
  $url ||= url(-absolute=>1,-query=>1);
  $label   .= '[' . a({-href=>$url . ";details=$class",-target=>$target},$link_text) . ']';
  return $label;
}

# DisplayMore($obj,$tag);
sub DisplayMore {
  my ($obj,$tag) = @_;
  my @items = $obj->tag;
  StartSection($tag);
  SubSection("",Tableize(\@items));
  EndSection();
}

# Create a link to the glossary, including the cute little question mark image
# The optional second and third position arguments are for text only linking.
# The second position boolean results in a hyperlink of $term.
# The third position results in a superscripted $superscript linking to the glossary
sub LinkToGlossary {
  my ($term,$text_only,$superscript) = @_;
  if ($text_only) {
    return a({-href=>"/db/misc/glossary?name=$term;options=terms",-target=>'_blank'},$term);
  } elsif ($superscript) {
#    return span({-class=>'superscript'},
#		a({-href=>"/db/misc/glossary?name=$term;options=terms",-target=>'_blank'},$superscript));
      return (a({-href=>"/db/misc/glossary?name=$term;options=terms",-target=>'_blank'},$superscript));
  } else {
    return (a({-href=>"/db/misc/glossary?name=$term;options=terms",-target=>'_blank'},
	      img({-src=>'/images/question_small.gif',-halign=>'right',-valign=>'middle'})));
  }
}

# Create a string to use as an identifier of the back end server
# for dynamically created images
sub AppendImagePath {
  my $path = shift;
  # Create images with a path that includes a fragment of the server name
  # This lets squid automatically redirect us to the correct backend machine
  # This is primarily used by Bio::Graphics::Browser generated images
  my ($server) = $ENV{SERVER_NAME} =~ /(.*?)\..*/;
  $server    ||= 'local';
  return "$server/$path";
}

# given any object mapped onto the genome, find all genes that overlap it.
sub OverlappingGenes {
  my ($object,$DB,$GFF) = @_;
  $DB  ||= OpenDatabase()  or return;
#  $GFF ||= OpenDBGFF($DB) or return;
  $GFF ||= OpenGFFDB($DB,eval { $object->Species } || 'elegans');
  $object or return;
  my ($sequence) = $GFF->segment($object->class,$object->name) or return;
  my @genes = $sequence->features('CDS:curated');

  return map {$_->info} @genes;
}

sub OverlappingPCR {
  my @segments = @_;
  return map {$_->info} map { $_->features('PCR_product:GenePair_STS','structural:PCR_product') } @segments;
}

sub OverlappingOST {
  my @segments = @_;
  return map {$_->info} map { $_->features('alignment:BLAT_OST_BEST','PCR_product:Orfeome') } @segments;
}

sub OverlappingSAGE {
  my @segments = @_;
  return map {$_->info} map { $_->features('transcript:SAGE_transcript') } @segments;
}

sub HunterUrl {
    my ($ref,$start,$stop,$species);

  # can call with three args (ref,start,stop)
  if (@_ == 3) {
    ($ref,$start,$stop) = @_;
} elsif (@_ == 4) {
    ($ref,$start,$stop,$species) = @_;

  # or with a sequence object
}  else {
    my $seq_obj = shift or return;
    $seq_obj->absolute(1);
    $start      = $seq_obj->start;
    $stop       = $seq_obj->stop;
    $ref        = $seq_obj->refseq;
  }

  $ref =~ s/^CHROMOSOME_//;
  $start = int($start - 0.05*($stop-$start));
  $stop  = int($stop  + 0.05*($stop-$start));
  ($start,$stop) = ($stop,$start) if $start > $stop;
  $ref .= ":$start..$stop";
  $species ||= 'c_elegans';
  my $hunter = sprintf(Configuration->Hunter,$species,$ref);
  return $hunter;
}

# render inline image using gbrowse_img
sub InlineImage {
 my ($param,$SPECIES,$ref,$start,$stop)=@_;
 my $PICTURE_WIDTH = 600;
 my $position = (defined $start)?"$ref:$start..$stop":$ref;
 #my $link="/db/gb2/gbrowse_img/$SPECIES/?name=$position;$param;embed=1;width=".$PICTURE_WIDTH;
 my $link="/db/gb2/gbrowse_img/$SPECIES/?name=$position;$param;width=".$PICTURE_WIDTH;
 my $link_gb="/db/gb2/gbrowse/$SPECIES/?name=$position";
 #my $link_gb="/db/gb2/gbrowse/$SPECIES/?name=$position;$param;width=".$PICTURE_WIDTH;
 return a({href=>$link_gb},img{src=>$link});
=pod
 return iframe({ -name=>'genomice environment',
                 -src=>$link,
                 -width=> ($PICTURE_WIDTH+100),
                 -height=>250,
                 -scrolling=>'auto',
                 -frameborder=>0}
			).end_iframe();
=cut
}

# given a GD image, writes it into the image directory and returns correct URL
sub AceImage {
  my $gd = shift;
  my ($suffix,$data,$boxes);
  if ($gd->isa('Ace::Object')) {
    $suffix = 'gif';
    ($data,$boxes) = $gd->asGif(@_);
  } else {
    $suffix   = $gd->can('png') ? 'png' : 'gif';
    $data     = $gd->can('png') ? $gd->png : $gd->gif;
  }
  my $basename = md5_hex($data);

  my ($pic,$picroot) = @{Configuration()->Pictures};
  my $path = DB_Name();
  $path   .= '/hex';

  if ($ENV{MOD_PERL}) { # we have apache, so no reason not to take advantage of it
    my $r = Apache->request;
    my $subr = $r->lookup_uri($pic ."/");
    $picroot = $subr->filename if $subr;
  }

  my $dirs = substr($basename,0,6);  # e.g. E0F123
  $dirs    =~ s!^(.{2})(.{2})(.{2})!$1/$2/$3!g;

  mkpath (["$picroot/$path/$dirs"],0,0777) || AceError("Can't create directory to store image in")
    unless -d "$picroot/$path/$dirs";

  my $file_path = "$picroot/$path/$dirs/$basename.$suffix";
  my $file_url  = "$pic/$path/$dirs/$basename.$suffix";

  # write out data
  open (F,">$file_path") || AceError("Can't store image $file_path");
  print F $data;
  close F;
  $file_url = CGI->url(-base=>1) . $file_url;
  return wantarray ? ($file_url,$file_path,$boxes) : $file_url;
}


#### Microarray data

sub PrintMicroarray  {
  my $microarray_root = shift;    # e.g. Microarray_aff object

  # Print header
  unless ($microarray_root) {
    print blockquote({-class=>'databody'},
		     font({-class=>'note'},
			  'Either no expression map is known for this gene or it has not been entered into WormBase'));
    return;
  }
  next unless $microarray_root->Microarray_result;
  print  h3('Results: Microarray', $microarray_root);
  print p(   b("Paper "),
	     (":", $microarray_root->Microarray_result->Reference->Brief_citation),
	     (ObjectLink($microarray_root->Microarray_result->Reference)),
	 ) if $microarray_root->Microarray_result->Reference;

  my $chip_type =  $microarray_root->Microarray_result->Chip_type;

  # If microarray_root has a remark, or ref.
  print p(b("Remark:"),$microarray_root->Remark) if $microarray_root->Remark;
  if ($chip_type ne "SMD"){
    print p(b("Reference:"),$microarray_root->Reference) if $microarray_root->Reference;
  }


  print p(b("Chip type:"), $chip_type);
  print p(
	  b('Null Hypothesis:'),
	  ('no variation in the frequency of the transcript across the 8 
            samples'),br,
      	  b('Results:'),
	  ('p-value=',$microarray_root->Microarray_result->P_value),
 	      em({-align=>'RIGHT'}, "(where p=0.00 represents a certain significance and p >= ~0.5 represents random noise)")
	 ) if $chip_type eq "Affymetrix";

  microarray_smd($microarray_root) if $chip_type eq "SMD";
  microarray_affy($microarray_root) if $chip_type eq "Affymetrix";

  print br();
  print p("Chip information:", $microarray_root->Microarray_result->Chip_Info)
    if ($microarray_root->Microarray_result->Chip_Info);

  print p("Remark:", $microarray_root->Microarray_result->Remark)
    if ($microarray_root->Microarray_result->Remark);

} # end sub print_microarray


sub microarray_affy {
  my $microarray_root = shift;    # e.g. Microarray_aff object
  print start_table({-border=>1});

  # Print results
    print TR({-class => 'searchtitle'},
	     th('Microarray result'),
	     th('Condition'),
	     th('Life Stage'),
	     th('Frequency (ppm)'),
	     th('Presence*'),
	     th('Cluster'),
	    );
  my @m_results = $microarray_root->Microarray_result;

  foreach my $result (@m_results){
    my $life_stage = $result->Sample->right->Life_stage || "-";
    my $cluster = $result->Cluster || "-";
      print TR({-align=>'CENTER',-class=>'databody'},
	       td({-align=>'LEFT'},ObjectLink($result)), #microarray
	       td({-align=>'LEFT'},ObjectLink($result->Sample->right)), #condtn
	       td(ObjectLink($life_stage)),
	       td($result->Frequency),
	       td($result->Presence),
	       td($cluster),
	      );
    } # End of foreach $result
    print end_table;

## Print info table
  print br();
  print b("*Notes: "),
    em("For more details about  NP, PS and PA, see the corresponding", a({-href=>'http://athena.caltech.edu/~wen/userguide/Page/Affy/index.html'},"user guide page."),br,
       ("Frequency is in ppm or transcripts per million")
      );
  print start_table;
  print TR(
	   td("NP (Never Present):"),
	   td("The frequency value is not significant."),
	  );

  print TR(
	   td("PS (Present Sometimes):"),
	   td("The frequency value is significant."),
	  );

  print TR(
	   td("PA (Present Always):"),
	   td("The frequency value is highly significant."),
	  );
  print end_table;
}# end of sub microarray_affy



sub microarray_smd  {
  my $microarray_root = shift;    # e.g. Microarray_aff object
  print start_table({-border=>1,-width=>'80%'});

     # Print results
    print TR({-class => 'searchtitle'},
	     th('Microarray result'),
	     th('Sample A'),
	     th('Sample B'),
	     th('Life Stage'),
	     th('Log Ratio of test/control'),
	     th('Test/control SD'),
	     th('Cluster'),
	    );
  my @m_results = $microarray_root->Microarray_result;

  foreach my $result (@m_results){
      print TR({-align=>'CENTER',-class=>'databody'},
	       td({-align=>'LEFT'},ObjectLink($result)),
	       td({-align=>'LEFT'},ObjectLink($result->Sample_A)),
	       td({-align=>'LEFT'},ObjectLink($result->Sample_B)),
	       td({-align=>'LEFT'},ObjectLink($result->Sample_A->Life_Stage)),
	       td($result->A_vs_B_log_ratio),
	       td($result->A_vs_B_SD),
	       td(ObjectLink($result->Cluster)),
	      );
    } # end of foreach $result
    print end_table;
} # end of sub microarray_smd



# Display all papers that contain microarray results for a given
# microarray object
sub MicroarrayPapers {
  my $mr_obj = shift;
  my (%seen,@papers);
  foreach (my @experiments = $mr_obj->Results) {
    my $paper = $_->Reference;
    next if defined $seen{$paper};
    $seen{$paper}++;
    push (@papers,$paper);
  }
  return @papers;
}



sub overlapping_microarray {
  my @segments = @_;
  #  return map { $_->features('Microarray_results') } @segments;
  return map { $_->features('reagent:Oligo_set') } @segments;
}


# print Erich's long descriptions
sub PrintLongDescription {
    my $gene = shift;
    my $tag  = shift;
    my $title = shift;
    
    my @description = eval { $gene->$tag } or return;
    if (@description) {
	print h3({-class=>'heading'},$title || "$tag");
	
	foreach (@description){
	    print start_div({-class=>"container"}),$_;
	    print start_div({-class=>'evidence'});
	    
	    my $types = get_evidence_types($_);
	    
	    my $table;
	    if (@$types) {
		print h3('Supported by:');
		$table = start_table();
#		    . TR(th('Evidence type')
#			 . th('Source'));
	    }
	    
	    foreach my $type (@$types) {

		# Ignore curator confirmed
		next if $type eq 'Curator_confirmed';

		my $title = $type;
		$title  =~ s/_/ /g;
		
		$table .= start_TR().th({-valign=>'top'},$title);
		$table .= start_td();
		
		my $hashes = get_evidence_hashes($type);
		$table .= join(br, map { format_evidence($type,$_) } @$hashes);
		$table .= end_td(),end_TR();
	    }
	    $table .= end_table();
	    print $table;
	    print end_div,end_div();
	}
    }
}








# Call: GetEvidence($node,$dont_link,$dont_tag)
# $node is the node in the Ace tree - evidence is to the right of it
# $dont_link -- don't turn the node text into a link
# $dont_tag  -- don't even print the node text -- just return evidence
# $omit_label -- omit the primary node text altogether
# $format     -- inline|table (inline)
#                Create an inline list or a small table
# $flat - for single objects, returns evidence type and message, no formatting
sub GetEvidence {
  my @p = @_;
  my ($object,$dont_link,$dont_tag,$omit_label,$include_timestamp,$format) = 
    rearrange([qw/OBJ DONT_LINK DONT_TAG OMIT_LABEL INCLUDE_TIMESTAMP FORMAT/],@p);

  # blech
  $object = [$object] unless ref $object eq 'ARRAY';

  # Collect all the types of evidence available for each object
  my @rows;    # Each row in the table corresponds to an object (each row is stringified)
  my $return;

  # Build up a data structure of all objects passed, and all evidence
  my $evidence = {};

  for my $object (@$object){
    next unless $object;
    $dont_tag = 1 if $object eq 'Evidence'; # hack for cases in which evidence is attached
    my @row;           # Temporary row for this object
    my $description;
    unless ($omit_label) {
      $description = $dont_link ? $object :
	ref $object && $object->class eq 'Gene_name' ?
	  a({-href=>Object2URL(GeneName2Gene($object))},$object)
	    : ObjectLink($object) unless $dont_tag;
    }

    if ($format eq 'table') {
      $return .= start_table({-width=>'70%'}) .
	TR(th('Evidence type') .
	   th('Source'));
    }

    my @types = eval { $object->col };

    # evaluate Evidence hashes
    my $updated;
    foreach my $type (@types){
	next if $type eq 'Curator_confirmed'; # Turn off the display of this tag for now
	
      my @cell = ();   # Each cell is comprised of a specific Evidence type
      my $label;
      if ($type eq 'Paper_evidence') {
	$label = 'via paper evidence';
	foreach my $paper ($type->col) {
	  # Create a short-form citation...
	  my $citation = format_reference(-reference=>$paper,-format=>'short');

          my $pmid = get_PMID($paper);
	  if (0) {
	      if ($pmid) {
		  push (@cell,
			a({-href=>Object2URL($paper)},$citation) . " " .
			a({-href=>Configuration->Pubmed_retrieve . $pmid,-target=>'_blank'},
			  img({-src=>'/images/pubmed_button.gif'})));
		  
	      } else {
		  push (@cell,a({-href=>Object2URL($paper)},$citation));
	      }
	  }
	}
      } elsif ($type eq 'Published_as') {
	$label = 'published as';
	push @cell,map { ObjectLink($_,undef,'_blank') } $type->col;
      } elsif  ($type eq 'Person_evidence' || $type eq 'Curator_confirmed')   {
	$label = ($type eq 'Person_evidence') ? 'via person' : 'via curator';
	push @cell,map {ObjectLink($_->Standard_name,undef,'_blank')} $type->col;
      } elsif  ($type eq 'Author_evidence')   {
	$label = 'via author';
	push @cell,map { a({-href=>'/db/misc/author?name='.$_,-target=>'_blank'},$_) } $type->col;

      } elsif ($type eq 'Accession_evidence') {
	$label = 'via accession evidence';
	foreach my $entry ($type->col) {
	  my ($database,$accession) = $entry->row;
	  my $accession_links   ||= Configuration->Protein_links;  # misnomer
	  my $link_rule = $accession_links->{$database};
	  push @cell,$link_rule ? a({-href=>sprintf($link_rule,$accession),
				     -target=>'_blank'},"$database:$accession")
	    : ObjectLink($accession,"$database:$accession");
	}
	
      } elsif ($type eq 'Protein_id_evidence') {
	$label = 'via protein id evidence';
	push @cell,map { a({-href=>Configuration->Entrezp},$_) } $type->col;
    } elsif  ($type eq 'From_analysis')   {
        $label = 'via analysis';
        push @cell,map {ObjectLink($_,undef,'_blank')} $type->col;
    } elsif ($type eq 'GO_term_evidence') {
	$label = 'via GO term evidence';
	push @cell,map {ObjectLink($_) } $type->col;
      } elsif ($type eq 'Expr_pattern_evidence') {
	$label = 'via expression pattern evidence';
	push @cell,map {ObjectLink($_) } $type->col;
      } elsif ($type eq 'Microarray_results_evidence') {
	$label = 'via microarray results evidence';
	push @cell,map {ObjectLink($_) } $type->col;
      } elsif ($type eq 'RNAi_evidence') {
	$label = 'via RNAi_evidence';
	push @cell,map {ObjectLink($_,$_->History_name ? $_ . ' (' . $_->History_name . ')' : $_) } $type->col;
      } elsif ($type eq 'Gene_regulation_evidence') {
	$label = 'via gene regulation evidence';
	push @cell,map {ObjectLink($_) } $type->col;
      } elsif ($type eq 'CGC_data_submission') {
	$label = 'via CGC data submission';
      } elsif ($type =~ /Inferred_automatically/i) {
	$label = 'inferred automatically';
	push @cell,map { $_ } $type->col;
      } elsif ($type eq 'Date_last_updated' && $include_timestamp) {
	($updated) = $type->col;
	$updated =~ s/\s00:00:00//;
      }

      if ($format eq 'table') {
	unless ($type eq 'Date_last_updated') {  # Format this seperately
	  $return .= 
	    TR(td($type),
			td(join(br,@cell)));
	}
      } else {
	# Convoluted formatting of returned string - sorry!
	my $string = $dont_tag ? '' : "$label";
	$string   .= ": " if @cell && $string ne '';
	$string .= join ("; ",@cell) if (@cell);
	push @row,$string if $string ne '';
      }
    }

    if ($format eq 'table') {
      $return .= TR({-class=>'updated'},td({-colspan => 2},"Last updated: $updated"));
      $return .= end_table();
    } else {
      my $stringified_row = (@row)
	? "$description " . '(' . join('; ',@row) . ')'
	  : $description;
      $stringified_row .= br . "Last updated: $updated" if $updated;
      push (@rows,$stringified_row);
    }
  }
  return $return if ($format eq 'table');
  return @rows;
}


sub get_PMID {
  my $paper = shift;
  my $pmid;
  if($paper->Database) {
    my @dbs = map {$_->col } $paper->Database;
    foreach my $db (@dbs) {
      if ($db == 'PMID') {
        $pmid = $db->right;
      }
    }
  }
  return $pmid;
}

# Generically display a link to evidence for any given piece of data

sub DisplayEvidenceLink {
  my @p = @_;
  my ($parent,$tag,$format) = rearrange(qw/TAG FORMAT/,@p);
  $format ||= 'popup';
  return unless (eval { $tag->col });
#  my $link = ObjectLink
}


# display_tag (off by default, pass boolean true to turn on display of node)
# link_tag (off by default, pass boolean true to turn on linking of tag)

# display_label


sub GetEvidenceNew {
  my @p = @_;
  my ($object,@rest) = rearrange([qw/OBJECT/],@p);
  
  my $data = ParseHash(-nodes=>$object);
  my $formatted = FormatEvidenceHash(-data=>$data,@p);
  return $formatted;
}


=pod

=item ParseHash(@params)

Generically parse an evidence, paper, or molecular info
hash from a node of an object tree.

Options

 -node  A node of an object tree (or an array reference of nodes)

If an array reference of nodes is passed, the resulting data structure
will be an array of structures.

Returns

 A data structure suitable for display with DisplayEvidenceHash or
 null if no Evidence hash exists to the right of the provided node.

=cut
#'    
    
# This is in the process of being deprecated.
# Really, all this is for is checking for the presence
# of a not tag

# Idiom: For ALL associated evidence hashes for a given object
# do ANY of them have a NOT tag?

sub ParseHash {
    my @p = @_;
    my ($nodes,@rest) = rearrange([qw/NODES/],@p);
    
    # Mimic the passing of an array reference. Blech.
    $nodes = [$nodes] unless ref $nodes eq 'ARRAY';
    
    # The data structure - a hash of hashes, each pointing to an array
    my $data = [];
    
    my $c;

    # Each node can have one or many evidence hashes. Oy vey.
    # Wrap them all into a data structure.

    # Collect all the hashes available for each node
    foreach my $node (@$nodes) {
#	print ++$c . ": $node" . br;
	# Save all the top level tags as keys in a perl
	# hash for easier parsing and formatting

	# Eeeks!  Detected bug where value was set to key. 
	# Switched so that it's ->right.  Is this correct?
#	my %hash = map { $_ => $_->right || 1 } eval { $node->col };

	# Just save the object.  Will get value later
	# Original
	# my %hash = map { $_ => $_ } eval { $node->col };
	#     my %hash = map { $_ => $_ } eval { $node->row }; # No!

       # This sorta works but I need to preserve the TYPE of evidence, too
#       my %hash = map { $_ => $_ } eval { $node->right->col };

       my %hash = map { $_ => $_ } eval { $node->col };

       # If it is a single hash, we need to check and see if it has a NOT key present
       my $is_not = 1 if (defined $hash{Not});  # Keep track if this is a Not Phene annotation
       push @{$data},{ node     => $node,
		       hash     => \%hash,
		       is_not => $is_not || 0,
		   };
   }
    return $data;
}


=pod

# Simplified evidence parsing and presention
# Usage:

my $types = get_evidence_types($object);
my $types = get_evidence_types($node);
print "evidence is " . join("-",@$types);
       print br . br;
       foreach (@$types) {
	   my $hashes = get_evidence_hashes($_);
	   print "hashes " . join("-",@$hashes);
	   print br . br;
       }


=cut

sub inline_evidence {
    my $object = shift;
    my $types = get_evidence_types($object);
	    
    my @strings;
    if (@$types) {
	foreach my $type (@$types) {
	    my $title = $type;
	    $title  =~ s/_/ /g;
	    
	    my $string .= "via $title: ";
	    
	    my $hashes = get_evidence_hashes($type);
	    $string .= join(", ", map { format_evidence($type,$_) } @$hashes);
	    push @strings,$string;
	}
	return join(" | ",@strings);
    }
  return "";
}




# Get all the evidence types for a node or nodes.
# These are top level tags like "Person_evidence"
sub get_evidence_types {
    my $node = shift;    
    my @types;
    foreach my $type ( eval { $node->col} ) {
#	print "Evidence type is: $type<br />";	   
#	print $type->col;
	push @types,$type;
    }
    return \@types;
}

sub get_evidence_hashes {
    my $type   = shift;
    my @hashes = $type->col;
    return \@hashes;
}


# DEPRECATED?
# Get all hashes to the right of a given node.
# { evidence_type => { evidence } };
sub get_hashes {
    my $node = shift;
    my @hashes = eval { $node->right->col };
    return \@hashes if @hashes;
    @hashes = eval { $node->col } unless @hashes;
    return \@hashes;
}    


sub FormatEvidenceHash {
  my @p = @_;
  my ($data,$format,$display_tag,$link_tag,$display_label,$detail) =
    rearrange([qw/DATA FORMAT DISPLAY_TAG LINK_TAG DISPLAY_LABEL DETAIL/],@p);

  my @rows;    # Each row in the table corresponds to an object (each row is stringified)
  my $join = ($format eq 'table') ? br : ', ';
  my $all_evidence = {};

  foreach my $entry (@$data) {
      my $hash  = $entry->{hash};
      my $node  = $entry->{node};

      # Conditionally format the data for each type of evidence

      # This is either
      # 1. A single hash, in which case $key is a type of evidence
      # 2. A list of hashes, in which case $key is a HASH
      
      foreach my $key (keys %$hash) {

	  # This is absurd.  At some point the data structure changed.
	  # The Type of evidence is really the key in the hash, not the value now.	  
	  my $type = $key;
#	  my $type = $hash->{$key};
	  my $value = $hash->{$type};

	  # Suppress the display of Curator_confirmed
	  next if $type eq 'Curator_confirmed';

	  # Just grab the first level entries for each.
	  # For the evidence hash, Accession_evidence and Author_evidence 
	  # have additional information
#	  my @sources = eval { $type->col };
	  my @sources = eval { $value->right };
#	  print "$type $value";
#	  print @sources;
	  
	  # Add appropriate markup for each type of Evidence seen
	  # Lots of redundancy here - first we parse the data, then add primary formatting
	  # then secondary formatting (ie table, etc)
	  # This could all be much cleaner (albeit less flexible) with templates
	  if ($type eq 'Paper_evidence') {
	      my @papers;
	      foreach my $paper (@sources) {
		  next unless $paper;  # Huh?
		  # Create a short-form citation...
		  my $citation = format_reference(-reference=>$paper,-format=>'inline_evidence');
		  push @papers,$citation;
	      }
	      
	      $data = join($join,@papers);
	  } elsif ($type eq 'Published_as') {
	      $data = join($join,map { ObjectLink($_,undef,'_blank') } @sources);
	  } elsif  ($type eq 'Person_evidence' || $type eq 'Curator_confirmed') {
	      $data = join($join,map {ObjectLink($_->Standard_name,undef,'_blank')} @sources);
	  } elsif  ($type eq 'Author_evidence')   {
	      $data = join($join,map { a({-href=>'/db/misc/author?name='.$_,-target=>'_blank'},$_) } @sources);
	  } elsif ($type eq 'Accession_evidence') {
	      foreach my $entry (@sources) {
		  my ($database,$accession) = $entry->row;
		  my $accession_links   ||= Configuration->Protein_links;  # misnomer
		  my $link_rule = $accession_links->{$database};
		  $data = $link_rule ? a({-href=>sprintf($link_rule,$accession),
					  -target=>'_blank'},"$database:$accession")
		      : ObjectLink($accession,"$database:$accession");
	      }	
	  } elsif ($type eq 'Protein_id_evidence') {
	      $data = join($join,map { a({-href=>Configuration->Entrezp},$_) } @sources);

	# Lots of generic entries that just need to be linked
      } elsif ($type eq 'GO_term_evidence' || $type eq 'Laboratory_evidence'||$type eq 'Variation_evidence') {
	$data = join($join,map {ObjectLink($_) } @sources);
      } elsif ($type eq 'Expr_pattern_evidence') {
	$data = join($join,map {ObjectLink($_) } @sources);
      } elsif ($type eq 'Microarray_results_evidence') {
	$data = join($join,map {ObjectLink($_) } @sources);
      } elsif ($type eq 'From_analysis') {
	  $data = join($join,map {ObjectLink($_) } @sources);
      } elsif ($type eq 'RNAi_evidence') {
	$data = join($join,map {ObjectLink($_,$_->History_name ? $_ . ' (' . $_->History_name . ')' : $_) } @sources);
      } elsif ($type eq 'Gene_regulation_evidence') {
	$data = join($join,map {ObjectLink($_) } @sources);
      } elsif ($type eq 'CGC_data_submission') {
      } elsif ($type =~ /Inferred_automatically/i) {
	$data = join($join,map { $_ } @sources);
      } elsif ($type eq 'Date_last_updated') {
	($data) = @sources;
	$data =~ s/\s00:00:00//;
      }
      
      $type =~ s/_/ /g;

	# Retain $node again since this is an object
      push @{$all_evidence->{$type}},
	{ type => $type,
	  data => $data,
	  node => $node,
	};
    }
  }
  
  # Format the evidence as requested
  my $return;
  if ($format eq 'table') {
      foreach my $tag (keys %$all_evidence) {
	  
	  my @evidence = @{$all_evidence->{$tag}};
	  my $table =
	      start_table()
	      . TR(th('Evidence type')
		   . th('Source'));
	  
	  my $count = 0;
	  foreach (@evidence) {
	      my $node = $_->{node};
	      
	      # Only need to do this for the first iteration
	      if ($count == 0) {
		  if ($display_tag) {
		      $link_tag = 1 if $node eq 'Evidence'; # hack for cases in which evidence is attached
		      my $description = $link_tag ? $node :
			  ref $node && $node->class eq 'Gene_name' ?
			  a({-href=>Object2URL(GeneName2Gene($node))},$node)
			  : ObjectLink($node);
		      $return .= $description;
		  }
		  $count++;
		  $return .= h3('Supported by:');
	      }
	      
	      my $type = $_->{type};
	      my $data = $_->{data};
	      $table .= TR(td({-valign=>'top'},$type),
			   td($data));
	  }
	  $table .= end_table();
	  $return .= $table;
      }
  } else {
      # Returning stringified form of evidence
      my @entries;
      foreach my $tag (keys %$all_evidence) {	
	my @evidence = @{$all_evidence->{$tag}};
	
	my $count = 0;	
	foreach (@evidence) {
	    my $node = $_->{node};
	    if ($count == 0) { # necessary on first iteration only. stoopid, I know
		if ($display_tag) {
		    $link_tag = 1 if $node eq 'Evidence'; # hack for cases in which evidence is attached
		    my $description = $link_tag ? $node :
			ref $node && $node->class eq 'Gene_name' ?
			a({-href=>Object2URL(GeneName2Gene($node))},$node)
			: ObjectLink($node);
		    $return .= $description;
		}
		$count++;
	    }
	    my $type = $_->{type};
	    my $data = $_->{data};
	    push @entries,($display_label) ? "via " . lc($type) . ': ' . $data : $data;
	}
    }
      $return .= join('; ',@entries);
  }
  return undef unless $return;
  return $return;
}

# SIMPLIFIED EVIDENCE HSH PARSING AND PRESENTATION
# Format a given piece of evidence
# join is unnecessary since I'm only dealing with single objects.
sub format_evidence {
    my ($type,$object) = @_;
    my $data;
    my $join = "";
    if ($type eq 'Paper_evidence') {
	# Create a short-form citation...
	my $citation = format_reference(-reference=>$object,-format=>'inline_evidence');
	return $citation;

    } elsif ($type eq 'Published_as') {
	$data = join($join,ObjectLink($object,undef,'_blank'));
    } elsif  ($type eq 'Person_evidence' || $type eq 'Curator_confirmed') {
	$data = join($join,ObjectLink($object->Standard_name,undef,'_blank'));
    } elsif  ($type eq 'Author_evidence')   {
	$data = join($join,a({-href=>'/db/misc/author?name='.$object,-target=>'_blank'},$object));
    } elsif ($type eq 'Accession_evidence') {
	my ($database,$accession) = $object->row;
	my $accession_links   ||= Configuration->Protein_links;  # misnomer
	my $link_rule = $accession_links->{$database};
	$data = $link_rule ? a({-href=>sprintf($link_rule,$accession),
				-target=>'_blank'},"$database:$accession")
	    : ObjectLink($accession,"$database:$accession");
    } elsif ($type eq 'Protein_id_evidence') {
	$data = join($join,a({-href=>Configuration->Entrezp},$object));
	
	# Lots of generic entries that just need to be linked
    } elsif ($type eq 'GO_term_evidence' || $type eq 'Laboratory_evidence') {
	$data = join($join,ObjectLink($object));
    } elsif ($type eq 'Expr_pattern_evidence') {
	$data = join($join,ObjectLink($object));
    } elsif ($type eq 'Microarray_results_evidence') {
	$data = join($join,ObjectLink($object));
    } elsif ($type eq 'From_analysis') {
	$data = join($join,ObjectLink($object));
    } elsif ($type eq 'RNAi_evidence') {
	$data = join($join,ObjectLink($object,$object->History_name
				      ? $object . ' (' . $object->History_name . ')' : $object));
    } elsif ($type eq 'Gene_regulation_evidence') {
	$data = join($join,ObjectLink($object)); 
    } elsif ($type eq 'CGC_data_submission') {
    } elsif ($type =~ /Inferred_automatically/i) {
	$data = $object;
    } elsif ($type eq 'Date_last_updated') {
	$data = $object;
	$data =~ s/\s00:00:00//;
    }
    
    return $data;
}



sub Best_BLAST_Table {
    my $protein = shift;  # ace object
    
    my @pep_homol = $protein->Pep_homol;
    my $length    = $protein->Peptide(2);
    
    # find the best pep_homol in each category
    my %best;
    return "no hits" unless @pep_homol;

    for my $hit (@pep_homol) {
	next if $hit eq $protein;         # Ignore self hits
	my ($method,$score) = $hit->row(1) or next;

	# HACK HACK HACK!
	# With WS196, the method for C. brenneri entries is "wublastp_worm".
	# This clobbers the C. elegans entries.
	# Fix this.
	my $species = ID2Species($hit);
	$species  ||= ID2Species($method);	
	$method = ($species =~ /brenneri/) ? 'wupblastp_brenneri' : $method;
	
	my $prev_score = (!$best{$method}) ? $score : $best{$method}{score};
	$prev_score = ($prev_score =~ /\d+\.\d+/) ? $prev_score .'0' : "$prev_score.0000";
	my $curr_score = ($score =~ /\d+\.\d+/) ? $score . '0' : "$score.0000";

	$best{$method} = {score=>$score,hit=>$hit,adjusted_score=>$curr_score} if !$best{$method} || $prev_score < $curr_score;	
    }
    
    foreach (values %best) {
	my $covered = _covered($_->{score}->col);
	$_->{covered} = $covered;
    }
    
    my $links = Configuration->Protein_links;
    
    my %seen;  # Display only one hit / species
    my $table = start_table({-border=>1,-width=>'100%'}) . TR(th(['Species','Hit','Description','BLAST E-value','% Length']));

    # I think the perl glitch on x86_64 actually resides *here*
    # in sorting hash values.  But I can't replicate this outside of a
    # mod_perl environment
    # Adding the +0 forces numeric context
    foreach (sort {$best{$b}{adjusted_score}+0 <=>$best{$a}{adjusted_score}+0 } keys %best) {
	my $method = $_;
	my $hit = $best{$_}{hit};

	# Try fetching the species first with the identification
	# then method then the embedded species
	my $species = ID2Species($hit);
	$species  ||= ID2Species($method);
	
	# Not all proteins are populated with the species 
	$species ||= $best{$method}{hit}->Species;
	$species =~ s/^(\w)\w* /$1. /;

	my $description = $best{$method}{hit}->Description || $best{$method}{hit}->Gene_name;
	if ($method =~ /worm|briggsae|remanei|japonica|brenneri|pristionchus/) {
	    $description ||= eval{$best{$method}{hit}->Corresponding_CDS->Brief_identification};
	    # Kludge: display a description using the CDS
	    if (!$description) {
		for my $cds (eval { $best{$method}{hit}->Corresponding_CDS }) {
		    next if $cds->Method eq 'history';
		    $description ||= "gene $cds";

		}
	    }
	}

	# Ignore mass spec hits
	next if ($hit =~ /^MSP/);

	# Ignore if we have already seen this species
#	next if ($seen{$species}++);
	
	if ($hit =~ /(\w+):(.+)/) {

	    my $prefix    = $1;
	    my $accession = $2;

	    # Try fetching accessions directly from the protein object
	    my @dbs = $hit->Database;
	    foreach my $db (@dbs) {
		if ($db eq 'FLYBASE') {
		    foreach my $col ($db->col) {
			if ($col eq 'FlyBase_gn') {
			    $accession = $col->right;
			    last;
			}
		    }
		}
	    }

	    my $link_rule = $links->{$prefix};

	    ### incorporate fix for H-invitational hits here
	    # to the tune of changing the url to http://www.jbirc.jbic.or.jp/hinv/spsoup/transcript_view?hit_id=HIT000038191 if 
	    # $hit contains  the string HIT
	    # work with Todd given that there are some caching considerations to deal with in implementing this fix.....
	    #####
	    
	    my $url       = sprintf($link_rule,$accession);
	    $hit = a({-href=>$url,-target=>'_blank'},$hit);

#	    # TH: 1/2006 - remanei not yet in the database but blast hits available
#	    # Generate links to the remanei browser
#	    # This will not work for mirror sites, of course...
#	    if ($species =~ /remanei/i) {
#		$hit .= br . i('Note: <b>C. remanei</b> predictions are based on an early assembly of the genome. Predictions subject to possibly dramatic revision pending final assembly. Sequences available on the <a href="ftp://ftp.wormbase.org/pub/wormbase/genomes/c_remanei">WormBase FTP site</a>.');
#	    }
	}
	$table .= TR(th({-align=>'right'},$species),
		     td($hit),
		     td($description),
		     td(sprintf("%7.3g",10**-$best{$_}{score})),
		     td(sprintf("%2.1f%%",100*($best{$_}{covered})/$length)));
    }
    $table .= end_table;
    return $table;
}


sub _covered {
    my @starts = @_;
    # linearize
    my @segs;
    for my $s (@starts) {
	my @ends = $s->col;
	# Major kludge for architecture-dependent Perl bug(?) in interpreting integers as strings
	$s = "$s.0";
	push @segs,map {[$s,"$_.0"]} @ends;
    }
    my @sorted = sort {$a->[0]<=>$b->[0]} @segs;
    my @merged;
    foreach (@sorted) {
	my ($start,$end) = @$_;
	if ($merged[-1] && $merged[-1][1]>$start) {
	    $merged[-1][1] = $end if $end > $merged[-1][1];
	} else {
	    push @merged,$_;
	}
    }
    my $total = 0;
    foreach (@merged) {
	$total += $_->[1]-$_->[0];
    }
    $total;
}

# Map a given ID to a species (This might also be a method instead of an ID)
# Because of recpirocal BLASTing with elegans and briggsae and database XREFs
# always try to use the ID of the hit first when doing identifications
sub ID2Species {
  my ($id) = @_;

  # Ordered according to (guesstimated) probability
  return 'Caenorhabditis briggsae'   if ($id =~ /WP\:CBP/i || $id =~ /briggsae/ || $id =~ /^BP/);
  return 'Caenorhabditis elegans'    if ($id =~ /worm/i || $id =~ /^WP/);
  return 'Caenorhabditis remanei'    if ($id =~ /^RP\:/i || $id =~ /remanei/) ;  # Temporary IDs for C. remanei
  return 'Caenorhabditis brenneri'   if ($id =~ /^CN\:/i) ;
  return 'Caenorhabditis japonica'   if ($id =~ /^JA\:/i) ;
  return 'Drosophila melanogaster'   if ($id =~ /fly.*\:CG/i);
  return 'Drosophila pseudoobscura'  if ($id =~ /fly.*\:GA/i);
  return 'Saccharomyces cerevisiae'  if ($id =~ /^SGD/i || $id =~ /yeast/);
  return 'Schizosaccharomyces pombe' if ($id =~ /pombe/);
  return 'Homo sapiens'              if ($id =~ /ensembl/ || $id =~ /ensp\d+/);
  return 'Rattus norvegicus'         if ($id =~ /rgd/i);
  return 'Anopheles gambiae'         if ($id =~ /ensang/i);
  return 'Apis mellifera'            if ($id =~ /ensapmp/i);
  return 'Canis familiaris'          if ($id =~ /enscafp/i);
  return 'Danio rerio'               if ($id =~ /ensdarp/i);
  return 'Dictyostelium discoideum'  if ($id =~ /ddb\:ddb/i);
  return 'Fugu rubripes'             if ($id =~ /sinfrup/i);
  return 'Gallus gallus'             if ($id =~ /ensgalp/i);
  return 'Mus musculus'              if ($id =~ /mgi/i);
  return 'Oryza sativa'              if ($id =~ /^GR/i);
  return 'Pan troglodytes'           if ($id =~ /ensptrp/i);
  return 'Plasmodium falciparum'     if ($id =~ /pfalciparum/);
  return 'Tetraodon nigroviridis'    if ($id =~ /gstenp/i);
  return 'Pristionchus pacificus'    if ($id =~ /PP\:/);
}


# Reformat IDs and map them to correct URLs
sub Species2URL {
  my ($species,$id) = @_;

  # Oryza sativa
  if ($species =~ /oryza/i) {
      $id =~ s/^GR\://;
      # Plasmodium falciparum
#  } elsif ($species =~ /sapiens/) {

  } elsif ($species =~ /pfalciparum/) {
    $id =~ s/GeneDB_Pfalciparum://g;
    # S. cervisiae
  } elsif ($species eq 'Saccharomyces cerevisiae') {
    $id =~ s/SGD\://g;
  } elsif ($id =~ /fly/i) {
    $id =~ s/FLYBASE://g;
    $id =~ s/CG//i;
    $id =~ s/GA//i;
    $id = sprintf("%07d",$id);
    # S. pombe
  } elsif ($species =~ /Schizosaccharomyces/) {
    $id =~ s/GeneDB_Spombe://g;
  } elsif ($species =~ /dictyostelium/i) {
    $id =~ s/^DDB://;
  } elsif ($id =~ /RefSeq/i) {
    $id =~ s/REFSEQ://;
    $species = 'refseq';
  } elsif ($id =~ /ENSEMBL/) {
    $id =~ s/ENSEMBL\://g;
    my $url = Configuration->Species_to_url->{ensembl};
    $species =~ s/ /_/g;
    return (sprintf($url,$species,$id));
  }

  my $url = Configuration->Species_to_url->{$species};
  return (sprintf($url,$id)) if $url;
}


sub MultipleChoices {
  my ($symbol,$objects,$term,$tag) = @_;
  if (ref $symbol eq 'ARRAY') {
    $objects = $symbol;
    $symbol  = url_param('name') || param('name');
  }
  if ($objects && @$objects == 1) {
    my $destination = Object2URL($objects->[0]);
    AceHeader(-Refresh => "1; URL=$destination");
    print start_html (
			   '-Title' => 'Redirect',
			   '-Style' => Style(),
			),
      h1('Redirect'),
      p("Automatically transforming this query into a request for corresponding object",
	ObjectLink($objects->[0],$objects->[0]->class.':'.$objects->[0])),
      p("Please wait..."),
      Footer(),
      end_html();
    return;
  }

  PrintTop(undef,undef,'Multiple Choices');
  print
    p(qq/Multiple objects correspond to "$symbol."/,
      "Please choose one:");

  # Create a multiple choices display for genes
#  if ($symbol eq 'gene') {
#
#  }
  $symbol = $term || url_param('name') || $symbol;
  print ol(
       li(
	  [
	   map {
	     my $url = Object2URL($_);
	     # $url   .= ';multiple=1';
	     # De-emphasize WBGene IDs
	     if ($_->class eq 'Gene') {
		 # Append a brief description from the KOG...
		 my $temp = $_->Concise_description || $_->Provisional_description;
		 my $desc = substr($temp,0,60);
		 $desc =~ s/(.*)\s.*/$1/;
		 $desc ||= '';

		 # Display the Public_name first
		 # and in parenthesis the Sequence_name and CGC_name (whichever is not the Public_name)

		 a({-href=>$url},font({-color=>'red'},$_->class) . ': '
		   . b($_->Public_name)
		   . ' ('
		   #		 . ($_->Sequence_name ? join("; ",$_->Sequence_name) . '; ' : '')
		   #		 . ($_->CGC_name ? join("; ",$_->CGC_name) . '; ' : '')
		   . (($_->Sequence_name && $_->Sequence_name ne $_->Public_name) ? $_->Sequence_name . '; ' : '')
		   . (($_->CGC_name && $_->CGC_name ne $_->Public_name) ? $_->CGC_name . '; ' : '')
		   . ($_->Other_name ? join("; ",$_->Other_name) . '; ' : '')
		   . $_ 
		   . ($desc ? ": $desc...)" : ')'));
	
		 } else {
		   if ($tag) {
		     a({-href=>$url},font({-color=>'red'},$_->class).': ' . $_ . '-' . $_->$tag)
		   } else {
		     a({-href=>$url},font({-color=>'red'},$_->class).': '.$_)
		   }
		 }
	   }
	   # Sloppy. Some lists may not be made of genes
	   sort { eval { lc($a->Public_name)}  cmp eval { lc($b->Public_name) } }
	   @$objects
	  ]
	 )
      );
  PrintBottom();
}

sub StartDataTable {
  print start_table({-border=>1,-width=>'100%'});
}

sub EndDataTable {
  EndSection() if $SECTION;
  print end_table();
}

sub StartSection {
  my $caption = shift;
  if ($SECTION) {
    EndSection();
    undef $SECTION;
  }
  print start_Tr({-class=>'databody',-valign=>'top'}),
    th({-colspan=>2,-class=>'searchtitle'},
       a({-name=>$caption},$caption)),start_td(),"\n",start_table({-cellpadding=>0,-cellspacing=>4,-border=>0});
  $SECTION++;
  $ROWS_PRINTED = 0;
}

sub EndSection {
  print Tr(td('&nbsp;')) unless $ROWS_PRINTED;  #netscape workaround
  undef $SECTION;
  print end_table(),"\n",end_td(),end_Tr();
}

sub SubSection {
  return unless defined $_[1];
  PrintMultiple(@_);
  $ROWS_PRINTED++;
}

# (useful if creating tables of disparate information linked/sorted in advance).
# Pass an explicit value for the number of columns to prevent them from spreading across page.
# Pass true to prevent linking
sub Tableize {
  my $list    = shift;
  my $no_link = shift;
  my $columns = shift;
  return unless @$list;
  my $rows = int(sqrt(@$list)) || 1;
  my $table;
  if ($columns) {
    $table = CGI::_tableize(undef,$columns,undef,undef,map {$no_link ? $_ : ObjectLink($_)} @$list);
  } else {
    $table = CGI::_tableize($rows,undef,undef,undef,map {$no_link ? $_ : ObjectLink($_)} @$list);
  }
  $table;
}





# Site wide reference formatting
# *_link should be one of id, generic, or image
# which controls the nature of the linked text
sub format_reference {
  my (@p) = @_;
  my ($paper,$format,$pubmed_link,$cgc_link,$wbpaper_link,$curator)
    = rearrange([qw/REFERENCE FORMAT PUBMED_LINK CGC_LINK WBPAPER_LINK CURATOR/],@p);
  my @authors    = eval { $paper->Author };
  my $authors    = @authors <= 2 ? (join ' and ',@authors) : "$authors[0] et al.";

  my $year       = parse_year($paper->Publication_date);
  my $short_form = "$authors: $year";
  my $title   = $paper->Title;

  # Short form: Authors
  return a({-href=>Object2URL($paper)},$authors) if ($format eq 'short');


  # inline_evidence form: Authors, Year (PMID image)
  # Hackish.  Duplicated code below.
  if ($format eq 'inline_evidence') {
      ## Does this paper also have a PMID?
      my $pmid = get_PMID($paper);
      if ($pmid) {
	      return a({-href=>Object2URL($paper)},"$authors, $year" ) . " " .
		  a({-href=>Configuration->Pubmed_retrieve . $pmid,-target=>'_blank'},
		    img({-src=>'/images/pubmed_button.gif'}));
	  
	  } else {
	      return a({-href=>Object2URL($paper)},"$authors, $year");
	  }
  }


  # If this is a WormBook paper, link to WormBook via the Remark.  Yuck.
  if ($title eq 'WormBook') {
      my $remark = $_->Remark;
      $title = a({-href=>$remark},$title);
  }

  my $cit     = $paper->Journal;
  $cit       .= ' ' . b($paper->Volume) if $paper->Volume;
  my @pages = ($paper->Page->row) if ($paper->Page);
  $cit       .= ': ' . join('-',@pages) if @pages;


      my $pubmed;
      my $pmid = get_PMID($paper);
      # Add a pubmed link if necessar
      if ($pmid&& $pubmed_link) {
	  if ($pubmed_link eq 'generic') {
	      $pubmed = a({-href=>Configuration->Pubmed_retrieve . $pmid},'[PubMed]');
	  } elsif ($pubmed_link eq 'id') {
	      $pubmed = a({-href=>Configuration->Pubmed_retrieve . $pmid},"[PubMed-" . $pmid . "]");
	  } elsif ($pubmed_link eq 'image') {
	      $pubmed = a({-href=>Configuration->Pubmed_retrieve . $pmid,-target=>'_blank'},
			  img({-align=>'middle',-src=>'/images/pubmed_button.gif'}));
	  }
      }


  # There is no extra informational content here
  # my $cgc;
  # if ($paper->CGC_name && $cgc_link) {
  #    if ($cgc_link eq 'generic') {
  #      $cgc = a({-href=>Object2URL('[' . $paper->CGC_name . ']','paper')},'[CGC]');
  #    } elsif ($cgc_link eq 'id') {
  #      $cgc = a({-href=>Object2URL('[' . $paper->CGC_name . ']','paper')},"[" . $paper->CGC_name . "]");
  #    } elsif ($cgc_link eq 'image') {
  #      $cgc = a({-href=>Object2URL('[' . $paper->CGC_name . ']','paper')},
  #	       img({-align=>'middle',-src=>'/images/cgc_button.gif'}));
  #    }
  #  }

#  my $wormbook_chapter;
#  if ($wbpaper_link) {
#    if ($wbpaper_link eq 'generic') {
#      $wbpaper = a({-href=>Object2URL($paper)},'[WormBase Curated Paper]');
#    } elsif ($wbpaper_link eq 'id') {
#      $wbpaper = a({-href=>Object2URL($paper)},"[$paper]");
#    } elsif ($cgc_link eq 'image') {
#      $wbpaper = a({-href=>Object2URL($paper)},
#		   img({-align=>'middle',-src=>'/images/wb_button.gif'}));
#    }
#  }

  my $wbpaper;
  if ($wbpaper_link) {
    if ($wbpaper_link eq 'generic') {
      $wbpaper = a({-href=>Object2URL($paper)},'[WormBase Curated Paper]');
    } elsif ($wbpaper_link eq 'id') {
      $wbpaper = a({-href=>Object2URL($paper)},"[$paper]");
    } elsif ($cgc_link eq 'image') {
      $wbpaper = a({-href=>Object2URL($paper)},
		   img({-align=>'middle',-src=>'/images/wb_button.gif'}));
    }
  }

  my $ids;

  # (but this curator specific view is deprecated anyways
  my $pmid = get_PMID($paper);
      if ($curator) {
	  my @temp = (
	      ($pmid) ? 
	      a({-href=>Configuration->Pubmed_retrieve . $pmid},"[PubMed-" . $pmid . "]") : '',
	      ($paper->Name)
	      ? a({-href=>Object2URL($paper->Name,'paper')},"[" . $paper->Name . "]") : '',
	      a({-href=>Object2URL($paper)},"[$paper]"));
	  $ids = join(' ',@temp);
      }
  return ObjectLink($paper,$short_form . i(". $title") . " $cit. $pubmed $wbpaper $ids")
}

# Generate a data structure of formatted references keyed by year released
sub format_references {
  my @p = @_;
  my ($references,$format,$pubmed_link,$cgc_link,$wbpaper_link,$suppress_years,$curator)
    = rearrange([qw/REFERENCES FORMAT PUBMED_LINK CGC_LINK WBPAPER_LINK SUPPRESS_YEARS CURATOR/],@p);
  my (%seen,%sorted);
  foreach (@$references) {
    next if defined $seen{$_};
    $seen{$_}++;
    my $year = parse_year($_->Publication_date);
    push @{$sorted{$year}},$_;
  }
  my @formatted;
  foreach (sort {$b<=>$a} keys %sorted) {
    my @refs = sort {$a->Author cmp $b->Author} @{$sorted{$_}};

    if ($suppress_years) {
      push (@formatted,map {
	format_reference(-reference=>$_,-format=>$format,-pubmed_link=>$pubmed_link,-curator=>$curator);
      } @refs);
    } else {
      SubSection($_,
		 map {
		   format_reference(-reference=>$_,-format=>$format,-pubmed_link=>$pubmed_link,-curator=>$curator);
		 } @refs
		);
    }
  }
  return @formatted if $suppress_years;
}



  

sub build_citation {
    my @p = @_;
    my ($paper,$object,$include_images,$include_externals,$format) = 
	rearrange([qw/PAPER OBJECT INCLUDE_IMAGES INCLUDE_EXTERNALS FORMAT/],@p);

    $paper or return;
    
    my $authors;
    if ($format eq 'long') {
	my @authors;
	foreach my $author ($paper->Author) {
	  my $obj = $author;
	  foreach my $col ($author->col) {
	    if($col eq 'Person') {
	      $obj = $col->right;
	    }
	  }
	  push(@authors,a({-href=>Object2URL($obj)},$author));
	}
	$authors = join(', ',@authors);
    } else {
	my @authors = $paper->Author;
	$authors = @authors <= 2 ? (join ' and ',@authors) : "$authors[0] et al.";
    }

    my @affil     = $paper->Affiliation;

    # The paper or chapter title
    my ($title)   = $paper->Title;
    $title =~ s/\.*$//;
    
    # The journal title
    my ($journal) = $paper->Journal;

    # the worm meetings don't have a journal
    $journal ||= 'Meeting abstract' if $paper->Meeting_abstract;

#     fix a bug in some data records    
    if ($paper->Gazette_article) {
	$journal ||= "Worm Breeder's Gazette";
#	my $target = CGI::escape ("[" . $paper->Name . "]");
	my $target = $paper->Name;
	$journal = a({ -href=>Configuration->Wbg . $target, -target => '_blank'},$journal);
    }

    # Volume
    my ($volume)  = $paper->Volume;
    $volume = "$volume:" if $volume;

    # Pages
    my $pages  = join('-',$paper->Page->row) if $paper->Page;
    
    
    my $citation;
    # Establish links back to WormBase, PubMed and WormBook if requested
    my $wormbook_links;
    if ($include_externals) {
	my @links;
	if ($include_images) {
           
	    # WormBase
	    push @links, a({-name=>$paper,-href=>Object2URL($paper)},img({-src=>'/images/wb_button.gif'}));

# Link to PMID
            my $pmid = get_PMID($paper);
	    push @links,a({-href=>Configuration->Pubmed_retrieve . $pmid},
			      img({-src=>'/images/pubmed_button.gif'})) if $pmid;


	    if ($paper->Type eq 'WormBook') {
		my $term = ($object && $object->class eq 'Gene') ? Bestname($object) : param('name');
		# Screwy hack.  We really only want to pass terms that WormBook indexes
		$term = undef unless ($object);
		my ($wormbook,$chapter,$occurrences_by_chapter,$total_occurrences) 
		    = GenerateWormBookLinks(-obj => $paper,-term => $term);
		push @links,$chapter;
		if ($occurrences_by_chapter) {
		    $wormbook_links = join(br,
					   $occurrences_by_chapter,
					   #$total_occurrences
					   );
		}
	    }	    
	} else {
	    push @links,a({-name=>$paper,-href=>Object2URL($paper)},"[" . $paper . "]");
	}
	$citation = join(' ',@links) . br;
    }
    
    # Parse the Paper hash if this is a book citation
    my %parsed;
    if ($paper->Book || $paper->WormBook) {
	my $data = ParseHash(-nodes=>$paper->Book);
	# There should be only a single node...
	# Piggybacking on some pre-existing code

	foreach my $node (@{$data}) {
	    my $hash = $node->{hash};
	    foreach (qw/Title Editor Publisher Year/) {
		$parsed{$_} = $hash->{$_} =~ /ARRAY/ ? join(', ',@{$hash->{$_}}) : $hash->{$_};
	    }
	    last;
	}
    }
    
    my $year = parse_year($paper->Publication_date) || $parsed{Year};
    my $short_form = "$authors $year";
    return $short_form if $format eq 'short';
    
    if ($paper->WormBook) {
        my $doi = $paper->Name;
	$citation .= qq{$authors.<br>$year. $title. In: $parsed{Editor}, eds. $parsed{Title}, doi/$doi, <a href="http://www.wormbook.org">http://www.wormbook.org</a>.};
    } elsif ($paper->Book){
        $citation .= "$authors.<br>$year. $title. In: $parsed{Editor}. $parsed{Title}$pages.";
    } else {
	$citation .= "$authors.<br>$year. $title. $journal $volume$pages."; 
    }

    $citation .= br . join(', ',@affil) if @affil;
    if ($wormbook_links) {
	$citation .= div({-class=>'wormbook_box'},$wormbook_links);
    } else {
	$citation .= br;
    }
    
    return $citation;
}


# Filter references according to their category
# where categories are
#		 'ALL' => 'All Papers',
#		 'WBG' => 'Worm Breeders Gazette Abstracts',
#		 'CGC' => 'Papers in WormBase Bibliography',
#		 'WMA' => 'Worm Meeting Abstracts',
#		 'WB'  => 'WormBook Chapters',
# ... and return an array of paper objects
sub filter_references {
    my ($refs,$category) = @_;
    # filter the  references according to the pattern
    my @filtered;
    if ($category eq 'ALL') {
	@filtered = @$refs;
    } elsif ($category eq 'WBG') {
	@filtered = grep { $_->Gazette_article } @$refs;
    } elsif ($category eq 'CGC') {
        @filtered = grep { $_->Journal_article || $_->Letter || $_->Review || $_->Retracted_publication || $_->Published_erratum} @$refs;
    } elsif ($category eq 'WMA') {
	@filtered = grep { $_->Meeting_abstract } @$refs;
    } elsif ($category eq 'WB') {
	@filtered = grep {$_->WormBook} @$refs;
    }
    return @filtered;
}

sub filter_and_display_references {
    my ($references,$source,$object,$class) = @_;
    my %all_bib_patterns = %{Configuration()->Bibliography_patterns};
    # Some opaque processing here. We are typing references using categories
    # that are specified in elegans.pm and used in biblio and here.   Sorry, just expedient
    
    my %bib_patterns;
    if ($source) {
	%bib_patterns = ($source => 1);
    } else {
	%bib_patterns = %all_bib_patterns;
    }
    foreach (keys %bib_patterns) {
	next if $_ eq 'ALL';  # Small performance tweak. Already have this value
	my @refs = filter_references($references,$_);
	if (@refs) {
	    SubSection($all_bib_patterns{$_},
		       a({-href=>"/db/misc/biblio?name=$object;class=$class;category=$_"},
			 scalar @refs . ' [view all]'));
	}
    }
}



sub AlleleDescription {
    my $allele = shift;
    my @desc;
    push @desc,GetEvidenceNew(-object => $allele->Phenotype_remark,
			      -format => 'inline',
			      -display_label => 1);
    push @desc,GetEvidenceNew(-object => $allele->Remark,
			      -format => 'inline',
			      -display_label => 1);
    return unless @desc;
    return join(br,@desc); # . '.'; Don't add punctuation, Mary Ann does
}



########################################
#    Phenotype processing
########################################
sub MutantPhenotype {
  my $gene = shift;
  # fetch the description (phenotype) lines
  my @description = $gene->Legacy_information or return;

  my @xref = $gene->Allele;
  push @xref,$gene->Strain;

  # cross-reference laboratories
  foreach my $d (@description) {
    $d =~ s/;\s+([A-Z]{2})(?=[;\]])
      /"; ".ObjectLink($1,undef,'Laboratory')
	/exg;

    # cross-reference genes
    $d =~ s/\b([a-z]+-\d+)\b
      /ObjectLink($1,undef,'Locus')
	/exg;

    # cross-reference other stuff
    my %xref = map {$_=>$_} @xref;
    $d =~ s/\b(.+?)\b/$xref{$1} ? ObjectLink($xref{$1}) : $1/gie;
  }
  @description;
}


########################################
#    Phenotype ontology
########################################
# Pick the best display new for new Phenotype-ontology objects
# and append a short name if one exists
sub best_phenotype_name {
  my $phenotype = shift;
  my $name = ($phenotype =~ /WBPheno.*/) ? $phenotype->Primary_name : $phenotype;
  $name =~ s/_/ /g;
  my $short_name = eval{$phenotype->Short_name;};
  $name .= ' (' . $short_name . ')' if  $short_name;
  return $name;
}


## Data is a collection of one or more phenotype
## hashes with top-level tags already extracted
sub FormatPhenotypeHash {
    my @p = @_;
    my ($data,$phenotype) =
	rearrange([qw/DATA PHENOTYPE/],@p);
    
    my $join = '; ';
    
    # These tags have a single entry following them
    # They should *not* have any evidence hashes, either
    # The contents of these entries can be fetched as
    # $tag->col
    my %evidence_only = map { $_ => 1 }
    qw/
	Not
	Recessive
	Semi_dominant
	Dominant
	Haplo_insufficient
	Paternal
	/;
    
    my %simple = map { $_ => 1 }
    qw/
	Quantity_description
	Remark
	/;
    
    my %nested = map { $_ => 1 }
    qw/ 
	Penetrance
	Quantity
	Loss_of_function
	Gain_of_function
	Other_allele_type
	Temperature_sensitive
	Maternal
	Phenotype_assay
	/;
    
    my %is_row = map { $_ => 1 } qw/Quantity Range Penetrance/;
    
    # Prioritize display of tags
    my @tags = qw/
	Not
	Penetrance Recessive Semi_dominant Dominant
	Haplo_insufficient
	Loss_of_function
	Gain_of_function
	Other_allele_type
	Temperature_sensitive
	Maternal
	Paternal
	Phenotype_assay
	Quantity_description
	Quantity
	Paper_evidence
	Person_evidence
	Remark
	/;

# disabled for now
#	Curator_confirmed
    my $return;
    foreach my $entry (@$data) {
	my $table =
	    start_table({-width=>'100%',-border=>1});
	my $hash  = $entry->{hash};
	my $node  = $entry->{node};   # Node is the originating object
	
	# Debug
#	foreach (keys %$hash) {
#	    print $hash->{$_} . br;
#	}

	$table .= start_TR().
	    td({-colspan => '3'},
	       b(ObjectLink($node,best_phenotype_name($node) . " ($node)")));
	
	$table .= TR(th(''),th('Note/Value'),th('Evidence')) if (keys %$hash > 0);
	
	foreach my $tag (@tags) {
            #  next unless (my $tag = $hash->{$tag_priority});
	    next unless (defined $hash->{$tag});
	    
	    my $formatted_tag = $tag;
	    $formatted_tag =~ s/_/ /g;
	    
	    # Fetch the first entries to the right of each tag
#	    my @sources = eval { $tag->col || $tag->right || $hash->{$tag} };
	    my @sources = $hash->{$tag};
	    @sources = eval { $tag->col } unless @sources;

	    # Add appropriate markup for each tag seen
	    # Lots of redundancy here - first we parse the data, then add primary formatting
	    # then secondary formatting (ie table, etc)
   
	    if ($tag eq 'Paper_evidence') {
		my @papers;
		foreach my $paper (@sources) {
		    next unless $paper;  # Huh?
		    # Create a short-form citation...
		    my $citation = format_reference(-reference=>$paper->right,-format=>'inline_evidence');
		    push @papers,$citation;
		}
		$table .= TR(td($formatted_tag),td(''),td(join(br,@papers)));
		
	    } elsif  ($tag eq 'Person_evidence' || $tag eq 'Curator_confirmed') {
		$table .= TR(td($formatted_tag),
			     td(),
			     td(
				join(br,
				     map {ObjectLink($_->right->Standard_name,undef,'_blank')} @sources)));
	    } elsif (defined $evidence_only{$tag}) {
		$table .= TR(td($formatted_tag),td(),td(
						   join('; ',
							GetEvidenceNew(-object => $tag,
								       -format => 'inline',
								       -display_label => 1))));
		} elsif (defined $simple{$tag})  {
		#print @sources;
		$table .= TR(td($formatted_tag),
			     td(join(br,map{$_->right} @sources)),
			     td(join(br,map { GetEvidenceNew(-object       => $_,
						     -format       => 'inline',
						     -display_label => 1,
						     -link_tag      => 0)} map{$_->right} @sources )));
		
	    } elsif ($tag eq 'Phenotype_assay') {
		# Step into the Phenotype_assay object, displaying select tags.
		if (@sources) {
		    $table .= start_TR() . td($formatted_tag);
		    my ($cell,$evidence);
		    foreach my $condition (@sources) {
			my $data = $condition->right;
			if ($data) {
			    my ($evi) =  GetEvidenceNew(-object       => $data,
							-format       => 'inline',
							-display_label  => 1,
							-link_tag     => 0);
			    $evidence .= $evi;
			}
			$cell .= br . "$condition: $data";
		    }
		    
		    $table .= td($cell);
		    $table .= td($evidence);
		    $table .= end_TR();
		}
		# Handle tags that contain substructure


		# This is broken at the moment.
		# Really need to reformat everything.
		# I hate the hash parsing routines.
	    } 
	     elsif (defined $nested{$tag}) {
#		my @subtags = $node->$tag->col;
		my @subtags = eval { $node->col };
		
		@subtags = @sources if $tag eq 'Quantity';
		
		$table .= start_TR();
		
		my @cells;
		foreach my $subtag (@subtags) {
		    # Ignore the value if we have an Evidence hash
		    # to the right. All set to fetch evidence
		    my ($value,$evi);
		    my $evidence;
		    eval {$evidence = $subtag->right;};
		    
		    if ($evidence =~ /evidence/) {   
			($evi) = GetEvidenceNew(-object           => $subtag,
						-format        => 'inline',
						-display_label => 1);
		    } else {
			# HACK - Range and Quantity are rows
			if (defined ($is_row{$subtag})) {  
			    
			    my (@values) = $subtag->row;
			    # Fetch evidence off the end of the row
			    # This is total hack
			    ($evi) = GetEvidenceNew(-object        => $values[2],
						    -format        => 'inline',
						    -display_label => 1);
			    $value = join("-",$values[1],$values[2]);
			    $value = '100%' if $value eq '100-100';
			} else {
			    $value = $subtag->right;
			    ($evi) = GetEvidenceNew(-object        => $value,
						    -format        => 'inline',
						    -display_label => 1);
			}
		    }
		    
		    $subtag =~ s/_/ /g;
		    
		    $table .= td(($formatted_tag ne $subtag ? "$formatted_tag: $subtag"
				  : $subtag));
		    $table .= td($value);
		    $table .= td($evi);
		    $table .= end_TR();
		}
	    }
	};
	$table .= end_table();
	$return .= $table . br;
    }
    return $return;
}

sub DisplayPhenotypes {
    my @phenotypes = @_;
    
    my $positives = [];
    my $negatives = [];
    
    my $data = ParseHash(-nodes => \@phenotypes);
    ($positives,$negatives) = is_NOT_phene($data);

    SubSection('',
	       div({-style=>'background-color:#E7E7E7; padding:5px; border:1px dotted black;'},
		   'The following phenotypes were observed in this experiment.',
	       FormatPhenotypeHash(-data      => $positives))) if @$positives > 0;
    
    SubSection('',
	       (@$positives > 0) ?  hr : '',
	       div({-style=>'background-color:#E7E7E7; padding:5px; border:1px dotted black; opacity:0.6'},
	       'The following phenotypes were <b>NOT</b> observed in this experiment.',
	       FormatPhenotypeHash(-data      => $negatives))) if @$negatives > 0;    
}

sub DisplayPhenotypeNots {

	my @phenotypes = @_;
    
    my $positives = [];
    my $negatives = [];
    
    my $data = ParseHash(-nodes => \@phenotypes);
    ($positives,$negatives) = is_NOT_phene($data);

    SubSection('',
	       div({-style=>'background-color:#E7E7E7; padding:5px; border:1px dotted black;'},
		   'The following phenotypes were NOT observed in this experiment.',
	       FormatPhenotypeHash(-data      => $positives))) if @$positives > 0;
    
    SubSection('',
	       (@$positives > 0) ?  hr : '',
	       div({-style=>'background-color:#E7E7E7; padding:5px; border:1px dotted black; opacity:0.6'},
	       'The following phenotypes were <b>NOT</b> observed in this experiment.',
	       FormatPhenotypeHash(-data      => $negatives))) if @$negatives > 0;    

}



# Determine which of a list of Phenotypes are NOTs
sub is_NOT_phene {
    my ($data) = shift;
    my $positives = [];
    my $negatives = [];
    
    foreach my $entry (@$data) {

	if ($entry->{is_not}) {
	    push @$negatives,$entry;
	} else {
	    push @$positives,$entry;
	}
	
    }
#    return $is_not;
    return ($positives,$negatives);
}



##################################################
# ANATOMY ONTOLOGY
##################################################
sub FetchAnatomyTerm {
  my ($query,$db) = @_;
  my @anat_terms;
  # ?Anatomy_term should be in the form of WBbt:1234567
  if ($query =~ /^WBbt:/) {
      @anat_terms = $db->fetch(Anatomy_term => $query);
  } elsif (my @anat_names = $db->fetch(Anatomy_name => $query)) {
      @anat_terms = map { $_->Name_for_anatomy_term || $_->Synonym_for_anatomy_term } @anat_names;
  } else {
      # Finally try generically searching the Anatomy_term class
      # First try searching terms via an ace query, then fetching objects for each result individually
      # There has GOT to be a better way.
      my $clean = $query;
      $clean =~ s/^\*//;
      $clean =~ s/\*$//;
      my $ace_query = 'select a,a->Term from a in class Anatomy_term where a->Term like "*' . $clean . '*"';
      my @tmp = $db->aql($ace_query);
      my @objs = map { $db->fetch(Anatomy_term=>$_->[0]) } @tmp;
      
      # do a full database grep
      push(@objs,$db->grep(-pattern=>$query,-long=>1)) unless (@objs);
      my %seen;
      @anat_terms = grep {!$seen{$_}++} grep {$_->class eq 'Anatomy_term'} @objs;
  }
  return \@anat_terms;
}







#####################################################
#  Gene Ontology
#####################################################
sub DisplayGeneOntologySearch {
    my $url = url(-absolute=>1);
#  my @values = qw/go_term gene motif definition phenotype expression anatomy pseudogene homology cell reference/;
    my @values = qw/go_term gene motif definition phenotype/;
    my %search_by = (gene   => 'Gene ' 
		     . '('
		     . a({-href=>"$url?name=unc-26;class=Gene"},'unc-26')
		     . '; '
		     . a({-href=>"$url?name=T20H4.4;class=Gene"},'T20H4.4')
		     . ')',
		     'go_term' => 'GO ID ' . '(' . a({-href=>"$url?name=GO:0004437;class=GO_term"},'GO:0004437') . ')',
		     'definition' => 'Description '
		     . ' (' . a({-href=>"$url?name=endocytosis;class=definition"},'endocytosis') . ')',
		     'motif' => 'Motif ' . '(' . a({-href=>"$url?name=SH3;class=Motif"},'SH3') . ')',
		     'phenotype' => 'Phenotype',
		     );
    #		   'expression' => 'Expression pattern',
    #		   'phenotype'  => 'Phenotype',
    #		   'anatomy'    => 'Anatomy ontology term',
    #		   'pseudogene' => 'Pseudogene',
    #		   'homology'   => 'Homology group',
    #		   'cell'       => 'Cell',
    #		   'reference'  => 'Reference'
    
    my %limit_to = (
		    Gene           => 'Genes',
		    CDS            => 'CDS',
#		    Transcript     => 'Transcripts',
#		    Pseudogene     => 'Pseudogenes',
		    Motif          => 'Motifs',
#		    Expr_pattern   => 'Expression patterns',
#		    Homology_group => 'Homology groups',
#		    Anatomy_term   => 'Anatomy ontology',
#		    Cell           => 'Cells',
#		    Reference      => 'Publications',
		    Phenotype       => 'Phenotypes',);
    
    autoEscape(0);
    print hr;
    print table({-width=>'100%'},
		start_form(),
		TR({-class=>'searchtitle'},
		   th('Query Term or ID'),
#		 th('Search By'),
		   th('Aspect'),
		   th('Limit To Terms Attached To'),
		   th('')),
		TR({-class=>'searchbody',-align=>'center'},
		   td(
		      i('Enter a gene ontology ID ('
			. a({-href=>"$url?name=GO:0004437;class=GO_term"},'GO:0004437')
			. '), a gene ('
			. a({-href=>"$url?name=unc-26;class=Gene"},'unc-26')
			. '; '
			. a({-href=>"$url?name=T20H4.4;class=Gene"},'T20H4.4')
			. '), ' . br . 'or a brief text description ('
			. a({-href=>"$url?name=endocytosis;class=definition"},'endocytosis') . ')'),
		      br,br,
		      textfield({-size=>50,-name=>'name'})),
		   
		   #		 td({-align=>'left'},
		   #		    radio_group({-name=>'class',
		   #				 -values => \@values,
		   #				 -labels => \%search_by,
		   #				 -linebreak => 1})),
		   td({-align=>'left'},
		      checkbox_group({-name=>'aspect',
				      -values => [ 'Biological process','Cellular component','Molecular function'],
				      -default => ['Biological process','Cellular component','Molecular function'],
				      -linebreak => 1})),
		   td({-align=>'left'},
		      checkbox_group({-name => 'limit_to',
				      -values => [sort keys %limit_to],
				      -labels => \%limit_to,
				      -linebreak => 1})),
		   #checkbox_group({-name   =>'limit_to',
		   #		    -values => \@values,
		   #		    -labels => \%labels,
		   #		    -linebreak => 1})),
		   #		    radio_group({-name=>'class',
		   #				    -values => \@values,
		   #				    -labels => \%labels,
		   #				    -linebreak => 1})),
		   td(submit())),
		end_form());
    autoEscape(1);
}




sub parse_year {
    my $date = shift;
    $date =~ /.*(\d\d\d\d).*/;
    my $year = $1 || $date;
    return $year;
}



sub setup_cache {
  local $^W=0;
  # Set up the CGI Cache...
  CGI::Cache::setup({
 		     cache_options => { 
 				       cache_root         => $WORMBASE_CACHE,
				       default_expires_in => '4 weeks',
				       max_size           => 1024 * 1024 * 100,
				      }
		    }
		   );
}

sub ClearCache {
  setup_cache();
  $CGI::Cache::THE_CACHE->Clear($WORMBASE_CACHE);
  mkdir $WORMBASE_CACHE,0777;
  chmod 0777,$WORMBASE_CACHE;
}

sub StartCache {
  return if Configuration->Development;
  local $^W=0;
  my @keys = @_;
  AceHeader();
  setup_cache();
  @keys = CGI->new->Vars unless @keys;
  CGI::Cache::set_key(@keys);

  my $warning = human_readable_cache_key(@keys);
  # warn "key: $warning";

  my $explanation;
  # identify partial pages and purge them
  my $cached_output = $CGI::Cache::THE_CACHE->get($CGI::Cache::THE_CACHE_KEY);
  if (defined($cached_output) && ($cached_output !~ m!</html>!)) {
    $explanation ||= human_readable_cache_key(@keys);
    warn "bad cached page ($explanation); Clearing.";
    $CGI::Cache::THE_CACHE->remove($CGI::Cache::THE_CACHE_KEY);
  }
  my $result = CGI::Cache::start();
  if (Configuration->Debug) {
    $explanation ||= human_readable_cache_key(@keys);
    warn $result ? "cache miss on $explanation" : "cache hit on $explanation"
  }
  exit 0 unless $result;
  if (my $request = Apache->request) {
    $request->register_cleanup(\&EndCache);
  }
}

sub EndCache {
  CGI::Cache::stop();
}

sub human_readable_cache_key {
  my @keys = @_;
  join ' ',(map { ref($_) eq 'HASH'  ? join ',',%$_
		 :ref($_) eq 'ARRAY' ? join ',',@$_
		 :$_} @keys);
}


# Generically fetch object(s) from the Autocomplete
# database. Currently this is Gene class specific
sub FetchObject {
    my ($db,$name,$class) = @_;
    my $auto = WormBase::Autocomplete->new("autocomplete") or die;
    my $max_results = 50;

    my $results = $auto->lookup($class,$name,10*$max_results);
    warn "Fetching Object: $name; @$results";
    # The autocomplete lookup is greedy.
    # Let's see if we have an exact match.
    foreach (@$results) {
	my ($display,$canonical,$note) = @{$_};
	if ($display =~ /^$name$/i) {
	    my $gene = $db->fetch('Gene' => $canonical);
	    return ($gene,Bestname($gene));
	}
    }    
    
    # else multiple objects
    MultipleObjectListing($results,$name,'Gene');
}


sub MultipleObjectListing {
    my ($objects,$query,$class) = @_;

    PrintTop("Multiple results: $class");      
    print h3(scalar @$objects . " results for your query: $query");
    print start_table({-width=>'100%'});

#    print TR(map {th({-class=>'dataheader',-width=>$widths{$_}},
#		     a({-href=>$url . $_ . ";order=$sort_order"},
#		       $cols{$_}
#		       . img({-width=>17,-src=>'/images/sort.gif'})
#		       ))}
    
    foreach (@$objects) {
	my ($display,$canonical,$note) = @$_;
	print TR(td({-class=>'datacell',-width=>'15%'},
		    a({-href=>Object2URL($canonical,$class)},$display)),
		 td({-class=>'datacell'},$note));
    }
    print end_table();
    PrintBottom();
    exit;
}



# This subroutine enables multi-tiered searches for Gene objects
# It returns both a Gene object, as well as a text string
# corresponding to the best name of the gene

# It uses a denormalized gene database that waas obsoleted by LSs autocomplete db
#sub FetchGeneNew {
#  my ($DB,$query,$suppress_multiples) = @_;
#
#  my $dbh = OpenDBGeneSearch($DB);
#  my $genes;
#  # Enable retrieval of all genes by species
#  if ($query =~ /^elegans|briggsae|remanei/i || $query =~ /C\.\s+[elegans|briggsae|remanei]/i) {
#      my $species = $query =~ /remanei/i ? 'remanei'
#	  : $query =~ /elegans/i ? 'elegans' : 'briggsae';
#      my $sth = $dbh->prepare(qq{select * from genes where species REGEXP ?});
#      $sth->execute($species);
#      $genes = $sth->fetchall_hashref('gene_id');
#  } elsif ($query =~ /^(I|II|III|IV|V|X|MtDNA):(\d+)\.\.(\d+)/) {
#      my ($chrom,$start,$stop) = ($1,$2,$3);
#      my $sth = $dbh->prepare(qq{select * from genes where chromosome=? and genomic_start >= ? and genomic_stop <= ?});
#      $sth->execute($chrom,$start,$stop);
#      $genes = $sth->fetchall_hashref('gene_id');
#  } else {
#      # Just try searching names
#      my $sth = $dbh->prepare(qq{select * from names2genes,genes where names2genes.name=? and names2genes.gene_id=genes.gene_id GROUP BY genes.gene_id});
#      $sth->execute($query);
#      $genes = $sth->fetchall_hashref('gene_id');
#  }
#  
#  # Try searching the gene class
#  unless (keys %$genes > 0) {
#      my $sth = $dbh->prepare(qq{select * from genes where gene_class=?});
#      $sth->execute($query);
#      $genes = $sth->fetchall_hashref('gene_id');
#  }
#  
#  unless (keys %$genes > 0) {
#B      my $sth = $dbh->prepare(qq{select * from genes where match(concise_description,homol_description,gene_class_description,go) against(?)});
#      $sth->execute($query);
#      $genes = $sth->fetchall_hashref('gene_id');
#  }
#  
#  # Only one object?  Good!  Fetch it and return
#  if (keys %$genes == 1) {
#      my ($key) = keys %$genes;
#      # Is the other_name_for presetn?  If so, it is a merge - let's go to that gene instead
#      my $gene_id = ($genes->{$key}->{merged_into}) ? $genes->{$key}->{merged_into} : $genes->{$key}->{gene};
#     
#      my $gene     = $DB->fetch(Gene      => $gene_id);
#      my $bestname = $DB->fetch(Gene_name => $genes->{$key}->{bestname});
#      # Have to return Bestname for compataibility although in this case
#      # it is only a string, not an object
#      return ($gene,$bestname);
#  } elsif (keys %$genes > 1) {
#      my @rows;
#      foreach my $gene (keys %$genes) {
#	  # Ignore genes that have merged.
#	  next if $genes->{$gene}->{merged_into};
#	  my $name  = $genes->{$gene}->{gene};
#	  my $chrom = $genes->{$gene}->{chromosome};
#	  my $genomic_start = $genes->{$gene}->{genomic_start};
#	  my $genomic_stop  = $genes->{$gene}->{genomic_stop};
#	  my $sequence_name = $genes->{$gene}->{sequence_name} || $genes->{$gene}->{merged_into};
#	  my $cgc_name      = $genes->{$gene}->{cgc_name};
#	  my $genetic_position  = $genes->{$gene}->{genetic_position};
#	  my $gene_class    = $genes->{$gene}->{gene_class};
#	  my @keys = (qw/concise_description gene_class_description homol_description go/);
#	  my $description = join(' ',map {$genes->{$gene}->{$_}} @keys);
#	  
#	  # From whence did the match come in the description? Just use the first match
#	  # Might be quicker to just split the string using the query term as delimiter.
#	  my $substr;
#	  if ($description && $description =~ m/$query/gi) {
#	      my $pos = pos($description);
#	      my $start = ($pos + 1 - 100 < 0) ? 0 : ($pos + 1 - 100);
#	      $substr = substr($description,$start,200);
#	      $substr =~ s/$query/<b>$query<\/b>/gi;
#	      # Split off leading and trailing characters not part of words...
#	      # No way to tell what is actually a word!
#	      my @words = split(/\s/,$substr);
#	      pop @words   unless $words[-1] =~ /$query/i;;
#	      shift @words unless $words[0]  =~ /$query/i;
#	      $substr = '...' . join(' ',@words) . '...';
#	  }
#	  $substr ||= 'none available';
#	  push @rows,[$sequence_name,$cgc_name,$gene_class,"$chrom"  .
#		      ($genetic_position ? ":$genetic_position" : ':unknown'),
#		      ($genomic_start) ? "$chrom:$genomic_start..$genomic_stop" : 'unknown',
#		      #($description ? substr($description,0,60) . '...' : 'none available')
#		      $substr,
#		      ,$name,$genes->{$gene}->{species}];
#      }
##		  0 => 'ID',
#      my %cols = (
#		  0 => 'Sequence',
#		  1 => 'CGC name',
##		  2 => 'Gene class',
##		  2 => 'Genetic position',
#		  2 => 'Genomic position',
#		  3 => 'Description',
#		  );
#      
##      my %widths = (0=>'10%',1=>'10%',2=>'10%',3=>'10%',4=>'10%',5=>'72%');
#      my %widths = (0=>'10%',1=>'10%',2=>'10%',3=>'70%');
#      
#      my $sort_by    = url_param('sort');
#      $sort_by = ($sort_by eq '') ? '1' : $sort_by; # Have to do it this way because of 0
#      my $sort_order = (param('order') eq 'ascending') ? 'descending' : 'ascending';
#      my @sorted;
#      if ($sort_by =~ /[013]/) {
#	  @sorted = sort { lc ($a->[$sort_by]) cmp lc ($b->[$sort_by]) } @rows;
#      } elsif ($sort_by =~ /[34]/) {
#	  # This rather complicated sort splits off the chromosome so that we can sort by both chrom and map position
#	  @sorted = sort { 
#	      my ($achrom,$apos) = (split ':',$a->[$sort_by],2);
#	      my ($bchrom,$bpos) = (split ':',$b->[$sort_by],2);
#	      $apos = $apos eq 'unknown' ? 100000000 : $apos;
#	      $bpos = $bpos eq 'unknown' ? 100000000 : $bpos;
#	      $achrom cmp $bchrom
#		  ||
#		  $apos <=> $bpos } @rows;
#      } else {
#	  @sorted = sort { $a->[$sort_by] <=> $b->[$sort_by] } @rows;
#      }
#      
#      if ($sort_order eq 'descending') {
#	  @sorted = reverse @sorted;
#      }
#
#      PrintTop("Multiple results: $query");      
#      print start_table({-width=>'100%'});
#      print h3(scalar @rows . " results for your query: $query");
#      my $url = url(-absolute=>1) . "?test=1;name=" . param('name') . ';sort=';
#      print TR(map {th({-class=>'dataheader',-width=>$widths{$_}},
#		       a({-href=>$url . $_ . ";order=$sort_order"},
#			 $cols{$_}
#			 . img({-width=>17,-src=>'/images/sort.gif'})
#			 ))}
#	       sort {$a <=> $b} keys %cols);
#      my $shade;
#      foreach (@sorted) {
#	  my ($sequence,$cgc,$class,$gmap,$genomic,$desc,$id,$species) = @$_;
#	  $shade = $shade eq '#FFCCCC' ? '#CCFFFF' : '#FFCCCC';
#	  my $gff = ($species =~ /elegans/) ? 'wormbase'
#	      : ($species =~ /briggsae/) ? 'briggsae'
#	      : ($species =~ /remanei/) ? 'remanei'
#	      : 'no_link';
#	  my $gbrowse = ($gff ne 'no_link' && $genomic ne 'unknown') ? a({-href=>"/db/seq/gbrowse/$gff/?name=$genomic"},$genomic) : $genomic;
#	  print TR({-bgcolor=>$shade},
#		   td({-class=>'datacell'},pre(a({-href=>"/db/gene/gene?name=$id;class=Gene"},$sequence))),
#		   td({-class=>'datacell'},pre(a({-href=>"/db/gene/gene?name=$id;class=Gene"},$cgc))),
##		   td({-class=>'datacell'},a({-href=>"/db/gene/gene_class?name=$class;class=Gene"},$class)),
##		   td({-class=>'datacell'},pre($gmap)),
#		   td({-class=>'datacell'},pre($gbrowse)),
#		   td({-class=>'datacell'},$desc),
#		   );
#      }
#      print end_table;
#      PrintBottom();
#      exit;
##      return (undef,undef,$table,scalar @rows);
#  }
#  
#  # Do a multiple objects listing
#  
#  # Yikes!  How to handle these weird cases?
#  # These may be gene predictions which remain only as CDS objects
##  unless (@genes) {
##    warn "CACHE: $query empty; falling through to CDS check";
##    if (my $cds = $DB->fetch(-class=>'CDS',-name=>$query)) {
##	# HACK HACK HACK
##	# FetchGene is called by the sequence page
##	# Unfortunately, there are orphan CDSs with no attached Gene objects
##	# and that are not tagged as history
##	# The code below results in an endless Redirect
##	my $url = url();
##	# This could also test for the absence of a method
##	if ($url =~ /sequence/) {
##	    AceRedirect('gene' => $cds) unless ($cds->Method eq 'history');
##	} else {
##	    # We won't redirect to the sequence display if this is a history object
##	    # In that case the Gene Page has a built in history display
##	    AceRedirect('sequence'=>$cds) unless ($cds->Method eq 'history');
##	}
##    }
##  }
##
##  # I don't think my database is hanlding these cases correctly
##  if (@unique_genes > 1 && !$suppress_multiples) {
##    MultipleChoices('gene',\@unique_genes,$query);
##    exit 0;
##  }
##
##  my $bestname = Bestname($unique_genes[0]);
##  return ($unique_genes[0],$bestname);
#}

    

# This subroutine enables multi-tiered searches for Gene objects
# It returns both a Gene object, as well as a text string
# corresponding to the best name of the gene
sub FetchGene {
  my ($DB,$submitted_query,$suppress_multiples) = @_;
  my (@genes,%seen);

  # Parse out query away from descriptive terms added by autocomplete
  my ($query,$desc) = $submitted_query =~ /(.*) \((.*)\)/;
  $query ||= $submitted_query;

  # 1. Are we trying to fetch a WB* unique ID?
  if ($query =~ /^WBG.*\d+/) {
    @genes = $DB->fetch(-class=>'Gene',-name=>$query,-fill=>1);

    return ($genes[0],Bestname($genes[0])) if @genes == 1;

# Probably no longer necessary as protein names are now Gene_name objects, too
#    # 2. User is searching via a WormPep ID
#  } elsif ($query =~ /^CE\d+/) {
#    # Enable searches via a WormPep ID
#    # allow users to type "CE12345" rather than "WP:CE12345"
#    $query = "WP:$query" if $query =~ /^CE\d+/;
#    if (my $protein = $DB->fetch(-class=>'Protein',-name=>$query,-fill=>1)) {
#      my $CDS = $protein->Corresponding_CDS;
#      # Fetch the corresponding gene for this CDS
#      @genes = $CDS->Gene(-filled=>1) if $CDS;
#    }
    # 3. Loci (unc-26) and Molecular IDs (R13A5.12)
    # Try searching the Gene_name class.  This should work for
    #   approved CGC names, non-approved names, genes, etc
  } elsif (my @gene_names = $DB->fetch(-class=>'Gene_name',-name=>$query,-fill=>1)) {
      # HACK!  For cases in which a gene is assigned to more than one Public_name_for.
      @genes = grep { !$seen{$_}++} map { $_->Public_name_for } @gene_names;

      @genes = grep {!$seen{$_}++} map {$_->Sequence_name_for
					    || $_->Molecular_name_for
					    || $_->Other_name_for
					} @gene_names unless @genes;
      undef @gene_names;
  } elsif (my @gene_classes = $DB->fetch(-class=>'Gene_class',-name=>$query,-fill=>1)) {
      @genes = map { $_->Genes } @gene_classes;
  } elsif (my @transcripts = $DB->fetch(-class=>'Transcript',-name=>$query,-fill=>1)) {
      @genes = map { eval { $_->Corresponding_CDS->Gene } } @transcripts;
  } elsif (my @ests = $DB->fetch(-class=>'Sequence',-name=>$query,-fill=>1)) {
    foreach (@ests) {
      if (my $gene = $_->Gene(-filled=>1)) {
	push @genes,$gene;
      } elsif (my $cds = $_->Matching_CDS(-filled=>1)) {
	my $gene = $cds->Gene(-filled=>1);
	push @genes,$gene if $gene;
      }
    }

    #    # Temporary kludge for handling briggsae non-gene CDSes.  DAMN!
    #  } elsif (my @cds = $DB->fetch(-class=>'CDS',-name=>$query)) {
    #    my %seen;
    #    my @unique_cds = grep { !$seen{$_}++ } @cds;
    #    if (@unique_cds > 1 && !$suppress_multiples) {
    #      MultipleChoices('gene',\@unique_cds);
    #      exit 0;
    #    }
    #    return ($query,@unique_cds[0]);
# UNNECESSARY
#  } elsif (my @transcripts = $DB->fetch(-class=>'Transcript',-name=>$query,-fill=>1)) {
#    @genes = map { eval { $_->Corresponding_CDS->Gene} } @transcripts;
# DISABLED
  } elsif (my @variations = $DB->fetch(-class=>'Variation',-name=>$query,-fill=>1)) {
      @genes = map { eval { $_->Gene} } @variations;
}

  # Try finding genes using general terms
  # 1. Homology_group
  # 2. Concise_description
  # 3. Gene_class

  unless (@genes) {
      my @homol = $DB->fetch(-query=>qq{find Homology_group where Title=*$query*});
      @genes = map { eval { $_->Protein->Corresponding_CDS->Gene } } @homol;
      push (@genes,map { $_->Genes } $DB->fetch(-query=>qq{find Gene_class where Description="*$query*"}));
      push (@genes,$DB->fetch(-query=>qq{find Gene where Concise_description=*$query*}));
  }

  unless (@genes) {
      my @accession_number = $DB->fetch(Accession_number => $query);
      my %seen;
      my @cds = grep {  $seen{$_}++ } map { $_->CDS } @accession_number;
      push @cds,grep { !$seen{$_}++ } map { eval {$_->Protein->Corrsponding_CDS } } @accession_number;
      push @cds,grep { !$seen{$_}++ } map { eval {$_->Sequence->Matching_CDS }  } @accession_number;
      @genes =  grep { !$seen{$_}++ } map { $_->Gene } @cds;
  }
  # DEPRECATED!
  # Try fetching pseudogenes that have never been classified as loci
  # Is this still necessary?
  #  unless (@genes) {
  #    my @transcripts = $DB->fetch(-class=>'Pseudogene',-name=>$query);
  #	     my %seen;
  #    @genes = map {$_->fetch} grep {!$seen{$_}++} map {$_->Gene} @transcripts;
  #  }

  # These may be gene predictions which remain only as CDS objects
  unless (@genes) {
    #warn "CACHE: $query empty; falling through to CDS check";
    if (my $cds = $DB->fetch(-class=>'CDS',-name=>$query)) {
	# HACK HACK HACK
	# FetchGene is called by the sequence page
	# Unfortunately, there are orphan CDSs with no attached Gene objects
	# and that are not tagged as history
	# The code below results in an endless Redirect
	my $url = url();
	if ($cds->Method eq 'twinscan') {
	    if ($url !~ /sequence/) {
		AceRedirect('sequence' => $cds);
	    } else {
		return $cds;
	    }
	}

	# This could also test for the absence of a method
	if ($url =~ /sequence/) {
	    AceRedirect('gene' => $cds) unless ($cds->Method eq 'history' || $cds->Method eq 'Genefinder' || $cds->Method eq '');
	} else {
	    # We won't redirect to the sequence display if this is a history object
	    # In that case the Gene Page has a built in history display
	    AceRedirect('sequence'=>$cds) unless ($cds->Method eq 'history');
	}
    }
  }

  # Analyze the Other_name_for of the Gene_name to see if the gene
  # corresponds to another named gene.
  my (@unique_genes);
  %seen = ();
  foreach my $gene (@genes) {
    next if defined $seen{$gene};
    my $gene_name  = $gene->Public_name;
    my @other_names = eval { $gene_name->Other_name_for; };
    foreach my $other_name (@other_names) {
      if ($other_name ne $gene) {
	#warn "other: $other_name";
        #warn "gene: $gene";
#	push (@unique_genes,$other_name) unless defined $seen{$other_name};
	$seen{$other_name}++;
      }
    }
    push (@unique_genes,$gene);
    $seen{$gene}++;
  }

  if (@unique_genes > 1 && !$suppress_multiples) {
    MultipleChoices($query,\@unique_genes,$query);
    exit 0;
  }

  my $bestname = Bestname($unique_genes[0]);
  
  # See "searches/basic" for rational on this redirect over 
  # simply returning the object
  return unless @unique_genes > 0;
  my $url = url();
  my $abs = url(-query=>1);
  if ($url =~ /gene\/gene/ && $url !~ /genetable/ && $abs !~ /details/) {
      my $gene = $unique_genes[0];
      redirect("/db/gene/gene?name=$gene;class=Gene");
  } else {
      return ($unique_genes[0],$bestname);
  }
}

# Pick out the best descriptive name for a gene object
# Cascade:
# 1. 3-letter locus name
# 2. Primary CDS (ie a Molecular ID but without a splice variant ID)
# 3. Corresponding protein
# 4. original query
sub Bestname {
  my $gene = shift;
  return unless $gene && $gene->class eq 'Gene';
  my $name = $gene->Public_name ||
      $gene->CGC_name || $gene->Molecular_name || eval { $gene->Corresponding_CDS->Corresponding_protein } || $gene;
  return $name;
}

sub GeneName2Gene {
  my $gene_name = shift;
  return $gene_name unless $gene_name->class eq 'Gene_name';  # Bizarre hack
  my $gene = $gene_name->CGC_name_for || $gene_name->Molecular_name_for || $gene_name->Public_name_for || $gene_name->Other_name_for;
  return $gene;
}



# Generic search for powering Cell and Anatomy pages.
# This is a bit disjointed at the moment.
# The Cell pages are driven from Cell objects.  These
# are being replaced by Anatomy term pages.

# Raymond prefers that the AO pages are displayed first,
# and that cell pages only when there is no AO term
sub FetchCell {

    my ($DB,$query) = @_;
    # Search the Anatomy_term class first
    my @anat_terms;
    if ($query =~ /^WBbt:/) {
	my @anat_terms = $DB->fetch(Anatomy_term => $query);
	
	# Try the anatomy_name class.
    } elsif (my @anat_names = $DB->fetch(Anatomy_name => $query)) {
	my %seen;
	@anat_terms = grep { !$seen{$_}++ } map { $_->Name_for_anatomy_term || $_->Synonym_for_anatomy_term } @anat_names;
    }  else {
	# Finally try generically searching the Anatomy_term class
	# First try searching terms via an ace query, then fetching objects for each result individually
	# There has GOT to be a better way.
	my $clean = $query;
	$clean =~ s/^\*//;
	$clean =~ s/\*$//;
	my $ace_query = 'select a,a->Term from a in class Anatomy_term where a->Term like "*' . $clean . '*"';
	my @tmp = $DB->aql($ace_query);
	my @objs = map { $DB->fetch(Anatomy_term=>$_->[0]) } @tmp;
	
	# do a full database grep
	push(@objs,$DB->grep(-pattern=>$query,-long=>1)) unless (@objs);
	my %seen;
	@anat_terms = grep {!$seen{$_}++} grep {$_->class eq 'Anatomy_term'} @objs;
    }
    
    if (@anat_terms) {
	# Okay, we have anatomy names.
	return \@anat_terms;
    }
    
    # No cell yet from AO term? Try the cell class.
    # This should be completely unnecessary
    my @cells = $DB->fetch(-class=>'Cell', -name=>"$query*");
    return \@cells if @cells;
    return;
}


# Fetch genes using the autocomplete database
# THIS HAS BEEN GENERALIZED to FetchObject, currently in my wormbase-devel/todd
#sub FetchGeneAutocomplete {
#    my ($db,$query,$class) = @_;
#    my $auto   = WormBase::Autocomplete->new("autocomplete");
#    $class ||= 'Gene';
#    
#    my ($result) = $auto->lookup($class,$query) || [];
#    
#    # Multiple objects not yet supported
#    # This really needs to be a list of Objects
##    if (@unique_genes > 1 && !$suppress_multiples) {
##	MultipleChoices($query,\@unique_genes,$query);
##	exit 0;
##    }
#
#    # Only one result
#    while (@$result) {
#	my $r = shift @$result;
#	$r or last;
#	my ($display,$canonical,$note) = @$r;
#	
#	my $gene = $db->fetch(Gene => $canonical);
#	my $bestname = Bestname($gene);
#	return ($gene,$bestname);
#    redirect("/db/gene/gene?name=$canonical;class=Gene");
#    }
#
#
#    # May also need to return the Bestname in select cases
#    
##    my $bestname = Bestname($unique_genes[0]);
##    
##    # See "searches/basic" for rational on this redirect over 
###    # simply returning the object
##    return unless @unique_genes > 0;
##    my $url = url();
##    my $abs = url(-query=>1);
##    if ($url =~ /gene\/gene/ && $url !~ /genetable/ && $abs !~ /details/) {
##	my $gene = $unique_genes[0];
##	redirect("/db/gene/gene?name=$gene;class=Gene");
##    } else {
##	return ($unique_genes[0],$bestname);
##    }    
#}



# Provided with a name or WBPerson ID, fetch the corresponding person/people
sub FetchPeople {
  my ($DB,$input_name) = @_;
  return unless $input_name;
  $input_name    =~ s/,//g;

  my @fields = split(/\s/,$input_name);
  
  my @results;
  # 1. Easiest case: search by WBPerson ID or a number
  if ($input_name =~ /WBPerson/i || $input_name =~ /\d+/) {
    my $query = ($input_name =~ /(WBPerson\d+)/i) ? $1 : 'WBPerson' . $1;
    @results = $DB->fetch(-class =>'Person',
			  -name  => $query,
			  -fill  => 1,
			  );

    # GET requests by URL, limiting the search by either
    # a Paper ID (ie from Genetics) or an Author name.
  } elsif ($ENV{REQUEST_METHOD} ne 'POST') {
      
      # Requests for a specific paper
      if (my $paper = url_param('paper')) {
	  my $input = url_param('name');
	  # Fetch the paper
	  my $paper_obj = $DB->fetch(-class=>'Paper',-name=>$paper);
	  
	  # Iterate over all Authors of the paper.
	  if ($paper_obj) {
	      my @authors = $paper_obj->Author;
	      foreach (@authors) {
		  # Does this author match that we are searching for?
		  if ($_ eq $input) {
		      # Does this author have an affiliation hash?
		      my %affiliation = map { $_ => $_->right } eval { $_->col };
		      if ($affiliation{Person}) {
			  push @results,$affiliation{Person};
		      } else {
			  push @results,$_;
		      }
		  }
	      }
	  } else {
	      # 2010.04: OH NO! Sometimes the paper doesn't exist yet.
	      # Dumb dumb dumb. I guess we'll just fall back to the basic
	      # Author search, copy-pasted here in a moment of incredible 
	      # lassitude.
	      
	      my $class = url_param('class') || 'Person_name';
	      my (@temp) = $DB->fetch(-name=>$input,-class=>$class);
	      
	      # Count all the contents of each tag under Person_name objects
	      if ($class eq 'Person_name') {
		  foreach (@temp) {
		      push (@results,$_->Last_name_of,$_->Standard_name_of,$_->Full_name_of,
			    $_->Other_name_of);
		  }
	      } else {
		  foreach (@temp) {
		      if (my @people = eval { $_->Possible_person }) {
			  push @results,@people;
		      } else {
			  push @results,$_;
		      }
		  }
	      }
	  }	  
      } elsif (my $input = url_param('name')) {
	  # Search heuristics
	  
	  # 1. Linking in via a URL
	  # Another search or script has already pinpointed the appropriate
	  # individual. Typically, this is an author object link.  In these
	  # cases, let's make the query as specific as possible to avoid a
	  # needless "multiple hits" display. This isn't perfect since we
	  # are passing text and not a unique ID.
	  
	  my $class = url_param('class') || 'Author';
	  my (@temp) = $DB->fetch(-name=>$input,-class=>$class);
	  
	  # Count all the contents of each tag under Person_name objects
	  if ($class eq 'Person_name') {
	      foreach (@temp) {
		  push (@results,$_->Last_name_of,$_->Standard_name_of,$_->Full_name_of,
			$_->Other_name_of);
	      }
	  } else {
	      foreach (@temp) {
		  if (my @people = eval { $_->Possible_person }) {
		      push @results,@people;
		  } else {
		      push @results,$_;
		  }
	      }
	  }
      }
  } else { }
  
  # Finally, POSTs from the prompt.
  unless (@results) {
      if (@fields == 1) {
	  
	  # 2. No URL has been passed. There is no way to discern if the
	  #    search will be an author or a person at this point.
	  #    Search both and map to unique ?Person objects
	 
	  my @queries = ($input_name,$fields[0] . ' *');
	  foreach (@queries) {
	      my @authors =  $DB->fetch(-name=>$_,-class=>'Author');
	      push (@results,map { $_->Possible_person || $_ } @authors);
	      my @person_name = $DB->fetch(-name=>$_,-class=>'Person_name');
	      # Count all the contents of each tag under Person_name objects
	      foreach (@person_name) {
		  push (@results,$_->Last_name_of,$_->Standard_name_of,$_->Full_name_of);
	      }
	  }
      } else {
	  # For a single name, let's assume it's the last name and wildcard it
	  # More than a single name was entered.
	  # I'm assuming that the format is last first (this isn't the case for URL-passed authors).	  
	  	  
	  my @queries = $input_name . '*';
	  foreach (@queries) {
	      my @authors =  $DB->fetch(-name=>$_,-class=>'Author');
	      push (@results,map { $_->Possible_person || $_ } @authors);
	      my @person_name = $DB->fetch(-name=>$_,-class=>'Person_name');
	      # Count all the contents of each tag under Person_name objects
	      foreach (@person_name) {
		  push (@results,$_->Last_name_of,$_->Standard_name_of,$_->Full_name_of);
	      }   
	  }
      }
  }


  my %seen;
  my @people = grep {!$seen{$_}++} map {eval $_->Possible_person || $_} @results;
  return @people;
}


sub autocomplete_field {
  textfield(-name => 'name', -size => 20);
}

sub autocomplete_end {
  '';
}

sub display_reactome_data {
 my ($proID,$count) = @_;
 $count = "" unless(defined $count); 
 my ($reactome_info,$response);
 my $path="http://banon.cshl.edu:5555/biomart/martservice?";
 my $ua = LWP::UserAgent->new;

 foreach my $type (('pathway','reaction','complex')){
	my $query = get_xml($type,$proID,$count);
	my $request = HTTP::Request->new("POST",$path,HTTP::Headers->new(),'query='.$query."\n");
	$response = $ua->request($request);
	if ($response->is_success) {
		if($count eq 1){
			 $reactome_info+=$response->content;
		} else {
			$reactome_info->{$type}=$response->content if($response->content ne '') ;
		}
	}	
	else {
		#die $response->status_line;
		last;
	}	
  }

 return $reactome_info; 
}

sub get_xml {

 my ($db,$protein,$count) = @_;
 my $xml = qq
 {<?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE Query>
  <Query  virtualSchemaName = "default" formatter = "TSV" header = "0" uniqueRows = "1" count = "}.$count.qq{" datasetConfigVersion = "0.6" >
        <Dataset name = "}.$db.qq{" interface = "default" >
                <Filter name = "species_selection" value = "Caenorhabditis elegans"/>
                <Filter name = "referencepeptidesequence_wormbase_id_list" value = "}.$protein.qq{"/>
                <Attribute name = "}.$db."_db_id".qq{" />
                <Attribute name = "_displayname" />
        </Dataset>
 </Query>
 };
 $xml =~ s/complex_db_id/complex_db_id_key/ if($db eq "complex");
 return $xml;
}



1;
