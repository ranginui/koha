package Koha::Schema::Permissions;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("permissions");
__PACKAGE__->add_columns(
  "module_bit",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "code",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 64 },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("module_bit", "code");
__PACKAGE__->belongs_to(
  "module_bit",
  "Koha::Schema::Userflags",
  { bit => "module_bit" },
);
__PACKAGE__->has_many(
  "user_permissions",
  "Koha::Schema::UserPermissions",
  {
    "foreign.code"       => "self.code",
    "foreign.module_bit" => "self.module_bit",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vPjnOm8yU4CixgoUVPfbOQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
