package Koha::Schema::ImportBiblios;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("import_biblios");
__PACKAGE__->add_columns(
  "import_record_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "matched_biblionumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "control_number",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "original_source",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "author",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "isbn",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "issn",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 9 },
  "has_items",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
);
__PACKAGE__->belongs_to(
  "import_record_id",
  "Koha::Schema::ImportRecords",
  { import_record_id => "import_record_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WGondv85PMIY77JwqPJBww


# You can replace this text with custom content, and it will be preserved on regeneration
1;
