#!/usr/bin/perl

use strict;
use warnings;
use C4::Context;
use Koha::DataObject::Borrower;

my $context = C4::Context->new();

my $borrower = Koha::DataObject::Borrower->new_by_primary_key($context,1);