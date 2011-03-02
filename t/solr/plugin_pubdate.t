#!/usr/bin/perl
use utf8;
use Modern::Perl;
use Test::More;

my $tests;
plan tests => $tests;

BEGIN { $tests += 2 }
use_ok('C4::Search::Engine::Solr');
use_ok('C4::Search::Plugins::PubDate');

sub perform_test {
    my ($date_str, $expected) = @_;
    my $record = MARC::Record->new;
    $record->add_fields(210, " ", " ", d => $date_str);
    my @got = ComputeValue($record);
    is_deeply(\@got, $expected, ">$date_str");

}


BEGIN { $tests += 11 }
my @expected = ("1998-01-01T00:00:00Z");
perform_test (
    "1998", \@expected
);

@expected = ("1998-01-01T00:00:00Z");
perform_test (
    "cop. 1998", \@expected
);

@expected = ("1700-01-01T00:00:00Z");
perform_test (
    "Avec privilège du Roy, 1700", \@expected
);

@expected = ("2006-01-01T00:00:00Z");
perform_test (
    "DL 2006", \@expected
);

@expected = ("2006-01-01T00:00:00Z");
perform_test (
    "ca 2006", \@expected
);

@expected = ("2010-01-01T00:00:00Z");
perform_test (
    "2010 printing", \@expected
);

@expected = ("2004-01-01T00:00:00Z");
perform_test (
    "[2004]", \@expected
);

@expected = ("1982-01-01T00:00:00Z");
perform_test (
    "[cop. 1982]", \@expected
);

@expected = ("1978-01-01T00:00:00Z", "1979-01-01T00:00:00Z");
perform_test (
    "[1978 or 1979]", \@expected
);

@expected = ("2004-01-01T00:00:00Z", "2005-01-01T00:00:00Z", "2006-01-01T00:00:00Z");
perform_test (
    "2004-2006", \@expected
);

@expected = ("2004-01-01T00:00:00Z", "2005-01-01T00:00:00Z", "2006-01-01T00:00:00Z");
perform_test (
    "[2004-2006]", \@expected
);

