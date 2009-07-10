#! /usr/bin/perl
use strict;
use warnings;
use C4::Context;
my $dbh=C4::Context->dbh;
$dbh->do("ALTER TABLE issuingrules ADD COLUMN `finedays` int(11) default NULL AFTER `fine`");
print "Upgrade done (Adding a finedays field in issuingrules table)\n";
