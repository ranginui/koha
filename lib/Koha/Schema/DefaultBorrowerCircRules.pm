package Koha::Schema::DefaultBorrowerCircRules;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("default_borrower_circ_rules");
__PACKAGE__->add_columns(
  "categorycode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "maxissueqty",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("categorycode");
__PACKAGE__->belongs_to(
  "categorycode",
  "Koha::Schema::Categories",
  { categorycode => "categorycode" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H989P6/rIVPkhJHzTBz9CA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
