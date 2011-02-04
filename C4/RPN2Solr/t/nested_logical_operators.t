#! /usr/bin/perl
use Modern::Perl;
# use Test::More tests => 8;
use YAML;
use RPN2Solr qw< RPN2Solr >;

my $query = q{@attrset Bib-1 @and @attr 1=1016 @attr 4=6 @attr 5=1 le @or @attr 1=8009 NUM @attr 1=8009 THE};
my $got   = RPN2Solr( $query );
say $got;
