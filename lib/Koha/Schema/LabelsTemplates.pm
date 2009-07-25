package Koha::Schema::LabelsTemplates;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("labels_templates");
__PACKAGE__->add_columns(
  "tmpl_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "tmpl_code",
  { data_type => "CHAR", default_value => "", is_nullable => 1, size => 100 },
  "tmpl_desc",
  { data_type => "CHAR", default_value => "", is_nullable => 1, size => 100 },
  "page_width",
  { data_type => "FLOAT", default_value => 0, is_nullable => 1, size => 32 },
  "page_height",
  { data_type => "FLOAT", default_value => 0, is_nullable => 1, size => 32 },
  "label_width",
  { data_type => "FLOAT", default_value => 0, is_nullable => 1, size => 32 },
  "label_height",
  { data_type => "FLOAT", default_value => 0, is_nullable => 1, size => 32 },
  "topmargin",
  { data_type => "FLOAT", default_value => 0, is_nullable => 1, size => 32 },
  "leftmargin",
  { data_type => "FLOAT", default_value => 0, is_nullable => 1, size => 32 },
  "cols",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 2 },
  "rows",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 2 },
  "colgap",
  { data_type => "FLOAT", default_value => 0, is_nullable => 1, size => 32 },
  "rowgap",
  { data_type => "FLOAT", default_value => 0, is_nullable => 1, size => 32 },
  "active",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 1 },
  "units",
  { data_type => "CHAR", default_value => "PX", is_nullable => 1, size => 20 },
  "fontsize",
  { data_type => "INT", default_value => 3, is_nullable => 0, size => 4 },
  "font",
  { data_type => "CHAR", default_value => "TR", is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("tmpl_id");
__PACKAGE__->has_many(
  "printers_profiles",
  "Koha::Schema::PrintersProfile",
  { "foreign.tmpl_id" => "self.tmpl_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aH9/kRM1dCufEpy83Lvegg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
