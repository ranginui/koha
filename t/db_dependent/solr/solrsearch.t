#!/usr/bin/perl

use utf8;
use Test::More;
use C4::Search;

#export PERL5LIB=<src_directory>:<src_directory>/t/lib
use KohaTest::Search::SolrSearch;

#To launch this test, you can truncate some tables and populate db with these 3 lines
#KohaTest::Search::SolrSearch::add_biblio_from_file ('split0000000');
#KohaTest::Search::SolrSearch::add_biblio_from_file('bib-8.utf8');
#KohaTest::Search::SolrSearch::index_all_datas;

#plan tests => 1;
plan 'no_plan';

#Search settings
my $query = '*:*';
# $solr_url = C4::Context->preference("SolrAPI");

#Test base settings
my $got = C4::Search::SimpleSearch($query, $filters, $page, $max_results, $sort);
ok (defined scalar(@{$got->{items}}), "search returns result(s)");

#utf-8 tests
$got = C4::Search::SimpleSearch("桜", $filters, $page, $max_results, $sort);
is ($got->{pager}->{total_entries},  0, "桜 is found 0 time");
$got = C4::Search::SimpleSearch("体", $filters, $page, $max_results, $sort);
is ($got->{pager}->{total_entries},  1, "体 is found 1 time");
$got = C4::Search::SimpleSearch("田", $filters, $page, $max_results, $sort);
is ($got->{pager}->{total_entries},  1, "田 is found 1 time");

#Controlfields
$got = C4::Search::SimpleSearch("str_biblionumber:113581033");
is ($got->{pager}->{total_entries},  1, "query=str_biblionumber:113581033 => biblionumber:113581033 is found 1 time");
is ($got->{items}->[0]->{values}->{recordid}, "113581033" , "query=str_biblionumber:113581033 => good biblionumber:113581033 found");
$got = C4::Search::SimpleSearch("*:*", {str_biblionumber => "1135"});
is ($got->{pager}->{total_entries},  1, "query=*:* and filters => biblionumber:113581033 is found 1 time");
is ($got->{items}->[0]->{values}->{recordid}, "113581033" , "query=*:* and filters => good biblionumber:113581033 found");
$got = C4::Search::SimpleSearch("str_biblionumber:1135*");
is ($got->{pager}->{total_entries},  1, "query=str_biblionumber:1135* => biblionumber:1135* is found 1 time");
is ($got->{items}->[0]->{values}->{recordid}, "113581033" , "query=str_biblionumber:1135*  => good biblionumber:113581033 found");

#Dates - not implemented yet > should return result
$got = C4::Search::SimpleSearch("date_entereddate:2009");
ok (got);
$got = C4::Search::SimpleSearch("date_entereddate:201007");
ok ($got);
$got = C4::Search::SimpleSearch("date_entereddate:200907-201001");
ok ($got);

#warn Data::Dumper::Dumper($got);
#warn Data::Dumper::Dumper($got->{items}->[0]->{values}->{recordid});
