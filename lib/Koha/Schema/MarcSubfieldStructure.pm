package Koha::Schema::MarcSubfieldStructure;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marc_subfield_structure");
__PACKAGE__->add_columns(
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
  "kohafield",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "tab",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "authorised_value",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "authtypecode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "value_builder",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "isurl",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "hidden",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "frameworkcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 4 },
  "seealso",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 1100,
  },
  "link",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "defaultvalue",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("frameworkcode", "tagfield", "tagsubfield");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AIytAZ/f6JgfCsPnZnSWaQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
