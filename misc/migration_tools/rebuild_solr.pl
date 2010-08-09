#!/usr/bin/perl

use strict;

use C4::Context;
use C4::Biblio;
use C4::Search;
use Data::Dumper;
use Data::SearchEngine::Query;
use Data::SearchEngine::Item;
use Data::SearchEngine::Solr;

my $solr_url = "http://descartes.biblibre.com:8180/solr/";

$|=1; # flushes output

my $dbh = C4::Context->dbh;
$dbh->do('SET NAMES UTF8;');
my $sth = $dbh->prepare("SELECT
  biblionumber,
  author,
  title,
  biblio.notes,
  abstract,
  itemtype,
  isbn,
  issn,
  collectiontitle,
  collectionissn,
  collectionvolume
FROM biblio 
  LEFT JOIN biblioitems USING (biblionumber) 
GROUP BY biblionumber
ORDER BY biblionumber 
LIMIT 10
");

my $itemsth = $dbh->prepare("
  SELECT * FROM items WHERE biblionumber = ?
");

$sth->execute();

my $solr = Data::SearchEngine::Solr->new(
  url => $solr_url,
  options => {autocommit => 1, }
);

my @indexloop = C4::Search::GetIndexes;

while ( my $biblio = $sth->fetchrow_hashref ) {
    my $record = Data::SearchEngine::Item->new( id => $biblio->{biblionumber}, score => 1);
    my $allfields;
    for ( qw/title author/ ){
        $record->set_value( $_ , $biblio->{$_});
        $allfields .= $biblio->{$_};
    }
    $record->set_value( 'allfields', $allfields);

    $itemsth->execute($biblio->{biblionumber});
    my @holdingbranches;
    my @homebranches;
    while ( my $item = $itemsth->fetchrow_hashref ) {
      push @holdingbranches, $item->{holdingbranch};
      push @homebranches, $item->{homebranch};
    }
    $record->set_value( 'holdingbranch',  \@holdingbranches );
    $record->set_value( 'homebranch',  \@homebranches );
    
    for my $index ( @indexloop ) {
        my { 'field' => $field, 'subfield' => $subfield } = GetSubfieldsForIndex($index);
    }

    if($solr->add( [ $record ] )){
        print $biblio->{title}."\n";
    }else{
        print "!";
    }
}

$sth->finish;

