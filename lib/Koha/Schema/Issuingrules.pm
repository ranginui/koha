package Koha::Schema::Issuingrules;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("issuingrules");
__PACKAGE__->add_columns(
  "categorycode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "itemtype",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "restrictedtype",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "rentaldiscount",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
  "reservecharge",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
  "fine",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 28,
  },
  "firstremind",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "chargeperiod",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "accountsent",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "chargename",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "maxissueqty",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 4 },
  "issuelength",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 4 },
  "branchcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("branchcode", "categorycode", "itemtype");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Tebr2HEzCRsW0CFjlrU5tw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
