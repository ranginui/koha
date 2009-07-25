package Koha::Schema::LabelsProfile;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("labels_profile");
__PACKAGE__->add_columns(
  "tmpl_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "prof_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->add_unique_constraint("tmpl_id", ["tmpl_id"]);
__PACKAGE__->add_unique_constraint("prof_id", ["prof_id"]);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mRIercWvqHQKiAxg9HpeSQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
