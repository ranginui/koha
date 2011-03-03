#! /usr/bin/perl
use Regexp::Grammars::Z3950::RPN;
use Modern::Perl;
use YAML;
use Test::More;

my $tests;
plan tests => $tests;

sub test_output {
    my ( $rpn, $solr, $desc ) = @_;
    is( RPN2Solr::RPN2Solr($rpn), $solr, $desc );
}

# Use
BEGIN { $tests += 2 }
use_ok('C4::RPN2Solr::lib::RPN2Solr');
use_ok('C4::Search::Query');

my $titleindex = C4::Search::Query::getIndexName("title");
my $authorindex = C4::Search::Query::getIndexName("author");
my $eanindex = C4::Search::Query::getIndexName("ean");
my $isbnindex = C4::Search::Query::getIndexName("isbn");
my $harvestdateindex = C4::Search::Query::getIndexName("harvestdate");
my $publisherindex = C4::Search::Query::getIndexName("publisher");

# Indexes
BEGIN { $tests += 3 }
test_output
( q{@attr 1=1016 tata}
, "all_fields:'tata'"
, q{@attr 1=1016 : All fields index}
);

test_output
( q{@attr 1=4 tata}
, "$titleindex:'tata'"
, q{@attr 1=4 : $titleindex index}
);

test_output
( q{@attr 1=1018 tata}
, "$publisherindex:'tata'"
, q{@attr 1=1018 : publisher index}
);

# Atomic query
BEGIN { $tests += 2 }
test_output
( q{jean}
, "all_fields:'jean'"
, "Atomic query"
);

test_output
( q{@attr 1=1016 ""}
, "all_fields:[* TO *]"
, "Atomic query with *"
);

# Operators AND, OR, NOT
BEGIN { $tests += 4 }
test_output
( q{@and @attr 1=4 foo @attr 1=7 bar}
, "( $titleindex:'foo' AND $isbnindex:'bar' )"
, q{@and : logic operator AND}
);
test_output
( q{@or @attr 1=4 foo @attr 1=7 bar}
, "( $titleindex:'foo' OR $isbnindex:'bar' )"
, q{@or logic operator OR}
);

test_output
( q{@not @attr 1=4 foo @attr 1=7 bar}
, "( $titleindex:'foo' NOT $isbnindex:'bar' )"
, q{@not logic operator NOT}
);

test_output
( q{@and @attr 1=4 foo @or @attr 1=7 bar1 @attr 1=7 bar2}
, "( $titleindex:'foo' AND ( $isbnindex:'bar1' OR $isbnindex:'bar2' ) )"
, "multiple logics operators"
);

# Relation attributes
BEGIN { $tests += 5 }
test_output
( q{@attr 2=2 @attr 1=4 foo}
, "$titleindex:[* TO 'foo']"
, q{@attr 2=2 : Less than}
);

test_output
( q{@attr 2=3 @attr 1=4 foo}
, "$titleindex:'foo'"
, q{@attr 2=3 : equal}
);

test_output
( q{@attr 2=5 @attr 1=4 foo}
, "$titleindex:['foo' TO *]"
, q{@attr 2=5 : greater than}
);

test_output
( q{@attr 2=6 @attr 1=4 foo}
, "!$titleindex:'foo'"
, q{@attr 2=6 : not equal}
);

test_output
( q{@and @and bang @and @or @attr 2=3 @attr 1=4 "foo bar" @attr 1=4 "bar foo" @attr 2=6 @attr 1=4 "foo foo" @attr 2=5 @attr 1=1003 middle}
, "( ( all_fields:'bang' AND ( ( $titleindex:'foo bar' OR $titleindex:'bar foo' ) AND !$titleindex:'foo foo' ) ) AND ste_author:['middle' TO *] )"
, "more complex query with relation attributes"
);

# Truncation
BEGIN { $tests += 4 }
test_output
( q{@attr 5=1 @attr 1=4 foo}
, "$titleindex:'foo*'"
, q{@attr 5=1 : Right truncation}
);

test_output
( q{@attr 5=2 @attr 1=4 foo}
, "$titleindex:'*foo'"
, q{@attr 5=2 : Left truncation}
);

test_output
( q{@attr 5=3 @attr 1=4 foo}
, "$titleindex:'*foo*'"
, q{@attr 5=3 : Left and Right truncation}
);

test_output
( q{@attr 5=100 @attr 1=4 foo}
, "$titleindex:'foo'"
, q{@attr 5=100 : Do not truncate}
);

# Structure Attribues
BEGIN { $tests += 3 }
test_output
( q{@attr 1=4 @attr 4=1 "my title"}
, "$titleindex:'my title'"
, q{@attr 4=1 : Phrase}
);

test_output
( q{@attr 1=4 @attr 4=2 title}
, "$titleindex:title"
, q{@attr 4=2 : Word}
);

# TODO Not yet implemented
# test_output 
# ( q{@attr 1=4 @attr 4=6 "mozart amadeus"}
# , "$titleindex:mozart AND $titleindex:amadeus"
# , "word list"
# );

# We have not yet an integer index
test_output
( q{@attr 4=109 @attr 2=5 @attr 1=int_idx 5}
, "int_idx:[5 TO *]"
, q{@attr 4=109 : numeric string}
);

# Don't use attrset
BEGIN { $tests += 1 }
test_output
( q{@attrset gils @and @attr 1=4 foo @attr 1=7 bar}
, "( $titleindex:'foo' AND $isbnindex:'bar' )"
, q{@attr 4=1 : Phrase}
);

# Complex rpn query with _ALLRECORDS "rpn index"
BEGIN { $tests += 1 }
test_output
( q{@not @attr 2=103 @attr 1=_ALLRECORDS "" @attr 1=harvestdate @attr 2=103 ""}
, "( all_fields:[* TO *] NOT $harvestdateindex:[* TO *] )"
, q{_ALLRECORDS}
);

