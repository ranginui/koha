package Koha::Schema::Subscriptionhistory;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("subscriptionhistory");
__PACKAGE__->add_columns(
  "biblionumber",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "subscriptionid",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "histstartdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "enddate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "missinglist",
  {
    data_type => "LONGTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 4294967295,
  },
  "recievedlist",
  {
    data_type => "LONGTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 4294967295,
  },
  "opacnote",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 150 },
  "librariannote",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 150 },
);
__PACKAGE__->set_primary_key("subscriptionid");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P8pPnrHgKmSMzH+vKGN9tQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
