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
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `categories` (
  `categorycode` varchar(10) NOT NULL default '',
  `description` mediumtext,
  `enrolmentperiod` smallint(6) default NULL,
  `upperagelimit` smallint(6) default NULL,
  `dateofbirthrequired` tinyint(1) default NULL,
  `finetype` varchar(30) default NULL,
  `bulk` tinyint(1) default NULL,
  `enrolmentfee` decimal(28,6) default NULL,
  `overduenoticerequired` tinyint(1) default NULL,
  `issuelimit` smallint(6) default NULL,
  `reservefee` decimal(28,6) default NULL,
  `category_type` varchar(1) NOT NULL default 'A',
  PRIMARY KEY  (`categorycode`),
  UNIQUE KEY `categorycode` (`categorycode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `categories`
--

LOCK TABLES `categories` WRITE;
/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
INSERT INTO `categories` VALUES ('A','Adult',360,120,16,NULL,NULL,'0.000000',1,NULL,'1.000000','A'),('ADMIN','Mending etc',0,0,0,NULL,NULL,'0.000000',0,NULL,'0.000000','X'),('B','Blind',360,120,16,NULL,NULL,'0.000000',1,NULL,'0.000000','A'),('C','Child',192,16,0,NULL,NULL,'0.000000',1,NULL,'0.000000','C'),('D','Deaf',360,120,0,NULL,NULL,'0.000000',1,NULL,'1.000000','A'),('E','Senior Citizen',360,120,65,NULL,NULL,'0.000000',1,NULL,'1.000000','A'),('H','Housebound',360,120,16,NULL,NULL,'0.000000',0,NULL,'0.000000','A'),('I','Institution',360,0,0,NULL,NULL,'0.000000',0,NULL,'0.000000','I'),('L','Library',360,0,0,NULL,NULL,'0.000000',1,NULL,'0.000000','I'),('M','Minor',192,16,5,NULL,NULL,'0.000000',1,NULL,'0.000000','C'),('S','Subscribing Adult',12,120,16,NULL,NULL,'25.000000',1,NULL,'1.000000','A'),('W','Worker',360,75,15,NULL,NULL,'0.000000',0,NULL,'0.000000','S');
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;
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
