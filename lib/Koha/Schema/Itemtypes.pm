package Koha::Schema::Itemtypes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("itemtypes");
__PACKAGE__->add_columns(
  "itemtype",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "description",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "renewalsallowed",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "rentalcharge",
  { data_type => "DOUBLE", default_value => undef, is_nullable => 1, size => 64 },
  "notforloan",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "imageurl",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 200,
  },
  "summary",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("itemtype");
__PACKAGE__->add_unique_constraint("itemtype", ["itemtype"]);
__PACKAGE__->has_many(
  "branch_item_rules",
  "Koha::Schema::BranchItemRules",
  { "foreign.itemtype" => "self.itemtype" },
);
__PACKAGE__->has_many(
  "default_branch_item_rules",
  "Koha::Schema::DefaultBranchItemRules",
  { "foreign.itemtype" => "self.itemtype" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UWiOhlwSQuKfD8+UusX0pw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
