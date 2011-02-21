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

BEGIN { $tests += 7 } # 'Normal' search
@$operands[0] = "txt_title:maudits"; # Solr indexes
@$indexes = ();
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($got, $expected, "Test Solr indexes in 'normal' search");

@$operands[0] = "title:maudits"; # code indexes
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($got, $expected, "Test Code indexes in 'normal' search");

@$operands[0] = "ti:maudits"; # zebra indexes
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($got, $expected, "Test Zebra indexes in 'normal' search");

@$operands[0] = "*:*"; # all fields search
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "*:*";
is($got, $expected, "Test *:* in 'normal' search");

@$operands[0] = "txt_title:maudits OR ste_author:andre NOT txt_title:crépuscule"; # long normal search
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "txt_title:maudits OR ste_author:andre NOT txt_title:crépuscule";
is($got, $expected, "Test long 'normal' search");

@$operands[0] = "txt_title:maudits and a or ste_author:andre not txt_title:crépuscule"; # test operators
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "txt_title:maudits AND a OR ste_author:andre NOT txt_title:crépuscule";
is($got, $expected, "Test operators in 'normal' search");

$q = "title:maudits and a or author:andre not ean:blabla"; # test normal search
$got = C4::Search::Query->normalSearch($q);
$expected = "txt_title:maudits AND a OR ste_author:andre NOT str_ean:blabla";
is($got, $expected, "Test 'normal' search");

BEGIN { $tests += 7 } # Advanced search
@$operands = ("maudits"); # Solr indexes
@$indexes = ("title", "all_fields", "all_fields");
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($got, $expected, "Test Solr indexes in advanced search");

@$operands = ("maudits"); # Zebra indexes
@$indexes = ("ti", "kw", "kw");
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($got, $expected, "Test Solr indexes in advanced search");

@$operands = ("maudits"); # Code indexes
@$indexes = ("title", "all_fields", "kw");
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($got, $expected, "Test Code indexes in advanced search");

@$operands = ("maudits", "a", "andre"); # More elements
@$indexes = ("title", "all_fields", "ste_author");
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "txt_title:maudits OR a OR ste_author:andre";
is($got, $expected, "Test Zebra indexes in advanced search");

@$operands = ("maudits", "a", "andre", "Besson"); # With 'More options'
@$indexes = ("title", "all_fields", "ste_author", "ste_author");
@$operators = ("AND", "NOT", "OR");
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "txt_title:maudits AND a NOT ste_author:andre OR ste_author:Besson";
is($got, $expected, "Test 'More options' in advanced search");

@$operands = ("crépuscule", "André"); # Accents
@$indexes = ("title", "ste_author");
@$operators = ("AND");
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "txt_title:crépuscule AND ste_author:André";
is($got, $expected, "Test Accents in advanced search");

@$operands = ("maudits", "a", "andre"); # Bad indexes types
@$indexes = ("", undef, ());
@$operators = ();
$got = C4::Search::Query->buildQuery($indexes, $operands, $operators);
$expected = "maudits OR a OR andre";
is($got, $expected, "Test call with bad indexes types");

