#!/usr/bin/perl

# Copyright Catalyst IT 2011

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
#

use strict;
use LWP::Simple;
use warnings;
use CGI;

my $cgi        = new CGI;
my $image_type = 'jpeg';

my $id   = $cgi->param('id');
my $type = $cgi->param('type');
my $size = $cgi->param('size');
my $url;

if ( $type eq 'amazon' ) {
    $url = "http://images.amazon.com/images/P/$id.01.TZZZZZZZ.jpg";
    if ( $size eq 'medium' ) {
        $url = "http://images.amazon.com/images/P/$id.01.MZZZZZZZ.jpg";
    }
    elsif ( $size eq 'shelfbrowse' ) {
        $url = "http://images.amazon.com/images/P/$id.01._AA75_PU_PU-5_.jpg";
    }
    elsif ( $size eq 'large' ) {
        $url =
          "http://images.amazon.com/images/P/$id.01._THUMBZZZ_PB_PU_PU0_.jpg";
    }
}

print $cgi->header(
    -type    => "image/$image_type",
    -expires => "+100d"
);

# print $cgi->header;
# print $url;
# binmode;
my $content = get($url);
print $content;
