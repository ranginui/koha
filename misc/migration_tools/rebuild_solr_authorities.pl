#!/usr/bin/perl

use strict;
use warnings;
use C4::Context;
use C4::Search;
use Data::Dumper;
use Getopt::Long;

$|=1; # flushes output

my $recordtype = 'authority';

my ( $reset, $number );
GetOptions(
    'r'   => \$reset,
    'n:i' => \$number,
);

if ( $reset ) {
    my $sc = C4::Search::GetSolrConnection;
    $sc->remove( "recordtype:$recordtype" );
}

my $dbh = C4::Context->dbh;
   $dbh->do('SET NAMES UTF8;');

my $query  = "SELECT authid FROM auth_header ORDER BY authid";
   $query .= " LIMIT $number" if $number;

my $sth = $dbh->prepare( $query );
   $sth->execute();

IndexRecord($recordtype, [ map { $_->[0] } @{ $sth->fetchall_arrayref } ] );

$sth->finish;

