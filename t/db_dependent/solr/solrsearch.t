#!/usr/bin/perl

use utf8;
use Modern::Perl;
use Test::More;
use C4::Search;

use KohaTest::Search::SolrSearch;

#To launch this test, you can truncate some tables and populate db with these 3 lines
# INSERT INTO `branches` (`branchcode`,`branchname`) VALUES ('VITRE','Vitré');
#KohaTest::Search::SolrSearch::add_biblio_from_file('set/lot_notices_test.mrc');

#plan tests => 1;
plan 'no_plan';

#Search settings
my $query = '*:*';
my $got;
my $expected;

#Test base settings

$got = C4::Search::SimpleSearch($query);
ok (defined scalar(@{$got->{items}})
    , "search returns result(s)"
);

$got = C4::Search::SimpleSearch("str_ccode:\"TIRE\"");
$expected = 1;
is ($got->{pager}->{total_entries}
    , $expected
    , "notice with ccode of type 'article' is found $expected time"
);

#utf-8 tests

$query = "桜";
$got = C4::Search::SimpleSearch($query);
$expected = 0;
is ($got->{pager}->{total_entries}
    ,  $expected
    , "$query is found $expected time"
);

$query = "体";
$got = C4::Search::SimpleSearch($query);
$expected = 1;
is ($got->{pager}->{total_entries}
    , $expected
    , "$query is found $expected time"
);

$query = "田";
$got = C4::Search::SimpleSearch($query);
$expected = 1;
is ($got->{pager}->{total_entries}
    , $expected
    , "$query is found $expected time"
);

#Controlfields

$query="str_biblionumber:113581033";
$got = C4::Search::SimpleSearch($query);
$expected = 1;
is ($got->{pager}->{total_entries}
    , $expected
    , "query=$query => is found $expected time"
);
$expected = "113581033";
is ($got->{items}->[0]->{values}->{recordid}
    , $expected 
    , "query=$query => good biblionumber found"
);

$got = C4::Search::SimpleSearch("*:*", {str_biblionumber => "1135*"});
$expected = 1;
is ($got->{pager}->{total_entries}
    , $expected
    , "query=*:* and filters => biblionumber is found $expected time"
);
$expected = "113581033";
is ($got->{items}->[0]->{values}->{recordid}
    , $expected
    , "query=*:* and filters => good biblionumber:$expected found"
);

$query="str_biblionumber:1135*";
$got = C4::Search::SimpleSearch($query);
$expected = 1;
is ($got->{pager}->{total_entries}
    ,  $expected
    , "query=$query => is found $expected time"
);
$expected = "113581033";
is ($got->{items}->[0]->{values}->{recordid}
    , $expected
    , "query=$query  => good biblionumber found"
);

#Dates - not implemented yet

$query = "date_entereddate:2009";
#$got = C4::Search::SimpleSearch($query);
#ok (got);

$query = "date_entereddate:201007";
#$got = C4::Search::SimpleSearch($query);
#ok ($got);

$query = "date_entereddate:200907-201001";
#$got = C4::Search::SimpleSearch($query);
#ok ($got);

$query = "str_pubdate:1995";
$got = C4::Search::SimpleSearch($query);
ok ($got);

$query = "str_entereddate:31/08/2010";
$got = C4::Search::SimpleSearch($query);
ok ($got);

$query = 'date_acqdate:"2010-08-31T00:00:00Z"';
$got = C4::Search::SimpleSearch($query);
ok ($got);

#warn Data::Dumper::Dumper($got);
