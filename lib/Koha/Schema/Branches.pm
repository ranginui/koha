package Koha::Schema::Branches;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("branches");
__PACKAGE__->add_columns(
  "branchcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "branchname",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 16777215,
  },
  "branchaddress1",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "branchaddress2",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "branchaddress3",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "branchphone",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "branchfax",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "branchemail",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "issuing",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 4 },
  "branchip",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 15,
  },
  "branchprinter",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
);
__PACKAGE__->add_unique_constraint("branchcode", ["branchcode"]);
__PACKAGE__->has_many(
  "borrowers",
  "Koha::Schema::Borrowers",
  { "foreign.branchcode" => "self.branchcode" },
);
__PACKAGE__->has_many(
  "branch_borrower_circ_rules",
  "Koha::Schema::BranchBorrowerCircRules",
  { "foreign.branchcode" => "self.branchcode" },
);
__PACKAGE__->has_many(
  "branch_item_rules",
  "Koha::Schema::BranchItemRules",
  { "foreign.branchcode" => "self.branchcode" },
);
__PACKAGE__->has_many(
  "branchrelations",
  "Koha::Schema::Branchrelations",
  { "foreign.branchcode" => "self.branchcode" },
);
__PACKAGE__->has_many(
  "branchtransfers_frombranches",
  "Koha::Schema::Branchtransfers",
  { "foreign.frombranch" => "self.branchcode" },
);
__PACKAGE__->has_many(
  "branchtransfers_tobranches",
  "Koha::Schema::Branchtransfers",
  { "foreign.tobranch" => "self.branchcode" },
);
__PACKAGE__->has_many(
  "default_branch_circ_rules",
  "Koha::Schema::DefaultBranchCircRules",
  { "foreign.branchcode" => "self.branchcode" },
);
__PACKAGE__->has_many(
  "hold_fill_targets",
  "Koha::Schema::HoldFillTargets",
  { "foreign.source_branchcode" => "self.branchcode" },
);
__PACKAGE__->has_many(
  "items_homebranches",
  "Koha::Schema::Items",
  { "foreign.homebranch" => "self.branchcode" },
);
__PACKAGE__->has_many(
  "items_holdingbranches",
  "Koha::Schema::Items",
  { "foreign.holdingbranch" => "self.branchcode" },
);
__PACKAGE__->has_many(
  "reserves",
  "Koha::Schema::Reserves",
  { "foreign.branchcode" => "self.branchcode" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GDTOnRUezVxOoIVqXzRLjQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
