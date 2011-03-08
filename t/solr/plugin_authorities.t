#!/usr/bin/perl

use utf8;
use Modern::Perl;
use Test::More;
use KohaTest::Search::MocksForSearch;

use C4::Search::Plugins::Authorities;
use C4::Biblio;
use C4::AuthoritiesMarc;
use Test::MockModule;
use Sub::Override;
use MARC::Record;

plan 'no_plan';

# Authority author case

my $module = new Test::MockModule('C4::AuthoritiesMarc');
$module->mock('GetAuthority', sub { &KohaTest::Search::MocksForSearch::MockGetAuthority });

my $rec = KohaTest::Search::MocksForSearch::MockBiblio;
my @got;
my @expected;
my $mapping;

# behaviour before change
#@got = ComputeValue($rec);
#@expected = ('RejPapillon', 'ParPapillon', 'RejEurope', 'ParEurope', 'Gaa', 'Rom', 'Ajar', 'Emilie');
#is_deeply (\@got, \@expected, 'Old Authority plugin');

$mapping = KohaTest::Search::MocksForSearch::MockMappingAuthor;
@got = ComputeValue($rec, $mapping);
@expected = ('Gary', 'Romain', 'Gaa', 'Rom', 'Ajar', 'Emilie');
is_deeply (\@got, \@expected, 'Authority plugin in Author authority case');

$mapping = KohaTest::Search::MocksForSearch::MockMappingSubject;
@got = ComputeValue($rec, $mapping);
@expected = ('Papillon', 'RejPapillon','ParPapillon');
is_deeply (\@got, \@expected, 'Authority plugin in Subject authority case');

$mapping = KohaTest::Search::MocksForSearch::MockMappingGeoSubject;
@got = ComputeValue($rec, $mapping);
@expected = ('Europe', 'RejEurope','ParEurope');
is_deeply (\@got, \@expected, 'Authority plugin in geographic Subject authority case');
