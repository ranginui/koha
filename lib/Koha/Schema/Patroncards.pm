package Koha::Schema::Patroncards;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("patroncards");
__PACKAGE__->add_columns(
  "cardid",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "batch_id",
  { data_type => "VARCHAR", default_value => 1, is_nullable => 0, size => 10 },
  "borrowernumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("cardid");
__PACKAGE__->belongs_to(
  "borrowernumber",
  "Koha::Schema::Borrowers",
  { borrowernumber => "borrowernumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KU41AE0PRNBzOdNkTUZzqQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
