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
-- Table structure for table `issuingrules`
--

DROP TABLE IF EXISTS `issuingrules`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `issuingrules` (
  `categorycode` varchar(10) NOT NULL default '',
  `itemtype` varchar(10) NOT NULL default '',
  `restrictedtype` tinyint(1) default NULL,
  `rentaldiscount` decimal(28,6) default NULL,
  `reservecharge` decimal(28,6) default NULL,
  `fine` decimal(28,6) default NULL,
  `firstremind` int(11) default NULL,
  `chargeperiod` int(11) default NULL,
  `accountsent` int(11) default NULL,
  `chargename` varchar(100) default NULL,
  `maxissueqty` int(4) default NULL,
  `issuelength` int(4) default NULL,
  `renewalsallowed` smallint(6) NOT NULL default '0',
  `reservesallowed` smallint(6) NOT NULL default '0',
  `branchcode` varchar(10) NOT NULL default '',
  PRIMARY KEY  (`branchcode`,`categorycode`,`itemtype`),
  KEY `categorycode` (`categorycode`),
  KEY `itemtype` (`itemtype`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `issuingrules`
--

LOCK TABLES `issuingrules` WRITE;
/*!40000 ALTER TABLE `issuingrules` DISABLE KEYS */;
INSERT INTO `issuingrules` VALUES ('*','*',NULL,NULL,NULL,'1.000000',7,7,NULL,NULL,NULL,21,0,50,'*'),('*','BPF',NULL,NULL,NULL,'1.000000',7,7,NULL,NULL,NULL,14,1,50,'*'),('*','BPN',NULL,NULL,NULL,'1.500000',4,3,NULL,NULL,NULL,7,0,50,'*'),('*','CCP',NULL,NULL,NULL,'2.500000',4,3,NULL,NULL,NULL,21,1,50,'*'),('*','CDM',NULL,NULL,NULL,'1.000000',7,7,NULL,NULL,NULL,14,1,50,'*'),('*','CDPM',NULL,NULL,NULL,'0.500000',4,3,NULL,NULL,NULL,7,1,50,'*'),('*','CNP',NULL,NULL,NULL,'2.500000',4,3,NULL,NULL,NULL,21,1,50,'*'),('*','CP',NULL,NULL,NULL,'2.500000',4,3,NULL,NULL,NULL,21,1,50,'*'),('*','DJP',NULL,NULL,NULL,'1.300000',4,3,NULL,NULL,NULL,7,1,50,'*'),('*','DP',NULL,NULL,NULL,'1.300000',4,3,NULL,NULL,NULL,7,1,50,'*'),('*','DYP',NULL,NULL,NULL,'1.300000',4,3,NULL,NULL,NULL,7,1,50,'*'),('*','M',NULL,NULL,NULL,'1.000000',7,7,NULL,NULL,NULL,14,1,50,'*'),('*','MJ',NULL,NULL,NULL,'1.000000',7,7,NULL,NULL,NULL,14,1,50,'*'),('*','MP',NULL,NULL,NULL,'0.500000',4,3,NULL,NULL,NULL,7,1,50,'*'),('*','MY',NULL,NULL,NULL,'1.000000',7,7,NULL,NULL,NULL,14,1,50,'*'),('*','MYP',NULL,NULL,NULL,'1.000000',4,3,NULL,NULL,NULL,7,1,50,'*'),('*','TNP',NULL,NULL,NULL,'2.500000',4,3,NULL,NULL,NULL,21,1,50,'*'),('*','TP',NULL,NULL,NULL,'2.500000',4,3,NULL,NULL,NULL,21,1,50,'*'),('ADMIN','*',NULL,NULL,NULL,'0.000000',0,0,NULL,NULL,NULL,90,0,50,'*'),('B','*',NULL,NULL,NULL,'0.000000',0,0,NULL,NULL,NULL,21,0,50,'*'),('H','*',NULL,NULL,NULL,'0.000000',0,0,NULL,NULL,NULL,21,0,50,'*'),('I','*',NULL,NULL,NULL,'0.000000',0,0,NULL,NULL,NULL,21,0,50,'*'),('L','*',NULL,NULL,NULL,'0.000000',0,0,NULL,NULL,NULL,42,0,50,'*'),('W','*',NULL,NULL,NULL,'0.000000',0,0,NULL,NULL,NULL,21,0,50,'*');
/*!40000 ALTER TABLE `issuingrules` ENABLE KEYS */;
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
