<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:template name="about_mods">
        <div class="header2">About GMOD common URLs</div>
        <div class="header3">Overview</div>
        <div class="description">In order to simplify the retrieval of common datasets, the Generic
            Model Organisms Database (GMOD) community has implemented a series of standard URLs.
            Each MOD has an index page like this one describing the species and datasets that are
            available.  Read more about the GMOD project at <a href="http://www.gmod.org/">www.gmod.org</a>.</div>
        <div class="header3">Available URLs</div>
        <div class="description">Version 1.0 of the common URL specification defines the following
            URLs (all located under <span class="mono">http://yoursite.org/</span>): </div>
        <div class="specification">
            <table cellpadding="3" cellspacing="1" border="1">
                <tr>
                    <td class="mono">/genome</td>
                    <td>Display this HTML-formatted index page that contains links to each of the
                        species available through common URLs. </td>
                </tr>
                <tr>
                    <td class="mono">/genome/Binomial_name</td>
                    <td>An index page for species "Binomial_name". This will be an HTML-format page
                        containing links to each of the genome releases. </td>
                </tr>
                <tr>
                    <td class="mono">/genome/Binomial_name/release</td>
                    <td>Leads to index for the named release. It should be an HTML-format page
                        containing links to each of the data sets described below. </td>
                </tr>
                <tr>
                    <td class="mono">/genome/Binomial_name/current</td>
                    <td>Leads to an index of the most current release, symbolic link style. </td>
                </tr>
                <tr>
                    <td class="mono">/genome/Binomial_name/current/dna</td>
                    <td>Returns a FASTA file containing big DNA fragments (e.g. chromosomes). MIME
                        type is application/x-fasta. </td>
                </tr>
                <tr>
                    <td class="mono">/genome/Binomial_name/current/mrna</td>
                    <td>Returns a FASTA file containing spliced mRNA transcript sequences. MIME type
                        is application/x-fasta. </td>
                </tr>
                <tr>
                    <td class="mono">/genome/Binomial_name/current/ncrna</td>
                    <td>Returns a FASTA file containing non-coding RNA sequences. MIME type is
                        application/x-fasta. </td>
                </tr>
                <tr>
                    <td class="mono">/genome/Binomial_name/current/protein</td>
                    <td>Returns a FASTA file containing all the protein sequences known to be
                        encoded by the genome. MIME type is application/x-fasta </td>
                </tr>
                <tr>
                    <td class="mono">/genome/Binomial_name/current/feature</td>
                    <td>Returns a GFF3 file describing genome annotations. MIME type is
                        application/x-gff3. </td>
                </tr>
            </table>
        </div>
        <div class="header3">Participating MODs</div>
        <div class="description">
            <table cellpadding="3" cellspacing="1" border="1">
                <tr>
                    <th>MOD</th>
                    <th>Standard URL Index Page</th>
                    <th>Description</th>
                </tr>
                <tr>
                    <td>
                        <a href="http://www.wormbase.org">WormBase</a>
                    </td>
                    <td>
                        <a href="http://www.wormbase.org/genome">http://www.wormbase.org/genome</a>
                    </td>
                    <td>The database of C. elegans and related nematodes</td>
                </tr>
            </table>
        </div>
    </xsl:template>
</xsl:stylesheet>
