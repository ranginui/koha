package Koha::Schema::BorrowerAttributeTypes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("borrower_attribute_types");
__PACKAGE__->add_columns(
  "code",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "repeatable",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "unique_id",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "opac_display",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "password_allowed",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "staff_searchable",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "authorised_value_category",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
);
__PACKAGE__->set_primary_key("code");
__PACKAGE__->has_many(
  "borrower_attributes",
  "Koha::Schema::BorrowerAttributes",
  { "foreign.code" => "self.code" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+MNwB8QcTWPOk5KHpSkGaA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
