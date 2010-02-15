#!/usr/bin/perl

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


use strict;
use warnings;

use CGI;
use C4::Auth;
use C4::Output;
use C4::Context;

my $query = new CGI;
my $admin = C4::Context->preference('KohaAdminEmailAddress');
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "errors/401.tmpl",
        query           => $query,
        type            => "opac",
        authnotrequired => 1,
        debug           => 1,
    }
);
$template->param( admin => $admin );
output_with_http_headers $query, $cookie, $template->output, 'html', '401 Unauthorized';
