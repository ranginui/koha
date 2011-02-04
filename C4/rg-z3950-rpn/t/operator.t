#! /usr/bin/perl
use Modern::Perl;
use Test::More tests => 8;
use Regexp::Grammars::Z3950::RPN;
use Regexp::Grammars;
require YAML;

my $is_operator = qr{ <nocontext:> <extends: Z3950::RPN> <operator> }x;

my ( $string, $expected ); 

for
( [ q{@or}  => 'or'  ]
, [ q{@and} => 'and' ]
, [ q{@not} => 'not' ]
) {
    ( $string, $expected ) = @$_;
    ok( $string ~~ /$is_operator/ , "$string parsed"   );
    is( $/{operator}, $expected, "$string  matched" );
}

$string  = q{@prox void 10 0 15 private 5};
$expected =
{ "" => q{void 10 0 15 private 5}
, qw/
distance 10 
exclusion void 
ordered 0 
relation 15 
unit 5
which private
/};
ok( $string ~~ /$is_operator/ , "$string parsed"   );
is_deeply( $/{operator}{proximity}, $expected, "$string  matched" ) 
    or diag(YAML::Dump ($/{operator}) )


