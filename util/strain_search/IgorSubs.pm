package IgorSubs;


require Exporter;

use vars qw(
            @ISA @EXPORT @EXPORT_OK
            $VERSION 
	    );
use strict;

@ISA = qw(Exporter);
@EXPORT = qw(PrintTop PrintBottom);
@EXPORT_OK = qw();
$VERSION = 1.00;





sub PrintTop {
    my $title=shift;
    my $fh=shift;
    my $body=shift;
    if ($fh) {
	if (!fileno($fh)) {
	    print "filehandle $fh is not opened\n";
	    exit;
	}
	select($fh);
    }

    print qq(


	     <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
	     <html><head>
	     <title>$title</title>
	     
	     
	     <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
	     <link rel="stylesheet" href="/stylesheets/wormbase.css"></head><body $body>
	     <script type="text/javascript">
	     <!--
	     function c(p){location.href=p;return false;}
	     // -->
	     </script>
	     <table border="0" cellpadding="4" cellspacing="1" width="100%">
	     <tbody><tr>
	     <td style="" onclick="c('/')" align="center" bgcolor="#5870a3" nowrap="nowrap">
	     <a href="http://wormbase.org/" class="binactive"><font color="#ffff99"><b>Home</b></font></a></td>
	     <td style="" onclick="c('/db/seq/gbrowse/wormbase/')" align="center" bgcolor="#5870a3" nowrap="nowrap">
	     <a href="http://www.wormbase.org/db/seq/gbrowse/wormbase/" class="binactive"><font color="#ffffff">Genome</font></a></td>
	     <td style="" onclick="c('/db/searches/blat')" align="center" bgcolor="#5870a3" nowrap="nowrap">
	     <a href="http://www.wormbase.org/db/searches/blat" class="binactive"><font color="#ffffff">Blast / Blat</font></a></td>
	     <td style="" onclick="c('http://www.wormbase.org/Multi/martview')" align="center" bgcolor="#5870a3" nowrap="nowrap">
	     <a href="http://www.wormbase.org/Multi/martview" class="binactive"><font color="#ffffff">WormMart</font></a></td>
	     <td style="" onclick="c('/db/searches/advanced/dumper')" align="center" bgcolor="#5870a3" nowrap="nowrap">
	     <a href="http://www.wormbase.org/db/searches/advanced/dumper" class="binactive"><font color="#ffffff">Batch Sequences</font></a></td>
	     <td style="" onclick="c('/db/searches/strains')" align="center" bgcolor="#5870a3" nowrap="nowrap">
	     <a href="http://www.wormbase.org/db/searches/strains" class="binactive"><font color="#ffffff">Markers</font></a></td>
	     <td style="" onclick="c('/db/gene/gmap')" align="center" bgcolor="#5870a3" nowrap="nowrap">
	     <a href="http://www.wormbase.org/db/gene/gmap" class="binactive"><font color="#ffffff">Genetic Maps</font></a></td>
	     <td style="" onclick="c('/db/curate/base')" align="center" bgcolor="#5870a3" nowrap="nowrap">
	     <a href="http://www.wormbase.org/db/curate/base" class="binactive"><font color="#ffffff">Submit</font></a></td>
	     <td style="" onclick="c('/db/misc/site_map?format=searches')" align="center" bgcolor="#5870a3" nowrap="nowrap">
	     <a href="http://www.wormbase.org/db/misc/site_map?format=searches" class="binactive"><font color="#ffffff"><b>Searches</b></font></a></td>
	     <td style="" onclick="c('/db/misc/site_map')" align="center" bgcolor="#5870a3" nowrap="nowrap">
	     <a href="http://www.wormbase.org/db/misc/site_map" class="binactive"><font color="#ffffff"><b>Site Map</b></font></a></td>
	     </tr>
	     </tbody></table><table nowrap="1" border="0" cellpadding="0" cellspacing="1" width="100%"><tbody><tr class="white" nowrap="1" valign="top"><td align="left" valign="middle" width="50%">
	     	     
	     <form method="post" action="http://www.wormbase.org/db/searches/basic" enctype="multipart/form-data">
	     <b>Find: <input name="query" size="12" type="text"></b> 
	     <i><select name="class">
	     <option value="Any">Anything</option>
	     <option selected="selected" value="AnyGene">Any Gene</option>
	     <option value="Author_Person">Author/Person</option>
	     <option value="Variation">Allele</option>
	     <option value="Cell">Cell</option>
	     <option value="Clone">Clone</option>
	     <option value="Model">Database Model</option>
	     <option value="GO_term">Gene Ontology Term</option>
	     <option value="Gene_class">Gene class</option>
	     <option value="Genetic_map">Genetic Map</option>
	     <option value="Accession_number">Genbank Acc. Num</option>
	     <option value="Paper">Literature Search</option>
	     <option value="Microarray_results">Microarray Expt</option>
	     <option value="Operon">Operon</option>
	     <option value="PCR_Product">Primer Pair</option>
	     <option value="Protein">Protein, Any</option>
	     <option value="Wormpep">Protein, C. elegans</option>
	     <option value="Motif">Protein Family/Motif</option>
	     <option value="RNAi">RNAi Result</option>
	     <option value="Sequence">Sequence, Any</option>
	     <option value="Genome_sequence">Sequence, C. elegans</option>
	     <option value="Strain">Strain, C. elegans</option>
	     <option value="Y2H">Y2H interaction</option>
	     </select> </i>
	     </form>
	     
	     </td> <td align="right"><a href="http://www.wormbase.org/"><img src="/images/image_new_colour.jpg" alt="WormBase Banner" border="0"></a></td></tr></tbody></table><br>                                               
	     
	     
	     <p>   <!-- End of Wormbase Header -->                                   
	     </p>
	     );
    
    if ($fh) {
	select(STDOUT);
    }
}





sub PrintBottom {  
    my $fh=shift;
    if ($fh) {
	if (!fileno($fh)) {
	    print "filehandle $fh is not opened\n";
	    exit;
	}
	select($fh);
    }

    print qq (
	      <hr>
	      <table width="100%"><tbody><tr><td class="small" align="left"><a href="mailto:webmaster\@wormbase.org">webmaster\@www.wormbase.org</a></td> <td class="small" align="right"><a href="http://www.wormbase.org/copyright.html">Copyright Statement</a></td></tr> <tr><td class="small" align="left"><a target="_blank" href="http://www.wormbase.org/db/misc/feedback">Send comments or questions to WormBase</a></td> <td class="small" align="right"><a href="http://www.wormbase.org/privacy.html">Privacy Statement</a></td></tr></tbody></table>
	      );
    if ($fh) {
	select(STDOUT);
    }
}



1;
