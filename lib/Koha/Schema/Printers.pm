package Koha::Schema::Printers;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("printers");
__PACKAGE__->add_columns(
  "printername",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 40 },
  "printqueue",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "printtype",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("printername");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MVONCB7lhHHezDvRBO49qg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
