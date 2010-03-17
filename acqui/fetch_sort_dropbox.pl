#!/usr/bin/perl

# Copyright 2008-2009 BibLibre SARL
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
use CGI;
use C4::Context;
use C4::Output;
use C4::Auth;
use C4::Budgets;

=head1

fetch_sort_dropbox : 

=cut

my $input = new CGI;

my $budget_id = $input->param('budget_id');
my $sort_id   = $input->param('sort');

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {   template_name   => "acqui/ajax.tmpl", # FIXME: REMOVE TMPL DEP?
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired => {editcatalogue => 'edit_catalogue'},
        debug => 0,
    }
);

my $sort_dropbox;
my $budget = GetBudget($budget_id);

if ( $sort_id == 1 ) {
    $sort_dropbox = GetAuthvalueDropbox( 'sort1', $budget->{'sort1_authcat'}, '' );
} elsif ( $sort_id == 2 ) {
    $sort_dropbox = GetAuthvalueDropbox( 'sort2', $budget->{'sort2_authcat'}, '' );
}

#strip off select tags ;/
$sort_dropbox =~ s/^\<select.*?\"\>//;
$sort_dropbox =~ s/\<\/select\>$//;
chomp $sort_dropbox;

$template->param( return => $sort_dropbox );
output_html_with_http_headers $input, $cookie, $template->output;
1;
