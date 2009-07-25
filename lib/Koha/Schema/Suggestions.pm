package Koha::Schema::Suggestions;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("suggestions");
__PACKAGE__->add_columns(
  "suggestionid",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "suggestedby",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "managedby",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "status",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "note",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "author",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "copyrightdate",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "publishercode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "date",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "volumedesc",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "publicationyear",
  { data_type => "SMALLINT", default_value => 0, is_nullable => 1, size => 6 },
  "place",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "isbn",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "mailoverseeing",
  { data_type => "SMALLINT", default_value => 0, is_nullable => 1, size => 1 },
  "biblionumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "reason",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("suggestionid");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HKM9gL9vIvjoJ+ys/sRotA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
