#! /usr/bin/perl
use strict;
use warnings;
use C4::Context;
my $dbh=C4::Context->dbh;

$dbh->do("ALTER TABLE `subscription` ADD COLUMN `graceperiod` INT(11) NOT NULL default '0';");
print "Upgrade done (Adding a field in issuingrules table)\n";

