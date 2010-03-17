#!/usr/bin/perl
#
# Copyright 2009 LibLime
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
use C4::Service;
use C4::Members;

my ($query, $response) = C4::Service->init(circulate => 'circulate_remaining_permissions');

unless (C4::Context->preference('WebBasedSelfCheck')) {
    print $query->header(status => '403 Forbidden - web-based self-check not enabled');
    exit;
}
unless (C4::Context->preference('ShowPatronImageInWebBasedSelfCheck')) {
    print $query->header(status => '403 Forbidden - displaying patron images in self-check not enabled');
    exit;
}

my ($cardnumber) = C4::Service->require_params('cardnumber');

my ($imagedata, $dberror) = GetPatronImage($cardnumber);

if ($dberror) {
    print $query->header(status => '500 internal error');
}

if ($imagedata) {
    print $query->header(-type => $imagedata->{'mimetype'}, 
                         -Content_Length => length ($imagedata->{'imagefile'})), 
          $imagedata->{'imagefile'};
} else {
    print $query->header(status => '404 patron image not found');
}
