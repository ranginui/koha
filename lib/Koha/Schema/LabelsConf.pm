package Koha::Schema::LabelsConf;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("labels_conf");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "barcodetype",
  { data_type => "CHAR", default_value => "", is_nullable => 1, size => 100 },
  "title",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
  "subtitle",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
  "itemtype",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
  "barcode",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
  "dewey",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
  "classification",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 1 },
  "subclass",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
  "itemcallnumber",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
  "author",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
  "issn",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
  "isbn",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
  "startlabel",
  { data_type => "INT", default_value => 1, is_nullable => 0, size => 2 },
  "printingtype",
  { data_type => "CHAR", default_value => "BAR", is_nullable => 1, size => 32 },
  "layoutname",
  { data_type => "CHAR", default_value => "TEST", is_nullable => 0, size => 20 },
  "guidebox",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
  "active",
  { data_type => "TINYINT", default_value => 1, is_nullable => 1, size => 1 },
  "fonttype",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 10 },
  "ccode",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 4 },
  "callnum_split",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 1 },
  "text_justify",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 1 },
  "formatstring",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J67tDO0ShZLdp9n1qbh/Qg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
