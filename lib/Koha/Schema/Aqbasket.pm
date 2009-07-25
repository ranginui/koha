package Koha::Schema::Aqbasket;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("aqbasket");
__PACKAGE__->add_columns(
  "basketno",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "creationdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "closedate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "booksellerid",
  { data_type => "INT", default_value => 1, is_nullable => 0, size => 11 },
  "authorisedby",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "booksellerinvoicenumber",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
);
__PACKAGE__->set_primary_key("basketno");
__PACKAGE__->belongs_to(
  "booksellerid",
  "Koha::Schema::Aqbooksellers",
  { id => "booksellerid" },
);
__PACKAGE__->has_many(
  "aqorders",
  "Koha::Schema::Aqorders",
  { "foreign.basketno" => "self.basketno" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Wm4/BxtrYMKDAi4W7UiUhQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
