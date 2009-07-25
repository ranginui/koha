package Koha::Schema::TagsIndex;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tags_index");
__PACKAGE__->add_columns(
  "term",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "biblionumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "weight",
  { data_type => "INT", default_value => 1, is_nullable => 0, size => 9 },
);
__PACKAGE__->set_primary_key("term", "biblionumber");
__PACKAGE__->belongs_to(
  "biblionumber",
  "Koha::Schema::Biblio",
  { biblionumber => "biblionumber" },
);
__PACKAGE__->belongs_to("term", "Koha::Schema::TagsApproval", { term => "term" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lQ+LAMnYdW35+Bk5WryMuw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
