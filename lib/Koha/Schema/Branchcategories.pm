package Koha::Schema::Branchcategories;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("branchcategories");
__PACKAGE__->add_columns(
  "categorycode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "categoryname",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "codedescription",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "categorytype",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
);
__PACKAGE__->set_primary_key("categorycode");
__PACKAGE__->has_many(
  "branchrelations",
  "Koha::Schema::Branchrelations",
  { "foreign.categorycode" => "self.categorycode" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jBFCymwjqcA+ilYPUI3Ulw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
