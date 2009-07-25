package Koha::Schema::Aqorderbreakdown;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("aqorderbreakdown");
__PACKAGE__->add_columns(
  "ordernumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "linenumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "branchcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "bookfundid",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "allocation",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
);
__PACKAGE__->belongs_to(
  "ordernumber",
  "Koha::Schema::Aqorders",
  { ordernumber => "ordernumber" },
);
__PACKAGE__->belongs_to(
  "bookfundid",
  "Koha::Schema::Aqbookfund",
  { bookfundid => "bookfundid" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/0U6lDTp7XdBzzPmOv/59g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
