package Koha::Schema::Roadtype;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("roadtype");
__PACKAGE__->add_columns(
  "roadtypeid",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "road_type",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 100 },
);
__PACKAGE__->set_primary_key("roadtypeid");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5QDpXAHAL1Z6v8hJs2+EKw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
