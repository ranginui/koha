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
-- Table structure for table `itemtypes`
--

DROP TABLE IF EXISTS `itemtypes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `itemtypes` (
  `itemtype` varchar(10) NOT NULL default '',
  `description` mediumtext,
  `rentalcharge` double(16,4) default NULL,
  `notforloan` smallint(6) default NULL,
  `imageurl` varchar(200) default NULL,
  `summary` text,
  PRIMARY KEY  (`itemtype`),
  UNIQUE KEY `itemtype` (`itemtype`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `itemtypes`
--

LOCK TABLES `itemtypes` WRITE;
/*!40000 ALTER TABLE `itemtypes` DISABLE KEYS */;
INSERT INTO `itemtypes` VALUES ('BF','Free Fiction',0.0000,0,'bridge/book.gif',''),('BFR','Paperback Romance',0.0000,0,'bridge/book.gif',''),('BH','Local History',0.0000,0,'bridge/book.gif',''),('BHR','Local History Reference',0.0000,1,'bridge/book.gif',''),('BJBP','Babies Boardbooks',0.0000,0,'bridge/book.gif',''),('BJCF','Easy Children\'s Fiction',0.0000,0,'bridge/book.gif',''),('BJCN','Easy Children\'s Nonfiction',0.0000,0,'bridge/book.gif',''),('BJCP','First Readers',0.0000,0,'bridge/book.gif',''),('BJF','Children\'s Fiction',0.0000,0,'bridge/book.gif',''),('BJK','First Chapter Books',0.0000,0,'bridge/book.gif',''),('BJM','Children\'s Books in Maori',0.0000,0,'bridge/book.gif',''),('BJN','Children\'s Nonfiction',0.0000,0,'bridge/book.gif',''),('BJP','Picturebook',0.0000,0,'bridge/book.gif',''),('BJRN','Children\'s Reference',0.0000,1,'bridge/book.gif',''),('BJZP','NZ Picturebooks',0.0000,0,'bridge/book.gif',''),('BLF','Largeprint Fiction',0.0000,0,'bridge/book.gif',''),('BLN','Largeprint Nonfiction',0.0000,0,'bridge/book.gif',''),('BM','Te Ao Maori',0.0000,0,'bridge/book.gif',''),('BN','General Nonfiction',0.0000,0,'bridge/book.gif',''),('BPF','Rental Fiction',2.0000,0,'bridge/book.gif',''),('BPN','Rental Nonfiction',3.0000,0,'bridge/book.gif',''),('BR','Reference',0.0000,1,'bridge/book.gif',''),('BRM','Reference Te Ao Maori',0.0000,1,'bridge/book.gif',''),('BSF','Older Fiction',0.0000,0,'bridge/book.gif',''),('BSN','Older Nonfiction',0.0000,0,'bridge/book.gif',''),('BT','Taonga Cabinet',0.0000,1,'bridge/book.gif',''),('BYF','Teen Fiction',0.0000,0,'bridge/book.gif',''),('BYN','Teen Nonfiction',0.0000,0,'bridge/book.gif',''),('BYP','Teen Picturebooks',0.0000,0,'bridge/book.gif',''),('C','Audio Book on CD',0.0000,0,'bridge/cd_music.gif',''),('CAS','Cassette Tape',0.0000,0,'bridge/tape_music.gif',''),('CASM','Maori Cassette',0.0000,0,'bridge/tape_music.gif',''),('CCP','Co-op Rental Audio Book on CD',5.0000,0,'bridge/cd_music.gif',''),('CD','CD for Book',0.0000,0,'bridge/cd_music.gif',''),('CDM','CD for a Magazine',0.0000,0,'bridge/cd_music.gif',''),('CDPM','CD for a Rental Magazine',0.0000,0,'bridge/cd_music.gif',''),('CJ','Children\'s Audio Book on CD',0.0000,0,'bridge/cd_music.gif',''),('CNJ','WN Children\'s Audio Book on CD',0.0000,0,'bridge/cd_music.gif',''),('CNP','WN Rental Audio Book on CD',5.0000,0,'bridge/cd_music.gif',''),('CP','Rental Audio Book on CD',5.0000,0,'bridge/cd_music.gif',''),('D','Free DVD',0.0000,0,'bridge/dvd.gif',''),('DEL','Items to be deleted post conversion',0.0000,0,NULL,''),('DJ','Children\'s DVD',0.0000,0,'bridge/dvd.gif',''),('DJP','Childen\'s Rental DVD',2.5000,0,'bridge/dvd.gif',''),('DM','Maori DVD',0.0000,0,'bridge/dvd.gif',''),('DP','Rental DVD',2.5000,0,'bridge/dvd.gif',''),('DY','Teen DVD',0.0000,0,'bridge/dvd.gif',''),('DYP','Rental Teen DVD',2.5000,0,'bridge/dvd.gif',''),('F','File Packet',0.0000,0,'bridge/archive.gif',''),('FJ','Children\'s File Packet',0.0000,0,'bridge/archive.gif',''),('GWB','Get Well Bag',0.0000,0,'bridge/kit.gif',''),('JIG','Jigsaws',0.0000,0,'bridge/kit.gif',''),('M','Magazine',0.0000,0,'bridge/periodical.gif',''),('MAP','Maps',0.0000,1,'bridge/map.gif',''),('MJ','Children\'s Magazine',0.0000,0,'bridge/periodical.gif',''),('MP','Rental Magazine',1.0000,0,'bridge/periodical.gif',''),('MR','Rental Magazine',1.0000,0,'bridge/periodical.gif',''),('MY','Teen Magazines',0.0000,0,'bridge/periodical.gif',''),('MYP','Rental Teen Magazine',1.0000,0,'bridge/periodical.gif',''),('ODD','Odd items during conversion',0.0000,0,NULL,''),('PB','Pamphlets',0.0000,0,'bridge/book.gif',''),('PHOT','Photographs',0.0000,1,'bridge/2d_art.gif',''),('T','Audio Book on Tape',0.0000,0,'bridge/tape_music.gif',''),('TJ','Children\'s Audio Book on Tape',0.0000,0,'bridge/tape_music.gif',''),('TNJ','WN Children\'s Audio Book on tape',0.0000,0,'bridge/tape_music.gif',''),('TNP','WN Rental Audio Book on tape',5.0000,0,'bridge/tape_music.gif',''),('TP','Rental Audio Book on Tape',5.0000,0,'bridge/tape_music.gif',''),('V','Free Video',0.0000,0,'bridge/vhs.gif',''),('VJ','Children\'s Video',0.0000,0,'bridge/vhs.gif',''),('VM','Maori Video',0.0000,0,'bridge/vhs.gif',''),('VY','Teen Video',0.0000,0,'bridge/vhs.gif','');
/*!40000 ALTER TABLE `itemtypes` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-12-17  0:39:45
