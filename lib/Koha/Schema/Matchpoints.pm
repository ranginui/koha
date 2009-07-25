package Koha::Schema::Matchpoints;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("matchpoints");
__PACKAGE__->add_columns(
  "matcher_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "matchpoint_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "search_index",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 30 },
  "score",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("matchpoint_id");
__PACKAGE__->has_many(
  "matchchecks_source_matchpoint_ids",
  "Koha::Schema::Matchchecks",
  { "foreign.source_matchpoint_id" => "self.matchpoint_id" },
);
__PACKAGE__->has_many(
  "matchchecks_target_matchpoint_ids",
  "Koha::Schema::Matchchecks",
  { "foreign.target_matchpoint_id" => "self.matchpoint_id" },
);
__PACKAGE__->has_many(
  "matcher_matchpoints",
  "Koha::Schema::MatcherMatchpoints",
  { "foreign.matchpoint_id" => "self.matchpoint_id" },
);
__PACKAGE__->has_many(
  "matchpoint_components",
  "Koha::Schema::MatchpointComponents",
  { "foreign.matchpoint_id" => "self.matchpoint_id" },
);
__PACKAGE__->belongs_to(
  "matcher_id",
  "Koha::Schema::MarcMatchers",
  { matcher_id => "matcher_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:x17bTwyASp+lmmiF/cO+tw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
