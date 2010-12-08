#!/usr/bin/perl

use utf8;
use Modern::Perl;
use Test::More;

use C4::Search::Plugins::Illustration;
use C4::Biblio;

#plan tests => 1;
plan 'no_plan';

my $record = MARC::Record->new;
$record->add_fields(105, " ", " ", a => "y    xxxxxxxx");
my @got = ComputeValue($record);
my @expected = ("sans illustration");
is_deeply (\@got, \@expected, '105$a contains y');

$record = MARC::Record->new;
$record->add_fields(105, " ", " ", a => "bc   xxxxxxxx");
@got = ComputeValue($record);
@expected = ("cartes","portraits");
is_deeply (\@got, \@expected, '105$a contains ab');

$record = MARC::Record->new;
$record->add_fields(105, " ", " ", a => "defg xxxxxxxx");
@got = ComputeValue($record);
@expected = ("cartes maritimes", "plans", "planches hors texte", "musique notée");
is_deeply (\@got, \@expected, '105$a contains defg');
