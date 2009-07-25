package Koha::Schema::Borrowers;

# Copyright 2009 Chris Cormack <chrisc@catalyst.net.nz>                                                                                                                   
#                                                                                                                                                                         
# This file is part of Koha.                                                                                                                                              
#                                                                                                                                                                         
# Koha is free software; you can redistribute it and/or modify it under the                                                                                               
# terms of the GNU General Public License as published by the Free Software                                                                                               
# Foundation; either version 3 of the License, or (at your option) any later                                                                                              
# version.                                                                                                                                                                
#                                                                                                                                                                         
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY                                                                                                 
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR                                                                                           
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.                                                                                             
#                                                                                                                                                                         
# You should have received a copy of the GNU General Public License along with                                                                                            
# Koha; If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("borrowers");
__PACKAGE__->add_columns(
  "borrowernumber",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "cardnumber",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "surname",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 16777215,
  },
  "firstname",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "title",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "othernames",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "initials",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "streetnumber",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "streettype",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "address",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 16777215,
  },
  "address2",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "city",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 0,
    size => 16777215,
  },
  "zipcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "email",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "phone",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "mobile",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "fax",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "emailpro",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "phonepro",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "b_streetnumber",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "b_streettype",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "b_address",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "b_city",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "b_zipcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "b_email",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "b_phone",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "dateofbirth",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "branchcode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "categorycode",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 10 },
  "dateenrolled",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "dateexpiry",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
  "gonenoaddress",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "lost",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "debarred",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
  "contactname",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "contactfirstname",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "contacttitle",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "guarantorid",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "borrowernotes",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "relationship",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "ethnicity",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "ethnotes",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "sex",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 1 },
  "password",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "flags",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "userid",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  "opacnote",
  {
    data_type => "MEDIUMTEXT",
    default_value => undef,
    is_nullable => 1,
    size => 16777215,
  },
  "contactnote",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "sort1",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "sort2",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "altcontactfirstname",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "altcontactsurname",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "altcontactaddress1",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "altcontactaddress2",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "altcontactaddress3",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "altcontactzipcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "altcontactphone",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "smsalertnumber",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("borrowernumber");
__PACKAGE__->add_unique_constraint("cardnumber", ["cardnumber"]);
__PACKAGE__->has_many(
  "accountlines",
  "Koha::Schema::Accountlines",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "accountoffsets",
  "Koha::Schema::Accountoffsets",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "borrower_attributes",
  "Koha::Schema::BorrowerAttributes",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "borrower_message_preferences",
  "Koha::Schema::BorrowerMessagePreferences",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->belongs_to(
  "categorycode",
  "Koha::Schema::Categories",
  { categorycode => "categorycode" },
);
__PACKAGE__->belongs_to(
  "branchcode",
  "Koha::Schema::Branches",
  { branchcode => "branchcode" },
);
__PACKAGE__->has_many(
  "hold_fill_targets",
  "Koha::Schema::HoldFillTargets",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "issues",
  "Koha::Schema::Issues",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "message_queues",
  "Koha::Schema::MessageQueue",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "old_issues",
  "Koha::Schema::OldIssues",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "old_reserves",
  "Koha::Schema::OldReserves",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "patroncards",
  "Koha::Schema::Patroncards",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "patronimages",
  "Koha::Schema::Patronimage",
  { "foreign.cardnumber" => "self.cardnumber" },
);
__PACKAGE__->has_many(
  "reserves",
  "Koha::Schema::Reserves",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "tags_alls",
  "Koha::Schema::TagsAll",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "tags_approvals",
  "Koha::Schema::TagsApproval",
  { "foreign.approved_by" => "self.borrowernumber" },
);
__PACKAGE__->has_many(
  "user_permissions",
  "Koha::Schema::UserPermissions",
  { "foreign.borrowernumber" => "self.borrowernumber" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ege60h1RrgqAFViVoN0Ggw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
