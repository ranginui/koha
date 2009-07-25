package Koha::Schema::TagsApproval;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tags_approval");
__PACKAGE__->add_columns(
  "term",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "approved",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 1 },
  "date_approved",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "approved_by",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "weight_total",
  { data_type => "INT", default_value => 1, is_nullable => 0, size => 9 },
);
__PACKAGE__->set_primary_key("term");
__PACKAGE__->belongs_to(
  "approved_by",
  "Koha::Schema::Borrowers",
  { borrowernumber => "approved_by" },
);
__PACKAGE__->has_many(
  "tags_indexes",
  "Koha::Schema::TagsIndex",
  { "foreign.term" => "self.term" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BGqUDxqL7pJ4YN0jR9TuOg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
