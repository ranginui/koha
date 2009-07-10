#! /usr/bin/perl
use strict;
use warnings;
use C4::Context;
my $dbh=C4::Context->dbh;

$dbh->do("INSERT INTO `systempreferences` ( `variable` , `value` , `options` , `explanation` , `type` ) VALUES ( 'AllowNotForLoanOverride', '0', '', 'If ON, Koha will allow the librarian to loan a not for loan item.', 'YesNo')");
print "Upgrade done (added AllowNotForLoanOverride system preference)\n";
