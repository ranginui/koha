package Koha::Schema::LanguageScriptMapping;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("language_script_mapping");
__PACKAGE__->add_columns(
  "language_subtag",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "script_subtag",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uO++elCbTFVm5VUGlHTzkQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
