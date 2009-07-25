package Koha::Schema::HoldFillTargets;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hold_fill_targets");
__PACKAGE__->add_columns(
  "borrowernumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "biblionumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "itemnumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "source_branchcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "item_level_request",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("itemnumber");
__PACKAGE__->belongs_to(
  "borrowernumber",
  "Koha::Schema::Borrowers",
  { borrowernumber => "borrowernumber" },
);
__PACKAGE__->belongs_to(
  "biblionumber",
  "Koha::Schema::Biblio",
  { biblionumber => "biblionumber" },
);
__PACKAGE__->belongs_to(
  "itemnumber",
  "Koha::Schema::Items",
  { itemnumber => "itemnumber" },
);
__PACKAGE__->belongs_to(
  "source_branchcode",
  "Koha::Schema::Branches",
  { branchcode => "source_branchcode" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WKFKFvP14Hd2aZAJ/ka1xQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
