-- MySQL dump 10.13  Distrib 5.1.49, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: koha_solr
-- ------------------------------------------------------
-- Server version	5.1.49-2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `indexes`
--

DROP TABLE IF EXISTS `indexes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `indexes` (
  `code` varchar(255) NOT NULL DEFAULT '',
  `label` varchar(255) DEFAULT NULL,
  `type` varchar(20) DEFAULT NULL,
  `faceted` tinyint(4) DEFAULT NULL,
  `ressource_type` varchar(255) DEFAULT NULL,
  `mandatory` tinyint(4) DEFAULT NULL,
  `sortable` tinyint(4) DEFAULT NULL,
  `plugin` varchar(255) DEFAULT NULL,
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=552 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `indexes`
--

LOCK TABLES `indexes` WRITE;
/*!40000 ALTER TABLE `indexes` DISABLE KEYS */;
INSERT INTO `indexes` VALUES ('usedinxbiblios','Used in X biblios','int',0,'authority',1,1,'C4::Search::Plugins::UsedInXBiblios',1),('name','Name','txt',1,'authority',0,0,'',2),('electronic-resource','Ressource électronique','txt',0,'biblio',0,0,'',551),('printed-music','Musique imprimée','txt',0,'biblio',0,0,'',550),('date','Date','date',0,'authority',0,0,'',7),('authtype','Authority Type','str',1,'authority',0,1,'',8),('serials','Ressources continues','txt',0,'biblio',0,0,'',549),('name','Auteur personne','str',2,'biblio',0,2,'',548),('upc','UPC','str',0,'biblio',0,0,'',546),('onloan','En prêt','int',0,'biblio',0,0,'',547),('music-source','Source éditoriale','str',0,'biblio',0,0,'',545),('music-number','Référence éditoriale','int',0,'biblio',0,0,'',544),('graphics-types','graphics-types','str',0,'biblio',0,0,'',543),('video-mt','video-mt','str',0,'biblio',0,0,'',542),('illustration-code','Code d\'illustration','str',0,'biblio',0,0,'',540),('type-of-serial','Type de périodique','str',0,'biblio',0,0,'',541),('second-author-name','Nom du second auteur','str',0,'biblio',0,0,'',538),('second-author-firstname','Prénom du second auteur','str',0,'biblio',0,0,'',539),('author-firstname','Prénom de l\'auteur','str',0,'biblio',0,0,'',537),('author-name-personal','Nom de l\'auteur','str',1,'biblio',0,1,'',536),('harvestdate','Date de dernière vendange','date',0,'biblio',0,0,'',535),('rflag','Indicateur de vendange','int',0,'biblio',0,0,'',534),('identifier','Identifiant notice','str',0,'biblio',0,0,'',533),('serialnote','Note sur le numéro','str',0,'biblio',0,0,'',532),('status','Statut','str',0,'biblio',0,0,'',531),('location','Localisation','str',0,'biblio',0,1,'',530),('acqdate','Date d\'acquisition','date',0,'biblio',0,1,'',529),('subject','Sujet','str',1,'biblio',0,0,'',528),('lost','Exemplaire perdu','int',0,'biblio',0,0,'',527),('item','Exemplaire','str',0,'biblio',0,0,'',526),('barcode','Code barre','str',0,'biblio',0,0,'',525),('availability','Disponibilité','int',0,'biblio',0,0,'C4::Search::Plugins::Availability',524),('callnumber','Cote','str',0,'biblio',0,1,'',523),('holdingbranch','Dépositaire','str',1,'biblio',0,0,'',522),('itype','Type de prêt','str',0,'biblio',0,0,'',521),('dewey','Cote dewey','str',0,'biblio',0,0,'',520),('ccode','Type de document','str',1,'biblio',0,1,'',518),('abstract','Résumé','str',0,'biblio',0,0,'',519),('authorities','Formes Rejetées','txt',0,'biblio',0,0,'C4::Search::Plugins::Authorities',517),('lastmodified','Date de modification','str',0,'biblio',0,0,'',516),('genre','Genre','str',1,'biblio',0,0,'',515),('title-cover','Titre de couverture','txt',0,'biblio',0,0,'',510),('title','Titre','txt',0,'biblio',1,1,'',513),('audience','Public','str',0,'biblio',0,0,'C4::Search::Plugins::Audience',514),('authid','AuthId','int',0,'biblio',0,0,'',512),('title-series','Collection','txt',0,'biblio',0,0,'',511),('author','Auteur','str',2,'biblio',0,2,'C4::Search::Plugins::Author',509),('title-uniform','Titre uniforme','txt',0,'biblio',0,0,'',508),('isbn','ISBN','str',0,'biblio',0,0,'',507),('title-host','Document hôte','txt',0,'biblio',0,0,'',506),('entereddate','Date de saisie','str',0,'biblio',0,0,'',505),('biblionumber','Biblionumber','str',0,'biblio',0,0,'',504),('itemtype','Type de document','str',0,'biblio',0,0,'',503),('name-geographic','Sujet géographique','str',0,'biblio',0,0,'',502),('pubplace','Lieu de publication','str',0,'biblio',0,0,'',500),('lang','Langue','str',0,'biblio',1,0,'',501),('ppn','PPN','str',0,'biblio',0,0,'',499),('personnal-name','Sujet nom de personne','str',0,'biblio',0,0,'',498),('note','Note','txt',0,'biblio',0,0,'',497),('issn','ISSN','str',0,'biblio',0,0,'',496),('corporate-name','Auteur collectivité','str',0,'biblio',0,0,'',495),('size','Taille','str',0,'biblio',0,0,'',494),('publisher','Éditeur','str',0,'biblio',0,0,'',493),('ean','EAN','str',0,'biblio',1,0,'',492),('pubdate','Date de publication','str',0,'biblio',0,1,'',490),('itemcallnumber','Cote exemplaire','str',0,'biblio',0,0,'',491),('homebranch','Propriétaire','str',1,'biblio',0,0,'',489);
/*!40000 ALTER TABLE `indexes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `indexmappings`
--

DROP TABLE IF EXISTS `indexmappings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `indexmappings` (
  `field` char(3) DEFAULT NULL,
  `subfield` char(1) DEFAULT NULL,
  `index` varchar(15) DEFAULT NULL,
  `ressource_type` varchar(20) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `indexmappings`
--

LOCK TABLES `indexmappings` WRITE;
/*!40000 ALTER TABLE `indexmappings` DISABLE KEYS */;
INSERT INTO `indexmappings` VALUES ('995','r','itype','biblio'),('995','r','itemtype','biblio'),('250','a','name','authority'),('210','a','name','authority'),('995','o','status','biblio'),('995','n','onloan','biblio'),('995','k','callnumber','biblio'),('995','k','itemcallnumber','biblio'),('995','k','callnumber','biblio'),('995','h','ccode','biblio'),('995','f','barcode','biblio'),('995','e','location','biblio'),('200','a','name','authority'),('152','b','authtype','authority'),('995','d','holdingbranch','biblio'),('995','c','holdingbranch','biblio'),('995','b','homebranch','biblio'),('995','a','homebranch','biblio'),('995','6','acqdate','biblio'),('995','2','lost','biblio'),('200','b','name','authority'),('995','*','item','biblio'),('9..','9','authid','biblio'),('909','a','itemtype','biblio'),('8..','9','authid','biblio'),('712','*','corporate-name','biblio'),('711','*','corporate-name','biblio'),('710','*','corporate-name','biblio'),('71.','*','corporate-name','biblio'),('702','b','homebranch','biblio'),('702','a','homebranch','biblio'),('702','*','name','biblio'),('701','*','name','biblio'),('700','b','homebranch','biblio'),('700','a','homebranch','biblio'),('700','*','name','biblio'),('70.','*','name','biblio'),('7..','9','authid','biblio'),('7..','*','author','biblio'),('686','a','callnumber','biblio'),('676','a','callnumber','biblio'),('676','a','dewey','biblio'),('610','*','subject','biblio'),('608','a','genre','biblio'),('607','*','name-geographic','biblio'),('606','a','subject','biblio'),('606','*','subject','biblio'),('605','*','subject','biblio'),('604','*','subject','biblio'),('603','*','subject','biblio'),('602','*','subject','biblio'),('602','*','personnal-name','biblio'),('601','*','subject','biblio'),('600','*','subject','biblio'),('600','*','personnal-name','biblio'),('6..','9','authid','biblio'),('5..','9','authid','biblio'),('5..','*','title','biblio'),('464','t','title-host','biblio'),('461','t','title-host','biblio'),('410','t','title-series','biblio'),('403','t','title-uniform','biblio'),('4..','t','title','biblio'),('4..','d','pubdate','biblio'),('4..','9','authid','biblio'),('330','a','abstract','biblio'),('3..','9','authid','biblio'),('3..','*','note','biblio'),('230','a','homebranch','biblio'),('225','x','issn','biblio'),('225','v','title-series','biblio'),('225','i','title-series','biblio'),('225','h','title-series','biblio'),('225','e','title-series','biblio'),('225','d','title-series','biblio'),('225','a','title-series','biblio'),('210','d','pubdate','biblio'),('210','c','publisher','biblio'),('210','a','pubplace','biblio'),('208','*','printed-music','biblio'),('207','*','serials','biblio'),('205','*','title','biblio'),('200','i','title','biblio'),('200','f','author','biblio'),('200','i','title-cover','biblio'),('200','e','title-cover','biblio'),('200','e','title','biblio'),('200','d','title','biblio'),('200','c','title','biblio'),('200','b','itype','biblio'),('200','b','itemtype','biblio'),('200','a','title','biblio'),('200','a','title-cover','biblio'),('2..','9','authid','biblio'),('116','a','graphics-types','biblio'),('115','a','video-mt','biblio'),('110','a','type-of-serial','biblio'),('105','a','homebranch','biblio'),('101','a','lang','biblio'),('1..','9','authid','biblio'),('099','t','ccode','biblio'),('099','d','lastmodified','biblio'),('099','c','entereddate','biblio'),('099','c','acqdate','biblio'),('091','b','harvestdate','biblio'),('091','a','rflag','biblio'),('090','9','biblionumber','biblio'),('073','a','ean','biblio'),('072','a','upc','biblio'),('071','b','music-source','biblio'),('071','a','music-number','biblio'),('011','a','issn','biblio'),('010','a','isbn','biblio'),('995','u','note','biblio'),('995','v','serialnote','biblio'),('001','@','biblionumber','biblio'),('009','@','ppn','biblio'),('001','@','identifier','biblio'),('009','@','identifier','biblio'),('035','*','identifier','biblio'),('010','*','identifier','biblio'),('011','*','identifier','biblio'),('071','*','identifier','biblio'),('072','*','identifier','biblio'),('073','*','identifier','biblio');
/*!40000 ALTER TABLE `indexmappings` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-11-24 10:04:36
