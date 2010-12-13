#!/usr/bin/perl -w

# Copyright 2010 Biblibre SARL
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

use strict;
use warnings;
use utf8;

BEGIN {

    # find Koha's Perl modules
    # test carefully before changing this
    use FindBin;
    eval { require "$FindBin::Bin/../kohalib.pl" };
}

use Getopt::Long;
use Pod::Usage;
use C4::Letters;

my ($help);

GetOptions(
    'help|?'         => \$help
);

if($help){
    print <<EOF
    This script delete message without subject nor content.
    It has to be run before sending messages.
    Parameters :
    -help|? This message

     example :
     export PERL5LIB=/path/to/koha;export KOHA_CONF=/etc/koha/koha-conf.xml;./purge_message_queue.pl
EOF
;
    exit;
}

DelEmptyMessages();

