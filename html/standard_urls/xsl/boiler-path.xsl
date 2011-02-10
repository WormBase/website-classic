<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:template name="path">
        <div class="header2">
            <a>
                <xsl:attribute name="href">
                    <xsl:value-of select="//mod_url"/>
                </xsl:attribute>
                <xsl:value-of select="//name"/>
            </a> / <a>
                <xsl:attribute name="href">
                    <xsl:value-of select="//mod_url"/>/genome</xsl:attribute>genome</a>
            <xsl:if test="$selected_species"> / <a>
                    <xsl:attribute name="href">
                        <xsl:value-of select="//mod_url"/>/genome/<xsl:value-of
                            select="$selected_species"/>
                    </xsl:attribute>
                    <xsl:value-of select="$selected_species"/>
                </a>
            </xsl:if>
            <xsl:if test="$selected_release"> / <a>
                    <xsl:attribute name="href">
                        <xsl:value-of select="//mod_url"/>/genome/<xsl:value-of
                            select="$selected_species"/>/<xsl:value-of select="$selected_release"/>
                    </xsl:attribute>
                    <xsl:value-of select="$selected_release"/>
                </a>
            </xsl:if>
        </div>
    </xsl:template>
</xsl:stylesheet>
