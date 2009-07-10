#! /usr/bin/perl
use strict;
use warnings;
use C4::Context;
my $dbh=C4::Context->dbh;

$dbh->do(INSERT INTO `systempreferences` (variable,value,explanation,options,type) VALUES('opacSerialDefaultTab', 'serialcollection', 'Define the default tab for serials in OPAC. If set to holdings when there are no items, then serial collections are still displayed by default.', 'holdings|serialcollection', 'Choice')");
print "Upgrade done (added default tab for serial collections system preference)\n";
