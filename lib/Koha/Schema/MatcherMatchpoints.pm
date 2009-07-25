package Koha::Schema::MatcherMatchpoints;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("matcher_matchpoints");
__PACKAGE__->add_columns(
  "matcher_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "matchpoint_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->belongs_to(
  "matcher_id",
  "Koha::Schema::MarcMatchers",
  { matcher_id => "matcher_id" },
);
__PACKAGE__->belongs_to(
  "matchpoint_id",
  "Koha::Schema::Matchpoints",
  { matchpoint_id => "matchpoint_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IToyjK6tzlg6obAKYdasTQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
