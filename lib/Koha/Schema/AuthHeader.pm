package Koha::Schema::AuthHeader;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("auth_header");
__PACKAGE__->add_columns(
  "authid",
  { data_type => "BIGINT", default_value => undef, is_nullable => 0, size => 20 },
  "authtypecode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "datecreated",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "datemodified",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "origincode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "authtrees",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "marc",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "linkid",
  { data_type => "BIGINT", default_value => undef, is_nullable => 1, size => 20 },
  "marcxml",
  {
    data_type => "LONGTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 4294967295,
  },
);
__PACKAGE__->set_primary_key("authid");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dJQCxWLzW9cFobT2C45PbQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
