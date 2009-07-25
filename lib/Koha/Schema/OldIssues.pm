package Koha::Schema::OldIssues;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("old_issues");
__PACKAGE__->add_columns(
  "borrowernumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "itemnumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "date_due",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "branchcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "issuingbranch",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 18,
  },
  "returndate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "lastreneweddate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "return",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 4 },
  "renewals",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 4 },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "issuedate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
);
__PACKAGE__->belongs_to(
  "borrowernumber",
  "Koha::Schema::Borrowers",
  { borrowernumber => "borrowernumber" },
);
__PACKAGE__->belongs_to(
  "itemnumber",
  "Koha::Schema::Items",
  { itemnumber => "itemnumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mq98Cv4cUlUzs2MX4EIKpQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
