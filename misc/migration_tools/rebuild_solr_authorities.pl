#!/usr/bin/perl

use strict;
use warnings;
use C4::Context;
use C4::Biblio;
use C4::Search;
use Data::Dumper;
use Getopt::Long;

$|=1; # flushes output

my ( $reset, $number );
GetOptions(
    'r'   => \$reset,
    'n:i' => \$number,
);

if ( $reset ) {
    my $sc = C4::Search::GetSolrConnection;
    $sc->remove( 'recordtype:authority' );
}

my $dbh = C4::Context->dbh;
$dbh->do('SET NAMES UTF8;');
my $sth = $dbh->prepare("SELECT authid
    FROM auth_header
    ORDER BY authid
    LIMIT $number
");

$sth->execute();

IndexRecord("authority", [ map { $_->[0] } @{ $sth->fetchall_arrayref } ] );

$sth->finish;

