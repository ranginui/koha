#!/usr/bin/perl

use utf8;
use Modern::Perl;
use Test::More;

use C4::Search::Plugins::Author;
use C4::Biblio;

plan 'no_plan';

sub MockBiblio {
  my $record = MARC::Record->new;
  $record->add_fields(700, " ", " ", a => "Hugo", b => "Victor");
  return $record;
}

my $record = MockBiblio;
my @got = ComputeValue($record);
my @expected = ("Hugo Victor");
is_deeply (\@got, \@expected, 'Bind Biblio Author field');
