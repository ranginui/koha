package Koha::Schema::OpacNews;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("opac_news");
__PACKAGE__->add_columns(
  "idnew",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "title",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 250 },
  "new",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
  "lang",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 25,
  },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "expirationdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "number",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
);
__PACKAGE__->set_primary_key("idnew");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:j4V4utsc4Fhb3YTn9ki9hw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
