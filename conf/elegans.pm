use CGI ':standard';
use Ace 1.81;
#$Id: elegans.pm,v 1.14 2011-02-07 18:05:41 tharris Exp $
#$Date: 2011-02-07 18:05:41 $
#$Revision: 1.14 $

# here's the root of all our stuff
$APPLICATION_ROOT = '/usr/local/wormbase';

# Where all temp files shold be written
$TMP_DIR = $APPLICATION_ROOT . "/tmp";

$WORMBASE = '/usr/local/wormbase/website/classic';  # location of our stuff on filesystem
$WB       = '';        # Prefix to append to URLs
$ROOT     = "$WB/db";  # where the scripts live in URL space
$CONF     = "$WORMBASE/conf";  # where the configuration files live

# all passwords and port numbers have been moved
# into this NON-CVS file
require "$CONF/localdefs.pm";

# ========= $NAME =========
# symbolic name of the database (defaults to name of file, lowercase)
$NAME = 'wormbase';

# Mysql database configuration
$USE_GBROWSE1 = 1;

if ($USE_GBROWSE1) {
    $GFF_CONF      = "$CONF/gbrowse.conf";
} else {
    $GFF_CONF       = "$CONF/gb2";
}

# Let's override the current bioperl transcript aggregator
@DBGFF    = (-adaptor     => 'dbi::mysqlace',
	     -dsn         => "dbi:mysql:database=c_elegans;host=$MYSQL_HOST",
             -aggregators => ['processed_transcript{coding_exon,5_UTR,3_UTR/CDS}',
			      'full_transcript{coding_exon,five_prime_UTR,three_prime_UTR/Transcript}',
			      'transposon{coding_exon,five_prime_UTR,three_prime_UTR}',
			      'clone',
			      'alignment',
			      'waba_alignment',
			      'coding{coding_exon}',
			      'pseudo{exon:Pseudogene/Pseudogene}',
			      'rna{exon/Transcript}',
			      'wormbase_cds{coding_exon,three_prime_UTR,five_prime_UTR}',
			      'motif_span{motif_segment/Motif}',
#			      'cgh_allele'
			      ],
	     -user        => $MYSQL_USER || 'nobody',
	     -pass        => $MYSQL_PASS || '',
	     );


@REMGFF    = (-adaptor     => 'dbi::mysqlace',
	      -dsn         => "dbi:mysql:database=c_remanei;host=$MYSQL_HOST",
	      -aggregators => ['processed_transcript{coding_exon,5_UTR,3_UTR/CDS}',
			       'full_transcript{coding_exon,five_prime_UTR,three_prime_UTR/Transcript}',
			       'transposon{coding_exon,five_prime_UTR,three_prime_UTR}',
			       'clone',
			       'alignment',
			       'waba_alignment',
			       'coding{coding_exon}',
			       'pseudo{exon:Pseudogene/Pseudogene}',
			       'rna{exon/Transcript}'
			       ],
	      -user        => $MYSQL_USER || 'nobody',
	      -pass        => $MYSQL_PASS || '',
	      );



@BRIGGFF    = (-adaptor     => 'dbi::mysqlace',
	       -dsn         => "dbi:mysql:database=c_briggsae;host=$MYSQL_HOST",
	       -aggregators => ['wormbase_cds{coding_exon,three_prime_UTR,five_prime_UTR}','clone','alignment','waba_alignment'],
#	       -aggregators => ['wormbase_cds{coding_exon,three_prime_UTR,five_primer_UTR/CDS}','clone','alignment','waba_alignment'],
	       -user        => $MYSQL_USER || 'nobody',
	       -pass        => $MYSQL_PASS || '',
	       );

@PMAPGFF    = (-adaptor     => 'dbi::mysqlace',
	       -dsn         => "dbi:mysql:database=c_elegans_pmap;host=$MYSQL_HOST",
	       -aggregators => [qw(wormbase_gene)],
	       -user        => $MYSQL_USER || 'nobody',
	       -pass        => $MYSQL_PASS || '',
	       );

@GMAPGFF    = (-adaptor     => 'dbi::mysqlace',
	       -dsn         => "dbi:mysql:database=c_elegans_gmap;host=$MYSQL_HOST",
	       -aggregators => [qw(wormbase_gene)],
	       -user        => $MYSQL_USER || 'nobody',
	       -pass        => $MYSQL_PASS || '',
	       );

$GMAPGFF_URL  = '/db/gb2/gbrowse/c_elegans_gmap/?name=%s';

# ========= $STYLESHEET =========
# stylesheet to use
$STYLESHEET = "$WB/stylesheets/wormbase.css";

# Expression cartoons, previously hard-coded
$WORMVIEW_IMAGE = "$WORMBASE/html/images/expression/assembled";

# ========= $PICTURES ==========
# Where to write temporary picture files to:
#   The URL and the physical location, which must be writable
# by the web server.

$tmpimages = tmpimages();
@PICTURES = ("/dynamic_images/$tmpimages" => "/var/tmp/dynamic_images/$tmpimages");

$IMAGES = '/images';
$EXPRESSION_IMAGES = "$IMAGES/expression/patterns";
$LOCALIZOME_IMAGES = "$IMAGES/expression/localizome";

# This controls at what point the "pic" script should stop making individually-clickable
# elements.
$MAX_IN_COLUMN = 100;

# location of random pictures to display on certain pages
$RANDOM_PICTS = "$WB/random_pic";
$PIC_SCRIPT   = "$ROOT/misc/random_pic";

#pictures for win32 explorer-style drawing
$MENU_OPEN    = '/images/menu-images/menu_corner_minus.gif';
$MENU_CLOSED  = '/images/menu-images/menu_corner_plus.gif';
$MENU_CORNER  = '/images/menu-images/menu_corner.gif';
$MENU_TEE     = '/images/menu-images/menu_tee.gif';
$MENU_BAR     = '/images/menu-images/menu_bar.gif';
$MENU_LEAF    = '/images/menu-images/menu_leaf.gif';
$MENU_FILL    = '/images/menu-images/menu_blank.gif';


#========================= WORMBASE-SPECIFIC CONFIGURATION ==================

# ========== An icon to use for "home" ==========
# leaving this undefined suppresses the generation of a "home" link
# $HOME_ICON = '/ico/arrows/uarrw.gif';

# =========  An icon to use for searching =======
# leaving this undefined suppresses the generation of a "search" link
# $SEARCH_ICON = '/ico/unknown.gif';

# position of the big banner
# $BANNER_LEFT    = "$WB/images/test_logo.jpg";
$BANNER_RIGHT   = "/images/image_new_colour.jpg";
$BANNER_LEFT    = "$WB/images/l.gif";
#$BANNER_RIGHT   = "$WB/images/banner_right";


# fixed width for the page
$PAGEWIDTH = 700;

# Anti-turing test Captcha image directories
$CAPTCHA_DATA   = "$WB/captcha/data";
$CAPTCHA_OUTPUT = "$WB/captcha/output";

# position of the "cross"
$CROSS_ICON = "$WB/images/cross1.gif";
$ARROWR_ICON = "$WB/images/arrow_right.gif";
$ARROWL_ICON = "$WB/images/arrow_left.gif";

# position of neuron diagrams
$NEURON_DIAGRAMS = "$WB/cell/diagrams";

# bullet and small bullet
$BULLET      = "$WB/images/reddot.jpg";
$SMALLBULLET = "$WB/images/reddot5.jpg";

# ========= $ZoomNavDIR Images ==========
# Where all the images related to zooming and navigation are. 
# aw_
$ZOOMNAVDIR = ('/buttons/zoom');


# ========= @ImageWidths ==========
# The widths that can be used to display the sequence.
# aw_
$IMAGEWIDTHS = [qw(480 640 800 1024 1280 1600)];


# ========= $DefaultImageWidth ==========
# The default width to be used initially. 
# aw_
$DEFAULTIMAGEWIDTH = 800;


# ======== BLAST ===========
$BLAST_ROOT    = -e '/usr/local/wublast.WB' ? '/usr/local/wublast.WB' : '/usr/local/wublast';
$BLAST_BIN     = -e "$BLAST_ROOT/bin" ? "$BLAST_ROOT/bin/" : "$BLAST_ROOT/";
$BLAST_MATRIX  = "$BLAST_ROOT/matrix";
$BLAST_FILTER  = "$BLAST_ROOT/filter";
$BLAST_DB      = "$WORMBASE/databases/blast";
$BLAST_CUTOFF  = 9999;
$BLAST_MAXHITS = 20;
@BLAST_default = ('blastp'               => 'WormPep');
%BLAST_labels  = ('EST_Elegans'        => 'C. elegans ESTs',
		  'Elegans'              => 'C. elegans genomic',
		  'Briggsae_genomic'     => 'C. briggsae genomic',
		  'Briggpep'             => 'C. briggsae proteins (Briggpep)',
		  'WormPep'              => 'C. elegans proteins (WormPep)');
%BLAST_ok      = ('blastn'  => [qw/Elegans EST_Elegans Briggsae_genomic/],
		  'tblastn' => [qw/Elegans EST_Elegans Briggsae_genomic/],
		  'blastp'  => [qw/WormPep Briggpep/],
		  'blastx'  => [qw/WormPep Briggpep/]
		 );

# ======== BLAT ===========
$BLAT_EXECUTABLE   = '/usr/local/blat/bin/blat';
%BLAT_DB_DIRS      = (
					'Elegans'           => '/usr/local/wormbase/website/classic/databases/blat/c_elegans',
					'Briggsae_genomic'  => '/usr/local/wormbase/website/classic/databases/blat/c_briggsae'
                    );
$BLAT_CLIENT_EXECUTABLE = '/usr/local/blat/bin/gfClient',
$BLAT_SERVER_EXECUTABLE = '/usr/local/blat/bin/gfServer',
%BLAT_SERVER_PORTS  = (
					'Elegans'           => 2007,
					'Briggsae_genomic'  => 2009
                    );

# ========= $BANNER =========
# Banner HTML
# This will appear at the top of each page. 
$BANNER  = 'WormBase';
$BANNER_ = 'A Worm Image';

# ========= $FOOTER =========
# Footer HTML
# This will appear at the bottom of each page
# $FOOTER = img({-src=>"$WORMBASE/images/foot_logo.gif"});


$MY_FOOTER = 
'<!-- begin footer -->
<div id="footer">
    <div id="footercredit">
          Questions? Comments? <a href="mailto:help@wormbase.org">help@wormbase.org</a> or
          <a href="/db/misc/feedback">web form</a>
          <p>
           WormBase is supported by a grant from the National Human Genome Research Institute
           at the US National Institutes of Health # P41 HG02223 and the British Medical Research Council.
          </p>

     </div>
    <div id="footermeta">
          <a href="http://wiki.wormbase.org/index.php/WormBaseWiki:Copyrights">Copyright </a> |
          <a href="http://wiki.wormbase.org/index.php/Acceptable_use_policy#Privacy_statement">Privacy</a>
    </div>
</div>
';

#    <script type="text/javascript" 
#src="http://w.sharethis.com/widget/?tabs=web%2Cpost%2Cemail&amp;charset=utf-8&amp;services=reddit%2Cdigg%2Cfacebook%2Cmyspace%2Cdelicious
#%2Cstumbleupon%2Ctechnorati%2Cgoogle_bmarks%2Cyahoo_bmarks%2Cslashdot&amp;style=default&amp;publisher=7ab86fe8-5972-4c0c-b8d5-e8a0240bc09d&amp;popup=true"></script> |



# ========= @SEARCHES  =========
# search scripts available
# NOTE: the order is important
@SEARCHES   = (
	       home   => { name      => '<font color="#FFFF99"><b>Home</b></font>',
			   url       => "/"},
	       hunter => { name      => '<font color="#FFFFFF">Genome</font>',
#			   url      => "$ROOT/seq/gbrowse/c_elegans/",
			   url      => "$ROOT/gb2/gbrowse/c_elegans/",
			   size     => [100,20], 
			 },
	       synteny => { name      => '<font color="#FFFFFF">Synteny</font>',
			    url      => "http://www.wormbase.org/db/gb2/gbrowse_syn/compara/",
			    size     => [100,20],
			  },
	       blast => { name       => '<font color="#FFFFFF">Blast / Blat</font>',
			  url        => "$ROOT/searches/blast_blat",
			  #onimage    => "$WB/buttons/blast_on.gif",
			  #offimage   => "$WB/buttons/blast_off.gif",
			  size       => [99,20],
			},

	       # Deprecating batch genes in WS142!
	       #info          => { name   => '<font color="#FFFFFF">Batch Genes</font>',
	       #                    url    => "$ROOT/searches/batch_genes",
	       #		 },

	       # Provide an absolute URL for now so that mirrors need
	       # not support WormMart directly.
	       wormmart       => { name  => '<font color="#FFFFFF">WormMart</font>',
				   url   => "http://caprica.caltech.edu:9002/biomart/martview",
				 },

#	       genome_dumper => { name   => '<font color="#FFFFFF">Batch Sequences</font>',
#				  url    => "$ROOT/searches/advanced/dumper",
#				},
	       strain_search => { name   => '<font color="#FFFFFF">Markers</font>',
				  url    => "$ROOT/searches/strains" 
				},

	       gmap => { name   => '<font color="#FFFFFF">Genetic Maps</font>',
			 url    => "$ROOT/gene/gmap",
		       },
	       submit => { name   => '<font color="#FFFFFF">Submit</font>',
			   url    => "$ROOT/curate/submit",
			 },
	       search_index => { name  => '<font color="#FFFFFF"><b>Searches</b></font>',
				 url   => "$ROOT/misc/site_map?format=searches"
			   },
	       site_map => { name  => '<font color="#FFFFFF"><b>Site Map</b></font>',
			     url   => "$ROOT/misc/site_map"
			   },
	       );

# ========= %HOME  =========
# Home page URL
@HOME      = (
	      'http://www.wormbase.org' => 'WormBase home'
	     );

@HOME_BUTTON = ("$WB/buttons/home_bottom.gif" => [20,56]);

# ========= %DISPLAYS =========
%DISPLAYS = (
	     align      => { url   => "$ROOT/seq/align",
			     label => 'alignment'},

	     aligner    => { url   => "$ROOT/seq/aligner",
			     label => 'EST Alignments'},

	     # Deprecated with WS140
	     # allele     => { url   => "$ROOT/gene/allele",
	     #                 label => 'Allele Summary'},
	     analysis      => { url   => "$ROOT/misc/analysis",
			     label => 'Analysis Summary'},

	     antibody   => { url   => "$ROOT/gene/antibody",
			     label => 'Antibody Summary'},

	     aoterm     => { url   => "$ROOT/ontology/anatomy",
			     label => 'Anatomy Ontology'},

	     anatomy_name   => { url   => "$ROOT/ontology/anatomy",
			          label => 'Anatomy Ontology'},

	     #	     author     => { url   => "$ROOT/misc/author",
	     #			     label => 'Author Info'},
	     #
	     # Unified author/person display
	     author     => { url   => "$ROOT/misc/person",
			     label => 'Author Info'},

	     author_example => { url   => "$ROOT/misc/author_example",
				 label => 'Publication list'},

	     biblio     => { url   => "$ROOT/misc/biblio",
			     label => 'Bibliography'},

	     cds        => { url   => "$ROOT/seq/sequence",
			     label => 'Sequence Summary'},

	     cell       => { url   => "$ROOT/ontology/anatomy",
#"$ROOT/cell/cell.cgi",
			     label => 'Cell Summary'},

	     clone      => { url   => "$ROOT/seq/clone",
			     label => 'Clone Summary'},

	     condition      => { url   => "$ROOT/misc/condition",
			     label => 'Condiction Summary'},

	     expression_cluster   => {
			   url => "$ROOT/microarray/expression_cluster",
			   label => "Microarray Expression Cluster Summary"},

	     expr_pattern => { url   => "$ROOT/gene/expression",
			       label => 'Expression Pattern'},

	     expr_profile => { url   => "$ROOT/gene/expr_profile",
			       label => 'Expression profile'},

	     gene       => { url   => "$ROOT/gene/gene",
			     label => 'Gene Summary'},

             gene_name  => { url   => "$ROOT/gene/gene",
                             label => 'Gene Summary'},

	     gene_class => { url   => "$ROOT/gene/gene_class",
			     label => 'Gene Class Summary'},

	     gene_regulation => { url   => "$ROOT/gene/regulation",
				  label => 'Gene Regulation Summary'},
	     
	     # geneapplet => {url   =>"$ROOT/gene/geneapplet",
	     #		          label => 'Java Map'},

	     gmap       => { url   => "$ROOT/misc/epic",
			     label => 'Genetic Map'},

#	     goterm     => { url   => "$ROOT/ontology/goterm",
#			     label => 'GO Term'},

	     # Gene ontology terms now go to their own display
	     go_term     => { url   => "$ROOT/ontology/gene",
			      label => 'GO Term'},

	     # This is a pseudoclass so I can display a link to the DAG
#	     go_dag      => { url   => "$ROOT/ontology/go_dag",
#			      label => 'GO DAG'},

	     homology_group  => { url   =>"$ROOT/gene/homology_group",
				  label => 'Homology Group'},

	     hunter     => { url   => "$ROOT/gb2/gbrowse/%s/",
			     label => 'Genome Browser'},

	     interaction  => { url   =>"$ROOT/gene/interaction",
			       label => 'Interaction'},

	     laboratory => { url   => "$ROOT/misc/laboratory",
			     label => 'Lab Listing'},

	     life_stage => { url   => "$ROOT/misc/life_stage",
			     label => 'Life StaSge'},

	     locus      => { url   => "$ROOT/gene/locus",
			     label => 'Locus Summary'},

	     mappingdata => { url   => "$ROOT/gene/mapping_data",
			      label => 'Map Data'},

	     mapservlet => { url   => "$ROOT/mapview/geneticmap",
			     label => 'Clickable Map'},

	     MindOfWorm => { url   => "$ROOT/cell/mindofworm",
			     label => "Mind of Worm"},

	     microarray_experiment => {
				       url => "$ROOT/microarray/results",
				       label => "Microarray Summary"},

	     microarray_results   => {
				      url => "$ROOT/microarray/results",
				      label => "Microarray Summary"},

	     motif      => { url   => "$ROOT/gene/motif",
			     label => 'Motif'},

	     model      => { url   => "$ROOT/misc/model",
			     label => 'Schema'},

	     nbrowse => { url   =>"$ROOT/seq/interaction_viewer",
			       label => 'N-Browse Interaction Viewer'},

	     nearby_genes => { url   =>"$ROOT/gene/genetable#pos",
			       label => 'Nearby Genes'},

	     oligo_set   => { url => "$ROOT/seq/pcr",
			      label => 'Microarray Oligos'},

	     operon     => { url => "$ROOT/gene/operon",
			     label => "Operon Summary"},

	     paper      => { url   => "$ROOT/misc/paper",
			     label => 'Citation'},

	     pcr_product => { url => "$ROOT/seq/pcr",
			      label => 'PCR Assay'},

	     pedigree   => { url   => "$ROOT/searches/pedigree",
			   label => 'Pedigree Browser'},

	     person   => { url      => "$ROOT/misc/person",
	     		     label    => 'Person Info'},

	     person_name=> { url      => "$ROOT/misc/person",
			     label    => 'Person Info'},

             phenotype  => { url     => "$ROOT/misc/phenotype",
                             label   => 'Phenotype'},

	     pic        => { url     => "$ROOT/misc/epic",
			     label   => 'Acedb Image'},

	     protein    => { url   => "$ROOT/seq/protein",
			     label => 'Protein Summary'},

	     rearrange  =>  { url => "$ROOT/gene/rearrange",
			      label => 'Rearrangement Summary'},

	     rnai       => { url   => "$ROOT/seq/rnai",
			     label => 'RNAi Summary'},

	     RNAi       => { url   => "$ROOT/seq/rnai",
			     label => 'RNAi Summary'},

	     sagetag   => { url => "$ROOT/seq/sage",
			    label => 'SAGE Summary'},

	     sequence   => { url   => "$ROOT/seq/sequence",
			     label => 'Sequence Summary'},

	     # snp      => { url   => "$ROOT/seq/snp",
	     #		    label => 'SNP Summary' },

	     strain     => { url   => "$ROOT/gene/strain",
			     label => "Strain Summary"},

	     structure_data  => { url   =>"$ROOT/gene/structure_data",
				  label => 'Structure_data'},

	     transgene  => { url   => "$ROOT/gene/transgene",
			     label => 'Transgene Summary'},

	     tree       => { url     => "$ROOT/misc/etree",
			     label   => 'Tree Display'},

	     variation  => { url     => "$ROOT/gene/variation",
			     label   => 'Variation Summary'},

	     wtp        => { url   =>"$ROOT/seq/wtp",
			     label => 'WTP Summary'},

	     xml        => { url     => "$ROOT/misc/xml",
			     label   => 'XML'},

	     y2h        => { url => "$ROOT/seq/y2h",
			    label => 'Y2H interaction'},

	     yh        => { url => "$ROOT/seq/y2h",
			    label => 'YH interaction'},

);

# ========= %CLASSES =========
# displays to show
# Note: These MUST be ucfirst...
%CLASSES = (
	    Analysis        => ['analysis'],

	    Anatomy_term => [ 'aoterm' ],

            Anatomy_name => [ 'anatomy_name' ],

	    Antibody => [ 'antibody' ],

	    # two representations of Author
	    Author => [ qw/author biblio/ ],
	    # Author => [ qw/author biblio author_example/ ],

            Cds  => \&sequence_displays,

	    Cell => \&cell_displays,

	    # one representation of Clone, Paper, Laboratory, and Expr_pattern
	    Clone         => [ 'clone' ],

	    Condition        => ['condition'],

	    Expression_cluster  => [ 'expression_cluster' ],

	    Expr_pattern  => [ 'expr_pattern' ],

	    Expr_profile  => [ 'expr_profile' ],

	    Gene          => \&gene_displays,

	    Gene_class    => [ 'gene_class' ],

	    Gene_regulation => [ 'gene_regulation' ],

#	    Go_term       => [ 'go_term','go_dag' ],
	    Go_term       => [ 'go_term' ],

	    Homology_group => [ 'homology_group' ],

	    Interaction    => [ 'interaction' ],

	    Laboratory    => [ 'laboratory' ],

	    Life_stage    => [ 'life_stage' ],

	    # Deprecated with WS140
	    # Locus can be a genetic marker, sequenced gene, or polymorphism.
	    # This gets so complicated that we use a subroutine to decide what displays to show
	    Locus           => \&locus_displays,

	    Microarray_results => [ 'microarray_results' ],

	    Microarray_experiment => [ 'microarray_results' ],

	    Motif         => [ 'motif' ],

	    Oligo_set     => ['oligo_set'],

	    Operon        => [ 'operon' ],

	    Paper         => [ 'paper' ],

	    Pcr_product   => [ 'pcr_product' ],

	    Person        => [qw/person biblio/],

	    Person_name   => [qw/person biblio/],

            Phenotype     => [ 'phenotype' ],

	    Protein       => \&protein_displays,

	    Pseudogene    => [qw/gene hunter biblio/],

	    Rearrangement => [ 'rearrange' ],

	    Rnai          => [ 'rnai' ],

	    Sage_tag      => [ 'sagetag' ],

	    # there are two representations of sequence, in addition to the basic ones
	    Sequence      => \&sequence_displays,

	    SK_map        => [ 'expr_profile' ],

	    SNP           => [ 'snp' ],

	    Strain        => [ 'strain' ],

	    Structure_data => [ 'structure_data' ],
        
	    Transcript    => [ qw/gene hunter/ ],

	    Transgene     => [ 'transgene' ],
		
	    Variation     => \&variation_displays,

	    Wtp           => [ 'wtp' ],

            Y2H           => ['y2h'],

            YH           => ['yh'],
            
	    # default  has special meaning
	    Default => [ qw/tree xml model pic/ ],
	   );



sub tmpimages {
#    my ($server) = $ENV{SERVER_NAME} =~ /(.*?)\..*/;
#    $server    ||= 'local';
    my $host = `hostname`;
    chomp $host;
    $host ||= 'local';
    return $host;
}

# ========= &URL_MAPPER  =========
# mapping from object type to URL.  Return empty list to fall through
# to default.
sub URL_MAPPER {
    my ($display,$name,$class) = @_;

    $class   ||= '';
    $name    ||= '';
    $display ||= '';

    # Small Ace inconsistency: Models named "#name" should be
    # transduced to Models named "?name"
    $name = "?$1" if $class eq 'Model' && $name=~/^\#(.*)/;
    my $n = CGI::escape($name);
    my $c = CGI::escape($class);
    my $qs = "name=$n";
    my $qsc = "name=$n;class=$c";

#    return (go_dag    => $qsc) if $class eq 'go_dag';

    return (variation => $qsc) if $class eq 'Variation';

    return (gene_name => $qsc) if $class eq 'Gene_name';

    return (interaction => $qsc) if $class eq 'Interaction';

    # pictures remain pictures
    return (pic => $qsc )  if $display =~ /e?pic/ && $class ne 'Clone';
    
    # trees remain trees
    return (tree => $qsc ) if $display =~ /e?tree/;
    
    # this is a placeholder for a real database lookup
    if ($class eq 'Protein') {
      if ($name =~ /^SW:(\w+)/) {
#	return sprintf("http://srs.ebi.ac.uk/srs6bin/cgi-bin/wgetz?-id+3LIc21HeBHW+-e+[SWALL:'%s']",$1);
	  return sprintf($SRS,$1);
      } elsif ($name =~ /^TR:(\w+)/) {
	return sprintf("http://srs.ebi.ac.uk/srs6bin/cgi-bin/wgetz?-e+[SWALL-acc:%s]+-vn+2",$1);
      } else {
	return (protein  => $qsc);
      }
    }

    # Pseudogene display
    if ($class eq 'Pseudogene') {
      return (gene => $qsc);
    }

    if ($class eq 'Antibody') { return (antibody => $qsc); }

    # Direct CDS to gene
    # Hmm.  This should be conditional
    # Sometimes (the gene page) CDS objects should link to sequence.
    # Other times (the locus page) they should link to gene
    if ($class eq 'CDS') {
      return (gene => $qsc);
    }

    if ($class eq 'Gene') {
      #      return (gene => $qsc) if ($class eq 'Gene' && ref($name));
      #      my $bestname = $name->CGC_name || $name->Molecular_name || { $name->CDS->Corresponding_protein } || $name;
      return (gene=>$qsc) if (ref($name));
      # return (gene => $qsc,$bestname) if (ref($name));
      # return ('gene',{-name=>$bestname,-target=>$bestname}) if (ref($name));
    }

    # Deprecated by WS124?
    # Deprecated by WS140?
    if ($display ne 'gene') {
      # Gone in WS140
      #return (gene     => $qsc)
      #    	if $class eq 'Locus'
      #    	  && ref($name)
      #    	    && ($name->Gene_Cluster(0));
      return (gene     => $qsc) if $class eq 'Sequence'
	&& ref($name)
	  && eval {$name->Coding(0)};

      return (gene     => $qsc) if $class eq 'Protein'
	&& ref($name) 
	  && eval {$name->Wormpep(0)};
    }

    return (gene_regulation => $qsc) if ($class eq 'Gene_regulation');
    return (biblio   => "$qs&class=Keyword") if $class eq 'Keyword';
    return (tree     => $qsc)                if $class eq 'Metabolite';
    return (pedigree => "group=$n;show_group=1") if $class eq 'Cell_group';
    return (tree => $qsc) if $class eq 'SK_map';
    return (y2h =>$qsc) if $class eq 'Y2H';
    return (yh =>$qsc) if $class eq 'YH';
    
    if ($class eq 'Pathway') {
      return (pic  => $qsc )  if $name =~ /^\*/;
      return (tree => $qsc)   if $name !~ /^\*/;
    }

    return (pic => $qsc )
      if $class eq 'Map' && $name !~ /Sequence/i;

    if ($class eq 'Homol_data' && ref $name) {
      my $ref = $name->S_parent(2);
      return "/db/gb2/gbrowse/c_elegans/?name=$ref";
    }

    if ($class eq 'Nbrowse') {
        return (nbrowse   => $qs);
    }    

    # maps are always displayed graphically by default
    return (tree => $qsc )        if $display =~ /tree/i;
    return (pic => $qsc )         if $class   =~ /map/i;
    return;
}

# Configure displays for different pages dynamically
# Note: There is not a strict 1:1 relationship of class:page
sub gene_displays {
  my($class,$obj) = @_;
  my @default_list = qw(gene locus hunter biblio);
  return @default_list unless ref($obj) && $obj->class eq 'Gene';
  # Also a locus?
  my @list = $obj->CGC_name(0) ? ('gene','locus') : ('gene');

  my $genetically_mapped = eval {$obj->Map};
  my $physically_mapped  = $obj->Corresponding_CDS;
  push @list,qw(sequence protein aligner hunter)  if $physically_mapped;
  push @list,qw(hunter) if eval {$obj->Transcript};
  push @list,qw(gmap nearby_genes)                if $genetically_mapped || $physically_mapped;
  push @list,'biblio';
  return @list;
}

sub locus_displays {
    my($class,$obj) = @_;
    my @default_list = qw(gene locus hunter biblio);
    return @default_list unless ref($obj) && lc($obj->class) eq 'locus';
    my $genetically_mapped = eval {$obj->Map};
    my $physically_mapped  = eval {$obj->CDS || $obj->Corresponding_CDS};
    my @list = eval { $obj->Gene(0) } || eval { $obj->Gene_Cluster(0) } ? ('gene','locus') : ('locus');
    push @list,qw(sequence protein aligner hunter)  if $physically_mapped;
    push @list,qw(hunter) if eval {$obj->Transcript};
    push @list,qw(gmap nearby_genes)                if $genetically_mapped;
    push @list,'biblio';
    return @list;
}

sub variation_displays {
  my ($class,$obj) = @_;
  my @default_list = qw/variation/;
  
  if (ref $obj && $obj->Gene) {
      push @default_list,qw/gene locus/;
  }
  
  if (ref $obj && $obj->Flanking_Sequences) {
      push @default_list,'hunter';
  }
  return @default_list;
}

sub gbrowse_url {
    my $obj = shift;
    my $genus_species = $object->Species;
    my ($genus,$species) = $genus_species =~ /(.*) (.*)/;
    my $string = lc(substr($genus_species,0,1)) . "_$species";
        
    my $url = sprintf($HUNTER,$string,$obj);
    return $url;
}





sub sequence_displays {
  my ($class,$obj) = @_;
  my @default_list = qw(sequence);
  return @default_list unless ref $obj;
  if (eval { $obj->Gene }) {
      push @default_list,'gene';
  }

  if (eval{$obj->Coding(0)}) {
#      unshift @default_list,'gene';
      push @default_list,'protein','aligner';
  }
  push @default_list,qw(nearby_genes hunter);
  return @default_list;
}

sub protein_displays {
  my ($class,$obj) = @_;
  return 'protein' unless ref($obj) && $obj->class eq 'Protein';
  return unless $obj->Wormpep(0) or $obj->Database eq 'WormPep';
  return qw(gene sequence protein) if $obj->Corresponding_CDS;
}

sub cell_displays {
  my ($class,$obj) = @_;
  my @list = qw(cell aoterm pedigree);
  return @list unless ref($obj) && $obj->class eq 'Cell';
  my $type = $obj->Cell_type or return @list;
  push @list,'MindOfWorm'       if $type =~ /neuron/i;
  @list;
}

#sub aoterm_displays {
#  my ($class,$obj) = @_;
#  my @list = qw(aoterm);
#  return @list unless ref($obj) && $obj->class eq 'Anatomy_term';
#  push @list,'cell','pedigree' if $obj->Cell;
#  
#  @list;
#}

# ========= Configuration information for the simple search script
@SIMPLE = ('Any'              => 'Anything',
	   'AnyGene'          => 'Any Gene',
	   'Author_Person'    => 'Author/Person',
	   'Variation'        => 'Allele',
	   'Cell'             => 'Cell/Tissue',
	   'Clone'            => 'Clone',
	   'Model'            => 'Database Model',
	   'GO_term'          => 'Gene Ontology Term',
	   'Gene_class'       => 'Gene class',
	   'Genetic_map'      => 'Genetic Map',
	   'Accession_number' => 'Genbank Acc. Num',
	   'Paper'            => 'Literature Search',
	   'Microarray_results'   => 'Microarray Expt',
	   'Operon'           => 'Operon',
	   'Phenotype'        => 'Phenotype',
	   'PCR_Product'      => 'Primer Pair',
           'Protein',         => 'Protein, Any',
           'Wormpep',         => 'Protein, C. elegans',
	   'Motif'            => 'Protein Family/Motif',
	   'RNAi'             => 'RNAi Result',
      	   'Sequence'         => 'Sequence, Any',
	   'Genome_sequence', => 'Sequence, C. elegans',
	   'Strain'           => 'Strains',
           'Y2H'	      => 'Y2H interaction',
           'YH'	      => 'YH interaction',
	  );

# Jalview configuration information
$JALVIEW       =  '/applets/jalview.jar';
$JALVIEW_MAIL  = 'beta.crbm.cnrs-mop.fr';
$JALVIEW_HELP  = 'http://circinus.ebi.ac.uk:6543/jalview/help.html';

# ========= Configuration information for the feedback script
@FEEDBACK_RECIPIENTS = (
			[ ' Paul Sternberg <pws@its.caltech.edu>'     => 'general complaints and suggestions'=>1 ],
			[ ' Lincoln Stein <lstein@cshl.org>'          => 'user interface' ],
			[ ' wormbase@caltech.edu'          => 'cells and expression patterns' ],
			[ ' Jonathan Hodgkin & Sylvia Martinelli <cgc@mrc-lmb.cam.ac.uk>'  => 'genetic data; gene names'],
                        [ ' wormbase@caltech.edu '                     => 'gene regulation and interactions' ],
			[ ' Wen Chen <wen@vericelli.caltech.edu>'        => 'Addresses; WormBase User\'s Guide'   ],
			[ ' Theresa Stiernagle <stier@biosci.cbs.umn.edu>' => 'strains, bibliographic references' ],
                        [ ' Richard Durbin <rd@sanger.ac.uk>'              =>'systematic genome sequence analysis, acedb problems' ],
			[ ' John Spieth <jspieth@watson.wustl.edu>'              => 'St. Louis sequence annotations; gene structures' ],
			[ ' worm@sanger.ac.uk'                                   => 'Cambridge sequence annotations; gene structures' ],
			[ ' Alan Coulson <alan@sanger.ac.uk> '                   => 'physical map' ],
		       );
@FEEDBACK_CHECKED = (0);  # number zero is paul
$FEEDBACK_RECIPIENT = 'help@wormbase.org';

# position of the chromosome tables, in URL space
$CHROMOSOME_TABLES = "$WB/chromosomes";
$CHROMOSOME_TABLE_LENGTH = 2_000_000;

# all-important copyright statement
$COPYRIGHT = "$WB/copyright.html";

# == location of gbrowse script, called "hunter" for historical reasons  ==
$HUNTER = "/db/gb2/gbrowse/%s/?name=%s";

# ========= seqview/dasview script ===========
# dimensions of the transcript picture shown in the sequence screen
# THIS IS PRETTY MUCH ALL DEFUNCT, REPLACED BY GBROWSE CONFIG

$DASVIEW_WIDTH    = $PAGEWIDTH;
my @dasview_features = (
			'Predicted Genes'   => [qw(transcript:curated)],
			'Worm Transcriptome Project Genes' => [qw(partial_gene:WTP)],
			'ESTs Aligned with BLAT (best)' => [qw(alignment:BLAT_EST_BEST)],
 			'ESTs Aligned with BLAT (other)'   => [qw(alignment:BLAT_EST_OTHER)],
 			'mRNAs Aligned with BLAT (best)'   => [qw(alignment:BLAT_mRNA_BEST)],
 			'mRNAs Aligned with BLAT (other)'   => [qw(alignment:BLAT_mRNA_OTHER)],
			'Genbank entries' => [qw(Sequence:Genomic_canonical)],
 			tRNAs   => [qw(Sequence:tRNAscan-SE-1.11)],
			'RNAi experiments'   => [qw(experimental:RNAi)],
			Oligos   => [qw(structural:GenePair_STS structural:PCR_product)],
			Prosite => [qw(alignment:Queryprosite translation:Queryprosite)],
			HMMer  => [qw(alignment:hmmfs.3)],
			'Expression Chip Profiles' => [qw(Expression:Expr_profile)],
			'Transposon Insertions' => [qw(insertion ALLELE)],
			SNPs    => [qw(variation)],
			'Briggsae Alignments (BLAST)' => [qw(alignment:BLASTN_briggsae_cosmid alignment:TBLASTX_briggsae)],
			'Briggsae Alignments (WABA)' => [qw(alignment:WABA_briggsae_cosmid)],
			'BLASTX Hits'                => [qw(alignment:BLASTX)],
			'TBLASTX Hits'               => [qw(alignment:TBLASTX)],
			Misc     => [qw(misc_feature:tandem misc_feature:inverted)],
			Clones  => [qw(Clone structural:Clone)],

		       );


%DASVIEW_FEATURES = @dasview_features;
@DASVIEW_FEATURELIST = @dasview_features[map {2*$_} (0..@dasview_features/2-1)];
@DASVIEW_DEFAULT = ('ESTs Aligned with BLAT (best)','mRNAs Aligned with BLAT (best)','Predicted Genes',
                     qw(Clones Oligos RNAi),'Worm Transcriptome Project Genes','Briggsae Alignments (WABA)');

# what features to show by default in the sequence display
@SEQUENCE_FEATURES = ('Worm Transcriptome Project Genes','Predicted Genes','Oligos','RNAi',
		      'Briggsae','Transposon Insertions','SNPs');

# ======== geneapplet script ==========

$JADEX_PORT = 2005;
$JADEX_PATH = '/applets/jadex.jar';
$JADEX_IMAGE = "$WB/images/geneticMapApplet.gif";

# ======== promoter motif search script ==========
$PROMOTER_DB = "$WB/etc/promoters.db";

# ======== sequence script ======================
$SEQDIAGRAM_WIDTH = 800;
%MOTIF_URLs = (
	       INTERPRO   => 'http://www.ebi.ac.uk/interpro/IEntry?ac=',
	       Pfam       => 'http://www.sanger.ac.uk//cgi-bin/Pfam/getacc?',
           Prosite    => 'http://kr.expasy.org/cgi-bin/prosite-search-ac?',
	      );
%MOTIF_DATABASE_URLs = (
			INTERPRO => 'http://www.ebi.ac.uk/interpro/',
			Pfam     => 'http://www.sanger.ac.uk/Software/Pfam/',
		       );

# Gene ontology labels and sort order
# currently only used by the gene page.
%GO_CODES = (IC=>'Inferred by curator',
	     IDA => 'Inferred from direct assay',
	     IEA => 'Inferred from electronic annotation',
	     IEP => 'Inferred from expression pattern',
	     IGI => 'Inferred from genetic interaction',
	     IMP => 'Inferred from mutant phenotype',
	     IPI => 'Inferred from physical interaction',
	     ISS => 'Inferred from sequence or structural similarity',
	     NAS => 'Ion-traceable author statement',
	     ND  => 'No biological data available',
	     TAS => 'Traceable author statement');

%GO_SORT = (IDA => 'a',
            IMP => 'b',
            IGI => 'c',
            ISS => 'd',
            IPI => 'e',
            IEP => 'f',
            IEA => 'g',
            TAS => 'h',
            IC => 'i',
            NAS => 'j',
            NA => 'k' );



# Strain search configuration
# Directory containg indexes (ixw.bdb, ixp.bdb, ixd.bdb)
#$STRAIN_INDEX_DIR = "$WORMBASE/html/strains";
$STRAIN_INDEX_DIR = "$APPLICATION_ROOT/databases/strains";
$STRAIN_HTML_ROOT = "/strains";
# full path to the lookup.strains file
$STRAIN_FILE      = $STRAIN_INDEX_DIR . '/lookup.strains';

$STATIC_CACHE_ROOT = "$APPLICATION_ROOT/databases/%s/cache";

# Ontology Browser configuration
$ONTOLOGY_SOCKET_PATH = "$WORMBASE/sockets";

# external URLs
$WIKI         = 'http://wiki.wormbase.org/index.php/%s';
$BLAST        = '/db/searches/blast_blat';
$INTRONERATOR = 'http://www.cse.ucsc.edu/~kent/cgi-bin/tracks.exe?where=';
$HYMAN        = 'http://worm-srv1.mpi-cbg.de/dbScreen/cgi-bin/ViewRNA.py?RNAName=';
$RNAIDB	      = 'http://www.rnai.org/cgi-bin/rnai/browse/card.rnai.cgi?query=';
$PHENOBANK    = 'http://worm.mpi-cbg.de/phenobank2';
$ORFEOME      = 'http://worfdb.dfci.harvard.edu/searchallwormorfs.pl?by=name&sid=';
$MOVIE        = 'http://www.wormbase.org/ace_images/elegans/external/movies/';
$KOCONSORTIUM = 'http://celeganskoconsortium.omrf.org/';
$GO_EVIDENCE  = 'http://www.geneontology.org/GO.evidence.html';

# These are redundant with Ace::Browser::GeneSubs
# but are consolidated here for quicker and easier modification
#$SRS            = 'http://srs.ebi.ac.uk/srs6bin/cgi-bin/wgetz?-newId+[SWALL-AllText:%s*]+-lv+30+-view+SeqSimpleView';
#$SRS            = 'http://www.ebi.ac.uk/ebisearch/search.ebi?db=allebi&query=%s&FormsButton3=Go';
# Link directly to the protein page
$SRS             = 'http://www.ebi.ac.uk/ebisearch/search.ebi?db=proteinSequences&query=%s';

$NEXTDB         = 'http://spock.genes.nig.ac.jp/~genome/cgi-bin/mas.pl.cgi?cele0:';

$NEXTDB_HOME           = 'http://nematode.lab.nig.ac.jp/db2/index.php';
$NEXTDB_EXPRESSION     = 'http://nematode.lab.nig.ac.jp/db2/ShowCloneInfo.php?clone=%s';

$UNIPROT        = 'http://www.uniprot.org/entry/';
# NCBI - Some obvious redunancy here
$NCBI           = 'http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query';
$GENBANK        = 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=nucleotide&cmd=search&term=%s';

$OMIM           = 'http://www.ncbi.nlm.nih.gov/entrez/dispomim.cgi?id=';

# NCBI
$PUBMED         = 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=PubMed&cmd=Search&term=nematode+AND+';
$PUBMED_RETRIEVE  = 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=pubmed&cmd=retrieve&dopt=abstract&list_uids=';
# Old format
# $PUBMED       = 'http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=m&form=4&term=nematode [ORGANISM]+AND+';
# $PUBMED         = 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=PubMed&cmd=Search&term=nematode%20[ORGANISM]+AND+';
$ENTREZ         = 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search&db=Nucleotide&doptcmdl=GenBank&term=';
$ENTREZP        = 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search&db=Protein&doptcmdl=GenPep&term=';
$ENTREZ_GENE    = 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=gene&cmd=Retrieve&dopt=full_report&list_uids=';
$ACEVIEW        = 'http://www.ncbi.nlm.nih.gov/IEB/Research/Acembly/av.cgi?db=worm&q=%s';

$PROTEOME       = 'http://www.proteome.com/WormPD/';
$SWISSPROT      = 'http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=p&form=1&field=Sequence+ID&term=';

$TREEFAM        = 'http://www.treefam.org/';
$TREEFAM_REPORT = 'http://www.treefam.org/cgi-bin/TFinfo.pl?ac=%s';
#$TREEFAM_IMG    = 'http://www.treefam.org/cgi-bin/treeview.pl?htype=show_taxa&stype=full&ltype=equal&ac=%s&build=';
$TREEFAM_IMG     = 'http://www.treefam.org/cgi-bin/treeview.pl?pic&ac=%s&stype=clean&highlight=%s'; 
#$TREEFAM_IMG    = 'http://www.treefam.org/cgi-bin/treeview.pl?pic&htype=show_taxa&stype=full&ltype=equal&ac=%s';
#$TREEFAM_IMG     = 'http://www.treefam.org/cgi-bin/treeview.pl?ac=%s&stype=full';
$MEOW_CONFIRMED = 'http://iubio.bio.indiana.edu/meow/.bin/moquery?dbid=ACEDB:';
$MEOW_PREDICTED = 'http://iubio.bio.indiana.edu/meow/.bin/moquery?dbid=ACEPRED:';
$GENESERVICE    = 'http://www.geneservice.co.uk/products/tools/Celegans_Finder.jsp';
$GENESERVICE_ORF = 'http://www.geneservice.co.uk/products/cdna/Celegans_ORF.jsp';
$GENESERVICE_FOSMIDS = 'http://www.geneservice.co.uk/products/clones/Celegans_Fos.jsp';
$OPENBIO         = 'http://www.openbiosystems.com/Query/dfci.harvard.php?clone=%s';

$TEXTPRESSO     = 'http://www.textpresso.org/cgi-bin/wb/textpressoforwormbase.cgi?allabstracts=on&searchmode=sentence&searchtargets=Paper&searchtargets=Abstract';
# $TREMBL         = 'http://www.expasy.org/cgi-bin/get-sprot-entry?';
$TREMBL         = 'http://www.ebi.uniprot.org/entry/%s',
$WB_NOMENCLATURE            = 'http://wiki.wormbase.org/index.php/Nomenclature';
$CGC_HOME       = 'http://www.cbs.umn.edu/CGC/';
$REACTOME       = 'http://www.genomeknowledge.org/cgi-bin/search?QUERY=%s&QUERY_CLASS=DatabaseIdentifier';
$WBG            = 'http://www.wormbook.org/wli/';
$KIM_MOUNTAINS  = 'http://www.sciencemag.org/feature/data/kim1061603/gl/gene_list.html';

# The DOI resolver for WormBook chapters
$WORMBOOK        = 'http://www.wormbook.org/';
$WORMBOOK_SEARCH = 'http://www.wormbook.org/db/misc/search.cgi?search_html=on;search_preprints=on;query=%s';
$DOI             = 'http://dx.doi.org/';

# ========== data submission forms ======================
@SUBMIT_FORMS = (
		 { 'Gene name, gene class name proposals' => 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/gene_name.cgi', },
		 # { 'Locus/Sequence connections' => 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/gene_name.cgi',               },
		 { 'Allele data'                => 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/allele.cgi',       },
		 { '2-point data'               => 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/2_pt_data.cgi',    },
		 { 'Multipoint data'            => 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/multi_pt.cgi'      },
		 { 'Breakpoint data'            => 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/breakpoint.cgi',   },
		 { 'Deletion/duplication data'  => 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/df_dp.cgi',        },
		 { 'Rearrangement data'         => 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/rearrangement.cgi' },
		 # { 'Polymorphisms'              => 'http://www.sanger.ac.uk/Projects/C_elegans/CGC/Poly_form.shtml',     },
		);

# ======== map servlet URL =====================
$MAP_SERVLET = "http://www.wormbase.org:8080/mapview/servlet/LocusDisplayHtml";

# ==== list of known das servers ===
$DAS_SERVERS = "$CONF/das.servers";
$DAS_DRAW    = "/db/seq/dasdraw";
$Gbrowse     = '/db/gb2/gbrowse';

# ==== Genetic interval dumper script ====
$INTERVAL_MAX_SEARCH = 2;  # 2 cM dump max
$INTERVAL_INTERPOLATION_FILE = '/chromosomes/interpolated_positions.txt';
$INTERVAL_DEFAULT_SIZE = 0.3; # 0.3 cM default interval

# ======== life stages ordering.  hard coded for now ========
@LIFE_STAGES = (
  'all stages',
  'embryo',
  'postembryonic',
  'L1 larva',
  'L2 larva',
  'dauer larva',
  'L3 larva',
  'L4 larva',
  'adult',
  'adult hermaphrodite',
  'adult male',
#  '----------------------',
  ' ',
  'proliferating embryo',
  'elongating embryo',
  'fully-elongated embryo',
#  '----------------------',
  ' ',
  'blastula embryo',
  'gastrulating embryo',
  'enclosing embryo',
  'bean embryo',
  'comma embryo',
  '1.5-fold embryo',
  '2-fold embryo',
  '3-fold embryo',
#  '----------------------',
  ' ',
  '1-cell embryo',
  '2-cell embryo',
  '4-cell embryo',
  '51-cell embryo',
  '88-cell embryo',
#  '----------------------',
  ' ',
  'early L1 larva',
  'early larva',
  'late cleavage stage embryo',
  'late L1 larva',
  'late larva',
  'L3/L4 larva',
  'L4/adult moult',
                );

# ###################  seq/rnai configuration ################
$RNAI_MOVIE_PATH = '/ace_images/elegans/external/movies/';

###################### slidable worm #################
$SW_IMAGES  = '/atlas/sw';  # where the images are in URL
$SW_CARTOON = '/atlas/sw/slidableworm.png';  # navigation diagram, in URL space
$SW_MAP     = "$CONF/slidableworm.conf";

###################### PROTEIN LINKS #################
# This is a misnomer.  It is now being used for all sorts of external database links.
%PROTEIN_LINKS = (
		  GADFLY  => 'http://www.flybase.net/cgi-bin/annot/basic.pl?qtype=batch&qpage=queryresults&format=detail&datatype=annotation&qid=%s',
		  FLYBASE => 'http://flybase.net/reports/%s.html',
		  ENSEMBL => 'http://www.ensembl.org/Homo_sapiens/protview?peptide=%s',
		  SGD     => 'http://yeastgenome.org/cgi-bin/locus.fpl?locus=%s',
		  WP      => '/db/seq/protein?class=Protein;name=WP:%s',
		  BP      => '/db/seq/protein?class=Protein;name=BP:%s',
		  RP      => '/db/seq/protein?class=Protein;name=RP:%s',		  
		  CN      => '/db/seq/protein?class=Protein;name=CN:%s',
		  JA      => '/db/seq/protein?class=Protein;name=JA:%s',
		  PP      => '/db/seq/protein?class=Protein;name=PP:%s',
		  VG      => 'http://vega.sanger.ac.uk/Homo_sapiens/protview?peptide=%s&amp;db=core',
		  SW      => 'http://www.ebi.uniprot.org/entry/%s',
		  SPTREMBL=> 'http://www.ebi.uniprot.org/entry/%s',
		  TR      => 'http://www.ebi.uniprot.org/entry/%s',
		  PFAM    => 'http://www.sanger.ac.uk//cgi-bin/Pfam/getacc?%s',
		  PS      => 'http://www.expasy.ch/cgi-bin/prosite-search-de?%s',
		  INTERPRO => 'http://www.ebi.ac.uk/interpro/IEntry?ac=%s',
		  NCBI =>     'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=protein&cmd=search&term=%s',
		  EMBL =>     'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=nucleotide&cmd=search&term=%s',
		  REFSEQ  => 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search&db=Protein&term=%s[accn]&doptcmdl=GenPept',
		  TARGETDB       => 'http://targetdb.pdb.org/servlet/TargetSearch?seqname=Query&id=%s&pdbid=&pfamid=&status=&which_lab=%s&which_seq=ALL&Aftermonth=&Afterday=&Afteryear=&Beforemonth=&Beforeday=&Beforeyear=&p_name=&org_name=&Sequence=&evalue=10&format=html&cp=1',         
		  NESG_TARGET    => 'http://spine.nesg.org/target.pl?id=%s',
		  NESG_GALLERY   => 'http://spine.nesg.org:7000/gallery/jsp/ShowStructure.jsp?pdb_id=%s',
		  PDB            => 'http://pdb.rcsb.org/pdb/explore.do?structureId=%s',
		  PFAM_WITH_PDB  => 'http://www.sanger.ac.uk//cgi-bin/Pfam/getacc?acc=%s&pdb=%s',
		  HI	=> 'http://www.jbirc.jbic.or.jp/hinv/spsoup/transcript_view?hit_id=%s'
		  );


# Used for classifying / sorting references on the gene and biblio pages
%BIBLIOGRAPHY_PATTERNS = (
		 'ALL' => 'All Papers',
		 'WBG' => 'Worm Breeders Gazette Abstracts',
		 'CGC' => 'Papers in WormBase Bibliography',
		 'WMA' => 'Worm Meeting Abstracts',
		 'WB'  => 'WormBook Chapters',
		 );


%SPECIES_TO_URL  = (
		    'Caenorhabditis elegans'      => '/db/seq/protein?class=Protein;name=%s',
		    'Caenorhabditis briggsae'     => '/db/seq/protein?class=Protein;name=%s',
		    'Dictyostelium discoideum'    => 'http://dictybase.org/db/cgi-bin/gene_page.pl?dictybaseid=%s',
		    'Drosophila melanogaster'     => 'http://flybase.net/cgi-bin/fbidq.html?FBan%s',
		    'Drosophila pseudoobscura'    => 'http://flybase.net/cgi-bin/fbidq.html?FBan%s',
#		    'Homo sapiens'                => 'http://www.ensembl.org/Homo_sapiens/searchview?species=Homo_sapiens;idx=;q=%s',
		    'Homo sapiens'                     => 'http://www.ensembl.org/%s/protview?peptide=%s',
		    'Mus musculus'                => 'http://www.informatics.jax.org/javawi2/servlet/WIFetch?page=searchTool&query=%s&selectedQuery=Genes+and+Markers',
		    'Oryza sativa'                => 'http://www.gramene.org/db/protein/protein_search?acc=%s',
		    'Rattus norvegicus'           => 'http://rgd.mcw.edu/tools/genes/genes_view.cgi?id=%s',
		    'Saccharomyces cerevisiae'    => 'http://genome-www4.stanford.edu/cgi-bin/SGD/locus.pl?locus=%s',
		    'Schizosaccharomyces pombe'   => 'http://www.genedb.org/genedb/Search?name=%s&organism=pombe&desc=yes&wildcard=yes&searchId=Search',
		    'ensembl'                     => 'http://www.ensembl.org/%s/protview?peptide=%s',
		    'refseq'                      => 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search&db=Protein&term=%s[accn]&doptcmdl=GenPept',
		);



# session management files
$SESSION = "$WORMBASE/html/session";


# Structure images dir
$STRUCTURE_IMAGES_DIR = '/images/structure-images/prot2prot';

# Pfam images dir
$PFAM_IMAGES_DIR = '/images/structure-images/pfam2prot';

# Pfam images dir
$PFAM_IMAGES_DIR = '/images/structure-images/pfam2prot';

# Geo Map related
$GEO_MAP_TEMPLATES = $WORMBASE . '/html/geo_map/templates';

1;
