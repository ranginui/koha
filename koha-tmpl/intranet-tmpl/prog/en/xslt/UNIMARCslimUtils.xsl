<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template name="datafield">
    <xsl:param name="tag"/>
    <xsl:param name="ind1"><xsl:text> </xsl:text></xsl:param>
    <xsl:param name="ind2"><xsl:text> </xsl:text></xsl:param>
    <xsl:param name="subfields"/>
    <xsl:element name="datafield">
      <xsl:attribute name="tag">
        <xsl:value-of select="$tag"/>
      </xsl:attribute>
      <xsl:attribute name="ind1">
        <xsl:value-of select="$ind1"/>
      </xsl:attribute>
      <xsl:attribute name="ind2">
       <xsl:value-of select="$ind2"/>
         </xsl:attribute>
       <xsl:copy-of select="$subfields"/>
    </xsl:element>
  </xsl:template>

	<xsl:template name="tag_205">
    <xsl:for-each select="marc:datafield[@tag=205]">
      <li>
        <strong>Edition: </strong>
        <xsl:if test="marc:subfield[@code='a']">
          <xsl:value-of select="marc:subfield[@code='a']"/>
        </xsl:if>
      </li>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="tag_210">
    <li>
      <strong>Éditeur: </strong>
      <xsl:for-each select="marc:datafield[@tag=210]">
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:value-of select="marc:subfield[@code='a']"/>
          <xsl:if test="marc:subfield[@code='b']">
            <xsl:if test="marc:subfield[@code='a']">, </xsl:if>
            <xsl:value-of select="marc:subfield[@code='b']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='a' or @code='b']">
            <xsl:if test="marc:subfield[@code='a']"> : </xsl:if>
            <xsl:value-of select="marc:subfield[@code='c']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='d']">
            <xsl:if test="marc:subfield[@code='a' or @code='c']">, </xsl:if>
            <xsl:value-of select="marc:subfield[@code='d']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']">
            <xsl:if test="marc:subfield[@code='a' or @code='c' or @code='d']"> — </xsl:if>
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='g']">
            <xsl:if test="marc:subfield[@code='e']"> : </xsl:if>
            <xsl:value-of select="marc:subfield[@code='g']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='h']">
            <xsl:if test="marc:subfield[@code='e' or @code='g']">, </xsl:if>
            <xsl:value-of select="marc:subfield[@code='h']"/>
          </xsl:if>
          <xsl:if test="not (position() = last())">
            <xsl:text> • </xsl:text>
          </xsl:if>
        </span>
      </xsl:for-each>
    </li>
  </xsl:template>

	<xsl:template name="tag_215">
    <xsl:for-each select="marc:datafield[@tag=215]">
      <li>
        <strong>Description: </strong>
        <xsl:if test="marc:subfield[@code='a']">
          <xsl:value-of select="marc:subfield[@code='a']"/>
        </xsl:if>
        <xsl:if test="marc:subfield[@code='c']"> :
          <xsl:value-of select="marc:subfield[@code='c']"/>
        </xsl:if>
        <xsl:if test="marc:subfield[@code='d']"> ;
          <xsl:value-of select="marc:subfield[@code='d']"/>
        </xsl:if>
        <xsl:if test="marc:subfield[@code='e']"> +
          <xsl:value-of select="marc:subfield[@code='e']"/>
        </xsl:if>
      </li>
    </xsl:for-each>
  </xsl:template>

	<xsl:template name="tag_4xx">
    <xsl:for-each select="marc:datafield[@tag=464 or @tag=461]">
        <li>
        <strong>Niveau de l'ensemble: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_430">
    <xsl:for-each select="marc:datafield[@tag=430]">
        <li>
        <strong>Suite de: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_413">
    <xsl:for-each select="marc:datafield[@tag=413]">
        <li>
        <strong>A pour extrait: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_421">
    <xsl:for-each select="marc:datafield[@tag=421]">
        <li>
        <strong>A pour supplément: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>


<xsl:template name="tag_422">
    <xsl:for-each select="marc:datafield[@tag=422]">
        <li>
        <strong>Est un supplément de: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_423">
    <xsl:for-each select="marc:datafield[@tag=423]">
        <li>
        <strong>Est publié avec: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_424">
    <xsl:for-each select="marc:datafield[@tag=424]">
        <li>
        <strong>Est mis à jour par: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_425">
    <xsl:for-each select="marc:datafield[@tag=425]">
        <li>
        <strong>Met à jour: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>


<xsl:template name="tag_431">
    <xsl:for-each select="marc:datafield[@tag=431]">
        <li>
        <strong>Succède après scission à: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_432">
    <xsl:for-each select="marc:datafield[@tag=432]">
        <li>
        <strong>Remplace: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_433">
    <xsl:for-each select="marc:datafield[@tag=433]">
        <li>
        <strong>Remplace partiellement: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_434">
    <xsl:for-each select="marc:datafield[@tag=434]">
        <li>
        <strong>Absorbe: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_435">
    <xsl:for-each select="marc:datafield[@tag=435]">
        <li>
        <strong>Absorbe partiellement: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_436">
    <xsl:for-each select="marc:datafield[@tag=436]">
        <li>
        <strong>Fusion de: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_437">
    <xsl:for-each select="marc:datafield[@tag=437]">
        <li>
        <strong>Suite partielle de: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_440">
    <xsl:for-each select="marc:datafield[@tag=440]">
        <li>
        <strong>Devient: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_441">
    <xsl:for-each select="marc:datafield[@tag=441]">
        <li>
        <strong>Devient partiellement: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_442">
    <xsl:for-each select="marc:datafield[@tag=442]">
        <li>
        <strong>Remplacé par: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_443">
    <xsl:for-each select="marc:datafield[@tag=443]">
        <li>
        <strong>Remplacé partiellement par: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_444">
    <xsl:for-each select="marc:datafield[@tag=444]">
        <li>
        <strong>Absorbé par: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_445">
    <xsl:for-each select="marc:datafield[@tag=445]">
        <li>
        <strong>Absorbé partiellement par: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_446">
    <xsl:for-each select="marc:datafield[@tag=446]">
        <li>
        <strong>Scindé en: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_447">
    <xsl:for-each select="marc:datafield[@tag=447]">
        <li>
        <strong>Fusionne avec: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_448">
    <xsl:for-each select="marc:datafield[@tag=448]">
        <li>
        <strong>Redevient: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>


<xsl:template name="tag_451">
    <xsl:for-each select="marc:datafield[@tag=451]">
        <li>
        <strong>Autre édition sur le même support: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_452">
    <xsl:for-each select="marc:datafield[@tag=452]">
        <li>
        <strong>Autre édition sur un support différent: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='0']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=kw:<xsl:value-of select="marc:subfield[@code='0']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='0']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>


<xsl:template name="tag_453">
    <xsl:for-each select="marc:datafield[@tag=453]">
        <li>
        <strong>Traduit sous le titre: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_454">
    <xsl:for-each select="marc:datafield[@tag=454]">
        <li>
        <strong>Est une traduction de: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_455">
    <xsl:for-each select="marc:datafield[@tag=455]">
        <li>
        <strong>Est une reproduction de: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_456">
    <xsl:for-each select="marc:datafield[@tag=456]">
        <li>
        <strong>Est reproduit comme: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_462">
    <xsl:for-each select="marc:datafield[@tag=462]">
        <li>
        <strong>Sous-ensemble: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_463">
    <xsl:for-each select="marc:datafield[@tag=463]">
        <li>
        <strong>Unité matérielle: </strong>
        <span>
          <xsl:call-template name="addClassRtl" />
          <xsl:if test="marc:subfield[@code='t']">
            <xsl:value-of select="marc:subfield[@code='t']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']"> :
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']"> /
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">,
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
	
	<xsl:if test="marc:subfield[@code='x']">,
            <xsl:element name="a">
	<xsl:attribute name="href">
     /cgi-bin/koha/catalogue/search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

	<xsl:template name="subfieldSelect">
		<xsl:param name="codes"/>
		<xsl:param name="delimeter"><xsl:text> </xsl:text></xsl:param>
		<xsl:param name="subdivCodes"/>
		<xsl:param name="subdivDelimiter"/>
		<xsl:variable name="str">
			<xsl:for-each select="marc:subfield">
				<xsl:if test="contains($codes, @code)">
                    <xsl:if test="contains($subdivCodes, @code)">
                        <xsl:value-of select="$subdivDelimiter"/>
                    </xsl:if>
					<xsl:value-of select="text()"/><xsl:value-of select="$delimeter"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring($str,1,string-length($str)-string-length($delimeter))"/>
	</xsl:template>

	<xsl:template name="buildSpaces">
		<xsl:param name="spaces"/>
		<xsl:param name="char"><xsl:text> </xsl:text></xsl:param>
		<xsl:if test="$spaces>0">
			<xsl:value-of select="$char"/>
			<xsl:call-template name="buildSpaces">
				<xsl:with-param name="spaces" select="$spaces - 1"/>
				<xsl:with-param name="char" select="$char"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="chopSpecialCharacters">
        <xsl:param name="title" />
        <xsl:variable name="ntitle"
             select="translate($title, '&#x0098;&#x009C;&#xC29C;&#xC29B;&#xC298;&#xC288;&#xC289;','')"/>
        <xsl:value-of select="$ntitle" />
    </xsl:template>


	<xsl:template name="chopPunctuation">
		<xsl:param name="chopString"/>
		<xsl:variable name="length" select="string-length($chopString)"/>
		<xsl:choose>
			<xsl:when test="$length=0"/>
			<xsl:when test="contains('.:,;/ ', substring($chopString,$length,1))">
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="substring($chopString,1,$length - 1)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="not($chopString)"/>
			<xsl:otherwise><xsl:value-of select="$chopString"/></xsl:otherwise>
		</xsl:choose>
    <xsl:text> </xsl:text>
	</xsl:template>

	<xsl:template name="addClassRtl">
    <xsl:variable name="lang" select="marc:subfield[@code='7']" />
    <xsl:if test="$lang = 'ha' or $lang = 'Hebrew' or $lang = 'fa' or $lang = 'Arabe'">
      <xsl:attribute name="class">rtl</xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template name="tag_title">
    <xsl:param name="tag" />
    <xsl:param name="label" />
    <xsl:if test="marc:datafield[@tag=$tag]">
      <li>
        <strong><xsl:value-of select="$label"/>: </strong>
        <xsl:for-each select="marc:datafield[@tag=$tag]">
          <xsl:value-of select="marc:subfield[@code='a']" />
          <xsl:if test="marc:subfield[@code='d']">
            <xsl:text> : </xsl:text>
            <xsl:value-of select="marc:subfield[@code='e']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='e']">
            <xsl:for-each select="marc:subfield[@code='e']">
              <xsl:text> </xsl:text>
              <xsl:value-of select="."/>
            </xsl:for-each>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='f']">
            <xsl:text> / </xsl:text>
            <xsl:value-of select="marc:subfield[@code='f']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='h']">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="marc:subfield[@code='h']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='i']">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="marc:subfield[@code='i']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='v']">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="marc:subfield[@code='v']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='x']">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="marc:subfield[@code='x']"/>
          </xsl:if>
          <xsl:if test="marc:subfield[@code='z']">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="marc:subfield[@code='z']"/>
          </xsl:if>
        </xsl:for-each>
      </li>
    </xsl:if>
  </xsl:template>


  <xsl:template name="tag_subject">
    <xsl:param name="tag" />
    <xsl:param name="label" />
    <xsl:if test="marc:datafield[@tag=$tag]">
      <li>
        <strong><xsl:value-of select="$label"/>: </strong>
        <xsl:for-each select="marc:datafield[@tag=$tag]">
          <a>
            <xsl:choose>
              <xsl:when test="marc:subfield[@code=9]">
                <xsl:attribute name="href">/cgi-bin/koha/catalogue/search.pl?q=an:<xsl:value-of select="marc:subfield[@code=9]"/></xsl:attribute>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="href">/cgi-bin/koha/catalogue/search.pl?q=su:<xsl:value-of select="marc:subfield[@code='a']"/></xsl:attribute>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="chopPunctuation">
              <xsl:with-param name="chopString">
                <xsl:call-template name="subfieldSelect">
                    <xsl:with-param name="codes">abcdjpvxyz</xsl:with-param>
                    <xsl:with-param name="subdivCodes">jpxyz</xsl:with-param>
                    <xsl:with-param name="subdivDelimiter">-- </xsl:with-param>
                </xsl:call-template>
              </xsl:with-param>
            </xsl:call-template>
          </a>
          <xsl:if test="not (position()=last())">
            <xsl:text> | </xsl:text>
          </xsl:if>
        </xsl:for-each>
      </li>
    </xsl:if>
  </xsl:template>


  <xsl:template name="tag_7xx">
    <xsl:param name="tag" />
    <xsl:param name="label" />
    <xsl:if test="marc:datafield[@tag=$tag]">
      <li>
        <strong><xsl:value-of select="$label" />: </strong>
        <xsl:for-each select="marc:datafield[@tag=$tag]">
          <span>
            <xsl:call-template name="addClassRtl" />
            <a>
              <xsl:choose>
                <xsl:when test="marc:subfield[@code=9]">
                  <xsl:attribute name="href">/cgi-bin/koha/catalogue/search.pl?q=an:<xsl:value-of select="marc:subfield[@code=9]"/></xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:attribute name="href">/cgi-bin/koha/catalogue/search.pl?q=au:<xsl:value-of select="marc:subfield[@code='a']"/><xsl:text> </xsl:text><xsl:value-of select="marc:subfield[@code='b']"/></xsl:attribute>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="marc:subfield[@code='a']">
                <xsl:value-of select="marc:subfield[@code='a']"/>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='b']">
                <xsl:text>, </xsl:text>
                <xsl:value-of select="marc:subfield[@code='b']"/>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='c']">
                <xsl:text>, </xsl:text>
                <xsl:value-of select="marc:subfield[@code='c']"/>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='d']">
                <xsl:text> </xsl:text>
                <xsl:value-of select="marc:subfield[@code='d']"/>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='f']">
                <span dir="ltr">
                <xsl:text> (</xsl:text>
                <xsl:value-of select="marc:subfield[@code='f']"/>
                <xsl:text>)</xsl:text>
                </span>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='g']">
                <xsl:text> </xsl:text>
                <xsl:value-of select="marc:subfield[@code='g']"/>
              </xsl:if>
              <xsl:if test="marc:subfield[@code='p']">
                <xsl:text> </xsl:text>
                <xsl:value-of select="marc:subfield[@code='p']"/>
              </xsl:if>
            </a>
          </span>
          <xsl:if test="not (position() = last())">
            <xsl:text> ; </xsl:text>
          </xsl:if>
        </xsl:for-each>
      </li>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
