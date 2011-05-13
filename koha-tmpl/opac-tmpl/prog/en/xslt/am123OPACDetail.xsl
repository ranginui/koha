<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: MARC21slim2DC.xsl,v 1.1 2003/01/06 08:20:27 adam Exp $ -->
<xsl:stylesheet xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:items="http://www.koha.org/items" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" exclude-result-prefixes="marc items">
  <xsl:import href="UNIMARCslimUtils.xsl"/>
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="marc:record">
    <xsl:variable name="leader" select="marc:leader"/>
    <xsl:variable name="leader6" select="substring($leader,7,1)"/>
    <xsl:variable name="leader7" select="substring($leader,8,1)"/>
    <xsl:variable name="biblionumber" select="marc:datafield[@tag=999]/marc:subfield[@code='9']"/>
    <xsl:if test="marc:datafield[@tag=200]">
      <xsl:for-each select="marc:datafield[@tag=200]">
        <h1>
            <xsl:variable name="title" select="marc:subfield[@code='a']"/>
            <xsl:variable name="ntitle"
                select="translate($title, '&#x0098;&#x009C;&#xC29C;&#xC29B;&#xC298;&#xC288;&#xC289;','')"/>
           <!-- <xsl:value-of select="$ntitle" />-->

<xsl:value-of select="marc:subfield[@code='a'][1]" />
<xsl:if test="marc:subfield[@code='a'][2]"><xsl:text>. </xsl:text><xsl:value-of select="marc:subfield[@code='a'][2]" /></xsl:if>
<xsl:if test="marc:subfield[@code='a'][3]"><xsl:text>. </xsl:text><xsl:value-of select="marc:subfield[@code='a'][3]" /></xsl:if>
<xsl:if test="marc:subfield[@code='a'][4]"><xsl:text>. </xsl:text><xsl:value-of select="marc:subfield[@code='a'][4]" /></xsl:if>

          <!--<xsl:if test="marc:subfield[@code='e']">
            <xsl:text> : </xsl:text>
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>-->

<xsl:if test="marc:subfield[@code='e'][1]"><xsl:text>: </xsl:text><xsl:value-of select="marc:subfield[@code='e'][1]" /></xsl:if>
<xsl:if test="marc:subfield[@code='e'][2]"><xsl:text>: </xsl:text><xsl:value-of select="marc:subfield[@code='e'][2]" /></xsl:if>
<xsl:if test="marc:subfield[@code='e'][3]"><xsl:text>: </xsl:text><xsl:value-of select="marc:subfield[@code='e'][3]" /></xsl:if> 
<xsl:if test="marc:subfield[@code='e'][4]"><xsl:text>: </xsl:text><xsl:value-of select="marc:subfield[@code='e'][4]" /></xsl:if>


        <xsl:if test="marc:subfield[@code='d']">
          <xsl:text> =</xsl:text>
<xsl:if test="marc:subfield[@code='d'][1]"><xsl:text></xsl:text><xsl:value-of select="marc:subfield[@code='d'][1]" /></xsl:if>
<xsl:if test="marc:subfield[@code='d'][2]"><xsl:text> = </xsl:text><xsl:value-of select="marc:subfield[@code='d'][2]" /></xsl:if>
<xsl:if test="marc:subfield[@code='d'][3]"><xsl:text> = </xsl:text><xsl:value-of select="marc:subfield[@code='d'][3]" /></xsl:if>
        </xsl:if>


          <xsl:if test="marc:subfield[@code='b']">
            <xsl:text> [</xsl:text>
            <xsl:value-of select="marc:subfield[@code='b']"/>
            <xsl:text>]</xsl:text>
          </xsl:if>

          <xsl:if test="marc:subfield[@code='h'][1]"><xsl:text> ; </xsl:text><xsl:value-of select="marc:subfield[@code='h'][1]" /></xsl:if>
<xsl:if test="marc:subfield[@code='h'][2]"><xsl:text> ; </xsl:text><xsl:value-of select="marc:subfield[@code='h'][2]" /></xsl:if>
<xsl:if test="marc:subfield[@code='h'][3]"><xsl:text> ; </xsl:text><xsl:value-of select="marc:subfield[@code='h'][3]" /></xsl:if>
          
<xsl:if test="marc:subfield[@code='i'][1]"><xsl:text> : </xsl:text><xsl:value-of select="marc:subfield[@code='i'][1]" /></xsl:if>
<xsl:if test="marc:subfield[@code='i'][2]"><xsl:text> : </xsl:text><xsl:value-of select="marc:subfield[@code='i'][2]" /></xsl:if>
<xsl:if test="marc:subfield[@code='i'][3]"><xsl:text> : </xsl:text><xsl:value-of select="marc:subfield[@code='i'][3]" /></xsl:if>

          <xsl:if test="marc:subfield[@code='f']">
            <xsl:text> / </xsl:text>
<xsl:if test="marc:subfield[@code='f'][1]"><xsl:text></xsl:text><xsl:value-of select="marc:subfield[@code='f'][1]" /></xsl:if>
<xsl:if test="marc:subfield[@code='f'][2]"><xsl:text> ; </xsl:text><xsl:value-of select="marc:subfield[@code='f'][2]" /></xsl:if>
<xsl:if test="marc:subfield[@code='f'][3]"><xsl:text> ; </xsl:text><xsl:value-of select="marc:subfield[@code='f'][3]" /></xsl:if>
          </xsl:if>
           <xsl:if test="marc:subfield[@code='g']">
          <xsl:text> ; </xsl:text>
<xsl:if test="marc:subfield[@code='g'][1]"><xsl:text>  </xsl:text><xsl:value-of select="marc:subfield[@code='g'][1]" /></xsl:if>
<xsl:if test="marc:subfield[@code='g'][2]"><xsl:text> ; </xsl:text><xsl:value-of select="marc:subfield[@code='g'][2]" /></xsl:if>
<xsl:if test="marc:subfield[@code='g'][3]"><xsl:text> ; </xsl:text><xsl:value-of select="marc:subfield[@code='g'][3]" /></xsl:if>
         </xsl:if>
        </h1>
      </xsl:for-each>
    </xsl:if>
<br/>
   <xsl:call-template name="tag_413" />
   <xsl:call-template name="tag_421" />
   <xsl:call-template name="tag_422" />
   <xsl:call-template name="tag_423" />
   <xsl:call-template name="tag_424" />
   <xsl:call-template name="tag_425" />
   <xsl:call-template name="tag_430" />
   <xsl:call-template name="tag_431" />
   <xsl:call-template name="tag_432" />
   <xsl:call-template name="tag_433" />
   <xsl:call-template name="tag_434" />
   <xsl:call-template name="tag_435" />
   <xsl:call-template name="tag_436" />
   <xsl:call-template name="tag_437" />
   <xsl:call-template name="tag_440" />
   <xsl:call-template name="tag_441" />
   <xsl:call-template name="tag_442" />
   <xsl:call-template name="tag_443" />
   <xsl:call-template name="tag_444" />
   <xsl:call-template name="tag_445" />
   <xsl:call-template name="tag_446" />
   <xsl:call-template name="tag_447" />
   <xsl:call-template name="tag_448" />
   <xsl:call-template name="tag_451" />
   <xsl:call-template name="tag_452" />
   <xsl:call-template name="tag_453" />
   <xsl:call-template name="tag_454" />
   <xsl:call-template name="tag_455" />
   <xsl:call-template name="tag_456" />
   <xsl:call-template name="tag_462" />
   <xsl:call-template name="tag_463" />
    <xsl:call-template name="tag_4xx"/>
<br/>

    <xsl:if test="marc:datafield[@tag=700] or marc:datafield[@tag=701] or marc:datafield[@tag=702] or marc:datafield[@tag=710] or marc:datafield[@tag=711] or marc:datafield[@tag=712]">
      <span class="results_summary">
      <span class="label">Auteur(s) : </span>
      <xsl:for-each select="marc:datafield[@tag=700]">
            <a>
              <xsl:choose>
                <xsl:when test="marc:subfield[@code=9]">
                  <xsl:attribute name="href">
                  /cgi-bin/koha/opac-search.pl?q=an:<xsl:value-of select="marc:subfield[@code=9]"/>
                </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=au:<xsl:value-of select="marc:subfield[@code='a']"/><xsl:text> </xsl:text><xsl:value-of select="marc:subfield[@code='b']"/></xsl:attribute>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="marc:subfield[@code='a']">
                <xsl:value-of select="marc:subfield[@code='a']"/>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='b']">,
              <xsl:value-of select="marc:subfield[@code='b']"/>
            </xsl:if>
              <xsl:if test="marc:subfield[@code='f']"> (<xsl:value-of select="marc:subfield[@code='f']"/>)
            </xsl:if>
            </a>
      </xsl:for-each>
      <xsl:if test="marc:datafield[@tag=700] and marc:datafield[@tag>700]/@tag &lt; 800"><xsl:text> ; </xsl:text></xsl:if>
      <xsl:for-each select="marc:datafield[@tag=701]">
          <a>
            <xsl:choose>
              <xsl:when test="marc:subfield[@code=9]">
                <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=an:<xsl:value-of select="marc:subfield[@code=9]"/></xsl:attribute>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=au:<xsl:value-of select="marc:subfield[@code='a']"/><xsl:text> </xsl:text><xsl:value-of select="marc:subfield[@code='b']"/></xsl:attribute>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="marc:subfield[@code='a']">
              <xsl:value-of select="marc:subfield[@code='a']"/>
            </xsl:if>
            <xsl:if test="marc:subfield[@code='b']">,
              <xsl:value-of select="marc:subfield[@code='b']"/>
            </xsl:if>
            <xsl:if test="marc:subfield[@code='f']"> (<xsl:value-of select="marc:subfield[@code='f']"/>)
            </xsl:if>
          </a>
          <xsl:call-template name="RelatorCode"/>
          <xsl:choose>
            <xsl:when test="position()=last()">
              <xsl:text></xsl:text>
            </xsl:when>
            <xsl:otherwise>
	      <xsl:text> ; </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
      </xsl:for-each>
      <xsl:if test="marc:datafield[@tag=701] and marc:datafield[@tag>701]/@tag &lt; 800"><xsl:text> ; </xsl:text></xsl:if>
      <xsl:for-each select="marc:datafield[@tag=702]">
          <a>
          <xsl:choose>
            <xsl:when test="marc:subfield[@code=9]"><xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=an:<xsl:value-of select="marc:subfield[@code=9]"/></xsl:attribute></xsl:when>
            <xsl:otherwise><xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=au:<xsl:value-of select="marc:subfield[@code='a']"/><xsl:text></xsl:text><xsl:value-of select="marc:subfield[@code='b']"/></xsl:attribute></xsl:otherwise>
	  </xsl:choose>
	  <xsl:if test="marc:subfield[@code='a']"><xsl:value-of select="marc:subfield[@code='a']"/></xsl:if>
          <xsl:if test="marc:subfield[@code='b']">, <xsl:value-of select="marc:subfield[@code='b']"/></xsl:if>
	  <xsl:if test="marc:subfield[@code='f']"> (<xsl:value-of select="marc:subfield[@code='f']"/>)</xsl:if>
	  </a>
          <xsl:call-template name="RelatorCode"/>
          <xsl:choose><xsl:when test="position()=last()"><xsl:text/></xsl:when><xsl:otherwise><xsl:text> 
; </xsl:text></xsl:otherwise></xsl:choose>
      </xsl:for-each>
      <xsl:if test="marc:datafield[@tag=702] and marc:datafield[@tag>702]/@tag &lt; 800"><xsl:text> ; </xsl:text></xsl:if>
      <xsl:for-each select="marc:datafield[@tag=710]">
            <a>
              <xsl:choose>
                <xsl:when test="marc:subfield[@code=9]">
                  <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=an:<xsl:value-of select="marc:subfield[@code=9]"/></xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=au:<xsl:value-of select="marc:subfield[@code='a']"/><xsl:text> </xsl:text><xsl:value-of select="marc:subfield[@code='b']"/></xsl:attribute>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="marc:subfield[@code='a']">
                <xsl:value-of select="marc:subfield[@code='a']"/>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='b']">,
              <xsl:value-of select="marc:subfield[@code='b']"/>
            </xsl:if>
              <xsl:if test="marc:subfield[@code='d']">,
              <xsl:value-of select="marc:subfield[@code='d']"/>
            </xsl:if>
              <xsl:if test="marc:subfield[@code='e']">,
              <xsl:value-of select="marc:subfield[@code='e']"/>
            </xsl:if>
              <xsl:if test="marc:subfield[@code='f']"> (<xsl:value-of select="marc:subfield[@code='f']"/>)
            </xsl:if>
            </a>
      </xsl:for-each>
      <xsl:if test="marc:datafield[@tag=710] and marc:datafield[@tag>710]/@tag &lt; 800"><xsl:text> ; </xsl:text></xsl:if>
      <xsl:for-each select="marc:datafield[@tag=711]">
            <a>
            <xsl:choose>
              <xsl:when test="marc:subfield[@code=9]">
                <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=an:<xsl:value-of select="marc:subfield[@code=9]"/></xsl:attribute>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=au:<xsl:value-of select="marc:subfield[@code='a']"/><xsl:text> </xsl:text><xsl:value-of select="marc:subfield[@code='b']"/></xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="marc:subfield[@code='a']">
              <xsl:value-of select="marc:subfield[@code='a']"/>
            </xsl:if>
            <xsl:if test="marc:subfield[@code='b']">,
              <xsl:value-of select="marc:subfield[@code='b']"/>
            </xsl:if>
            <xsl:if test="marc:subfield[@code='d']">,
              <xsl:value-of select="marc:subfield[@code='d']"/>
            </xsl:if>
            <xsl:if test="marc:subfield[@code='e']">,
              <xsl:value-of select="marc:subfield[@code='e']"/>
            </xsl:if>
            <xsl:if test="marc:subfield[@code='f']"> (<xsl:value-of select="marc:subfield[@code='f']"/>)
            </xsl:if>
            </a>
            <xsl:call-template name="RelatorCode"/>
            <xsl:choose>
              <xsl:when test="position()=last()">
                <xsl:text/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text> ; </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
      </xsl:for-each>
      <xsl:if test="marc:datafield[@tag=711] and marc:datafield[@tag>711]/@tag &lt; 800"><xsl:text> ; </xsl:text></xsl:if>
      <xsl:for-each select="marc:datafield[@tag=712]">
            <a>
              <xsl:choose>
                <xsl:when test="marc:subfield[@code=9]">
                  <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=an:<xsl:value-of select="marc:subfield[@code=9]"/></xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=au:<xsl:value-of select="marc:subfield[@code='a']"/><xsl:text> </xsl:text><xsl:value-of select="marc:subfield[@code='b']"/></xsl:attribute>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="marc:subfield[@code='a']">
                <xsl:value-of select="marc:subfield[@code='a']"/>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='b']">,
                <xsl:value-of select="marc:subfield[@code='b']"/>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='d']">,
                <xsl:value-of select="marc:subfield[@code='d']"/>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='e']">,
                <xsl:value-of select="marc:subfield[@code='e']"/>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='f']"> (<xsl:value-of select="marc:subfield[@code='f']"/>)
              </xsl:if>
            </a>
          <xsl:call-template name="RelatorCode"/>
          <xsl:choose>
              <xsl:when test="position()=last()">
                <xsl:text/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text> ; </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
      </xsl:for-each>
      </span>
    </xsl:if>
<!--  <xsl:if test="marc:datafield[@tag=101]"><span class="results_summary"><span class="label">Langue: </span><xsl:for-each select="marc:datafield[@tag=101]"><xsl:for-each select="marc:subfield"><xsl:choose><xsl:when test="@code='b'">de la trad. intermédiaire, </xsl:when><xsl:when test="@code='c'">de l'œuvre originale, </xsl:when><xsl:when test="@code='d'">du résumé, </xsl:when><xsl:when test="@code='e'">de la table des matières, </xsl:when><xsl:when test="@code='f'">de la page de titre, </xsl:when><xsl:when test="@code='g'">du titre propre, </xsl:when><xsl:when test="@code='h'">d'un livret, </xsl:when><xsl:when test="@code='i'">des textes d'accompagnement, </xsl:when><xsl:when test="@code='j'">des sous-titres, </xsl:when></xsl:choose><xsl:value-of select="text()"/><xsl:choose><xsl:when test="position()=last()"><xsl:text>.</xsl:text></xsl:when><xsl:otherwise><xsl:text> ; </xsl:text></xsl:otherwise></xsl:choose></xsl:for-each></xsl:for-each></span></xsl:if>
      <xsl:if test="marc:datafield[@tag=102]"><span class="results_summary"><span class="label">Pays: </span><xsl:for-each select="marc:datafield[@tag=102]"><xsl:for-each select="marc:subfield"><xsl:value-of select="text()"/><xsl:choose><xsl:when test="position()=last()"><xsl:text>.</xsl:text></xsl:when><xsl:otherwise><xsl:text>, </xsl:text></xsl:otherwise></xsl:choose></xsl:for-each></xsl:for-each></span></xsl:if>
-->
     <xsl:call-template name="tag_205" />
    <xsl:call-template name="tag_210"/>
    <xsl:call-template name="tag_215"/>
    <abbr class="unapi-id" title="koha:biblionumber:{marc:datafield[@tag=090]/marc:subfield[@code='a']}">
      <!-- unAPI -->
    </abbr>
    <xsl:if test="marc:datafield[@tag=010]/marc:subfield[@code='a']">
      <span class="results_summary">
        <span class="label">ISBN: </span>
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
    <xsl:if test="marc:datafield[@tag=676]">
      <span class="results_summary">
        <span class="label">Dewey: </span>
        <xsl:for-each select="marc:datafield[@tag=676]">
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
    <xsl:if test="marc:datafield[@tag=330]">
      <span class="results_summary">
        <span class="label">Résumé: </span>
        <xsl:for-each select="marc:datafield[@tag=330]">
          <p><xsl:value-of select="marc:subfield[@code='a']"/></p>
          <xsl:choose>
            <xsl:when test="position()=last()">
              <xsl:text>.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text> </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </span>
    </xsl:if>
    <xsl:if test="marc:datafield[@tag=317]">
      <span class="results_summary">
        <span class="label">Note sur la provenance: </span>
        <xsl:for-each select="marc:datafield[@tag=317]">
          <xsl:value-of select="marc:subfield[@code='a']"/>
        </xsl:for-each>
      </span>
    </xsl:if>
    <xsl:if test="marc:datafield[@tag=320]">
      <span class="results_summary">
        <span class="label">Bibliographie: </span>
        <xsl:for-each select="marc:datafield[@tag=320]">
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
    <xsl:if test="marc:datafield[@tag=328]">
      <span class="results_summary">
        <span class="label">Thèse: </span>
      <xsl:for-each select="marc:datafield[@tag=328]">
        <xsl:for-each select="marc:subfield">
          <xsl:value-of select="text()"/>
          <xsl:choose><xsl:when test="position()=last()"><xsl:text>.</xsl:text></xsl:when><xsl:otherwise><xsl:text>; </xsl:text></xsl:otherwise></xsl:choose>
        </xsl:for-each>
      </xsl:for-each>
      </span>
    </xsl:if>
    <xsl:if test="marc:datafield[@tag=333]">
      <span class="results_summary">
        <span class="label">Public: </span>
        <xsl:for-each select="marc:datafield[@tag=333]">
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
    <xsl:if test="marc:datafield[@tag=600 or @tag=601 or @tag=606 or @tag=607 or @tag=610]">
      <span class="results_summary">
        <span class="label">Sujets: </span>
        <xsl:for-each select="marc:datafield[@tag=600 or @tag=601 or @tag=605 or @tag=606 or @tag=607 or @tag=610]">
          <a>
            <xsl:choose>
              <xsl:when test="marc:subfield[@code=9]">
                <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=an:<xsl:value-of select="marc:subfield[@code=9]"/></xsl:attribute>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=su:<xsl:value-of select="marc:subfield[@code='a']"/></xsl:attribute>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="chopPunctuation">
              <xsl:with-param name="chopString">
                <xsl:call-template name="subfieldSelect">
                  <xsl:with-param name="codes">abcdjipvxyz</xsl:with-param>
                  <xsl:with-param name="subdivCodes">jpxyz</xsl:with-param>
                  <xsl:with-param name="subdivDelimiter">-- </xsl:with-param>
                </xsl:call-template>
              </xsl:with-param>
            </xsl:call-template>
          </a>
          <xsl:choose>
            <xsl:when test="position()=last()"/>
            <xsl:otherwise> | </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </span>
    </xsl:if>
    <xsl:if test="marc:datafield[@tag=856]">
      <span class="results_summary">
        <span class="label"><strong>URL: </strong></span>
        <xsl:for-each select="marc:datafield[@tag=856]">
          <a>
            <xsl:attribute name="href">
             <!--BIBLIBRE AJOUT http:// pour le lien--> <xsl:value-of select="marc:subfield[@code='u']"/>
            </xsl:attribute>
            <xsl:choose>
              <xsl:when test="marc:subfield[@code='y' or @code='3' or @code='z']">
                <xsl:call-template name="subfieldSelect">
                  <xsl:with-param name="codes">y3z</xsl:with-param>
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="not(marc:subfield[@code='y']) and not(marc:subfield[@code='3']) and not(marc:subfield[@code='z'])">
         <li><xsl:value-of select="marc:subfield[@code='u']"/> </li><!-- BIBLIBRE -->
            </xsl:when>
            </xsl:choose>
          </a>
          <xsl:choose>
            <xsl:when test="position()=last()"/>
            <xsl:otherwise>  </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </span>
    </xsl:if>
    <!-- 780 -->
    <xsl:if test="marc:datafield[@tag=780]">
      <xsl:for-each select="marc:datafield[@tag=780]">
        <span class="results_summary">
          <span class="label">
            <xsl:choose>
              <xsl:when test="@ind2=0">
            Continues:
        </xsl:when>
              <xsl:when test="@ind2=1">
            Continues in part:
        </xsl:when>
              <xsl:when test="@ind2=2">
            Supersedes:
        </xsl:when>
              <xsl:when test="@ind2=3">
            Supersedes in part:
        </xsl:when>
              <xsl:when test="@ind2=4">
            Formed by the union: ... and: ...
        </xsl:when>
              <xsl:when test="@ind2=5">
            Absorbed:
        </xsl:when>
              <xsl:when test="@ind2=6">
            Absorbed in part:
        </xsl:when>
              <xsl:when test="@ind2=7">
            Separated from:
        </xsl:when>
            </xsl:choose>
          </span>
          <xsl:variable name="f780">
            <xsl:call-template name="subfieldSelect">
              <xsl:with-param name="codes">at</xsl:with-param>
            </xsl:call-template>
          </xsl:variable>
          <a>
            <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=<xsl:value-of select="translate($f780, '()', '')"/></xsl:attribute>
            <xsl:value-of select="translate($f780, '()', '')"/>
          </a>
        </span>
        <xsl:choose>
          <xsl:when test="@ind1=0">
            <span class="results_summary">
              <xsl:value-of select="marc:subfield[@code='n']"/>
            </span>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
    </xsl:if>
    <!-- 785 -->
    <xsl:if test="marc:datafield[@tag=785]">
      <xsl:for-each select="marc:datafield[@tag=785]">
        <span class="results_summary">
          <span class="label">
            <xsl:choose>
              <xsl:when test="@ind2=0">
            Continued by:
        </xsl:when>
              <xsl:when test="@ind2=1">
            Continued in part by:
        </xsl:when>
              <xsl:when test="@ind2=2">
            Superseded by:
        </xsl:when>
              <xsl:when test="@ind2=3">
            Superseded in part by:
        </xsl:when>
              <xsl:when test="@ind2=4">
            Absorbed by:
        </xsl:when>
              <xsl:when test="@ind2=5">
            Absorbed in part by:
        </xsl:when>
              <xsl:when test="@ind2=6">
            Split into .. and ...:
        </xsl:when>
              <xsl:when test="@ind2=7">
            Merged with ... to form ...
        </xsl:when>
              <xsl:when test="@ind2=8">
            Changed back to:
        </xsl:when>
            </xsl:choose>
          </span>
          <xsl:variable name="f785">
            <xsl:call-template name="subfieldSelect">
              <xsl:with-param name="codes">at</xsl:with-param>
            </xsl:call-template>
          </xsl:variable>
          <a>
            <xsl:attribute name="href">/cgi-bin/koha/opac-search.pl?q=<xsl:value-of select="translate($f785, '()', '')"/></xsl:attribute>
            <xsl:value-of select="translate($f785, '()', '')"/>
          </a>
        </span>
      </xsl:for-each>
    </xsl:if>
		<xsl:if test="marc:datafield[@tag=923]">
			<span class="results_summary">
				<span class="label">État de collection : </span>
				<ul>
		      <xsl:for-each select="marc:datafield[@tag=923]">
		      	<li>
				    	<span class="label">Pour 
				    		<xsl:call-template name="CRC">
				    		  <xsl:with-param name="code" select="marc:subfield[@code='c']"/>
				    		</xsl:call-template>
				    		<xsl:if test="marc:subfield[@code='b']">
				    		, Cote <xsl:value-of select="marc:subfield[@code='b']"/>
				    		</xsl:if>
				    		:
				        </span>
				      <ul>
				      	<xsl:if test="marc:subfield[@code='d']">
				      		<li><span class="label">État de collection : </span><xsl:value-of select="marc:subfield[@code='d']"/></li>
				      	</xsl:if>
				      	<xsl:if test="marc:subfield[@code='e']">
				      		<li><span class="label">État de collection : </span><xsl:value-of select="marc:subfield[@code='e']"/></li>
				      	</xsl:if>
				      	<xsl:if test="marc:subfield[@code='a']">
				      		<li><span class="label">Lacunes : </span><xsl:value-of select="marc:subfield[@code='a']"/></li>
				      	</xsl:if>
				      	<xsl:if test="marc:subfield[@code='g']">
				      		<li><span class="label">Localisation : </span><xsl:value-of select="marc:subfield[@code='g']"/></li>
				      	</xsl:if>
                                        <xsl:if test="marc:subfield[@code='h']">
                                                <li><span class="label">Commentaires : </span><xsl:value-of select="marc:subfield[@code='h']"/></li>
                                        </xsl:if>
				      </ul>
		        </li>
		      </xsl:for-each>
        </ul>
			</span>
		</xsl:if>
  </xsl:template>
  <xsl:template name="CRC">
  	<xsl:param name="code"/>
  	<xsl:choose>
      <xsl:when test="$code='130015206'">Muséothèque AGCCPF-PACA</xsl:when>
      <xsl:when test="$code='130052201'">Bibliothèque IUP Image et son/CEFEDEM</xsl:when>
      <xsl:when test="$code='130012213'">Bibliothèque UFR Civilisations/Humanités</xsl:when>
      <xsl:when test="$code='130012215'">Bibliothèque UFR Géographie</xsl:when>
      <xsl:when test="$code='130012214'">Bibliothèque UFR LAG-LEA</xsl:when>
      <xsl:when test="$code='130012221'">Bibliothèque du Patio Nord</xsl:when>
      <xsl:when test="$code='130552107'">Bibliothèque Technopole de Château - Gombert</xsl:when>
      <xsl:when test="$code='130012101'">Bibliothèque Lettres et Sciences Humaines Aix</xsl:when>
      <xsl:when test="$code='130552104'">Bibliothèque Sciences et Sciences Humaines Saint-Charles</xsl:when>
      <xsl:when test="$code='130552316'">Bibliothèque CRFCB</xsl:when>
      <xsl:when test="$code='041922301'">Bibliothèque Observatoire de Haute-Provence</xsl:when>
      <xsl:when test="$code='130552304'">Bibliothèque Observatoire Château-Gombert</xsl:when>
      <xsl:when test="$code='130552205'">Bibliothèque Observatoire Château-Gombert</xsl:when>
      <xsl:when test="$code='130559902'">Bibliothèque électonique Université de Provence </xsl:when>
      <xsl:when test="$code='130552207'">Bibliothèque IUFM Marseille </xsl:when>
      <xsl:when test="$code='040702202'">Bibliothèque IUFM Digne  </xsl:when>
      <xsl:when test="$code='840072203'">Bibliothèque IUFM Avignon</xsl:when>
      <xsl:when test="$code='130012224'">Bibliothèque IUFM Aix -en-Provence</xsl:when>
      <xsl:when test="$code='130559901'">Bibliothèque électonique Université de la Méditerranée</xsl:when>
      <xsl:when test="$code='050612101'">BU Gap</xsl:when>
      <xsl:when test="$code='130552206'">Centre d'océanologie</xsl:when>
      <xsl:when test="$code='130552106'">BU Luminy</xsl:when>
      <xsl:when test="$code='130552105'">BU Pharmacie</xsl:when>
      <xsl:when test="$code='130552103'">BU Médecine</xsl:when>
      <xsl:when test="$code='130552101'">BU Médecine Nord</xsl:when>
      <xsl:when test="$code='130012104'">BU Sc. Éco.</xsl:when>
      <xsl:when test="$code='130012229'">Centre de documentation et d'information du Département Carrières Sociales option Gestion urbaine</xsl:when>
      <xsl:when test="$code='130012230'">Centre de documentation du Département Gestion Logistique et Transport</xsl:when>
      <xsl:when test="$code='130012231'">Centre de documentation du Département Techniques de commercialisation</xsl:when>
      <xsl:when test="$code='130012232'">Centre de documentation du Département Gestion des Entreprises et des Administrations</xsl:when>
      <xsl:when test="$code='130012222'">IRT</xsl:when>
      <xsl:when test="$code='130012223'">Métiers du Livre</xsl:when>
      <xsl:when test="$code='130282201'">IUT La Ciotat</xsl:when>
      <xsl:when test="$code='130012102'">Bibliothèque Droit Economie Aix</xsl:when>
      <xsl:when test="$code='130012103'">Bibliothèque de Montperrin</xsl:when>
      <xsl:when test="$code='130012105'">Bibliothèque du CDC</xsl:when>
      <xsl:when test="$code='130012202'">Bibliothèque de la Salle de Droit Privé</xsl:when>
      <xsl:when test="$code='130012203'">Bibliothèque du CRA et de l'IREDIC</xsl:when>
      <xsl:when test="$code='130012204'">Bibliothèque de l'IAE</xsl:when>
      <xsl:when test="$code='130012205'">Bibliothèque de l'ISPEC</xsl:when>
      <xsl:when test="$code='130012206'">Bibliothèque de l'IEP</xsl:when>
      <xsl:when test="$code='130012210'">Bibliothèque du CERIC</xsl:when>
      <xsl:when test="$code='130012211'">Bibliothèque de la FEA</xsl:when>
      <xsl:when test="$code='130012212'">Bibliothèque de l'IEFEE</xsl:when>
      <xsl:when test="$code='130012216'">Bibliothèque du CREEADP</xsl:when>
      <xsl:when test="$code='130012218'">Bibliothèque de Théorie du Droit</xsl:when>
      <xsl:when test="$code='130012219'">Bibliothèque de la Salle d'Histoire des Institutions</xsl:when>
      <xsl:when test="$code='130012220'">Bibliothèque de la Salle de Droit Public</xsl:when>
      <xsl:when test="$code='130042202'">Bibliothèque de l'antenne universitaire d'Arles</xsl:when>
      <xsl:when test="$code='130552102'">Bibliothèque Sciences Saint Jérôme</xsl:when>
      <xsl:when test="$code='130552108'">Bibliothèque Droit Economie Canebière</xsl:when>
      <xsl:when test="$code='130012233'">Bibliothèque Cassin : GERJC</xsl:when>
      <xsl:when test="$code='130012201'">Bibliothèque René Cassin : Institut de droit des affaires</xsl:when>
      <xsl:when test="$code='130012225'">Bibliothèque René Cassin : IREDIC </xsl:when>
      <xsl:when test="$code='130012226'">Bibliothèque René Cassin : Centre de droit social </xsl:when>
      <xsl:when test="$code='130012228'">Bibliothèque René Cassin : Centre d'études fiscales et financières</xsl:when>
      <xsl:when test="$code='130012227'">Bibliothèque René Cassin : Espace périodiques </xsl:when>
      <xsl:when test="$code='130012234'">Bibliothèque Poncet</xsl:when>
      <xsl:when test="$code='130012303'">Bibliothèque du CEREGE</xsl:when>
      <xsl:when test="$code='à venir'">Bibliothèque de l'IEP – Espace Philippe Seguin</xsl:when>
      <xsl:otherwise><xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
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
