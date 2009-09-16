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

#use constant DEBUG => 0;

my $query = CGI->new;

my ($template, $loggedinuser, $cookie)
  = get_template_and_user( { template_name => "offline_circ/process_pending.tmpl",
				query => $query,
				type => "intranet",
				authnotrequired => 0,
				 flagsrequired   => { circulate => "circulate_remaining_permissions" },
				});

my $operations = GetOfflineOperations;

for (@$operations) {
	$_->{'branch'} = GetBranchName($_->{'branchcode'});
	my $biblio = GetBiblioFromItemNumber(undef, $_->{'barcode'});
	$_->{'bibliotitle'} = $biblio->{'title'};
	my $borrower = GetMemberDetails(undef,$_->{'cardnumber'});
	$_->{'borrower'} = $borrower->{'firstname'}.' '.$borrower->{'surname'};
	warn Data::Dumper::Dumper($_);
}

$template->param(operations => $operations);

output_html_with_http_headers $query, $cookie, $template->output;

