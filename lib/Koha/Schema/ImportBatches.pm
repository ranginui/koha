package Koha::Schema::ImportBatches;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("import_batches");
__PACKAGE__->add_columns(
  "import_batch_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "matcher_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "template_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "branchcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "num_biblios",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "num_items",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "upload_timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "overlay_action",
  {
    data_type => "ENUM",
    default_value => "create_new",
    is_nullable => 0,
    size => 12,
  },
  "nomatch_action",
  {
    data_type => "ENUM",
    default_value => "create_new",
    is_nullable => 0,
    size => 10,
  },
  "item_action",
  {
    data_type => "ENUM",
    default_value => "always_add",
    is_nullable => 0,
    size => 20,
  },
  "import_status",
  {
    data_type => "ENUM",
    default_value => "staging",
    is_nullable => 0,
    size => 9,
  },
  "batch_type",
  { data_type => "ENUM", default_value => "batch", is_nullable => 0, size => 5 },
  "file_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "comments",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
);
__PACKAGE__->set_primary_key("import_batch_id");
__PACKAGE__->has_many(
  "import_records",
  "Koha::Schema::ImportRecords",
  { "foreign.import_batch_id" => "self.import_batch_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RxPIONKy3nrcV080XvH1aw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
