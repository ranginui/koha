package Koha::Schema::Accountlines;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("accountlines");
__PACKAGE__->add_columns(
  "borrowernumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "accountno",
  { data_type => "SMALLINT", default_value => 0, is_nullable => 0, size => 6 },
  "itemnumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "date",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "amount",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
  "description",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "dispute",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "accounttype",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 5 },
  "amountoutstanding",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "notify_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "notify_level",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 2 },
  "lastincrement",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
);
__PACKAGE__->belongs_to(
  "borrowernumber",
  "Koha::Schema::Borrowers",
  { borrowernumber => "borrowernumber" },
);
__PACKAGE__->belongs_to(
  "itemnumber",
  "Koha::Schema::Items",
  { itemnumber => "itemnumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZccWRG4kLF7iN5oIY4r5Yg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
