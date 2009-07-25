package Koha::Schema::MatchpointComponentNorms;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("matchpoint_component_norms");
__PACKAGE__->add_columns(
  "matchpoint_component_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "sequence",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "norm_routine",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 50 },
);
__PACKAGE__->belongs_to(
  "matchpoint_component_id",
  "Koha::Schema::MatchpointComponents",
  { "matchpoint_component_id" => "matchpoint_component_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uMO2y+MpfSc+gbYnMWE7rQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
