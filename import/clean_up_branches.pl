#!/usr/bin/perl -w

# script to tidy up branches

use strict;

use C4::Context;
use C4::Items;

my $dbh = C4::Context->dbh();

my $sql = "SELECT biblionumber,itemnumber FROM items";
my $sth = $dbh->prepare($sql);

$sth->execute();
while ( my $data = $sth->fetchrow_hashref() ) {
#    Issue items
#    FM issue to H00000248 
    # H issue to H00000022 
    # M issue to H00042816
    # P issue to H00000066 
    
    if (
#    ModItem({ column => $newvalue }, $biblionumber, $itemnumber[, $original_item_marc]);
}
