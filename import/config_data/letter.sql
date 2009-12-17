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
-- Table structure for table `letter`
--

DROP TABLE IF EXISTS `letter`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `letter` (
  `module` varchar(20) NOT NULL default '',
  `code` varchar(20) NOT NULL default '',
  `name` varchar(100) NOT NULL default '',
  `title` varchar(200) NOT NULL default '',
  `content` text,
  PRIMARY KEY  (`module`,`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `letter`
--

LOCK TABLES `letter` WRITE;
/*!40000 ALTER TABLE `letter` DISABLE KEYS */;
INSERT INTO `letter` VALUES ('circulation','CHECKIN','Item Check-in','Check-ins','The following items have been checked in:\r\n----\r\n<<biblio.title>>\r\n----\r\nThank you.'),('circulation','CHECKOUT','Item Checkout','Checkouts','The following items have been checked out:\r\n----\r\n<<biblio.title>>\r\n----\r\nThank you for visiting <<branches.branchname>>.'),('circulation','INV','Invoice for Lost Items','Invoice for Overdue Library Items','<<borrowers.firstname>> <<borrowers.surname>>\r\n<<borrowers.address>>\r\n<<borrowers.address2>>\r\n<<borrowers.city>> <<borrowers.zipcode>>\r\n\r\n\r\nThis is an invoice for the replacement cost of the items you borrowed from the library and have not returned:\r\n\r\n<<biblioitems.itemtype>>  <<biblio.title>> by <<biblio.author>>\r\n\r\nCould you please either:\r\n\r\n1.	Return all the items and make an arrangement for the payment of the fines; or\r\n2.	If you can’t return the items, pay the invoice total of «Total».\r\n\r\nIf you do neither of these things in the next 7 days, then this account will be handed over to a debt collection agency. This may affect your credit rating.\r\n\r\n\r\n\r\nPlease settle this matter immediately.\r\n\r\nLevin Library phone 368-1953\r\n'),('circulation','ODUE','Overdue Notice','Overdue Library Items','<<borrowers.firstname>> <<borrowers.surname>>\r\n<<borrowers.address>>\r\n<<borrowers.address2>>\r\n<<borrowers.city>> <<borrowers.zipcode>>\r\n\r\n\r\nAccording to the library\'s records, you or your children have the following overdue items borrowed from a Horowhenua Library and not yet returned: \r\n\r\n<<biblioitems.itemtype>>  <<biblio.title>> by <<biblio.author>>\r\n\r\nPlease return them immediately to avoid increasing fines. \r\n\r\nSincerely,\r\n\r\n\r\nLibrary Staff.\r\n'),('circulation','REMD','Reminder Notice of Overdues','Library Items due back today','<<borrowers.firstname>> <<borrowers.surname>>\r\n<<borrowers.address>>\r\n<<borrowers.address2>>\r\n<<borrowers.city>> <<borrowers.zipcode>>\r\n\r\n\r\nDear <<borrowers.firstname>>,\r\n\r\nAccording to our records, you or your children have items which are due back at the library. To avoid paying overdue fines you may renew the items by phoning Levin Library on 3681953, or online at the library website: www.library.org.nz  if you have selected a password for your account.\r\n\r\nItems due back today:\r\n\r\n<<biblioitems.itemtype>>  <<biblio.title>> by <<biblio.author>>\r\n\r\nThank you.'),('reserves','HOLD','Hold Available for Pickup','Hold Available for Pickup at <<branches.branchname>>','Dear <<borrowers.firstname>> <<borrowers.surname>>,\r\n\r\nYou have a hold available for pickup as of <<reserves.waitingdate>>:\r\n\r\nTitle: <<biblio.title>>\r\nAuthor: <<biblio.author>>\r\nCopy: <<items.copynumber>>\r\nLocation: <<branches.branchname>>\r\n<<branches.branchaddress1>>\r\n<<branches.branchaddress2>>\r\n<<branches.branchaddress3>>');
/*!40000 ALTER TABLE `letter` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-12-17  0:04:35
