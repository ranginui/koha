package Koha::Schema::TmpHoldsqueue;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tmp_holdsqueue");
__PACKAGE__->add_columns(
  "biblionumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "itemnumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "barcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "surname",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 16777215,
  },
  "firstname",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "phone",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "borrowernumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "cardnumber",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "reservedate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "title",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "itemcallnumber",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "holdingbranch",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "pickbranch",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "notes",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "item_level_request",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 4 },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ezXaREcCjnnxgKKWLc3dbQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
