package Koha::Schema::BorrowerMessagePreferences;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("borrower_message_preferences");
__PACKAGE__->add_columns(
  "borrower_message_preference_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "borrowernumber",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "categorycode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "message_attribute_id",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 11 },
  "days_in_advance",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 11 },
  "wants_digest",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("borrower_message_preference_id");
__PACKAGE__->belongs_to(
  "borrowernumber",
  "Koha::Schema::Borrowers",
  { borrowernumber => "borrowernumber" },
);
__PACKAGE__->belongs_to(
  "message_attribute_id",
  "Koha::Schema::MessageAttributes",
  { message_attribute_id => "message_attribute_id" },
);
__PACKAGE__->belongs_to(
  "categorycode",
  "Koha::Schema::Categories",
  { categorycode => "categorycode" },
);
__PACKAGE__->has_many(
  "borrower_message_transport_preferences",
  "Koha::Schema::BorrowerMessageTransportPreferences",
  {
    "foreign.borrower_message_preference_id" => "self.borrower_message_preference_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:caaWtK28ZTcd6KSlOyapoQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
