package Koha::Schema::Statistics;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("statistics");
__PACKAGE__->add_columns(
  "datetime",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "branch",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "proccode",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 4 },
  "value",
  { data_type => "DOUBLE", default_value => undef, is_nullable => 1, size => 64 },
  "type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "other",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "usercode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "itemnumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "itemtype",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "borrowernumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "associatedborrower",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:irV1sBBdWTPQpTuXxgSJdQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
