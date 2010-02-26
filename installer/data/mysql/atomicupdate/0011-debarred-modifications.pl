#! /usr/bin/perl
use strict;
use warnings;
use C4::Context;
my $dbh=C4::Context->dbh;
$dbh->do("ALTER TABLE borrowers MODIFY debarred DATE DEFAULT NULL;");
$dbh->do("ALTER TABLE borrowers ADD COLUMN debarredcomment VARCHAR(255) DEFAULT NULL AFTER debarred;");
print "Upgrade done (Change fields for debar)\n";
