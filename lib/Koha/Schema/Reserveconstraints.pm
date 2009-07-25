package Koha::Schema::Reserveconstraints;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("reserveconstraints");
__PACKAGE__->add_columns(
  "borrowernumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "reservedate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "biblionumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "biblioitemnumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4LRcUjrVF4HtYKYnB75ewQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
