#!/usr/bin/perl

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
