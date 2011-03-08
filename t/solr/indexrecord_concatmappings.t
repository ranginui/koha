#!/usr/bin/perl
use utf8;
use Modern::Perl;
use Test::More;

my $tests;
plan tests => $tests;

BEGIN { $tests += 1 }
use_ok('C4::Search::Engine::Solr');

BEGIN { $tests += 4 }

my $plugin = "TestWithMappings";
my @list_of_plugins = ("Foo", "TestWithMappings", "Bar", "TestWithoutMappings");
my $computevalue_sub = C4::Search::Engine::Solr::LoadSearchPlugin( $plugin, \@list_of_plugins );
my @values = &$computevalue_sub;
my @expected = (1, 2, 3);
is_deeply(\@values, \@expected,"with, test values");

my $concatmappings = &C4::Search::Engine::Solr::GetConcatMappingsValue( $plugin, \@list_of_plugins );
is ($concatmappings, 1, "with, concatmappings");

$plugin = "TestWithoutMappings";
$computevalue_sub = C4::Search::Engine::Solr::LoadSearchPlugin( $plugin, \@list_of_plugins );
@values = &$computevalue_sub;
@expected = (4, 5, 6);
is_deeply(\@values, \@expected,"without, test values");

$concatmappings = &C4::Search::Engine::Solr::GetConcatMappingsValue( $plugin, \@list_of_plugins );
is ($concatmappings, 0, "witouth, concatmappings");


package TestWithMappings;
sub ComputeValue {
    return (1, 2, 3);
}
sub ConcatMappings {
    return 1;
}

package TestWithoutMappings;
sub ComputeValue {
    return (4, 5, 6);
}
