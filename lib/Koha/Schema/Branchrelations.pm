package Koha::Schema::Branchrelations;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("branchrelations");
__PACKAGE__->add_columns(
  "branchcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "categorycode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("branchcode", "categorycode");
__PACKAGE__->belongs_to(
  "branchcode",
  "Koha::Schema::Branches",
  { branchcode => "branchcode" },
);
__PACKAGE__->belongs_to(
  "categorycode",
  "Koha::Schema::Branchcategories",
  { categorycode => "categorycode" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:y20fZSMlwsilcEzSkaGA7Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
