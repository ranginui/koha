package Koha::Schema::Letter;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("letter");
__PACKAGE__->add_columns(
  "module",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 20 },
  "code",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 20 },
  "name",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 100 },
  "title",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 200 },
  "content",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("module", "code");
__PACKAGE__->has_many(
  "message_transports",
  "Koha::Schema::MessageTransports",
  {
    "foreign.letter_code"   => "self.code",
    "foreign.letter_module" => "self.module",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1HbTNL4khEThXqQOUKZrFA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
