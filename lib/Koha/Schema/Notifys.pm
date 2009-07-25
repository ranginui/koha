package Koha::Schema::Notifys;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("notifys");
__PACKAGE__->add_columns(
  "notify_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "borrowernumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "itemnumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "notify_date",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "notify_send_date",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "notify_level",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 1 },
  "method",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 20 },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r2cxkpkhGT5mVBg/iWvldg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
