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
      <span class="results_summary">
        <span class="label">Édition: </span> 
        <xsl:if test="marc:subfield[@code='a']">
          <xsl:value-of select="marc:subfield[@code='a']"/>
        </xsl:if>
      </span>
    </xsl:for-each>
  </xsl:template>

	<xsl:template name="tag_210">
    <xsl:for-each select="marc:datafield[@tag=210]">
  	    <span class="results_summary">
        <span class="label">Éditeur: </span> 
        <xsl:value-of select="marc:subfield[@code='a']"/>
        <xsl:if test="marc:subfield[@code='c']">
          <xsl:if test="marc:subfield[@code='a']"> : </xsl:if>
          <xsl:value-of select="marc:subfield[@code='c']"/>
        </xsl:if>
        <xsl:if test="marc:subfield[@code='d']">
          <xsl:if test="marc:subfield[@code='a' or @code='c']">, </xsl:if>        
          <xsl:value-of select="marc:subfield[@code='d']"/>&#xA0;
        </xsl:if>
        <xsl:value-of select="marc:subfield[@code='e']"/>
        <xsl:if test="marc:subfield[@code='g']">
          <xsl:if test="marc:subfield[@code='e']"> : </xsl:if>
          <xsl:value-of select="marc:subfield[@code='g']"/>
        </xsl:if>
        <xsl:if test="marc:subfield[@code='h']">
          <xsl:if test="marc:subfield[@code='e' or @code='g']">, </xsl:if>        
          <xsl:value-of select="marc:subfield[@code='h']"/>
        </xsl:if>
      </span>
    </xsl:for-each>
  </xsl:template>

	<xsl:template name="tag_215">
    <xsl:for-each select="marc:datafield[@tag=215]">
  	  <span class="results_summary">
        <span class="label">Description: </span> 
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
      </span>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_4xx">
    <xsl:for-each select="marc:datafield[@tag=464 or @tag=461]">
        <li>
        Contient: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_430">
    <xsl:for-each select="marc:datafield[@tag=430]">
        <li>
        Suite de: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_413">
    <xsl:for-each select="marc:datafield[@tag=413]">
        <li>
        A pour extrait: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_421">
    <xsl:for-each select="marc:datafield[@tag=421]">
        <li>
        A pour supplément: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>


<xsl:template name="tag_422">
    <xsl:for-each select="marc:datafield[@tag=422]">
        <li>
        Est un supplément de: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_423">
    <xsl:for-each select="marc:datafield[@tag=423]">
        <li>
        Est publié avec: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_424">
    <xsl:for-each select="marc:datafield[@tag=424]">
        <li>
        Est mis à jour par: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_425">
    <xsl:for-each select="marc:datafield[@tag=425]">
        <li>
        Met à jour: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>


<xsl:template name="tag_431">
    <xsl:for-each select="marc:datafield[@tag=431]">
        <li>
        Succède après scission à: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_432">
    <xsl:for-each select="marc:datafield[@tag=432]">
        <li>
        Remplace: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_433">
    <xsl:for-each select="marc:datafield[@tag=433]">
        <li>
        Remplace partiellement: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_434">
    <xsl:for-each select="marc:datafield[@tag=434]">
        <li>
        Absorbe: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_435">
    <xsl:for-each select="marc:datafield[@tag=435]">
        <li>
        Absorbe partiellement: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_436">
    <xsl:for-each select="marc:datafield[@tag=436]">
        <li>
      Fusion de :
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
      </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_437">
    <xsl:for-each select="marc:datafield[@tag=437]">
        <li>
        Suite partielle de: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_440">
    <xsl:for-each select="marc:datafield[@tag=440]">
        <li>
        Devient: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_441">
    <xsl:for-each select="marc:datafield[@tag=441]">
        <li>
        Devient partiellement: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_442">
    <xsl:for-each select="marc:datafield[@tag=442]">
        <li>
        Remplacé par: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_443">
    <xsl:for-each select="marc:datafield[@tag=443]">
        <li>
        Remplacé partiellement par: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_444">
    <xsl:for-each select="marc:datafield[@tag=444]">
        <li>
        Absorbé par: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_445">
    <xsl:for-each select="marc:datafield[@tag=445]">
        <li>
        Absorbé partiellement par: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_446">
    <xsl:for-each select="marc:datafield[@tag=446]">
        <li>
        Scindé en: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_447">
    <xsl:for-each select="marc:datafield[@tag=447]">
        <li>
        Fusionne avec:
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_448">
    <xsl:for-each select="marc:datafield[@tag=448]">
        <li>
        Redevient:
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>


<xsl:template name="tag_451">
    <xsl:for-each select="marc:datafield[@tag=451]">
        <li>
        Autre édition sur le même support: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_452">
    <xsl:for-each select="marc:datafield[@tag=452]">
        <li>
        Autre édition sur un support différent: 
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
     /cgi-bin/koha/opac-search.pl?q=kw:<xsl:value-of select="marc:subfield[@code='0']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='0']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>


<xsl:template name="tag_453">
    <xsl:for-each select="marc:datafield[@tag=453]">
        <li>
        Traduit sous le titre: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_454">
    <xsl:for-each select="marc:datafield[@tag=454]">
        <li>
        Est une traduction de: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_455">
    <xsl:for-each select="marc:datafield[@tag=455]">
        <li>
        Est une reproduction de: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_456">
    <xsl:for-each select="marc:datafield[@tag=456]">
        <li>
        Est reproduit comme: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_462">
    <xsl:for-each select="marc:datafield[@tag=462]">
        <li>
        Sous-ensemble: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>

<xsl:template name="tag_463">
    <xsl:for-each select="marc:datafield[@tag=463]">
        <li>
        Unité matérielle: 
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
     /cgi-bin/koha/opac-search.pl?q=ns:<xsl:value-of select="marc:subfield[@code='x']"/>
</xsl:attribute><xsl:value-of select="marc:subfield[@code='x']"/></xsl:element>
       </xsl:if>
        </span>
      </li>
    </xsl:for-each>
  </xsl:template>


  <!--<xsl:template name="tag_4xx">
    <xsl:if test="marc:datafield[@tag=461]">
      <span class="results_summary">
      <span class="label">Fait partie de : </span> 
      <xsl:value-of select="marc:subfield[@code='t']"/>
      <xsl:if test="marc:subfield[@code='v']"><xsl:value-of select="marc:subfield[@code='v']"/></xsl:if>
      </span>
    </xsl:if>	
    <xsl:if test="marc:datafield[@tag=454]">
      <span class="results_summary">
      <span class="label">Traduit de : </span> 
      <xsl:value-of select="marc:datafield[@tag=454]"/>
      </span>
    </xsl:if>	
    <xsl:for-each select="marc:datafield[@tag=464]">
    	  <span class="results_summary">
        <span class="label">Contient : </span> 
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
      </span>
    </xsl:for-each>
  </xsl:template>-->

  <xsl:template name="RelatorCode">
       <xsl:if test="marc:subfield[@code=4]">
	    <xsl:choose>
	      <xsl:when test="node()='070'"><xsl:text>, coauteur</xsl:text></xsl:when>
	      <xsl:when test="node()='651'"><xsl:text>, directeur de publication</xsl:text></xsl:when>
	      <xsl:when test="node()='730'"><xsl:text>, traducteur</xsl:text></xsl:when>
              <xsl:when test="node()='080'"><xsl:text>, préfacier</xsl:text></xsl:when>
	      <xsl:when test="node()='340'"><xsl:text>, éditeur</xsl:text></xsl:when>
	      <xsl:when test="node()='440'"><xsl:text>, illustrateur</xsl:text></xsl:when>
	      <xsl:when test="node()='557'"><xsl:text>, organisateur</xsl:text></xsl:when>
	      <xsl:when test="node()='727'"><xsl:text>, directeur de thèse</xsl:text></xsl:when>
	      <xsl:when test="node()='295'"><xsl:text>, établissement de soutenance</xsl:text></xsl:when>
	      <xsl:otherwise><xsl:text></xsl:text></xsl:otherwise>
	    </xsl:choose>
	  </xsl:if>
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
      <span class="results_summary">
        <span class="label"><xsl:value-of select="$label"/>: </span>
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
      </span>
    </xsl:if>
  </xsl:template>


  <xsl:template name="tag_subject">
    <xsl:param name="tag" />
    <xsl:param name="label" />
    <xsl:if test="marc:datafield[@tag=$tag]">
      <span class="results_summary">
        <span class="label"><xsl:value-of select="$label"/>: </span>
        <xsl:for-each select="marc:datafield[@tag=$tag]">
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
      </span>
    </xsl:if>
  </xsl:template>


  <xsl:template name="tag_7xx">
    <xsl:param name="tag" />
    <xsl:param name="label" />
    <xsl:if test="marc:datafield[@tag=$tag]">
      <span class="results_summary">
        <span class="label"><xsl:value-of select="$label" />: </span>
        <xsl:for-each select="marc:datafield[@tag=$tag]">
          <span>
            <xsl:call-template name="addClassRtl" />
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
      </span>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
