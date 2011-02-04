#! /usr/bin/perl
use Modern::Perl;
# use Test::More tests => 10;
use Test::More 'no_plan';
use Regexp::Grammars::Z3950::RPN;
use Regexp::Grammars;
require YAML;

my $is_query = qr{ <extends: Z3950::RPN> <query> }x;
my ( $raw, $expected );

for
( [ q{test}                            => {qw/ term test /} ]
, [ q{@set test}                       => {qw/ set test /} ]
, [ q{@set "hannn mais ca c'est bien"} => {set => "hannn mais ca c'est bien"} ]
) { ( $raw, $expected ) = @$_;
    ok( $raw ~~ /$is_query/ , "parsing $raw"   );
    is_deeply( $/{query}{subquery}, $expected, "$raw datastructure ok" )
	or diag( YAML::Dump($/{query}{subquery}))
}

for
( [ q{@attrset Bib-1 test}      => {qw/ attrset Bib-1 subquery / => {qw/ term test /}} ]
, [ q{@attrset Bib-1 @set test} => {qw/ attrset Bib-1 subquery / => {qw/ set test  /}} ]
) { ( $raw, $expected ) = @$_;
    ok( $raw ~~ /$is_query/ , "parsing $raw"   );
    is_deeply( $/{query}, $expected, "$raw datastructure ok" )
	or diag( YAML::Dump($/{query}))
}
