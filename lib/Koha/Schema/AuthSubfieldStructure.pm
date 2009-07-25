package Koha::Schema::AuthSubfieldStructure;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("auth_subfield_structure");
__PACKAGE__->add_columns(
  "authtypecode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "tagfield",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 3 },
  "tagsubfield",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 1 },
  "liblibrarian",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "libopac",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "repeatable",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 4 },
  "mandatory",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 4 },
  "tab",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "authorised_value",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "value_builder",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "seealso",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "isurl",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "hidden",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },
  "linkid",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "kohafield",
  { data_type => "VARCHAR", default_value => "", is_nullable => 1, size => 45 },
  "frameworkcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("authtypecode", "tagfield", "tagsubfield");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7voPKccePHATf7YOx7vh9w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
