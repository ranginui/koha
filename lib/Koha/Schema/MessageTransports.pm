package Koha::Schema::MessageTransports;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("message_transports");
__PACKAGE__->add_columns(
  "message_attribute_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "message_transport_type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "is_digest",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "letter_module",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 20 },
  "letter_code",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 20 },
);
__PACKAGE__->set_primary_key("message_attribute_id", "message_transport_type", "is_digest");
__PACKAGE__->belongs_to(
  "message_attribute_id",
  "Koha::Schema::MessageAttributes",
  { message_attribute_id => "message_attribute_id" },
);
__PACKAGE__->belongs_to(
  "message_transport_type",
  "Koha::Schema::MessageTransportTypes",
  { "message_transport_type" => "message_transport_type" },
);
__PACKAGE__->belongs_to(
  "letter",
  "Koha::Schema::Letter",
  { code => "letter_code", module => "letter_module" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4jEctCfy8AwXrSWzZf5NJg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
