package Koha::Schema::Ethnicity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ethnicity");
__PACKAGE__->add_columns(
  "code",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("code");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XxXh2d41I3oTc59yhcCF9Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
