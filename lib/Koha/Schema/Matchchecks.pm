package Koha::Schema::Matchchecks;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("matchchecks");
__PACKAGE__->add_columns(
  "matcher_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "matchcheck_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "source_matchpoint_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "target_matchpoint_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("matchcheck_id");
__PACKAGE__->belongs_to(
  "matcher_id",
  "Koha::Schema::MarcMatchers",
  { matcher_id => "matcher_id" },
);
__PACKAGE__->belongs_to(
  "source_matchpoint_id",
  "Koha::Schema::Matchpoints",
  { matchpoint_id => "source_matchpoint_id" },
);
__PACKAGE__->belongs_to(
  "target_matchpoint_id",
  "Koha::Schema::Matchpoints",
  { matchpoint_id => "target_matchpoint_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lKizbhUeQ2DkxgN7eLNDZw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
