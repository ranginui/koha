package Koha::Schema::Items;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("items");
__PACKAGE__->add_columns(
  "itemnumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "biblionumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "biblioitemnumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "barcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "dateaccessioned",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "booksellerid",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "homebranch",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "price",
  { data_type => "DECIMAL", default_value => undef, is_nullable => 1, size => 8 },
  "replacementprice",
  { data_type => "DECIMAL", default_value => undef, is_nullable => 1, size => 8 },
  "replacementpricedate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "datelastborrowed",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "datelastseen",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "stack",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "notforloan",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "damaged",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "itemlost",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "wthdrawn",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "itemcallnumber",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "issues",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "renewals",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "reserves",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "restricted",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "itemnotes",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "holdingbranch",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "paidfor",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "location",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "onloan",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "cn_source",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "cn_sort",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "ccode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "materials",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "uri",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "itype",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "more_subfields_xml",
  {
    data_type => "LONGTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 4294967295,
  },
  "enumchron",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "copynumber",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("itemnumber");
__PACKAGE__->add_unique_constraint("itembarcodeidx", ["barcode"]);
__PACKAGE__->has_many(
  "accountlines",
  "Koha::Schema::Accountlines",
  { "foreign.itemnumber" => "self.itemnumber" },
);
__PACKAGE__->has_many(
  "branchtransfers",
  "Koha::Schema::Branchtransfers",
  { "foreign.itemnumber" => "self.itemnumber" },
);
__PACKAGE__->has_many(
  "hold_fill_targets",
  "Koha::Schema::HoldFillTargets",
  { "foreign.itemnumber" => "self.itemnumber" },
);
__PACKAGE__->has_many(
  "issues",
  "Koha::Schema::Issues",
  { "foreign.itemnumber" => "self.itemnumber" },
);
__PACKAGE__->belongs_to(
  "biblioitemnumber",
  "Koha::Schema::Biblioitems",
  { biblioitemnumber => "biblioitemnumber" },
);
__PACKAGE__->belongs_to(
  "homebranch",
  "Koha::Schema::Branches",
  { branchcode => "homebranch" },
);
__PACKAGE__->belongs_to(
  "holdingbranch",
  "Koha::Schema::Branches",
  { branchcode => "holdingbranch" },
);
__PACKAGE__->has_many(
  "old_issues",
  "Koha::Schema::OldIssues",
  { "foreign.itemnumber" => "self.itemnumber" },
);
__PACKAGE__->has_many(
  "old_reserves",
  "Koha::Schema::OldReserves",
  { "foreign.itemnumber" => "self.itemnumber" },
);
__PACKAGE__->has_many(
  "reserves",
  "Koha::Schema::Reserves",
  { "foreign.itemnumber" => "self.itemnumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tkwciZecCx+h55S004Xb8A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
