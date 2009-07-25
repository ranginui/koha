package Koha::Schema::Z3950servers;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("z3950servers");
__PACKAGE__->add_columns(
  "host",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "port",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "db",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "userid",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "password",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "name",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "checked",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "rank",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "syntax",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "icon",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "position",
  {
    data_type => "ENUM",
    default_value => "primary",
    is_nullable => 0,
    size => 9,
  },
  "type",
  { data_type => "ENUM", default_value => "zed", is_nullable => 0, size => 10 },
  "encoding",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2uGILXn/TGBXnioa09MkGQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
