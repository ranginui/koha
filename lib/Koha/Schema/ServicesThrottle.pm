package Koha::Schema::ServicesThrottle;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("services_throttle");
__PACKAGE__->add_columns(
  "service_type",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "service_count",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 45,
  },
);
__PACKAGE__->set_primary_key("service_type");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dzeBHyvZbMDdqu9BkV/0Dg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
