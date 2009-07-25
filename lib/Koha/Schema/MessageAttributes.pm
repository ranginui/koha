package Koha::Schema::MessageAttributes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("message_attributes");
__PACKAGE__->add_columns(
  "message_attribute_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "message_name",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 20 },
  "takes_days",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("message_attribute_id");
__PACKAGE__->add_unique_constraint("message_name", ["message_name"]);
__PACKAGE__->has_many(
  "borrower_message_preferences",
  "Koha::Schema::BorrowerMessagePreferences",
  { "foreign.message_attribute_id" => "self.message_attribute_id" },
);
__PACKAGE__->has_many(
  "message_transports",
  "Koha::Schema::MessageTransports",
  { "foreign.message_attribute_id" => "self.message_attribute_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2sBRI4EIFD8koXTv85k8QA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
