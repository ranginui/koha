<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: MARC21slim2DC.xsl,v 1.1 2003/01/06 08:20:27 adam Exp $ -->
<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:items="http://www.koha.org/items"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="marc items">

<xsl:import href="UNIMARCslimUtils.xsl"/>
<xsl:output method = "xml" indent="yes" omit-xml-declaration = "yes" />
<xsl:key name="item-by-status" match="items:item" use="items:status"/>
<xsl:key name="item-by-status-and-branch" match="items:item" use="concat(items:status, ' ', items:homebranch)"/>

<xsl:template match="/">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="marc:record">
  <xsl:variable name="leader" select="marc:leader"/>
  <xsl:variable name="leader6" select="substring($leader,7,1)"/>
  <xsl:variable name="leader7" select="substring($leader,8,1)"/>
  <xsl:variable name="biblionumber" select="marc:controlfield[@tag=001]"/>
  <xsl:variable name="isbn" select="marc:datafield[@tag=010]/marc:subfield[@code='a']"/>
     	
  <xsl:if test="marc:datafield[@tag=200]">
    <xsl:for-each select="marc:datafield[@tag=200]">
      	<a><xsl:attribute name="href">/cgi-bin/koha/opac-detail.pl?biblionumber=<xsl:value-of select="$biblionumber"/>
           </xsl:attribute>
        <xsl:variable name="title" select="marc:subfield[@code='a']"/>
        <xsl:variable name="ntitle"
             select="translate($title, '&#x0098;&#x009C;&#xC29C;&#xC29B;&#xC298;&#xC288;&#xC289;','')"/>
        <xsl:value-of select="$ntitle" />
      </a>
      <xsl:if test="marc:subfield[@code='e']">
        <xsl:text> : </xsl:text>
        <xsl:value-of select="marc:subfield[@code='e']"/>
      </xsl:if>
      <xsl:if test="marc:subfield[@code='b']">
        <xsl:text> [</xsl:text>
        <xsl:value-of select="marc:subfield[@code='b']"/>
        <xsl:text>]</xsl:text>
      </xsl:if>
      <xsl:if test="marc:subfield[@code='h']">
        <xsl:text> : </xsl:text>
        <xsl:value-of select="marc:subfield[@code='h']"/>
      </xsl:if>
      <xsl:if test="marc:subfield[@code='i']">
        <xsl:text> : </xsl:text>
        <xsl:value-of select="marc:subfield[@code='i']"/>
      </xsl:if>
      <xsl:if test="marc:subfield[@code='f']">
        <xsl:text> / </xsl:text>
        <xsl:value-of select="marc:subfield[@code='f']"/>
      </xsl:if>
      <xsl:if test="marc:subfield[@code='g']">
        <xsl:text> ; </xsl:text>
        <xsl:value-of select="marc:subfield[@code='g']"/>
      </xsl:if>
      <xsl:text> </xsl:text>
    </xsl:for-each>
  </xsl:if>

  <xsl:call-template name="tag_4xx" />

  <xsl:call-template name="tag_205" />

  <xsl:call-template name="tag_210" />

  <xsl:call-template name="tag_215" />

  <xsl:if test="marc:datafield[@tag=955]">
    <span class="results_summary">
      <span class="label">État de collection : </span>
      <ul>
        <xsl:for-each select="marc:datafield[@tag=955]">
          <li>
 	      <xsl:choose>
              <xsl:when test="marc:subfield[@code='5']">
              	<xsl:call-template name="RCR">
      		    <xsl:with-param name="code" select="substring-before(marc:subfield[@code='5'], ':')"/>
      	      	</xsl:call-template>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:value-of select="marc:subfield[@code='9']"/>
	      </xsl:otherwise>
	      </xsl:choose>
      	      <xsl:if test="marc:subfield[@code='r']">
      		  , <xsl:value-of select="marc:subfield[@code='r']"/>
      	      </xsl:if>
          </li>
        </xsl:for-each>
      </ul>
    </span>
  </xsl:if>
    <xsl:if test="marc:datafield[@tag=856]">
      <span class="results_summary">
        <span class="label">Ressource en ligne: </span>
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
              Cliquer ici
            </xsl:when>
            </xsl:choose>
          </a>
          <xsl:choose>
            <xsl:when test="position()=last()"/>
            <xsl:otherwise> | </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </span>
    </xsl:if>

  <span class="results_summary">
    <span class="label">Disponibilité: </span>
    <xsl:choose>
      <!--<xsl:when test="marc:datafield[@tag=856]">
        <xsl:for-each select="marc:datafield[@tag=856]">
          <xsl:choose>
            <xsl:when test="@ind2=0">
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
            </xsl:when> 
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>-->
      <xsl:when test="count(key('item-by-status', 'available'))=0 and count(key('item-by-status', 'reference'))=0">
        Pas de copie disponible
      </xsl:when>
      <xsl:when test="count(key('item-by-status', 'available'))>0">
        <span class="available">
          <b><xsl:text>Pour le prêt: </xsl:text></b>
          <xsl:variable name="available_items" select="key('item-by-status', 'available')"/>
          <xsl:for-each select="$available_items[generate-id() = generate-id(key('item-by-status-and-branch', concat(items:status, ' ', items:homebranch))[1])]">
            <xsl:value-of select="items:homebranch"/>
  			    <xsl:if test="items:itemcallnumber != '' and items:itemcallnumber">[<xsl:value-of select="items:itemcallnumber"/>]
  			    </xsl:if>
            <xsl:text> (</xsl:text>
            <xsl:value-of select="count(key('item-by-status-and-branch', concat(items:status, ' ', items:homebranch)))"/>
            <xsl:text>)</xsl:text>
            <xsl:choose>
              <xsl:when test="position()=last()">
                <xsl:text>. </xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>, </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </span>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="count(key('item-by-status', 'reference'))>0">
        <span class="available">
          <b><xsl:text>Indisponible au prêt : </xsl:text></b>
          <xsl:variable name="reference_items"
                        select="key('item-by-status', 'reference')"/>
          <xsl:for-each select="$reference_items[generate-id() = generate-id(key('item-by-status-and-branch', concat(items:status, ' ', items:homebranch))[1])]">
            <xsl:value-of select="items:homebranch"/>
            <xsl:if test="items:itemcallnumber != '' and items:itemcallnumber">[<xsl:value-of select="items:itemcallnumber"/>]</xsl:if>
            <xsl:text> (</xsl:text>
            <xsl:value-of select="count(key('item-by-status-and-branch', concat(items:status, ' ', items:homebranch)))"/>
            <xsl:text>)</xsl:text>
            <xsl:choose>
              <xsl:when test="position()=last()">
                <xsl:text>. </xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>, </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </span>
      </xsl:when>
    </xsl:choose>
    <xsl:if test="count(key('item-by-status', 'Checked out'))>0">
      <span class="unavailable">
        <xsl:text>Checked out (</xsl:text>
        <xsl:value-of select="count(key('item-by-status', 'Checked out'))"/>
        <xsl:text>). </xsl:text>
      </span>
    </xsl:if>
    <xsl:if test="count(key('item-by-status', 'Withdrawn'))>0">
      <span class="unavailable">
        <xsl:text>Withdrawn (</xsl:text>
        <xsl:value-of select="count(key('item-by-status', 'Withdrawn'))"/>
        <xsl:text>). </xsl:text>
      </span>
    </xsl:if>
    <xsl:if test="count(key('item-by-status', 'Lost'))>0">
      <span class="unavailable">
        <xsl:text>Lost (</xsl:text>
        <xsl:value-of select="count(key('item-by-status', 'Lost'))"/>
        <xsl:text>). </xsl:text>
      </span>
    </xsl:if>
    <xsl:if test="count(key('item-by-status', 'Damaged'))>0">
      <span class="unavailable">
        <xsl:text>Damaged (</xsl:text>
        <xsl:value-of select="count(key('item-by-status', 'Damaged'))"/>
        <xsl:text>). </xsl:text>
      </span>
    </xsl:if>
    <xsl:if test="count(key('item-by-status', 'On Orangemanr'))>0">
      <span class="unavailable">
        <xsl:text>On order (</xsl:text>
        <xsl:value-of select="count(key('item-by-status', 'On order'))"/>
        <xsl:text>). </xsl:text>
      </span>
    </xsl:if>
    <xsl:if test="count(key('item-by-status', 'In transit'))>0">
      <span class="unavailable">
        <xsl:text>In transit (</xsl:text>
        <xsl:value-of select="count(key('item-by-status', 'In transit'))"/>
        <xsl:text>). </xsl:text>
      </span>
    </xsl:if>
    <xsl:if test="count(key('item-by-status', 'Waiting'))>0">
      <span class="unavailable">
        <xsl:text>On hold (</xsl:text>
        <xsl:value-of select="count(key('item-by-status', 'Waiting'))"/>
        <xsl:text>). </xsl:text>
      </span>
    </xsl:if>
  </span>

</xsl:template>

    <xsl:template name="RCR">
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

</xsl:stylesheet>
