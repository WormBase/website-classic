<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:template name="contact">
        <span class="contact">
            For additional details about these datasets, contact <a>
                <xsl:attribute name="href">
                    <xsl:text>mailto:</xsl:text>
                    <xsl:value-of select="//admin_contact"/>
                </xsl:attribute>
                <xsl:value-of select="//admin_contact"/>
            </a>.
        </span>
    </xsl:template>
</xsl:stylesheet>
