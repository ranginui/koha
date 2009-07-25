package Koha::Schema::TagsAll;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tags_all");
__PACKAGE__->add_columns(
  "tag_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "borrowernumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "biblionumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "term",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "language",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 4 },
  "date_created",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("tag_id");
__PACKAGE__->belongs_to(
  "biblionumber",
  "Koha::Schema::Biblio",
  { biblionumber => "biblionumber" },
);
__PACKAGE__->belongs_to(
  "borrowernumber",
  "Koha::Schema::Borrowers",
  { borrowernumber => "borrowernumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vDufEvbqn+9eRTWBe/6lhw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
