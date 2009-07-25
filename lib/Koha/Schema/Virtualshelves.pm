package Koha::Schema::Virtualshelves;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("virtualshelves");
__PACKAGE__->add_columns(
  "shelfnumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "shelfname",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "owner",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "category",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 1 },
  "sortfield",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "lastmodified",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("shelfnumber");
__PACKAGE__->has_many(
  "virtualshelfcontents",
  "Koha::Schema::Virtualshelfcontents",
  { "foreign.shelfnumber" => "self.shelfnumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wbiGGSFSB6Vk7m+mBtkUOA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
