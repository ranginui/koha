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
use C4::Members;
use C4::Branch;
use C4::Category;

my $query = new CGI;
my $quicksearch = $query->param('quicksearch');
my $branch = $query->param('branchcode');
my ($template, $loggedinuser, $cookie);
my $template_name;

if($quicksearch){
($template, $loggedinuser, $cookie)
    = get_template_and_user({template_name => "members/member-quicksearch.tmpl",
                 query => $query,
                 type => "intranet",
                 authnotrequired => 0,
                 flagsrequired => {borrowers => 1},
                 debug => 1,
                 });
} else {
($template, $loggedinuser, $cookie)
    = get_template_and_user({template_name => "members/member.tmpl",
                 query => $query,
                 type => "intranet",
                 authnotrequired => 0,
                 flagsrequired => {borrowers => 1},
                 debug => 1,
                 });
}
my @categories=C4::Category->all;
$template->param(
    branchloop=>(defined $branch?GetBranchesLoop($branch):GetBranchesLoop()),
	categories=>\@categories,
);
$template->param( 
        "AddPatronLists_".C4::Context->preference("AddPatronLists")=> "1",
            );
my @letters = map { {letter => $_} } ( 'A' .. 'Z');
$template->param( letters => \@letters );

output_html_with_http_headers $query, $cookie, $template->output;
