#!/usr/bin/perl
use strict;
use warnings;
use C4::Context;
my $dbh=C4::Context->dbh;
$dbh->do(<<SUGGESTIONS);
ALTER TABLE `suggestions` ADD `collectiontitle` TEXT NULL AFTER `isbn` ,
ADD `itemtype` VARCHAR( 10 ) NULL AFTER `collectiontitle` ,
ADD `managedon` date  NULL AFTER `itemtype`,
ADD `acceptedby` int(11) NULL AFTER `managedon`,
ADD `acceptedon` date  NULL AFTER `acceptedby`,
ADD `createdon` date  NULL AFTER `acceptedon`,
ADD `branchcode` VARCHAR(10)  NULL AFTER `createdon`,
ADD `sort1` TEXT NULL AFTER `branchcode` ;
SUGGESTIONS
print "Add some fields to suggestions";
