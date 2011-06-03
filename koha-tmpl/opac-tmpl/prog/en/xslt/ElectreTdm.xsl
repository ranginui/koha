<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:msxsl="urn:schemas-microsoft-com:xslt"
xmlns:user="http://mycompany.com/mynamespace"
version="1.0" exclude-result-prefixes="user
msxsl">
<xsl:output
method="xml"
omit-xml-declaration="yes"
indent="no"
/>
<xsl:template match="tdm">
<table width="100%" class="electretdmtable">
<xsl:for-each select="head">
<tr>
<xsl:choose>
<xsl:when test="@level =
'0'">
<td align="center"
class="tochead0"><xsl:value-of select="."/></td>
</xsl:when>
<xsl:when test="@level =
'1'">
<td align="center"
class="tochead1"><xsl:value-of select="."/></td>
</xsl:when>
<xsl:when test="@level =
'2'">
<td align="center"
class="tochead2"><xsl:value-of select="."/></td>
</xsl:when>
<xsl:otherwise>
<td align="center"
class="tochead_other"><xsl:value-of select="."/></td>
</xsl:otherwise>
</xsl:choose>
</tr>
</xsl:for-each>
</table>
<table width="100%" class="electretdmtable">
<xsl:for-each select="tocitem">
<tr>
<xsl:choose>
<xsl:when test="item/@level =
'0'">
<td
class="tocbody0"><h1><xsl:apply-templates/></h1></td>
<td align="right"
class="tocbody0"><h1><xsl:value-of select="page"/></h1></td>
</xsl:when>
<xsl:when test="item/@level =
'1'">
<td class="tocbody1a">
<h2><xsl:apply-templates/></h2>
</td>
<td align="right"
class="tocbody1b"><h2><xsl:value-of select="page"/></h2></td>
</xsl:when>
<xsl:when test="item/@level =
'2'">
<td class="tocbody2a">
<xsl:apply-templates/>
</td>
<td align="right"
class="tocbody2b"><xsl:value-of select="page"/></td>
</xsl:when>
<xsl:when test="item/@level =
'3'">
<td class="tocbody3a">
<xsl:apply-templates/>
</td>
<td align="right"
class="tocbody3b"><xsl:value-of select="page"/></td>
</xsl:when>
<xsl:otherwise>
<td class="tocbody_othera">
<xsl:apply-templates/>
</td>
<td align="right"
class="tocbody_otherb"><xsl:value-of select="page"/></td>
</xsl:otherwise>
</xsl:choose>
</tr>
</xsl:for-each>
</table>
</xsl:template>
<xsl:template match="item">
<xsl:apply-templates/>
</xsl:template>
<xsl:template match="page" />
<xsl:template match="br">
<br /><xsl:apply-templates/>
</xsl:template>
<xsl:template match="i">
<i><xsl:apply-templates/></i>
</xsl:template>
<xsl:template match="b">
<b><xsl:apply-templates/></b>
</xsl:template>
<xsl:template match="sup">
<sup><xsl:apply-templates/></sup>
</xsl:template>
<xsl:template match="sub">
<sub><xsl:apply-templates/></sub>
</xsl:template>
</xsl:stylesheet>
