<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:include href="boiler-banner.xsl"/>
    <xsl:include href="boiler-about_mods.xsl"/>
    <xsl:include href="boiler-contact.xsl"/>
    <xsl:include href="boiler-path.xsl"/>
    <xsl:include href="boiler-footer.xsl"/>
    <!-- catch variables passed in from the handler -->
    <!-- path elements, largely -->
    <xsl:param name="selected_species"/>
    <xsl:param name="selected_release"/>
    <xsl:param name="selected_genome"/>
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
                        <div class="header3">Standard URLs for <i>
                                <xsl:value-of select="$selected_species"/>
                            </i>, release <xsl:value-of select="$selected_release"/>. <xsl:for-each
                                select="//release">
                                <xsl:if test="version=$selected_release">
                                    <div class="description">
                                        <table>
                                            <tr>
                                                <th> Release date </th>
                                                <td>
                                                  <xsl:choose>
                                                  <xsl:when test="release_date!=0">
                                                  <xsl:value-of select="release_date"/>
                                                  </xsl:when>
                                                  <xsl:when test="release_date!=here">
                                                  unknown 
                                                  </xsl:when>
                                                  </xsl:choose>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Source MOD</th>
                                                <td>
                                                  <a>
                                                  <xsl:attribute name="href">
                                                  <xsl:value-of select="//mod_url"/>
                                                  </xsl:attribute>
                                                  <xsl:value-of select="//name"/>
                                                  </a>
                                                </td>
                                            </tr>
                                        </table>
                                    </div>
                                </xsl:if>
                            </xsl:for-each>
                        </div>
                        <div class="header3">Available datasets</div>
                        <xsl:for-each select="release">
                            <xsl:call-template name="available_releases"/>
                        </xsl:for-each>
                        <xsl:call-template name="contact"/>
                        <!-- about gmod common URLs -->
                        <xsl:call-template name="about_mods"/>
                    </div>
                    <xsl:call-template name="footer"/>
                </body>
            </html>
        </xsl:for-each>
    </xsl:template>
    <!-- display available datasets: corresponds to http://a-mod.org/genome/Binomial_name/release -->
    <xsl:template name="available_releases">
            <xsl:if test="version=$selected_release">
                <div class="description">The following datasets are available through the common URL
                    mechanism. Contents of each URL are described below.</div>
                <div class="specification">
                    <table>
                        <tr>
                            <th>dataset</th>
                            <th>url</th>
                        </tr>
                        <xsl:for-each select="//supported_datasets/*">
                            <tr>
                                <td>
                                    <xsl:value-of select="."/>
                                </td>
                                <td class="mono">
                                    <a>
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="//mod_url"/>/genome/<xsl:value-of
                                                select="$selected_species"/>/<xsl:value-of
                                                select="$selected_release"/>/<xsl:value-of
                                                select="."/>
                                        </xsl:attribute>
                                        <xsl:value-of select="//mod_url"/>/genome/<xsl:value-of
                                            select="$selected_species"/>/<xsl:value-of
                                            select="$selected_release"/>/<xsl:value-of select="."/>
                                    </a>
                                </td>
                            </tr>
                        </xsl:for-each>
                    </table>
                </div>
            </xsl:if>
    </xsl:template>
</xsl:stylesheet>
