package Koha::Schema::Subscriptionroutinglist;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("subscriptionroutinglist");
__PACKAGE__->add_columns(
  "routingid",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "borrowernumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "ranking",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "subscriptionid",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
);
__PACKAGE__->set_primary_key("routingid");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oq7+V9i9U/5SZ5lC5pHauQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
