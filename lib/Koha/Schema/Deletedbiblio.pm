package Koha::Schema::Deletedbiblio;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("deletedbiblio");
__PACKAGE__->add_columns(
  "biblionumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "frameworkcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 4 },
  "author",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "title",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "unititle",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "notes",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "serial",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "seriestitle",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "copyrightdate",
  {
    data_type => "SMALLINT",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "datecreated",
  { data_type => "DATE", default_value => undef, is_nullable => 0, size => 10 },
  "abstract",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
);
__PACKAGE__->set_primary_key("biblionumber");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sqWlnOKHv+Z05LWIRm1/Hg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
