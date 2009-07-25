package Koha::Schema::ImportRecords;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("import_records");
__PACKAGE__->add_columns(
  "import_record_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "import_batch_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "branchcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "record_sequence",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "upload_timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "import_date",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "marc",
  {
    data_type => "LONGBLOB",
    default_value => undef,
    is_nullable => 0,
    size => 4294967295,
  },
  "marcxml",
  {
    data_type => "LONGTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 4294967295,
  },
  "marcxml_old",
  {
    data_type => "LONGTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 4294967295,
  },
  "record_type",
  { data_type => "ENUM", default_value => "biblio", is_nullable => 0, size => 8 },
  "overlay_status",
  {
    data_type => "ENUM",
    default_value => "no_match",
    is_nullable => 0,
    size => 13,
  },
  "status",
  {
    data_type => "ENUM",
    default_value => "staged",
    is_nullable => 0,
    size => 14,
  },
  "import_error",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "encoding",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 40 },
  "z3950random",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
);
__PACKAGE__->set_primary_key("import_record_id");
__PACKAGE__->has_many(
  "import_biblios",
  "Koha::Schema::ImportBiblios",
  { "foreign.import_record_id" => "self.import_record_id" },
);
__PACKAGE__->has_many(
  "import_items",
  "Koha::Schema::ImportItems",
  { "foreign.import_record_id" => "self.import_record_id" },
);
__PACKAGE__->has_many(
  "import_record_matches",
  "Koha::Schema::ImportRecordMatches",
  { "foreign.import_record_id" => "self.import_record_id" },
);
__PACKAGE__->belongs_to(
  "import_batch_id",
  "Koha::Schema::ImportBatches",
  { import_batch_id => "import_batch_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0p5NEbjnMAyh503kJTIJhA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
