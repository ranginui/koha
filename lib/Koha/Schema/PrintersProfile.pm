package Koha::Schema::PrintersProfile;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("printers_profile");
__PACKAGE__->add_columns(
  "prof_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "printername",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 40,
  },
  "tmpl_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "paper_bin",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "offset_horz",
  { data_type => "FLOAT", default_value => undef, is_nullable => 1, size => 32 },
  "offset_vert",
  { data_type => "FLOAT", default_value => undef, is_nullable => 1, size => 32 },
  "creep_horz",
  { data_type => "FLOAT", default_value => undef, is_nullable => 1, size => 32 },
  "creep_vert",
  { data_type => "FLOAT", default_value => undef, is_nullable => 1, size => 32 },
  "unit",
  { data_type => "CHAR", default_value => "POINT", is_nullable => 0, size => 20 },
);
__PACKAGE__->set_primary_key("prof_id");
__PACKAGE__->add_unique_constraint("printername", ["printername", "tmpl_id", "paper_bin"]);
__PACKAGE__->belongs_to(
  "tmpl_id",
  "Koha::Schema::LabelsTemplates",
  { tmpl_id => "tmpl_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KNAFUqTcFiovW75s/F+TpQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
