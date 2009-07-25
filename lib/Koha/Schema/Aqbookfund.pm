package Koha::Schema::Aqbookfund;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("aqbookfund");
__PACKAGE__->add_columns(
  "bookfundid",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "bookfundname",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "bookfundgroup",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 5 },
  "branchcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("bookfundid", "branchcode");
__PACKAGE__->has_many(
  "aqorderbreakdowns",
  "Koha::Schema::Aqorderbreakdown",
  { "foreign.bookfundid" => "self.bookfundid" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2J5I/L+6H5jOAaQhOMcRXw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
