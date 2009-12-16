-- MySQL dump 10.11
--
-- Host: localhost    Database: koha
-- ------------------------------------------------------
-- Server version	5.0.51a-24+lenny2

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
-- Table structure for table `authorised_values`
--

DROP TABLE IF EXISTS `authorised_values`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `authorised_values` (
  `id` int(11) NOT NULL auto_increment,
  `category` varchar(10) NOT NULL default '',
  `authorised_value` varchar(80) NOT NULL default '',
  `lib` varchar(80) default NULL,
  `lib_opac` varchar(80) default NULL,
  `imageurl` varchar(200) default NULL,
  PRIMARY KEY  (`id`),
  KEY `name` (`category`),
  KEY `lib` (`lib`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `authorised_values`
--

LOCK TABLES `authorised_values` WRITE;
/*!40000 ALTER TABLE `authorised_values` DISABLE KEYS */;
INSERT INTO `authorised_values` VALUES (2,'SUGGEST','BUY','Recommendation for purchase','This item has ben ordered, and may be reserved.',''),(3,'ETHNIC','European / Pakeha','European / Pakeha',NULL,''),(4,'ETHNIC','Asian','Asian',NULL,''),(5,'ETHNIC','Maori','Maori',NULL,''),(6,'ETHNIC','None','None',NULL,''),(7,'ETHNIC','Other','Other',NULL,''),(8,'ETHNIC','Pacific Island','Pacific Island',NULL,''),(9,'AREA','L','Levin',NULL,''),(10,'AREA','F','Foxton',NULL,''),(11,'AREA','S','Shannon',NULL,''),(12,'AREA','H','Horowhenua',NULL,''),(13,'AREA','K','Kapiti',NULL,''),(14,'AREA','O','Out of district',NULL,''),(15,'AREA','V','Village',NULL,''),(16,'AREA','I','Interloan',NULL,''),(17,'AREA','T','Temporary',NULL,''),(18,'SUGGEST','IL','Interloan (not purchase) ','This item will not be purchased, but it may be interloaned.',''),(20,'CCODE','BN','Adult Nonfiction',NULL,'bridge/book.gif'),(21,'CCODE','BF','Adult Fiction',NULL,'bridge/book.gif'),(22,'CCODE','BJN','Children\'s Nonfiction',NULL,'bridge/book.gif'),(23,'CCODE','BJF','Children\'s Fiction',NULL,'bridge/book.gif'),(24,'CCODE','BYF','Teen Fiction',NULL,'bridge/book.gif'),(27,'CCODE','D','DVD',NULL,'bridge/dvd.gif'),(34,'CCODE','TB','Audio Book on CD or cassette',NULL,'bridge/cd_music.gif'),(35,'CCODE','V','Video',NULL,'bridge/vhs.gif'),(36,'CCODE','M','Magazines',NULL,'bridge/periodical.gif'),(37,'CCODE','LP','Large Print',NULL,'bridge/book.gif'),(38,'CCODE','BJP','Picture Books',NULL,'bridge/book.gif'),(39,'CCODE','MAO','Maori Collections',NULL,'bridge/book.gif'),(40,'CCODE','ODD','Odd things to check post conversion',NULL,''),(41,'CCODE','DEL','Items to delete post conversion',NULL,''),(44,'LOST','Missing','Not on shelf',NULL,''),(46,'DAMAGED','Damaged','Damaged',NULL,''),(47,'LOST','1','Lost',NULL,''),(48,'SUGGEST','OP','Out of print','No longer available, out of print','');
/*!40000 ALTER TABLE `authorised_values` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-12-16 23:27:42
