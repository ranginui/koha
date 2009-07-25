package Koha::Schema::Tags;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tags");
__PACKAGE__->add_columns(
  "entry",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "weight",
  { data_type => "BIGINT", default_value => 0, is_nullable => 0, size => 20 },
);
__PACKAGE__->set_primary_key("entry");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3M/W97FBsLmX2FJig5RDTg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
