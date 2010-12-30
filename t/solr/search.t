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

BEGIN { $tests += 6 } # 'Normal' search
@$operands[0] = "txt_title:maudits"; # Solr indexes
@$indexes = ();
@$operators = ();
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($expected, $got, "Test Solr indexes in 'normal' search");

@$operands[0] = "title:maudits"; # code indexes
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($expected, $got, "Test Code indexes in 'normal' search");

@$operands[0] = "ti:maudits"; # zebra indexes
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($expected, $got, "Test Zebra indexes in 'normal' search");

@$operands[0] = "*:*"; # all fields search
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "*:*";
is($expected, $got, "Test *:* in 'normal' search");

@$operands[0] = "txt_title:maudits OR ste_author:andre NOT txt_title:crépuscule"; # long normal search
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "txt_title:maudits OR ste_author:andre NOT txt_title:crépuscule";
is($expected, $got, "Test long 'normal' search");

@$operands[0] = "txt_title:maudits and a or ste_author:andre not txt_title:crépuscule"; # test operators
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "txt_title:maudits AND a OR ste_author:andre NOT txt_title:crépuscule";
is($expected, $got, "Test operators in 'normal' search");

BEGIN { $tests += 6 } # Advanced search
@$operands = ("maudits"); # Solr indexes
@$indexes = ("title", "all_fields", "all_fields");
@$operators = ();
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($expected, $got, "Test Solr indexes in advanced search");

@$operands = ("maudits"); # Zebra indexes
@$indexes = ("ti", "kw", "kw");
@$operators = ();
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($expected, $got, "Test Solr indexes in advanced search");

@$operands = ("maudits"); # Code indexes
@$indexes = ("title", "all_fields", "kw");
@$operators = ();
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "txt_title:maudits";
is($expected, $got, "Test Code indexes in advanced search");

@$operands = ("maudits", "a", "andre"); # More elements
@$indexes = ("title", "all_fields", "ste_author");
@$operators = ();
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "txt_title:maudits OR a OR ste_author:andre";
is($expected, $got, "Test Zebra indexes in advanced search");

@$operands = ("maudits", "a", "andre", "Besson"); # With 'More options'
@$indexes = ("title", "all_fields", "ste_author", "ste_author");
@$operators = ("AND", "NOT", "OR");
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "txt_title:maudits AND a NOT ste_author:andre OR ste_author:Besson";
is($expected, $got, "Test 'More options' in advanced search");

@$operands = ("crépuscule", "André"); # Accents
@$indexes = ("title", "ste_author");
@$operators = ("AND");
$got = C4::Search::Query->new($indexes, $operands, $operators);
$expected = "txt_title:crépuscule AND ste_author:André";
is($expected, $got, "Test Accents in advanced search");

