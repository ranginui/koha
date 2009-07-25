package Koha::Schema::BranchTransferLimits;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("branch_transfer_limits");
__PACKAGE__->add_columns(
  "limitid",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "tobranch",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "frombranch",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "itemtype",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "ccode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
);
__PACKAGE__->set_primary_key("limitid");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6CbRHYPw6GWR0Cy1AoTrQQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
