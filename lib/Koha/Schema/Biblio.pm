package Koha::Schema::Biblio;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("biblio");
__PACKAGE__->add_columns(
  "biblionumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "frameworkcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 4 },
  "author",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "title",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "unititle",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "notes",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "serial",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "seriestitle",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "copyrightdate",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "datecreated",
  { data_type => "DATE", default_value => undef, is_nullable => 0, size => 10 },
  "abstract",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
);
__PACKAGE__->set_primary_key("biblionumber");
__PACKAGE__->has_many(
  "aqorders",
  "Koha::Schema::Aqorders",
  { "foreign.biblionumber" => "self.biblionumber" },
);
__PACKAGE__->has_many(
  "biblioitems",
  "Koha::Schema::Biblioitems",
  { "foreign.biblionumber" => "self.biblionumber" },
);
__PACKAGE__->has_many(
  "hold_fill_targets",
  "Koha::Schema::HoldFillTargets",
  { "foreign.biblionumber" => "self.biblionumber" },
);
__PACKAGE__->has_many(
  "old_reserves",
  "Koha::Schema::OldReserves",
  { "foreign.biblionumber" => "self.biblionumber" },
);
__PACKAGE__->has_many(
  "reserves",
  "Koha::Schema::Reserves",
  { "foreign.biblionumber" => "self.biblionumber" },
);
__PACKAGE__->has_many(
  "tags_alls",
  "Koha::Schema::TagsAll",
  { "foreign.biblionumber" => "self.biblionumber" },
);
__PACKAGE__->has_many(
  "tags_indexes",
  "Koha::Schema::TagsIndex",
  { "foreign.biblionumber" => "self.biblionumber" },
);
__PACKAGE__->has_many(
  "virtualshelfcontents",
  "Koha::Schema::Virtualshelfcontents",
  { "foreign.biblionumber" => "self.biblionumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i+nSCVsghfGED5wh/tY6fQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
