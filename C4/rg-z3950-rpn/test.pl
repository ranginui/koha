#! /usr/bin/perl
use Regexp::Grammars::Z3950::RPN;
use Modern::Perl;
use YAML;

my %parse_rpn = do {
    use Regexp::Grammars;
    ( operator => qr{ <nocontext:> <extends: Z3950::RPN> <operator>  }x
    , string   => qr{ <nocontext:> <extends: Z3950::RPN> <rpnstring> }x
    , query    => qr{ <nocontext:> <extends: Z3950::RPN> <query> }x
    );
};

# q{@attrset Bib-1 @term test @attrset Bib-1 foo} ~~ /$parse_rpn{operator}/;


for ( qw/bib1 1=4/, "la verdure" ) {
    /$parse_rpn{string}/ or die "$_ isn't rpn string";
}

while (<DATA>) {
    next if /^[#]/;
    chomp;
    say;
    say /$parse_rpn{query}/
    ? Dump($/{query})
    : "can't parse it"
    ; 
}

__DATA__
# goo
# @attr 1=3 test
# @or @attr 2=3 @attr 4=109 @attr bib1 1=3 foo @attr 1=7 bar
@or bang @or @attr 2=3 @attr 4=109 @attr bib1 1=3 "les bronzés" @attr 1=7 bar
# @attr bib1 1=3 foo 
# {qw/ attr bib1 by 1=3 value foo /}
# @attr bib1 
# @attrset Bib-1 pouet
# @attr bib1 1=4 "la verdure"
# @attrset Bib-1 @attr bib1 1=4 "la verdure"
# @attrset Bib-1 @attr 1=1016 @attr 4=6 "avenants contrats publics"
# @attrset Bib-1 @attr 1=4 code
# @attrset Bib-1 @attr "1=Any" Jean
# @or foo bar
# @and "this guy" isn't
# @set foo
# @or @set foo bar
# @or @set foo bar
# @attrset Bib-1 @or @set foo "toto tata tutu"
# @attrset Bib-1 @or foo @or bar bang
# @attrset Bib-1 @or foo @or bar @set bang
