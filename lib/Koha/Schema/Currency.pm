package Koha::Schema::Currency;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("currency");
__PACKAGE__->add_columns(
  "currency",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "symbol",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 5 },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "rate",
  { data_type => "FLOAT", default_value => undef, is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("currency");
__PACKAGE__->has_many(
  "aqbooksellers_listprices",
  "Koha::Schema::Aqbooksellers",
  { "foreign.listprice" => "self.currency" },
);
__PACKAGE__->has_many(
  "aqbooksellers_invoiceprices",
  "Koha::Schema::Aqbooksellers",
  { "foreign.invoiceprice" => "self.currency" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U5+wXI1YIkfIkFoKWjZhtA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
