package Koha::Schema::Reviews;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("reviews");
__PACKAGE__->add_columns(
  "reviewid",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "borrowernumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "biblionumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "review",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "approved",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 4 },
  "datereviewed",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("reviewid");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1GUqCYkwlzu/TnGzzQiPiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
