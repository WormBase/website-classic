<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:template name="footer">
        <div class="footer">
            <table width="100%">
                <tr class="small">
                    <td align='left'>
                        <a href="http://www.gmod.org">The GMOD project</a>
                    </td>
                    <td align='right'>
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
    </xsl:template>
</xsl:stylesheet>
