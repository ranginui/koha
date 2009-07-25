package Koha::Schema::Aqorders;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("aqorders");
__PACKAGE__->add_columns(
  "ordernumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "biblionumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "title",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "entrydate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "quantity",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "currency",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 3 },
  "listprice",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
  "totalamount",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
  "datereceived",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "booksellerinvoicenumber",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "freight",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
  "unitprice",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
  "quantityreceived",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "cancelledby",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "datecancellationprinted",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "notes",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "supplierreference",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "purchaseordernumber",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "subscription",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "serialid",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "basketno",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "biblioitemnumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "rrp",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 13,
  },
  "ecost",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 13,
  },
  "gst",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 13,
  },
  "budgetdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "sort1",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "sort2",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
);
__PACKAGE__->set_primary_key("ordernumber");
__PACKAGE__->has_many(
  "aqorderbreakdowns",
  "Koha::Schema::Aqorderbreakdown",
  { "foreign.ordernumber" => "self.ordernumber" },
);
__PACKAGE__->belongs_to(
  "basketno",
  "Koha::Schema::Aqbasket",
  { basketno => "basketno" },
);
__PACKAGE__->belongs_to(
  "biblionumber",
  "Koha::Schema::Biblio",
  { biblionumber => "biblionumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LpK8gd6w8FtrvxJUHauF2g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
