package Koha::Schema::Alert;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("alert");
__PACKAGE__->add_columns(
  "alertid",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "borrowernumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "type",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "externalid",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 20 },
);
__PACKAGE__->set_primary_key("alertid");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:auh6R/B1LWsTMg9RKnz0Vw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
