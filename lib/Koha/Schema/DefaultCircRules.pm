package Koha::Schema::DefaultCircRules;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("default_circ_rules");
__PACKAGE__->add_columns(
  "singleton",
  {
    data_type => "ENUM",
    default_value => "singleton",
    is_nullable => 0,
    size => 9,
  },
  "maxissueqty",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 4 },
  "holdallowed",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("singleton");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sht1MH7zl3cQYUJqeM9dbA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
