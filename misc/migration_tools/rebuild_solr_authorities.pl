#!/usr/bin/perl

use strict;

use C4::Context;
use C4::Biblio;
use C4::Search;
use Data::Dumper;
use Data::SearchEngine::Query;
use Data::SearchEngine::Item;
use Data::SearchEngine::Solr;

my $solr_url = C4::Context->preference("SolrAPI");

$|=1; # flushes output

my $dbh = C4::Context->dbh;
$dbh->do('SET NAMES UTF8;');
my $sth = $dbh->prepare("SELECT
  authid
FROM auth_header
ORDER BY authid
");

$sth->execute();

my $solr = Data::SearchEngine::Solr->new(
      url => $solr_url,
      options => {autocommit => 1, }
   );

my $authorities = $sth->fetchall_arrayref;

my @records;
for (@$authorities){
   push @records, @$_;
}

IndexRecord("authority", \@records );

$sth->finish;

