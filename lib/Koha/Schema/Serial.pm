package Koha::Schema::Serial;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("serial");
__PACKAGE__->add_columns(
  "serialid",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "biblionumber",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 100 },
  "subscriptionid",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 100 },
  "serialseq",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 100 },
  "status",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 4 },
  "planneddate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "notes",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "publisheddate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "itemnumber",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "claimdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "routingnotes",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("serialid");
__PACKAGE__->has_many(
  "serialitems",
  "Koha::Schema::Serialitems",
  { "foreign.serialid" => "self.serialid" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9Mi1qK94rFbx5VbLfujH/A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
