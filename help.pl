#!/usr/bin/perl

# Copyright 2010 Koha Development team
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
use C4::Templates;
use C4::Output;
# use C4::Auth;
use C4::Context;
use CGI;

my $query = new CGI;

# find the script that called the online help using the CGI referer()
our $refer = $query->referer();

$refer =~ /koha\/(.*)\.pl/;
my $from = "modules/help/$1.tt";

my $htdocs = C4::Context->config('intrahtdocs');
my ( $theme, $lang ) = themelanguage( $htdocs, $from, "intranet", $query );
unless ( -e "$htdocs/$theme/$lang/$from" ) {
    $from = "modules/help/nohelp.tt";
    ( $theme, $lang ) = themelanguage( $htdocs, $from, "intranet", $query );
}
my $template = C4::Templates->new('intranet', "$htdocs/$theme/$lang/$from");

output_html_with_http_headers $query, "", $template->output;

