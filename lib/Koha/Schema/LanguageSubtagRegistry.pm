package Koha::Schema::LanguageSubtagRegistry;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("language_subtag_registry");
__PACKAGE__->add_columns(
  "subtag",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "added",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MCjxA5UhgSb01axA8ZqgQw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
