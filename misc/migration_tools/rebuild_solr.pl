#!/usr/bin/perl

use strict;
use warnings;
use C4::Context;
use C4::Search;
use Data::Dumper;
use Getopt::Long;

$|=1; # flushes output

my ( $reset, $number, $recordtype );
GetOptions(
    'r'   => \$reset,
    'n:i' => \$number,
    't:s' => \$recordtype,
);

if ( $reset ) {
    my $sc = C4::Search::GetSolrConnection;
    $sc->remove( "recordtype:$recordtype" );
}

my $dbh = C4::Context->dbh;
   $dbh->do('SET NAMES UTF8;');

my $query;
if ( $recordtype eq 'biblio' ) {
  $query = "SELECT biblionumber FROM biblio ORDER BY biblionumber";
} elsif ( $recordtype eq 'authority' ) {
  $query = "SELECT authid FROM auth_header ORDER BY authid";
}
$query .= " LIMIT $number" if $number;

my $sth = $dbh->prepare( $query );
   $sth->execute();

IndexRecord($recordtype, [ map { $_->[0] } @{ $sth->fetchall_arrayref } ] );

$sth->finish;
