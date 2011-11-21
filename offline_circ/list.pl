#!/usr/bin/perl

# 2009 BibLibre <jeanandre.santoni@biblibre.com>

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

use CGI;
use C4::Output;
use C4::Auth;
use C4::Koha;
use C4::Context;
use C4::Circulation;
use C4::Branch;
use C4::Members;
use C4::Biblio;

my $query = CGI->new;

my ($template, $loggedinuser, $cookie) = get_template_and_user({ 
    template_name => "offline_circ/list.tmpl",
    query => $query,
    type => "intranet",
    authnotrequired => 0,
    flagsrequired   => { circulate => "circulate_remaining_permissions" },
});

my $operations = GetOfflineOperations;

for (@$operations) {
	$_->{'cardnumber'} = 0 . $_->{'cardnumber'} if length($_->{'cardnumber'}) == 15;
	$_->{'cardnumber'} = 00 . $_->{'cardnumber'} if length($_->{'cardnumber'}) == 14;
	$_->{'cardnumber'} =~ s/00000000([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/00000000$4$3$2$1/i;

	my $biblio             = GetBiblioFromItemNumber(undef, $_->{'barcode'});
	$_->{'bibliotitle'}    = $biblio->{'title'};
	$_->{'biblionumber'}   = $biblio->{'biblionumber'};
	my $borrower           = GetMemberDetails(undef,$cardnumber);
	$_->{'borrowernumber'} = $borrower->{'borrowernumber'};
	$_->{'borrower'}       = join(' ', $borrower->{'firstname'}, $borrower->{'surname'});
	$_->{'actionissue'}    = $_->{'action'} eq 'issue';
	$_->{'actionreturn'}   = $_->{'action'} eq 'return';
}

$template->param(operations => $operations);

output_html_with_http_headers $query, $cookie, $template->output;
