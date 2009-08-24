#!/usr/bin/perl
#-----------------------------------
# Copyright 2009 PTFS Inc.
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA
#-----------------------------------

=head1 NAME

cart_to_shelf.pl  cron script to set items with location of CART to original shelving location after X hours.
                  Execute without options for help.

=cut

use strict;
use warnings;

BEGIN {

    # find Koha's Perl modules
    # test carefully before changing this
    use FindBin;
    eval { require "$FindBin::Bin/../kohalib.pl" };
}
use C4::Context;
use Getopt::Long;

my $hours = 0;

GetOptions( 'h|hours=s' => \$hours, );

my $usage = << 'ENDUSAGE';
longoverdue.pl : This cron script will set any item of the location CART ( Shelving Cart ) to it's original shelving location
                 after the given numer of hours has passed.

This script takes the following parameters :

    --hours | -h         The number of hours that need to pass before the location is updated.

  examples :
  $PERL5LIB/misc/cronjobs/cart_to_shelf.pl --hours 24
    Would make any item that has a location of CART for more than 24 hours change to it's original shelving location.

ENDUSAGE

unless ($hours) {
    print $usage;
    die "ERROR: No --hours (-h) option defined";
}

my $query =
"UPDATE items SET location = permanent_location WHERE location = 'CART' AND TIMESTAMPDIFF(HOUR, items.timestamp, NOW() ) > ?";

my $dbh = C4::Context->dbh;
my $sth = $dbh->prepare($query);
$sth->execute($hours);
