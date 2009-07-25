package Koha::Schema::Overduerules;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("overduerules");
__PACKAGE__->add_columns(
  "branchcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "categorycode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "delay1",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 4 },
  "letter1",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "debarred1",
  { data_type => "VARCHAR", default_value => 0, is_nullable => 1, size => 1 },
  "delay2",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 4 },
  "debarred2",
  { data_type => "VARCHAR", default_value => 0, is_nullable => 1, size => 1 },
  "letter2",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "delay3",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 4 },
  "letter3",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "debarred3",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("branchcode", "categorycode");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oFkU3PJwgPixAuzXzKYXJA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
