<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:include href="boiler-banner.xsl"/>
    <xsl:include href="boiler-about_mods.xsl"/>
    <xsl:include href="boiler-contact.xsl"/>
    <xsl:include href="boiler-path.xsl"/>
    <xsl:include href="boiler-footer.xsl"/>
    <!-- start at the top of the document root -->
    <xsl:param name="selected_species"/>
    <xsl:param name="selected_release"/>
    <xsl:param name="selected_genome"/>
    <xsl:template match="/gmod_standard_urls">
        <html>
            <head>
                <link rel="stylesheet" href="/standard_urls/gmod.css" type="text/css"/>
                <!-- set the title to the name of the MOD -->
                <title> Model Organism Database Common URLs: <xsl:value-of select="//name"/>
                </title>
            </head>
            <body>
                <!-- boiler -->
                <xsl:call-template name="banner"/>
                <div id="content">
                    <xsl:call-template name="path"/>
                    <div class="description">This is the index page for <a>
                            <xsl:attribute name="href">
                                <xsl:value-of select="//mod_url"/>
                            </xsl:attribute>
                            <xsl:value-of select="//name"/>
                        </a> datasets available through the GMOD commom URL protocol. The following
                        species are available: </div>
                    <xsl:if test="species">
                        <xsl:call-template name="available_species"/>
                    </xsl:if>
                    <xsl:call-template name="contact"/>
                    <!-- about gmod common URLs -->
                    <xsl:call-template name="about_mods"/>
                </div>
                <xsl:call-template name="footer"/>
            </body>
        </html>
    </xsl:template>
    <!-- display available species: corresponds to http://a-mod.org/genome -->
    <xsl:template name="available_species">
        <!--        <div class="header3">Available species</div>
        <div class="description">The following species are available at <xsl:value-of
                select="//name"/> through the common URL mechanism.        
        </div> -->
        <div class="specification">
            <table>
                <tr>
                    <th>Short name</th>
                    <th>Binomial name</th>
                    <th>description</th>
                </tr>
                <xsl:for-each select="//species">
                    <tr>
                        <td>
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="//mod_url"/>/genome/<xsl:value-of
                                        select="short_name"/>
                                </xsl:attribute>
                                <xsl:value-of select="short_name"/>
                            </a>
                        </td>
                        <td>
                            <xsl:value-of select="binomial_name"/>
                        </td>
                        <td>
                            <xsl:value-of select="species_description"/>
                        </td>
                    </tr>
                </xsl:for-each>
            </table>
        </div>
    </xsl:template>
</xsl:stylesheet>
