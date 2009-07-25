package Koha::Schema::AuthorisedValues;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("authorised_values");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "category",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "authorised_value",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 80 },
  "lib",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "imageurl",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 200,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:06ig9zFaZDJY7d76Y3d9dQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
