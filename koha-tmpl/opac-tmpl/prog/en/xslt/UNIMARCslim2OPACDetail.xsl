<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE stylesheet [<!ENTITY nbsp "&#160;" >]>

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:items="http://www.koha-community.org/items"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="marc items">

<xsl:import href="UNIMARCslimUtils.xsl"/>
<xsl:output method = "xml" indent="yes" omit-xml-declaration = "yes" />
<xsl:template match="/">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="marc:record">
  <xsl:variable name="leader" select="marc:leader"/>
  <xsl:variable name="leader6" select="substring($leader,7,1)"/>
  <xsl:variable name="leader7" select="substring($leader,8,1)"/>
  <xsl:variable name="biblionumber" select="marc:datafield[@tag=090]/marc:subfield[@code='a']"/>


  <xsl:if test="marc:datafield[@tag=200]">
    <xsl:for-each select="marc:datafield[@tag=200]">
      <h1>
        <xsl:call-template name="addClassRtl" />
        <xsl:variable name="title" select="marc:subfield[@code='a']"/>
        <xsl:variable name="ntitle"
         select="translate($title, '&#x0098;&#x009C;','')"/>
        <xsl:value-of select="$ntitle" />
        <xsl:if test="marc:subfield[@code='e']">
          <xsl:text> : </xsl:text>
          <xsl:for-each select="marc:subfield[@code='e']">
            <xsl:value-of select="."/>
          </xsl:for-each>
        </xsl:if>
        <xsl:if test="marc:subfield[@code='b']">
          <xsl:text> [</xsl:text>
          <xsl:value-of select="marc:subfield[@code='b']"/>
          <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:if test="marc:subfield[@code='f']">
          <xsl:text> / </xsl:text>
          <xsl:value-of select="marc:subfield[@code='f']"/>
        </xsl:if>
        <xsl:if test="marc:subfield[@code='g']">
          <xsl:text> ; </xsl:text>
          <xsl:value-of select="marc:subfield[@code='g']"/>
        </xsl:if>
      </h1>
    </xsl:for-each>
  </xsl:if>

  <div id="views">
    <span class="view">
      <span id="Normalview">Normal View</span>
    </span>
    <span class="view">
      <a id="MARCviewPop" href="/cgi-bin/koha/opac-showmarc.pl?id={marc:datafield[@tag=090]/marc:subfield[@code='a']}" title="MARC" rel="gb_page_center[600,500]">MARC View</a>
    </span>
    <span class="view">
      <a id="MARCview" href="/cgi-bin/koha/opac-MARCdetail.pl?biblionumber={marc:datafield[@tag=090]/marc:subfield[@code='a']}" title="MARC">Expanded MARC View</a>
    </span>
    <span class="view">
      <a id="ISBDview" href="/cgi-bin/koha/opac-ISBDdetail.pl?biblionumber={marc:datafield[@tag=090]/marc:subfield[@code='a']}">Card View (ISBD)</a>
    </span>
  </div>

  <xsl:call-template name="tag_4xx" />

  <xsl:call-template name="tag_7xx">
    <xsl:with-param name="tag">700</xsl:with-param>
    <xsl:with-param name="label">Main Author</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_7xx">
    <xsl:with-param name="tag">710</xsl:with-param>
    <xsl:with-param name="label">Corporate Author (Main)</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_7xx">
    <xsl:with-param name="tag">701</xsl:with-param>
    <xsl:with-param name="label">Coauthor</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_7xx">
    <xsl:with-param name="tag">702</xsl:with-param>
    <xsl:with-param name="label">Secondary Author</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_7xx">
    <xsl:with-param name="tag">711</xsl:with-param>
    <xsl:with-param name="label">Corporate Author (Coauthor)</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_7xx">
    <xsl:with-param name="tag">712</xsl:with-param>
    <xsl:with-param name="label">Corporate Author (Secondary)</xsl:with-param>
  </xsl:call-template>

  <xsl:if test="marc:datafield[@tag=101]">
	  <span class="results_summary">
      <span class="label">Language: </span>
      <xsl:for-each select="marc:datafield[@tag=101]">
        <xsl:for-each select="marc:subfield">
          <xsl:choose>
            <xsl:when test="@code='b'">of intermediate text, </xsl:when>
            <xsl:when test="@code='c'">of original work, </xsl:when>
            <xsl:when test="@code='d'">of summary, </xsl:when>
            <xsl:when test="@code='e'">of contents page, </xsl:when>
            <xsl:when test="@code='f'">of title page, </xsl:when>
            <xsl:when test="@code='g'">of title proper, </xsl:when>
            <xsl:when test="@code='h'">of libretto, </xsl:when>
            <xsl:when test="@code='i'">of accompanying material, </xsl:when>
            <xsl:when test="@code='j'">of subtitles, </xsl:when>
          </xsl:choose>
          <xsl:value-of select="text()"/>
          <xsl:choose>
            <xsl:when test="position()=last()">
              <xsl:text>.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text> ; </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:if test="marc:datafield[@tag=102]">
	  <span class="results_summary">
      <span class="label">Country: </span>
      <xsl:for-each select="marc:datafield[@tag=102]">
        <xsl:for-each select="marc:subfield">
          <xsl:value-of select="text()"/>
          <xsl:choose>
            <xsl:when test="position()=last()">
              <xsl:text>.</xsl:text>
            </xsl:when>
              <xsl:otherwise><xsl:text>, </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:call-template name="tag_210" />

  <xsl:call-template name="tag_215" />

  <xsl:if test="marc:datafield[@tag=010]/marc:subfield[@code='a']">
    <span class="results_summary"><span class="label">ISBN: </span>
    <xsl:for-each select="marc:datafield[@tag=010]">
      <xsl:variable name="isbn" select="marc:subfield[@code='a']"/>
      <xsl:value-of select="marc:subfield[@code='a']"/>
      <xsl:choose>
        <xsl:when test="position()=last()">
          <xsl:text>.</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text> ; </xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:if test="marc:datafield[@tag=011]">
    <span class="results_summary">
      <span class="label">ISSN: </span>
      <xsl:for-each select="marc:datafield[@tag=011]">
        <xsl:value-of select="marc:subfield[@code='a']"/>
        <xsl:choose>
          <xsl:when test="position()=last()">
            <xsl:text>.</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>; </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:call-template name="tag_title">
    <xsl:with-param name="tag">225</xsl:with-param>
    <xsl:with-param name="label">Series</xsl:with-param>
  </xsl:call-template>

  <xsl:if test="marc:datafield[@tag=676]">
    <span class="results_summary">
    <span class="label">Dewey: </span>
      <xsl:for-each select="marc:datafield[@tag=676]">
        <xsl:value-of select="marc:subfield[@code='a']"/>
        <xsl:if test="marc:subfield[@code='v']">
          <xsl:text>, </xsl:text>
          <xsl:value-of select="marc:subfield[@code='v']"/>
        </xsl:if>
        <xsl:if test="marc:subfield[@code='z']">
          <xsl:text>, </xsl:text>
          <xsl:value-of select="marc:subfield[@code='z']"/>
        </xsl:if>
        <xsl:if test="not (position()=last())">
          <xsl:text> ; </xsl:text>
        </xsl:if>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:if test="marc:datafield[@tag=686]">
    <span class="results_summary">
    <span class="label">Classification: </span>
      <xsl:for-each select="marc:datafield[@tag=686]">
        <xsl:value-of select="marc:subfield[@code='a']"/>
        <xsl:if test="marc:subfield[@code='b']">
          <xsl:text>, </xsl:text>
          <xsl:value-of select="marc:subfield[@code='b']"/>
        </xsl:if>
        <xsl:if test="marc:subfield[@code='c']">
          <xsl:text>, </xsl:text>
          <xsl:value-of select="marc:subfield[@code='c']"/>
        </xsl:if>
        <xsl:if test="not (position()=last())"><xsl:text> ; </xsl:text></xsl:if>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:if test="marc:datafield[@tag=327]">
    <span class="results_summary">
      <span class="label">Contents note: </span>
      <xsl:for-each select="marc:datafield[@tag=327]">
        <xsl:call-template name="chopPunctuation">
          <xsl:with-param name="chopString">
            <xsl:call-template name="subfieldSelect">
                <xsl:with-param name="codes">abcdjpvxyz</xsl:with-param>
                <xsl:with-param name="subdivCodes">jpxyz</xsl:with-param>
                <xsl:with-param name="subdivDelimiter">-- </xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:if test="marc:datafield[@tag=330]">
    <span class="results_summary">
      <span class="label">Abstract: </span>
      <xsl:for-each select="marc:datafield[@tag=330]">
        <xsl:value-of select="marc:subfield[@code='a']"/>
        <xsl:choose>
          <xsl:when test="position()=last()">
            <xsl:text>.</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>; </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:if test="marc:datafield[@tag=317]">
    <span class="results_summary">
      <span class="label">Provenance note: </span>
      <xsl:for-each select="marc:datafield[@tag=317]">
          <xsl:value-of select="marc:subfield[@code='a']"/>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:if test="marc:datafield[@tag=320]">
    <span class="results_summary">
      <span class="label">Bibliography: </span>
      <xsl:for-each select="marc:datafield[@tag=320]">
        <xsl:value-of select="marc:subfield[@code='a']"/>
        <xsl:choose><xsl:when test="position()=last()"><xsl:text>.</xsl:text></xsl:when><xsl:otherwise><xsl:text>; </xsl:text></xsl:otherwise></xsl:choose>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:if test="marc:datafield[@tag=328]">
    <span class="results_summary">
      <span class="label">Thesis: </span>
      <xsl:for-each select="marc:datafield[@tag=328]">
        <xsl:value-of select="marc:subfield[@code='a']"/>
        <xsl:choose><xsl:when test="position()=last()"><xsl:text>.</xsl:text></xsl:when><xsl:otherwise><xsl:text>; </xsl:text></xsl:otherwise></xsl:choose>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:if test="marc:datafield[@tag=333]">
    <span class="results_summary">
      <span class="label">Audience: </span>
      <xsl:for-each select="marc:datafield[@tag=333]">
        <xsl:value-of select="marc:subfield[@code='a']"/>
        <xsl:choose><xsl:when test="position()=last()"><xsl:text>.</xsl:text></xsl:when><xsl:otherwise><xsl:text>; </xsl:text></xsl:otherwise></xsl:choose>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:if test="marc:datafield[@tag=955]">
    <span class="results_summary">
      <span class="label">SUDOC serial history: </span>
      <xsl:for-each select="marc:datafield[@tag=955]">
        <xsl:value-of select="marc:subfield[@code='9']"/>:
        <xsl:value-of select="marc:subfield[@code='r']"/>
        <xsl:choose><xsl:when test="position()=last()"><xsl:text>.</xsl:text></xsl:when><xsl:otherwise><xsl:text>; </xsl:text></xsl:otherwise></xsl:choose>
      </xsl:for-each>
    </span>
  </xsl:if>

  <xsl:call-template name="tag_subject">
    <xsl:with-param name="tag">600</xsl:with-param>
    <xsl:with-param name="label">Subject - Personal Name</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_subject">
    <xsl:with-param name="tag">601</xsl:with-param>
    <xsl:with-param name="label">Subject - Corporate Author</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_subject">
    <xsl:with-param name="tag">602</xsl:with-param>
    <xsl:with-param name="label">Subject - Family</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_subject">
    <xsl:with-param name="tag">604</xsl:with-param>
    <xsl:with-param name="label">Subject - Author/Title</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_subject">
    <xsl:with-param name="tag">606</xsl:with-param>
    <xsl:with-param name="label">Subject - Topical Name</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_subject">
    <xsl:with-param name="tag">607</xsl:with-param>
    <xsl:with-param name="label">Subject - Geographical Name</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_subject">
    <xsl:with-param name="tag">608</xsl:with-param>
    <xsl:with-param name="label">Subject - Form</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_subject">
    <xsl:with-param name="tag">610</xsl:with-param>
    <xsl:with-param name="label">Subject</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_subject">
    <xsl:with-param name="tag">615</xsl:with-param>
    <xsl:with-param name="label">Subject Category</xsl:with-param>
  </xsl:call-template>

  <xsl:call-template name="tag_subject">
    <xsl:with-param name="tag">616</xsl:with-param>
    <xsl:with-param name="label">Trademark</xsl:with-param>
  </xsl:call-template>

  <xsl:if test="marc:datafield[@tag=856]">
    <span class="results_summary">
      <span class="label">Online Resources: </span>
      <xsl:for-each select="marc:datafield[@tag=856]">
        <a>
          <xsl:attribute name="href">
            <xsl:value-of select="marc:subfield[@code='u']"/>
          </xsl:attribute>
          <xsl:choose>
            <xsl:when test="marc:subfield[@code='y' or @code='3' or @code='z']">
              <xsl:call-template name="subfieldSelect">
                <xsl:with-param name="codes">y3z</xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="not(marc:subfield[@code='y']) and not(marc:subfield[@code='3']) and not(marc:subfield[@code='z'])">
              Click here to access online
            </xsl:when>
          </xsl:choose>
        </a>
        <xsl:choose>
          <xsl:when test="position()=last()"></xsl:when>
          <xsl:otherwise> | </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </span>
  </xsl:if>

        <!-- 780 -->
        <xsl:if test="marc:datafield[@tag=780]">
        <xsl:for-each select="marc:datafield[@tag=780]">
        <span class="results_summary">
        <xsl:choose>
        <xsl:when test="@ind2=0">
            <span class="label">Continues:</span>
        </xsl:when>
        <xsl:when test="@ind2=1">
            <span class="label">Continues in part:</span>
        </xsl:when>
        <xsl:when test="@ind2=2">
            <span class="label">Supersedes:</span>
        </xsl:when>
        <xsl:when test="@ind2=3">
            <span class="label">Supersedes in part:</span>
        </xsl:when>
        <xsl:when test="@ind2=4">
            <span class="label">Formed by the union: ... and: ...</span>
        </xsl:when>
        <xsl:when test="@ind2=5">
            <span class="label">Absorbed:</span>
        </xsl:when>
        <xsl:when test="@ind2=6">
            <span class="label">Absorbed in part:</span>
        </xsl:when>
        <xsl:when test="@ind2=7">
            <span class="label">Separated from:</span>
        </xsl:when>
        </xsl:choose>
                <xsl:variable name="f780">
                    <xsl:call-template name="subfieldSelect">
                        <xsl:with-param name="codes">at</xsl:with-param>
                    </xsl:call-template>
                </xsl:variable>
             <a><xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=<xsl:value-of select="translate($f780, '()', '')"/></xsl:attribute>
                <xsl:value-of select="translate($f780, '()', '')"/>
            </a>
        </span>

        <xsl:choose>
        <xsl:when test="@ind1=0">
            <span class="results_summary"><xsl:value-of select="marc:subfield[@code='n']"/></span>
        </xsl:when>
        </xsl:choose>

        </xsl:for-each>
        </xsl:if>

        <!-- 785 -->
        <xsl:if test="marc:datafield[@tag=785]">
        <xsl:for-each select="marc:datafield[@tag=785]">
        <span class="results_summary">
        <xsl:choose>
        <xsl:when test="@ind2=0">
            <span class="label">Continued by:</span>
        </xsl:when>
        <xsl:when test="@ind2=1">
            <span class="label">Continued in part by:</span>
        </xsl:when>
        <xsl:when test="@ind2=2">
            <span class="label">Superseded by:</span>
        </xsl:when>
        <xsl:when test="@ind2=3">
            <span class="label">Superseded in part by:</span>
        </xsl:when>
        <xsl:when test="@ind2=4">
            <span class="label">Absorbed by:</span>
        </xsl:when>
        <xsl:when test="@ind2=5">
            <span class="label">Absorbed in part by:</span>
        </xsl:when>
        <xsl:when test="@ind2=6">
            <span class="label">Split into .. and ...:</span>
        </xsl:when>
        <xsl:when test="@ind2=7">
            <span class="label">Merged with ... to form ...</span>
        </xsl:when>
        <xsl:when test="@ind2=8">
            <span class="label">Changed back to:</span>
        </xsl:when>

        </xsl:choose>
                   <xsl:variable name="f785">
                    <xsl:call-template name="subfieldSelect">
                        <xsl:with-param name="codes">at</xsl:with-param>
                    </xsl:call-template>
                </xsl:variable>

                <a><xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=<xsl:value-of select="translate($f785, '()', '')"/></xsl:attribute>
                <xsl:value-of select="translate($f785, '()', '')"/>
            </a>

        </span>
        </xsl:for-each>
        </xsl:if>

    </xsl:template>

    <xsl:template name="nameABCDQ">
            <xsl:call-template name="chopPunctuation">
                <xsl:with-param name="chopString">
                    <xsl:call-template name="subfieldSelect">
                        <xsl:with-param name="codes">aq</xsl:with-param>
                    </xsl:call-template>
                </xsl:with-param>
                <xsl:with-param name="punctuation">
                    <xsl:text>:,;/ </xsl:text>
                </xsl:with-param>
            </xsl:call-template>
        <xsl:call-template name="termsOfAddress"/>
    </xsl:template>

    <xsl:template name="nameABCDN">
        <xsl:for-each select="marc:subfield[@code='a']">
                <xsl:call-template name="chopPunctuation">
                    <xsl:with-param name="chopString" select="."/>
                </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="marc:subfield[@code='b']">
                <xsl:value-of select="."/>
        </xsl:for-each>
        <xsl:if test="marc:subfield[@code='c'] or marc:subfield[@code='d'] or marc:subfield[@code='n']">
                <xsl:call-template name="subfieldSelect">
                    <xsl:with-param name="codes">cdn</xsl:with-param>
                </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="nameACDEQ">
            <xsl:call-template name="subfieldSelect">
                <xsl:with-param name="codes">acdeq</xsl:with-param>
            </xsl:call-template>
    </xsl:template>
    <xsl:template name="termsOfAddress">
        <xsl:if test="marc:subfield[@code='b' or @code='c']">
            <xsl:call-template name="chopPunctuation">
                <xsl:with-param name="chopString">
                    <xsl:call-template name="subfieldSelect">
                        <xsl:with-param name="codes">bc</xsl:with-param>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="part">
        <xsl:variable name="partNumber">
            <xsl:call-template name="specialSubfieldSelect">
                <xsl:with-param name="axis">n</xsl:with-param>
                <xsl:with-param name="anyCodes">n</xsl:with-param>
                <xsl:with-param name="afterCodes">fghkdlmor</xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="partName">
            <xsl:call-template name="specialSubfieldSelect">
                <xsl:with-param name="axis">p</xsl:with-param>
                <xsl:with-param name="anyCodes">p</xsl:with-param>
                <xsl:with-param name="afterCodes">fghkdlmor</xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <xsl:if test="string-length(normalize-space($partNumber))">
                <xsl:call-template name="chopPunctuation">
                    <xsl:with-param name="chopString" select="$partNumber"/>
                </xsl:call-template>
        </xsl:if>
        <xsl:if test="string-length(normalize-space($partName))">
                <xsl:call-template name="chopPunctuation">
                    <xsl:with-param name="chopString" select="$partName"/>
                </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="specialSubfieldSelect">
        <xsl:param name="anyCodes"/>
        <xsl:param name="axis"/>
        <xsl:param name="beforeCodes"/>
        <xsl:param name="afterCodes"/>
        <xsl:variable name="str">
            <xsl:for-each select="marc:subfield">
                <xsl:if test="contains($anyCodes, @code)      or (contains($beforeCodes,@code) and following-sibling::marc:subfield[@code=$axis])      or (contains($afterCodes,@code) and preceding-sibling::marc:subfield[@code=$axis])">
                    <xsl:value-of select="text()"/>
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="substring($str,1,string-length($str)-1)"/>
    </xsl:template>

</xsl:stylesheet>
