package Koha::Schema::SpecialHolidays;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("special_holidays");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "branchcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "day",
  { data_type => "SMALLINT", default_value => 0, is_nullable => 0, size => 6 },
  "month",
  { data_type => "SMALLINT", default_value => 0, is_nullable => 0, size => 6 },
  "year",
  { data_type => "SMALLINT", default_value => 0, is_nullable => 0, size => 6 },
  "isexception",
  { data_type => "SMALLINT", default_value => 1, is_nullable => 0, size => 1 },
  "title",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 50 },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OlVyWyDpfnCui9Wg11Eqww


# You can replace this text with custom content, and it will be preserved on regeneration
1;
