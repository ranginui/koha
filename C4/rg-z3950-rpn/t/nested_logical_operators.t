#! /usr/bin/perl
use Modern::Perl;
use Test::More tests => 2;
use YAML;
use Regexp::Grammars::Z3950::RPN;
use Regexp::Grammars;
my $matches = qr{ <nocontext:> <extends: Z3950::RPN> <query> }x;
my $query = q{@attrset Bib-1 @and @attr 1=1016 @attr 4=6 @attr 5=1 le @or @attr 1=8009 NUM @attr 1=8009 THE};
my $expected = YAML::Load <<'';
  attrset: Bib-1
  subquery:
    operands:
      - attrspec:
          - attr: 1=1016
          - attr: 4=6
          - attr: 5=1
        term: le
      - operands:
          - attrspec:
              - attr: 1=8009
            term: NUM
          - attrspec:
              - attr: 1=8009
            term: THE
        operator: or
    operator: and

ok( $query =~ /$matches/, "expression matched" );
is_deeply( $/{query}, $expected , "AST OK" );
