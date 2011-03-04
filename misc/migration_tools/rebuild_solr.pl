#!/usr/bin/perl

use strict;
use warnings;
use C4::Context;
use C4::Search;
use Data::Dumper;
use Getopt::Long;
use LWP::Simple;
use XML::Simple;

$|=1; # flushes output

if ( C4::Context->preference("SearchEngine") ne 'Solr' ) {
    warn "System preference 'SearchEngine' not equal 'Solr'.";
    warn "We can not indexing";
    exit(1);
}

#Setup

my ( $reset, $number, $recordtype, $biblionumber, $want_help );
GetOptions(
    'r'   => \$reset,
    'n:s' => \$number,
    't:s' => \$recordtype,
    'w' => \$biblionumber,
    'h|help' => \$want_help,
);
my $debug = C4::Context->preference("DebugLevel");
my $solrurl = C4::Context->preference("SolrAPI");

#Script

&PrintHelp if ($want_help);
if ($reset){
  if ($recordtype){
      &ResetIndex("recordtype:".$recordtype);
  } else {
      &ResetIndex("*:*");
  }
}


if (defined $biblionumber){
    &IndexBiblio($biblionumber);
} elsif  (defined $recordtype) {
    &IndexData;
}

#Functions

sub IndexBiblio {
    my ($biblionumber) = @_;
    IndexRecord($recordtype, [ $biblionumber ] );
}

sub IndexData {
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
}

sub ResetIndex {
    &ResetCommand;
    &CommitCommand;
    $debug eq '2' && &CountAllDocs eq 0 && warn  "Index cleaned!"
}

sub CommitCommand {
    my $commiturl = "/update?stream.body=%3Ccommit/%3E";
    my $urlreturns = get $solrurl.$commiturl;
}

sub ResetCommand {
    my ($query) = @_;
    my $deleteurl = "/update?stream.body=%3Cdelete%3E%3Cquery%3E".$query."%3C/query%3E%3C/delete%3E";
    my $urlreturns = get $solrurl.$deleteurl;
}

sub CountAllDocs {
    my $queryurl = "/select/?q=*:*";
    my $urlreturns = get $solrurl.$queryurl;
    my $xmlsimple = XML::Simple->new();
    my $data = $xmlsimple->XMLin($urlreturns);
    return $data->{result}->{numFound};
}

sub PrintHelp {
    print <<_USAGE_;
$0: reindex biblios and/or authorities in Solr.

Use this batch job to reindex all biblio or authority records in your Koha database.  This job is useful only if you are using Solr search engine.

Parameters:
    -t biblio               index bibliographic records

    -t authority            index authority records

    -r                      clear Solr index before adding records to index - use this option carefully!

    -n 100                  index 100 first records

    -n "100,2"              index 2 records after 100th (101 and 102)

    -w 101                  index biblio with biblionumber equals 101

    --help or -h            show this message.
_USAGE_
}
