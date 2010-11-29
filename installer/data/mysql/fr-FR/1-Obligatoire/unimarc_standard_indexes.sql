SET NAMES "UTF8";

--
-- Dumping data for table `indexes`
--

LOCK TABLES `indexes` WRITE;
INSERT INTO `indexes` (`code`,`label`,`type`,`faceted`,`ressource_type`,`mandatory`,`sortable`,`plugin`) VALUES 
('usedinxbiblios','Used in X biblios','int',0,'authority',1,1,'C4::Search::Plugins::UsedInXBiblios'),
('name','Name','txt',1,'authority',0,0,''),
('itemtype','Type','str',1,'biblio',0,1,''),
('lang','Langue','str',1,'biblio',1,0,''),
('issn','ISSN','str',0,'biblio',0,0,''),
('note','Note','txt',0,'biblio',0,0,''),
('publisher','Editeur','str',1,'biblio',0,1,''),
('size','Taille','str',0,'biblio',0,0,''),
('year','Annee','date',1,'biblio',0,1,''),
('subject','Sujet','str',1,'biblio',0,0,''),
('date','Date','date',0,'authority',0,0,''),
('authtype','Authority Type','str',1,'authority',0,1,''),
('title','Titre','txt',0,'biblio',1,1,''),
('ean','EAN','str',0,'biblio',1,0,''),
('callnumber','Cote','str',0,'biblio',0,0,''),
('authorities','Formes Rejetées','txt',0,'biblio',0,0,'C4::Search::Plugins::Authorities'),
('barcode','Code bare','str',0,'biblio',0,0,''),
('authid','AuthId','int',0,'biblio',0,0,''),
('availability','Disponibilité','int',0,'biblio',0,0,'C4::Search::Plugins::Availability'),
('author','Auteur','txt',1,'biblio',0,1,'C4::Search::Plugins::Author'),
('isbn','ISBN','str',0,'biblio',0,0,''),
('holdingbranch','Dépositaire','str',1,'biblio',0,0,''),
('homebranch','Propriétaire','str',1,'biblio',0,0,'');
UNLOCK TABLES;

--
-- Dumping data for table `indexmappings`
--

LOCK TABLES `indexmappings` WRITE;
INSERT INTO `indexmappings` VALUES 
('995','c','holdingbranch','biblio'),
('995','b','homebranch','biblio'),
('909','a','itemtype','biblio'),
('250','a','name','authority'),
('210','a','name','authority'),
('712','9','authid','biblio'),
('712','9','authid','biblio'),
('710','b','author','biblio'),
('710','a','author','biblio'),
('710','9','authid','biblio'),
('702','9','authid','biblio'),
('701','9','authid','biblio'),
('700','b','author','biblio'),
('700','a','author','biblio'),
('700','a','author','biblio'),
('700','9','authid','biblio'),
('610','9','authid','biblio'),
('606','a','subject','biblio'),
('328','a','note','biblio'),
('300','a','note','biblio'),
('200','a','name','authority'),
('152','b','authtype','authority'),
('210','c','publisher','biblio'),
('200','f','author','biblio'),
('200','a','title','biblio'),
('101','a','lang','biblio'),
('011','a','issn','biblio'),
('010','a','isbn','biblio'),
('995','k','callnumber','biblio'),
('995','n','availability','biblio'),
('995','v','barcode','biblio'),
('073','a','ean','biblio'),
('200','b','name','authority');
UNLOCK TABLES;

