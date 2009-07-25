package Koha::Schema::BiblioFramework;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("biblio_framework");
__PACKAGE__->add_columns(
  "frameworkcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 4 },
  "frameworktext",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("frameworkcode");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3r5RVx22RWGk+dlIvJUmcg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
