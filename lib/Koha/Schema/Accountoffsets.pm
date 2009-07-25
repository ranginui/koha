package Koha::Schema::Accountoffsets;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("accountoffsets");
__PACKAGE__->add_columns(
  "borrowernumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "accountno",
  { data_type => "SMALLINT", default_value => 0, is_nullable => 0, size => 6 },
  "offsetaccount",
  { data_type => "SMALLINT", default_value => 0, is_nullable => 0, size => 6 },
  "offsetamount",
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
);
__PACKAGE__->belongs_to(
  "borrowernumber",
  "Koha::Schema::Borrowers",
  { borrowernumber => "borrowernumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wMjVLeoURK7DghJMvlnkEQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
