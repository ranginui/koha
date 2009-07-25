package Koha::Schema::LanguageRfc4646ToIso639;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("language_rfc4646_to_iso639");
__PACKAGE__->add_columns(
  "rfc4646_subtag",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "iso639_2_code",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zH/bwJ+Z4URJvWk1QcC2AA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
