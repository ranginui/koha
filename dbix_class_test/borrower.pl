#!/usr/bin/perl

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

use warnings;
use strict;

use Koha::Schema;
use C4::Context;

my $context   = C4::Context->new;
my $db_name   = $context->config("database");
my $db_host   = $context->config("hostname");
my $db_port   = $context->config("port") || '';
my $db_user   = $context->config("user");
my $db_passwd = $context->config("pass");

# MJR added or die here, as we can't work without dbh

my $schema = Koha::Schema->connect(
    "DBI:mysql:dbname=$db_name;host=$db_host;port=$db_port",
    $db_user, $db_passwd )
  or die $DBI::errstr;

my $rs = $schema->resultset('Borrowers')->search( { borrowernumber => 1 } );

my $borrower = $rs->first;

print $borrower->firstname;
