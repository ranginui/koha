#!/usr/bin/perl
use C4::Context;
C4::Context->dbh->do(qq{
    	ALTER TABLE `deleteditems` ADD `statisticvalue` varchar(80) DEFAULT NULL
}
);
