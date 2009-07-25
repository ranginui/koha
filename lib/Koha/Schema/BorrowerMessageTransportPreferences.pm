package Koha::Schema::BorrowerMessageTransportPreferences;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("borrower_message_transport_preferences");
__PACKAGE__->add_columns(
  "borrower_message_preference_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "message_transport_type",
  { data_type => "VARCHAR", default_value => 0, is_nullable => 0, size => 20 },
);
__PACKAGE__->set_primary_key("borrower_message_preference_id", "message_transport_type");
__PACKAGE__->belongs_to(
  "borrower_message_preference_id",
  "Koha::Schema::BorrowerMessagePreferences",
  {
    "borrower_message_preference_id" => "borrower_message_preference_id",
  },
);
__PACKAGE__->belongs_to(
  "message_transport_type",
  "Koha::Schema::MessageTransportTypes",
  { "message_transport_type" => "message_transport_type" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rFg/TUJe3nX/VV2rAIPf2A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
