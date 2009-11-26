#! /usr/bin/perl
use strict;
use warnings;
use C4::Context;
my $dbh=C4::Context->dbh;

$dbh->do("ALTER TABLE `issuingrules` ADD COLUMN `holdspickupdelay` int(11) DEFAULT NULL;");

# FIXME Migrate datas

print "Upgrade done (Moved hold rules to issuing rules)\n";
