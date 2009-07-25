package Koha::Schema::AuthTypes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("auth_types");
__PACKAGE__->add_columns(
  "authtypecode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "authtypetext",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "auth_tag_to_report",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 3 },
  "summary",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 16777215,
  },
);
__PACKAGE__->set_primary_key("authtypecode");
__PACKAGE__->has_many(
  "auth_tag_structures",
  "Koha::Schema::AuthTagStructure",
  { "foreign.authtypecode" => "self.authtypecode" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pvJInyVUMeM7+B0jaPwi8A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
