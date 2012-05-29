#!/usr/bin/perl

# Copyright 2012 Catalyst IT
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
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# This is script is to create a batch of MARC records that have been added to Koha in a set period
# Then email the file to a designated email

use strict;
use warnings;
use DateTime;
use C4::RecordExporter;

BEGIN {

    # find Koha's Perl modules
    # test carefully before changing this
    use FindBin;
    eval { require "$FindBin::Bin/../kohalib.pl" };
}

use Getopt::Long;
use Pod::Usage;

my ( $help, $days, $months, $verbose, $lost, $address );
GetOptions(
    'help|?'    => \$help,
    'days=s'    => \$days,
    'months=s'  => \$months,
    'v'         => \$verbose,
    'lost'     => \$lost,
    'address=s' => \$address,
);

if ( $help or (not $days and not $months) or not $address ) {
    print <<EOF
    This script creates an emails a batch of marc records that have been deleted from Koha in a set period of time
    Parameters :
    --help|-? This message
    -v Verbose, output biblionumbers of records that can't be parsed
    --days TTT to define the age of marc records to export
    --months TTT to define the age of marc records to export eg -months 1 will export any created in the last calendar month
    --address TTT to define the email address to send the file too
    --lost if this is set, also export biblio where all items are lost
     example :
     export PERL5LIB=/path/to/koha;export KOHA_CONF=/etc/koha/koha-conf.xml;./newly_deleted_records --days 30 --address chrisc\@catalyst.net.nz --lost
EOF
      ;
    exit;
}



my $date = DateTime->now();
if ($days) {
    $date->subtract( days => $days );
}
elsif ($months) {
    $date->set_day(1);
    $date->subtract( months => $months );
}

export_and_mail_deleted($date,$address,$verbose,$lost );
