package Koha::Schema::Categories;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("categories");
__PACKAGE__->add_columns(
  "categorycode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "description",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "enrolmentperiod",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "upperagelimit",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "dateofbirthrequired",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "finetype",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "bulk",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "enrolmentfee",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
  "overduenoticerequired",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "issuelimit",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "reservefee",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
  "category_type",
  { data_type => "VARCHAR", default_value => "A", is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("categorycode");
__PACKAGE__->add_unique_constraint("categorycode", ["categorycode"]);
__PACKAGE__->has_many(
  "borrower_message_preferences",
  "Koha::Schema::BorrowerMessagePreferences",
  { "foreign.categorycode" => "self.categorycode" },
);
__PACKAGE__->has_many(
  "borrowers",
  "Koha::Schema::Borrowers",
  { "foreign.categorycode" => "self.categorycode" },
);
__PACKAGE__->has_many(
  "branch_borrower_circ_rules",
  "Koha::Schema::BranchBorrowerCircRules",
  { "foreign.categorycode" => "self.categorycode" },
);
__PACKAGE__->has_many(
  "default_borrower_circ_rules",
  "Koha::Schema::DefaultBorrowerCircRules",
  { "foreign.categorycode" => "self.categorycode" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C9L2kmtdp+uUqLA7FRcHyg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
