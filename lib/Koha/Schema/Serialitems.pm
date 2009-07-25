package Koha::Schema::Serialitems;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("serialitems");
__PACKAGE__->add_columns(
  "itemnumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "serialid",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->add_unique_constraint("serialitemsidx", ["itemnumber"]);
__PACKAGE__->belongs_to("serialid", "Koha::Schema::Serial", { serialid => "serialid" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DondAThQxierWFbK53sFQw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
