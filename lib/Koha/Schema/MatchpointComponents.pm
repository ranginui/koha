package Koha::Schema::MatchpointComponents;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("matchpoint_components");
__PACKAGE__->add_columns(
  "matchpoint_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "matchpoint_component_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "sequence",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "tag",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 3 },
  "subfields",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 40 },
  "offset",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 4 },
  "length",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("matchpoint_component_id");
__PACKAGE__->has_many(
  "matchpoint_component_norms",
  "Koha::Schema::MatchpointComponentNorms",
  {
    "foreign.matchpoint_component_id" => "self.matchpoint_component_id",
  },
);
__PACKAGE__->belongs_to(
  "matchpoint_id",
  "Koha::Schema::Matchpoints",
  { matchpoint_id => "matchpoint_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZyNXvDwe0jbam1wSegY4+Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
