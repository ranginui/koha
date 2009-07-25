package Koha::Schema::ImportItems;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("import_items");
__PACKAGE__->add_columns(
  "import_items_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "import_record_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "itemnumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "branchcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "status",
  { data_type => "ENUM", default_value => "staged", is_nullable => 0, size => 8 },
  "marcxml",
  {
    data_type => "LONGTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 4294967295,
  },
  "import_error",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
);
__PACKAGE__->set_primary_key("import_items_id");
__PACKAGE__->belongs_to(
  "import_record_id",
  "Koha::Schema::ImportRecords",
  { import_record_id => "import_record_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MvgZgG0nhgvHG0k1FnyA6Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
