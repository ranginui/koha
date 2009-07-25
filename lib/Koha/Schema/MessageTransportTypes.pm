package Koha::Schema::MessageTransportTypes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("message_transport_types");
__PACKAGE__->add_columns(
  "message_transport_type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("message_transport_type");
__PACKAGE__->has_many(
  "borrower_message_transport_preferences",
  "Koha::Schema::BorrowerMessageTransportPreferences",
  {
    "foreign.message_transport_type" => "self.message_transport_type",
  },
);
__PACKAGE__->has_many(
  "message_queues",
  "Koha::Schema::MessageQueue",
  {
    "foreign.message_transport_type" => "self.message_transport_type",
  },
);
__PACKAGE__->has_many(
  "message_transports",
  "Koha::Schema::MessageTransports",
  {
    "foreign.message_transport_type" => "self.message_transport_type",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sVKiWWdE3icCEDa4V7DMzA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
