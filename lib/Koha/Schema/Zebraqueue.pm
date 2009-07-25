package Koha::Schema::Zebraqueue;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("zebraqueue");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "biblio_auth_number",
  { data_type => "BIGINT", default_value => 0, is_nullable => 0, size => 20 },
  "operation",
  { data_type => "CHAR", default_value => "", is_nullable => 0, size => 20 },
  "server",
  { data_type => "CHAR", default_value => "", is_nullable => 0, size => 20 },
  "done",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "time",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UPr3rsWGada2+lMrN1VmrQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
