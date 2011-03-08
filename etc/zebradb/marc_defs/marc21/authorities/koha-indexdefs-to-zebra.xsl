<?xml version='1.0'?>
<xsl:stylesheet version="1.0" 
                xmlns:marc="http://www.loc.gov/MARC21/slim" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xslo="http://www.w3.org/1999/XSL/TransformAlias"
                xmlns:z="http://indexdata.com/zebra-2.0"
                xmlns:kohaidx="http://www.koha-community.org/schemas/index-defs">

    <xsl:namespace-alias stylesheet-prefix="xslo" result-prefix="xsl"/>
    <xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>
    <!-- disable all default text node output -->
    <xsl:template match="text()"/>

    <!-- Keys on tags referenced in the index definitions -->
    <xsl:key name="index_control_field_tag"   match="kohaidx:index_control_field"   use="@tag"/>
    <xsl:key name="index_subfields_tag" match="kohaidx:index_subfields" use="@tag"/>
    <xsl:key name="index_heading_tag"   match="kohaidx:index_heading"   use="@tag"/>
    <xsl:key name="index_match_heading_tag" match="kohaidx:index_match_heading" use="@tag"/>

    <xsl:template match="kohaidx:index_defs">
        <xslo:stylesheet version="1.0">
            <xslo:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>
            <xslo:template match="text()"/>
            <xslo:template match="text()" mode="index_subfields"/>
            <xslo:template match="text()" mode="index_heading"/>
            <xslo:template match="text()" mode="index_match_heading"/>
            <xslo:template match="text()" mode="index_subject_thesaurus"/>
            <xslo:template match="/">
                <xslo:if test="marc:collection">
                    <collection>
                        <xslo:apply-templates select="marc:collection/marc:record"/>
                    </collection>
                </xslo:if>
                <xslo:if test="marc:record">
                    <xslo:apply-templates select="marc:record"/>
                </xslo:if>
            </xslo:template>

            <xslo:template match="marc:record">
                <xslo:variable name="controlField001" select="normalize-space(marc:controlfield[@tag='001'])"/>
                <z:record type="update">
                    <xslo:attribute name="z:id"><xslo:value-of select="$controlField001"/></xslo:attribute>
                    <xslo:apply-templates/>
                    <xslo:apply-templates mode="index_subfields"/>
                    <xslo:apply-templates mode="index_heading"/>
                    <xslo:apply-templates mode="index_match_heading"/>
                    <xslo:apply-templates mode="index_subject_thesaurus"/>
                </z:record>
            </xslo:template>

            <xsl:call-template name="handle-index-leader"/>
            <xsl:call-template name="handle-index-control-field"/>
            <xsl:call-template name="handle-index-subfields"/>
            <xsl:call-template name="handle-index-heading"/>
            <xsl:call-template name="handle-index-match-heading"/>
            <xsl:apply-templates/>
        </xslo:stylesheet>
    </xsl:template>

    <!-- map kohaidx:var to stylesheet variables -->
    <xsl:template match="kohaidx:var">
        <xslo:variable>
            <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
            <xsl:value-of select="."/>
        </xslo:variable>
    </xsl:template>

    <xsl:template match="kohaidx:index_subject_thesaurus">   
        <xsl:variable name="tag"><xsl:value-of select="@tag"/></xsl:variable>
        <xsl:variable name="offset"><xsl:value-of select="@offset"/></xsl:variable>
        <xsl:variable name="length"><xsl:value-of select="@length"/></xsl:variable>
        <xsl:variable name="detail_tag"><xsl:value-of select="@detail_tag"/></xsl:variable>
        <xsl:variable name="detail_subfields"><xsl:value-of select="@detail_subfields"/></xsl:variable>
        <xsl:variable name="indexes">
            <xsl:call-template name="get-target-indexes"/>
        </xsl:variable>
        <xslo:template mode="index_subject_thesaurus">
            <xsl:attribute name="match">
                <xsl:text>marc:controlfield[@tag='</xsl:text>
                <xsl:value-of select="$tag"/>
                <xsl:text>']</xsl:text>
            </xsl:attribute>
            <xslo:variable name="thesaurus_code1">
                <xsl:attribute name="select">
                    <xsl:text>substring(., </xsl:text>
                    <xsl:value-of select="$offset + 1" />
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$length" />
                    <xsl:text>)</xsl:text>
                </xsl:attribute>
            </xslo:variable>
            <xsl:variable name="alt_select">
                <xsl:text>//marc:datafield[@tag='</xsl:text>
                <xsl:value-of select="$detail_tag"/>
                <xsl:text>']/marc:subfield[@code='</xsl:text>
                <xsl:value-of select="$detail_subfields"/>
                <xsl:text>']</xsl:text>
            </xsl:variable>
            <xslo:variable name="full_thesaurus_code">
                <xslo:choose>
                    <xslo:when test="$thesaurus_code1 = 'a'"><xslo:text>lcsh</xslo:text></xslo:when>
                    <xslo:when test="$thesaurus_code1 = 'b'"><xslo:text>lcac</xslo:text></xslo:when>
                    <xslo:when test="$thesaurus_code1 = 'c'"><xslo:text>mesh</xslo:text></xslo:when>
                    <xslo:when test="$thesaurus_code1 = 'd'"><xslo:text>nal</xslo:text></xslo:when>
                    <xslo:when test="$thesaurus_code1 = 'k'"><xslo:text>cash</xslo:text></xslo:when>
                    <xslo:when test="$thesaurus_code1 = 'n'"><xslo:text>notapplicable</xslo:text></xslo:when>
                    <xslo:when test="$thesaurus_code1 = 'r'"><xslo:text>aat</xslo:text></xslo:when>
                    <xslo:when test="$thesaurus_code1 = 's'"><xslo:text>sears</xslo:text></xslo:when>
                    <xslo:when test="$thesaurus_code1 = 'v'"><xslo:text>rvm</xslo:text></xslo:when>
                    <xslo:when test="$thesaurus_code1 = 'z'">
                        <xslo:choose>
                            <xslo:when>
                                <xsl:attribute name="test"><xsl:value-of select="$alt_select"/></xsl:attribute>
                                <xslo:value-of>
                                    <xsl:attribute name="select"><xsl:value-of select="$alt_select"/></xsl:attribute>
                                </xslo:value-of>
                            </xslo:when>
                            <xslo:otherwise><xslo:text>notdefined</xslo:text></xslo:otherwise>
                        </xslo:choose>
                    </xslo:when>
                    <xslo:otherwise><xslo:text>notdefined</xslo:text></xslo:otherwise>
                </xslo:choose>
            </xslo:variable>
            <z:index>
                <xsl:attribute name="name"><xsl:value-of select="normalize-space($indexes)"/></xsl:attribute>
                <xslo:value-of select="$full_thesaurus_code"/>
            </z:index>
        </xslo:template>
    </xsl:template>

    <xsl:template name="handle-index-leader">
        <xsl:if test="kohaidx:index_leader">
            <xslo:template match="marc:leader">
                <xsl:apply-templates select="kohaidx:index_leader" mode="secondary"/>
            </xslo:template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="kohaidx:index_leader" mode="secondary">
        <xsl:variable name="offset"><xsl:value-of select="@offset"/></xsl:variable>
        <xsl:variable name="length"><xsl:value-of select="@length"/></xsl:variable>
        <xsl:variable name="indexes">
            <xsl:call-template name="get-target-indexes"/>
        </xsl:variable>
        <z:index>
            <xsl:attribute name="name"><xsl:value-of select="normalize-space($indexes)"/></xsl:attribute>
            <xslo:value-of>
                <xsl:attribute name="select">
                    <xsl:text>substring(., </xsl:text>
                    <xsl:value-of select="$offset + 1" />
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$length" />
                    <xsl:text>)</xsl:text>
                </xsl:attribute>
            </xslo:value-of>
        </z:index>
    </xsl:template>

    <xsl:template name="handle-index-control-field">
        <xsl:for-each select="//kohaidx:index_control_field[generate-id() = generate-id(key('index_control_field_tag', @tag)[1])]">
            <xslo:template>
                <xsl:attribute name="match">
                    <xsl:text>marc:controlfield[@tag='</xsl:text>
                    <xsl:value-of select="@tag"/>
                    <xsl:text>']</xsl:text>
                </xsl:attribute>
                <xsl:for-each select="key('index_control_field_tag', @tag)">
                    <xsl:call-template name="handle-one-index-control-field"/>
                </xsl:for-each>
            </xslo:template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="handle-one-index-control-field">
        <xsl:variable name="offset"><xsl:value-of select="@offset"/></xsl:variable>
        <xsl:variable name="length"><xsl:value-of select="@length"/></xsl:variable>
        <xsl:variable name="indexes">
            <xsl:call-template name="get-target-indexes"/>
        </xsl:variable>
        <z:index>
            <xsl:attribute name="name"><xsl:value-of select="normalize-space($indexes)"/></xsl:attribute>
            <xslo:value-of>
                <xsl:attribute name="select">
                    <xsl:choose>
                        <xsl:when test="@length">
                            <xsl:text>substring(., </xsl:text>
                            <xsl:value-of select="$offset + 1" />
                            <xsl:text>, </xsl:text>
                            <xsl:value-of select="$length"/>
                            <xsl:text>)</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>.</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xslo:value-of>
        </z:index>
    </xsl:template>

    <xsl:template name="handle-index-subfields">
        <xsl:for-each select="//kohaidx:index_subfields[generate-id() = generate-id(key('index_subfields_tag', @tag)[1])]">
            <xslo:template mode="index_subfields">
                <xsl:attribute name="match">
                    <xsl:text>marc:datafield[@tag='</xsl:text>
                    <xsl:value-of select="@tag"/>
                    <xsl:text>']</xsl:text>
                </xsl:attribute>
                <xsl:for-each select="key('index_subfields_tag', @tag)">
                    <xsl:call-template name="handle-one-index-subfields"/>
                </xsl:for-each>
            </xslo:template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="handle-one-index-subfields">
        <xsl:variable name="indexes">
            <xsl:call-template name="get-target-indexes"/>
        </xsl:variable>
            <xslo:for-each select="marc:subfield">
                <xslo:if>
                    <xsl:attribute name="test">
                        <xsl:text>contains('</xsl:text>
                        <xsl:value-of select="@subfields"/>
                        <xsl:text>', @code)</xsl:text>
                    </xsl:attribute>
                    <z:index>
                        <xsl:attribute name="name"><xsl:value-of select="normalize-space($indexes)"/></xsl:attribute>
                        <xslo:value-of select="."/>
                    </z:index>
                </xslo:if>
            </xslo:for-each>
    </xsl:template>

    <xsl:template name="handle-index-heading">
        <xsl:for-each select="//kohaidx:index_heading[generate-id() = generate-id(key('index_heading_tag', @tag)[1])]">
            <xslo:template mode="index_heading">
                <xsl:attribute name="match">
                    <xsl:text>marc:datafield[@tag='</xsl:text>
                    <xsl:value-of select="@tag"/>
                    <xsl:text>']</xsl:text>
                </xsl:attribute>
                <xsl:for-each select="key('index_heading_tag', @tag)">
                    <xsl:call-template name="handle-one-index-heading"/>
                </xsl:for-each>
            </xslo:template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="handle-one-index-heading">
        <xsl:variable name="indexes">
            <xsl:call-template name="get-target-indexes"/>
        </xsl:variable>
        <z:index>
            <xsl:attribute name="name"><xsl:value-of select="normalize-space($indexes)"/></xsl:attribute>
            <xslo:variable name="raw_heading">
                <xslo:for-each select="marc:subfield">
                    <xslo:if>
                        <xsl:attribute name="test">
                            <xsl:text>contains('</xsl:text>
                            <xsl:value-of select="@subfields"/>
                            <xsl:text>', @code)</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="name"><xsl:value-of select="normalize-space($indexes)"/></xsl:attribute>
                        <xslo:if test="position() > 1">
                            <xslo:choose>
                                <xslo:when>
                                    <xsl:attribute name="test">
                                        <xsl:text>contains('</xsl:text>
                                        <xsl:value-of select="@subdivisions"/>
                                        <xsl:text>', @code)</xsl:text>
                                    </xsl:attribute>
                                    <xslo:text>--</xslo:text>
                                </xslo:when>
                                <xslo:otherwise>
                                    <xslo:value-of select="substring(' ', 1, 1)"/> <!-- FIXME surely there's a better way  to specify a space -->
                                </xslo:otherwise>
                            </xslo:choose>
                        </xslo:if>
                        <xslo:value-of select="."/>
                    </xslo:if>
                </xslo:for-each>
            </xslo:variable>
            <xslo:value-of select="normalize-space($raw_heading)"/>
        </z:index>
    </xsl:template>

    <xsl:template name="handle-index-match-heading">
        <xsl:for-each select="//kohaidx:index_match_heading[generate-id() = generate-id(key('index_match_heading_tag', @tag)[1])]">
            <xslo:template mode="index_match_heading">
                <xsl:attribute name="match">
                    <xsl:text>marc:datafield[@tag='</xsl:text>
                    <xsl:value-of select="@tag"/>
                    <xsl:text>']</xsl:text>
                </xsl:attribute>
                <xsl:for-each select="key('index_match_heading_tag', @tag)">
                    <xsl:call-template name="handle-one-index-match-heading"/>
                </xsl:for-each>
            </xslo:template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="handle-one-index-match-heading">
        <xsl:variable name="indexes">
            <xsl:call-template name="get-target-indexes"/>
        </xsl:variable>
        <z:index>
            <xsl:attribute name="name"><xsl:value-of select="normalize-space($indexes)"/></xsl:attribute>
            <xslo:variable name="raw_heading">
                <xslo:for-each select="marc:subfield">
                    <xslo:if>
                        <xsl:attribute name="test">
                            <xsl:text>contains('</xsl:text>
                            <xsl:value-of select="@subfields"/>
                            <xsl:text>', @code)</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="name"><xsl:value-of select="normalize-space($indexes)"/></xsl:attribute>
                        <xslo:if test="position() > 1">
                            <xslo:choose>
                                <xslo:when>
                                    <xsl:attribute name="test">
                                        <xsl:text>contains('</xsl:text>
                                        <xsl:value-of select="@subdivisions"/>
                                        <xsl:text>', @code)</xsl:text>
                                    </xsl:attribute>
                                    <xslo:choose>
                                        <xslo:when>
                                            <xsl:attribute name="test">
                                                <xsl:text>@code = $general_subdivision_subfield</xsl:text>
                                            </xsl:attribute>
                                            <xslo:text> generalsubdiv </xslo:text>
                                        </xslo:when>
                                        <xslo:when>
                                            <xsl:attribute name="test">
                                                <xsl:text>@code = $form_subdivision_subfield</xsl:text>
                                            </xsl:attribute>
                                            <xslo:text> formsubdiv </xslo:text>
                                        </xslo:when>
                                        <xslo:when>
                                            <xsl:attribute name="test">
                                                <xsl:text>@code = $chronological_subdivision_subfield</xsl:text>
                                            </xsl:attribute>
                                            <xslo:text> chronologicalsubdiv </xslo:text>
                                        </xslo:when>
                                        <xslo:when>
                                            <xsl:attribute name="test">
                                                <xsl:text>@code = $geographic_subdivision_subfield</xsl:text>
                                            </xsl:attribute>
                                            <xslo:text> geographicsubdiv </xslo:text>
                                        </xslo:when>
                                    </xslo:choose>
                                </xslo:when>
                                <xslo:otherwise>
                                    <xslo:value-of select="substring(' ', 1, 1)"/> <!-- FIXME surely there's a better way  to specify a space -->
                                </xslo:otherwise>
                            </xslo:choose>
                        </xslo:if>
                        <xslo:value-of select="."/>
                    </xslo:if>
                </xslo:for-each>
            </xslo:variable>
            <xslo:value-of select="normalize-space($raw_heading)"/>
        </z:index>
    </xsl:template>

    <xsl:template name="get-target-indexes">
        <xsl:for-each select="kohaidx:target_index">
            <xsl:value-of select="." /><xsl:text> </xsl:text>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
