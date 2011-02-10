<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:include href="boiler-banner.xsl"/>
    <xsl:include href="boiler-about_mods.xsl"/>
    <xsl:include href="boiler-contact.xsl"/>
    <xsl:include href="boiler-path.xsl"/>
    <xsl:include href="boiler-footer.xsl"/>
    <!-- catch variables passed in from the handler -->
    <xsl:param name="selected_species"/>
    <xsl:param name="selected_release"/>
    <!-- root the tree at the selected species -->
    <xsl:template match="gmod_standard_urls">
        <xsl:for-each select="species[short_name = $selected_species]">
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
                        
                        <div class="description">This is the index page for <span class="species"><xsl:value-of
                                select="$selected_species"/></span> datasets available through the common
                            URL protocol. These datasets are housed at <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="//mod_url"/>
                                </xsl:attribute>
                                <xsl:value-of select="//name"/>
                            </a>.
                        </div>
                      
                        <div class="specification">
                            <table>
                                <tr>
                                    <th>Release</th>
                                    <th>Release date</th>
                                    <th>Availability</th>
                                    <th>Notes</th>
                                </tr>                        
                        <xsl:for-each select="release">
                            <xsl:sort select="version" order="descending"/>
                            <xsl:call-template name="available_releases"/>
                        </xsl:for-each>
                            </table>
                        </div>
                        <xsl:call-template name="contact"/>
                        
                        <!-- about gmod common URLs -->
                        <xsl:call-template name="about_mods"/>
                    </div>
                    <xsl:call-template name="footer"/>
                </body>
            </html>
        </xsl:for-each>
    </xsl:template>
    <!-- display available species: corresponds to http://a-mod.org/genome/Binomial_name -->
    <xsl:template name="available_releases">
                    <tr>
                        <td>
                            <xsl:choose>
                                <xsl:when test="available='yes'">
                                    <a>
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="//mod_url"/>/genome/<xsl:value-of
                                                select="$selected_species"/>/<xsl:value-of
                                                select="version"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="version"/>
                                    </a>
                                </xsl:when>
                                <xsl:when test="available='no'">
                                    <xsl:value-of select="version"/>
                                </xsl:when>
                            </xsl:choose>
                        </td>
                        <td>
                            <xsl:value-of select="release_date"/>
                        </td>
                        <td>
                            <xsl:value-of select="available"/>
                        </td>
                        <td>
                            <xsl:value-of select="notes"/>
                        </td>
                    </tr>
    </xsl:template>
</xsl:stylesheet>
