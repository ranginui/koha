package Koha::Schema::MarcMatchers;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marc_matchers");
__PACKAGE__->add_columns(
  "matcher_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "code",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "description",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "record_type",
  {
    data_type => "VARCHAR",
    default_value => "biblio",
    is_nullable => 0,
    size => 10,
  },
  "threshold",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("matcher_id");
__PACKAGE__->has_many(
  "matchchecks",
  "Koha::Schema::Matchchecks",
  { "foreign.matcher_id" => "self.matcher_id" },
);
__PACKAGE__->has_many(
  "matcher_matchpoints",
  "Koha::Schema::MatcherMatchpoints",
  { "foreign.matcher_id" => "self.matcher_id" },
);
__PACKAGE__->has_many(
  "matchpoints",
  "Koha::Schema::Matchpoints",
  { "foreign.matcher_id" => "self.matcher_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jsc7UHPgtIOvD0MHr3uITg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
