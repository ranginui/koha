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
    my $sc = C4::Search::GetSolrRessource;
    $sc->remove( 'recordtype:authority' );
}

my $dbh = C4::Context->dbh;
$dbh->do('SET NAMES UTF8;');
my $sth = $dbh->prepare("
SELECT authid
FROM auth_header
ORDER BY authid
LIMIT $number
");

$sth->execute();

my $authorities = $sth->fetchall_arrayref;

my @records;
for (@$authorities){
   push @records, @$_;
}

IndexRecord("authority", \@records );

$sth->finish;

