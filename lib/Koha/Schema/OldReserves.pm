package Koha::Schema::OldReserves;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("old_reserves");
__PACKAGE__->add_columns(
  "borrowernumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "reservedate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "biblionumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "constrainttype",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 1 },
  "branchcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "notificationdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "reminderdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "cancellationdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "reservenotes",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "priority",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "found",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 1 },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "itemnumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "waitingdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
);
__PACKAGE__->belongs_to(
  "borrowernumber",
  "Koha::Schema::Borrowers",
  { borrowernumber => "borrowernumber" },
);
__PACKAGE__->belongs_to(
  "biblionumber",
  "Koha::Schema::Biblio",
  { biblionumber => "biblionumber" },
);
__PACKAGE__->belongs_to(
  "itemnumber",
  "Koha::Schema::Items",
  { itemnumber => "itemnumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TtGCZQiJ7cemS/3A9BwtRg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
