#!/usr/bin/perl

use utf8;
use Modern::Perl;
use Test::More;

my $tests;
plan tests => $tests;

my $q;
my $indexes;
my $operands;
my $operators;
my $expected;
my $got;

BEGIN { $tests += 2 }
use_ok('C4::Search::Query');
is(C4::Context->preference("SearchEngine"), 'Solr', "Test search engine = Solr");

my $titleindex = C4::Search::Query::getIndexName("title");
my $authorindex = C4::Search::Query::getIndexName("author");
my $eanindex = C4::Search::Query::getIndexName("ean");

BEGIN { $tests += 8 } # 'Normal' search
@$operands[0] = "title:maudits"; # Solr indexes
@$indexes = ();
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "$titleindex:maudits";
is($got, $expected, "Test Solr indexes in 'normal' search");

@$operands[0] = "title:maudits"; # code indexes
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "$titleindex:maudits";
is($got, $expected, "Test Code indexes in 'normal' search");

@$operands[0] = "ti:maudits"; # zebra indexes
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "$titleindex:maudits";
is($got, $expected, "Test Zebra indexes in 'normal' search");

@$operands[0] = "*:*"; # all fields search
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "*:*";
is($got, $expected, "Test *:* in 'normal' search");

@$operands[0] = "title:maudits OR author:andre NOT title:crépuscule"; # long normal search
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "$titleindex:maudits OR $authorindex:andre NOT $titleindex:crépuscule";
is($got, $expected, "Test long 'normal' search");

@$operands[0] = "title:maudits and a or author:andre not title:crépuscule"; # test operators
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "$titleindex:maudits AND a OR $authorindex:andre NOT $titleindex:crépuscule";
is($got, $expected, "Test operators in 'normal' search");

$q = "title:maudits and a or author:andre not ean:blabla"; # test normal search
$got = C4::Search::Query->normalSearch($q);
$expected = "$titleindex:maudits AND a OR $authorindex:andre NOT $eanindex:blabla";
is($got, $expected, "Test 'normal' search");

$q = "Mathématiques Analyse L3 : Cours complet"; # escape colon
$got = C4::Search::Query->normalSearch($q);
$expected = "Mathématiques Analyse L3 \\: Cours complet";
is($got, $expected, "Test escape colon");

BEGIN { $tests += 8 } # Advanced search
@$operands = ("maudits"); # Solr indexes
@$indexes = ("title", "all_fields", "all_fields");
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "$titleindex:maudits";
is($got, $expected, "Test Solr indexes in advanced search");

@$operands = ("maudits"); # Zebra indexes
@$indexes = ("ti", "kw", "kw");
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "$titleindex:maudits";
is($got, $expected, "Test Solr indexes in advanced search");

@$operands = ("maudits"); # Code indexes
@$indexes = ("title", "all_fields", "kw");
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "$titleindex:maudits";
is($got, $expected, "Test Code indexes in advanced search");

@$operands = ("maudits", "a", "andre"); # More elements
@$indexes = ("title", "all_fields", "author");
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "$titleindex:maudits AND a AND $authorindex:andre";
is($got, $expected, "Test Zebra indexes in advanced search");

@$operands = ("maudits", "a", "andre", "Besson"); # With 'More options'
@$indexes = ("title", "all_fields", "author", "author");
@$operators = ("AND", "NOT", "OR");
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "$titleindex:maudits AND a NOT $authorindex:andre OR $authorindex:Besson";
is($got, $expected, "Test 'More options' in advanced search");

@$operands = ("crépuscule", "André"); # Accents
@$indexes = ("title", "author");
@$operators = ("AND");
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "$titleindex:crépuscule AND $authorindex:André";
is($got, $expected, "Test Accents in advanced search");

@$operands = ("maudits", "a", "andre"); # Bad indexes types
@$indexes = ("", undef, ());
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "maudits AND a AND andre";
is($got, $expected, "Test call with bad indexes types");

@$operands = ("Mathématiques Analyse L3 : Cours complet"); # escape colon
@$indexes = ();
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "Mathématiques Analyse L3 \\: Cours complet";
is($got, $expected, "Test escape colon");

BEGIN { $tests += 1 } # normal search with rpn query
@$indexes = ();
@$operators = ();
# NB: not supported by Z3950 server (rflag=x is replaced by rflag='x')
@$operands[0] = q{allrecords,alwaysMatches="" not harvestdate,alwaysMatches="" and (rflag=1 or rflag=2)};
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "[* TO * ] NOT date_harvestdate:[* TO * ] AND (int_rflag:1 OR int_rflag:2)";
is($got, $expected, "Test alwaysMatches modifier and allrecords index in 'normal' search");


BEGIN { $tests += 3 } # Test BuildIndexString (of many words in one operand string)
@$operands = ("le crépuscule des maudits");
@$indexes = ("title");
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "($titleindex:le AND $titleindex:crépuscule AND $titleindex:des AND $titleindex:maudits)";
is($got, $expected, "Test BuildIndexString");

@$operands = ("maudits crépuscule");
@$indexes = ("title");
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "($titleindex:maudits AND $titleindex:crépuscule)";
is($got, $expected, "Test BuildIndexString");

@$operands = ("les maudits", "a", "andre besson"); # With 'More options'
@$indexes = ("title", "all_fields", "author");
@$operators = ("AND", "NOT");
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "($titleindex:les AND $titleindex:maudits) AND a NOT ($authorindex:andre AND $authorindex:besson)";
is($got, $expected, "Test BuildIndexString");
