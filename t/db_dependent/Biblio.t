#!/usr/bin/perl
#
# This Koha test module is a stub!  
# Add more tests here!!!

use strict;
use warnings;
use Test::More tests => 6;
use MARC::Record;
use C4::Biblio;

BEGIN {
	use_ok('C4::Biblio');
}

my $isbn = '0590353403';
my $title = 'Foundation';

my $marc_record=MARC::Record->new;
my $field = MARC::Field->new('020','','','a' => $isbn);
$marc_record->append_fields($field);
my($biblionumber,$biblioitemnumber) = AddBiblio($marc_record,'');
my $data = &GetBiblioData($biblionumber);
is($data->{Title},undef,'Makes sure title field in biblio is empty.');

$field = MARC::Field->new('245','','','a' => $title);
$marc_record->append_fields($field);
ModBiblio($marc_record,$biblionumber,'');
$data = &GetBiblioData($biblionumber);
is($data->{title},$title,'uses ModBiblio to add a title to the previously created record and checks that its there.');
is($data->{isbn},$isbn,'Makes sure the isbn is still there after using ModBiblio.');

my $itemdata = &GetBiblioItemData($biblioitemnumber);
is($itemdata->{title},$title,'First test of GetBiblioItemData to get same result of previous two GetBiblioData tests.');
is($itemdata->{isbn},$isbn,'Second test checking it returns the correct isbn.');


# clean up after ourselves
DelBiblio($biblionumber);
