package Koha::Schema::Cities;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cities");
__PACKAGE__->add_columns(
  "cityid",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "city_name",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 100 },
  "city_zipcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("cityid");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ArxhG5lzRGHPOQxR/7onXg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
