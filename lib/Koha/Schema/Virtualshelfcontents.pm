package Koha::Schema::Virtualshelfcontents;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("virtualshelfcontents");
__PACKAGE__->add_columns(
  "shelfnumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "biblionumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "flags",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "dateadded",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->belongs_to(
  "biblionumber",
  "Koha::Schema::Biblio",
  { biblionumber => "biblionumber" },
);
__PACKAGE__->belongs_to(
  "shelfnumber",
  "Koha::Schema::Virtualshelves",
  { shelfnumber => "shelfnumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QEw6P45N5Rn34acjWD/Csw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
