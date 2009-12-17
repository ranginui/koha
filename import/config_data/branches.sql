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
-- Table structure for table `branches`
--

DROP TABLE IF EXISTS `branches`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `branches` (
  `branchcode` varchar(10) NOT NULL default '',
  `branchname` mediumtext NOT NULL,
  `branchaddress1` mediumtext,
  `branchaddress2` mediumtext,
  `branchaddress3` mediumtext,
  `branchzip` varchar(25) default NULL,
  `branchcity` mediumtext,
  `branchcountry` text,
  `branchphone` mediumtext,
  `branchfax` mediumtext,
  `branchemail` mediumtext,
  `branchurl` mediumtext,
  `issuing` tinyint(4) default NULL,
  `branchip` varchar(15) default NULL,
  `branchprinter` varchar(100) default NULL,
  `branchnotes` mediumtext,
  UNIQUE KEY `branchcode` (`branchcode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `branches`
--

LOCK TABLES `branches` WRITE;
/*!40000 ALTER TABLE `branches` DISABLE KEYS */;
INSERT INTO `branches` VALUES ('C','Circulating','','','',NULL,NULL,NULL,'','','',NULL,NULL,'',NULL,NULL),('F','Foxton','','','','','','','','','','',NULL,'',NULL,''),('FM','Foxton Mending','','','','','','','','','','',NULL,'',NULL,''),('FP','Foxton Pemanent','','','','','','','','','','',NULL,'',NULL,''),('FS','Foxton Stack','','','','','','','','','','',NULL,'',NULL,''),('H','HDC Stack','','','',NULL,NULL,NULL,'','','',NULL,NULL,'',NULL,NULL),('L','Levin','','','','','','','','','','',NULL,'',NULL,''),('LP','Levin Permanent','','','','','','','','','','',NULL,'',NULL,''),('M','Mending','','','','','','','','','','',NULL,'',NULL,''),('P','Processing','','','','','','','','','','',NULL,'',NULL,''),('S','Shannon','','','',NULL,NULL,NULL,'','','',NULL,NULL,'',NULL,NULL),('SP','Shannon Permanent','','','',NULL,NULL,NULL,'','','',NULL,NULL,'',NULL,NULL),('T','Tokomaru','','','',NULL,NULL,NULL,'','','',NULL,NULL,'',NULL,NULL);
/*!40000 ALTER TABLE `branches` ENABLE KEYS */;
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
