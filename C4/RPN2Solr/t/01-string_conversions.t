#! /usr/bin/perl
use Regexp::Grammars::Z3950::RPN;
use Modern::Perl;
use YAML;
use RPN2Solr qw/ construct_string_from_node  RPN2Solr /;
use Test::More 'no_plan';

sub test_output {
    my ( $rpn, $solr, $desc ) = @_;
    is( RPN2Solr($rpn), $solr, $desc );
}

test_output
( q{@and toto tata}
, "all_fields:toto AND all_fields:tata"
, "logic operator AND"
);

test_output
( q{@attr 1=Title @attr 4=6 "mozart amadeus"}
, "Title:mozart amadeus"
, "attr 4=6 (word list)"
);







# test_output
# ( q{@or @attr 2=3 @attr 4=109 @attr bib1 1=3 foo @attr 1=7 bar}
# , q{txt_index:foo  OR str_isbn:bar}
# , q{DESC}
# );
# test_output
# ( q{@attr 1=3 test}
# , q{txt_index:test}
# , q{DESC}
# );
# test_output
# ( q{@or @attr 2=3 @attr 4=109 @attr bib1 1=3 foo @attr 1=7 bar}
# , q{txt_index:foo  OR str_isbn:bar}
# , q{DESC}
# );
# test_output
# ( q{@or bang @or @attr 2=3 @attr 4=109 @attr bib1 1=3 "les bronzés" @attr 1=7 bar}
# , q{all_fields:bang  OR txt_index:les bronzés  OR str_isbn:bar}
# , q{DESC}
# );
# test_output
# ( q{@attr bib1 1=3 foo}
# , q{txt_index:foo}
# , q{DESC}
# );
# test_output
# ( q{attr bib1 by 1=3 value foo}
# , q{}
# , q{DESC}
# );
# test_output
# ( q{@attr bib1}
# , q{}
# , q{DESC}
# );
# test_output
# ( q{@attrset Bib-1 pouet}
# , q{all_fields:pouet}
# , q{DESC}
# );
# test_output
# ( q{@attr bib1 1=4 "la verdure"}
# , q{txt_title:la verdure}
# , q{DESC}
# );
# test_output
# ( q{@attrset Bib-1 @attr bib1 1=4 "la verdure"}
# , q{txt_title:la verdure}
# , q{DESC}
# );
# test_output
# ( q{@attrset Bib-1 @attr 1=1016 @attr 4=6 "avenants contrats publics"}
# , q{all_fields:avenants contrats publics}
# , q{DESC}
# );
# test_output
# ( q{@attrset Bib-1 @attr 1=4 code}
# , q{txt_title:code}
# , q{DESC}
# );
# test_output
# ( q{@attrset Bib-1 @attr "1=Any" Jean}
# , q{Any:Jean}
# , q{DESC}
# );
# test_output
# ( q{@or foo bar}
# , q{all_fields:foo  OR all_fields:bar}
# , q{DESC}
# );
# test_output
# ( q{@and "this guy" isn't}
# , q{all_fields:this guy  AND all_fields:isn't}
# , q{DESC}
# );
# test_output
# ( q{@set foo}
# , q{}
# , q{DESC}
# );
# test_output
# ( q{@or @set foo bar}
# , q{  OR all_fields:bar}
# , q{DESC}
# );
# test_output
# ( q{@or @set foo bar}
# , q{  OR all_fields:bar}
# , q{DESC}
# );
# test_output
# ( q{@attrset Bib-1 @or @set foo "toto tata tutu"}
# , q{  OR all_fields:toto tata tutu}
# , q{DESC}
# );
# test_output
# ( q{@attrset Bib-1 @or foo @or bar bang}
# , q{all_fields:foo  OR all_fields:bar  OR all_fields:bang}
# , q{DESC}
# );
# test_output
# ( q{@attrset Bib-1 @or foo @or bar @set bang}
# , q{all_fields:foo  OR all_fields:bar  }
# , q{DESC}
# );
# 
