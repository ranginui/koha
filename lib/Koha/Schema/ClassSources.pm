package Koha::Schema::ClassSources;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("class_sources");
__PACKAGE__->add_columns(
  "cn_source",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "description",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "used",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 4 },
  "class_sort_rule",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("cn_source");
__PACKAGE__->add_unique_constraint("cn_source_idx", ["cn_source"]);
__PACKAGE__->belongs_to(
  "class_sort_rule",
  "Koha::Schema::ClassSortRules",
  { class_sort_rule => "class_sort_rule" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zMcYTr1Z/fvbWwaODmLT1Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
