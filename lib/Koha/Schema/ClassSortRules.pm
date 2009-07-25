package Koha::Schema::ClassSortRules;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("class_sort_rules");
__PACKAGE__->add_columns(
  "class_sort_rule",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "description",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "sort_routine",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 30 },
);
__PACKAGE__->set_primary_key("class_sort_rule");
__PACKAGE__->add_unique_constraint("class_sort_rule_idx", ["class_sort_rule"]);
__PACKAGE__->has_many(
  "class_sources",
  "Koha::Schema::ClassSources",
  { "foreign.class_sort_rule" => "self.class_sort_rule" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1J5I68HezMHUCha9vLGS0Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
