package Koha::Schema::Aqbudget;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("aqbudget");
__PACKAGE__->add_columns(
  "bookfundid",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "startdate",
  {
    data_type => "DATE",
    default_value => "0000-00-00",
    is_nullable => 0,
    size => 10,
  },
  "enddate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "budgetamount",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 13,
  },
  "aqbudgetid",
  { data_type => "TINYINT", default_value => undef, is_nullable => 0, size => 4 },
  "branchcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
);
__PACKAGE__->set_primary_key("aqbudgetid");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1BtxTWPWJSwa7lNvySjKwQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
