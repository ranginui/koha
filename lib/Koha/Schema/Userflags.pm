package Koha::Schema::Userflags;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("userflags");
__PACKAGE__->add_columns(
  "bit",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "flag",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "flagdesc",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "defaulton",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
);
__PACKAGE__->set_primary_key("bit");
__PACKAGE__->has_many(
  "permissions",
  "Koha::Schema::Permissions",
  { "foreign.module_bit" => "self.bit" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ULpJLW6U6sA3WPjVADF9eg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
