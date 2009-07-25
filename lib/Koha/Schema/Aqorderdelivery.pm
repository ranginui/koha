package Koha::Schema::Aqorderdelivery;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("aqorderdelivery");
__PACKAGE__->add_columns(
  "ordernumber",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "deliverynumber",
  { data_type => "SMALLINT", default_value => 0, is_nullable => 0, size => 6 },
  "deliverydate",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 18,
  },
  "qtydelivered",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "deliverycomments",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QKseIgBj+p9iiKfqkeZdXQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
