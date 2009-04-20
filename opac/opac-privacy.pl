#!/usr/bin/perl
# This script lets the users change their privacy rules
#
# copyright 2009, BibLibre, paul.poulain@biblibre.com
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
use CGI;

use C4::Auth;    # checkauth, getborrowernumber.
use C4::Context;
use C4::Circulation;
use C4::Members;
use C4::Output;

my $query = new CGI;
my $dbh   = C4::Context->dbh;

my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => "opac-privacy.tmpl",
        query           => $query,
        type            => "opac",
        authnotrequired => 0,
        flagsrequired   => { borrow => 1 },
        debug           => 1,
    }
);

my $op = $query->param("op");

# get borrower privacy ....
my ( $borr ) = GetMemberDetails( $borrowernumber );
if ($op eq "update_privacy")
{
    ModPrivacy($borrowernumber,$query->param('privacy'));
    $template->param('privacy_updated' => 1);
}
if ($op eq "delete_record") { 
    # delete all reading records. The hardcoded date should never be reached
    # even if Koha is a long leaving project ;-)
    AnonymiseIssueHistory('2999-31-12',$borrowernumber);
    # confirm the user the deletion has been done
    $template->param('deleted' => 1);
}
$template->param( 'Ask_data'       => '1',
                    'privacy'.$borr->{'privacy'} => 1,
                    'firstname' => $borr->{'firstname'},
                    'surname' => $borr->{'surname'},
                    'privacyview' => 1,
);

output_html_with_http_headers $query, $cookie, $template->output;