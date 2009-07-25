package Koha::Schema::MarcTagStructure;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marc_tag_structure");
__PACKAGE__->add_columns(
  "tagfield",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 3 },
  "liblibrarian",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "libopac",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "repeatable",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 4 },
  "mandatory",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 4 },
  "authorised_value",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "frameworkcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("frameworkcode", "tagfield");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fq75XninGex06H6cHiSWdw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
