package Koha::Schema::Patronimage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("patronimage");
__PACKAGE__->add_columns(
  "cardnumber",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 16,
  },
  "mimetype",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 15,
  },
  "imagefile",
  {
    data_type => "MEDIUMBLOB",
    default_value => undef,
    is_nullable => 0,
    size => 16777215,
  },
);
__PACKAGE__->set_primary_key("cardnumber");
__PACKAGE__->belongs_to(
  "cardnumber",
  "Koha::Schema::Borrowers",
  { cardnumber => "cardnumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oOCh2gzFJPUx+LzF1LVoOg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
