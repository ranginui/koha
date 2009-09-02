#!/usr/bin/perl -w

use strict;

use C4::Context;
use MARC::Record;
use MARC::File::XML;

my $dbh = C4::Context->dbh();

my $sql = "SELECT more_subfields_xml,itemnumber FROM items";
my $sth = $dbh->prepare($sql);

$sth->execute();
my $sth2 =
  $dbh->prepare("UPDATE items SET itemcallnumber = ? WHERE itemnumber = ?");
while ( my $data = $sth->fetchrow_hashref() ) {

    #    my $record = MARC::Record->new_from_xml( $xml, $encoding, $format );
    if ( $data->{'more_subfields_xml'} ) {
        my $record =
          MARC::Record->new_from_xml( $data->{'more_subfields_xml'} );
        my $itemcallnumber = $record->subfield( '999', "o" );
        $sth2->execute( $itemcallnumber, $data->{'itemnumber'} );
        print "$itemcallnumber\t$data->{itemnumber}\n";
    }
}
