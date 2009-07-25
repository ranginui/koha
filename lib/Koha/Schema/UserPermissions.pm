package Koha::Schema::UserPermissions;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user_permissions");
__PACKAGE__->add_columns(
  "borrowernumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "module_bit",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "code",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
);
__PACKAGE__->belongs_to(
  "borrowernumber",
  "Koha::Schema::Borrowers",
  { borrowernumber => "borrowernumber" },
);
__PACKAGE__->belongs_to(
  "permission",
  "Koha::Schema::Permissions",
  { code => "code", module_bit => "module_bit" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TKQE2OtGEHzKCkduS7ul2Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
