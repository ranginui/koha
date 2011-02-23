#! /usr/bin/perl
use Modern::Perl;
use KohaTest::Search::SolrSearch;

# If you execute me, you delete all index data !
# You will rebuild index

my $notices_file = 'set/lot_notices_test.mrc';

my ($nb_bibs, $batch_number) = KohaTest::Search::SolrSearch::add_biblio_from_file($notices_file);

my $dbh = C4::Context->dbh;
my $sth = $dbh->prepare("SELECT count(biblionumber) FROM biblioitems");
$sth->execute;
my $max = $sth->fetchrow;

my $begin_at = $max - $nb_bibs;

warn "Notices are added. You must call misc/migration_tools/rebuild_solr.pl -r -t biblio -n '$begin_at,$nb_bibs'\n";
warn "You must call 02-post-client.t after test with argument batch_number=$batch_number and reindex correctly\n";

