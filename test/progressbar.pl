#!/usr/bin/perl

# Script for testing progressbar, part 1 - initial screem
# it is split into two scripts so we can use firebug to debug it

# Koha library project  www.koha.org

# Licensed under the GPL

# Copyright 2000-2002 Katipo Communications
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
#use warnings; FIXME - Bug 2505

# standard or CPAN modules used
use CGI;
use CGI::Cookie;

# Koha modules used
use C4::Context;
use C4::Auth;
use C4::Output;
use C4::BackgroundJob;

my $input = new CGI;
my $dbh = C4::Context->dbh;
$dbh->{AutoCommit} = 0;

my ($template, $loggedinuser, $cookie)
	= get_template_and_user({template_name => "test/progressbar.tmpl",
					query => $input,
					type => "intranet",
					debug => 1,
					});

output_html_with_http_headers $input, $cookie, $template->output;

exit 0;


