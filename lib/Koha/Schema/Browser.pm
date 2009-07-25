package Koha::Schema::Browser;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("browser");
__PACKAGE__->add_columns(
  "level",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "classification",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "number",
  { data_type => "BIGINT", default_value => undef, is_nullable => 0, size => 20 },
  "endnode",
  { data_type => "TINYINT", default_value => undef, is_nullable => 0, size => 4 },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0OYw4YaS3uU0jRDAcqvRzg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
