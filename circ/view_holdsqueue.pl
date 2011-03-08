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


=head1 view_holdsqueue

This script displays items in the tmp_holdsqueue table

=cut

use strict;
use warnings;
use CGI;
use C4::Auth;
use C4::Output;
use C4::Biblio;
use C4::Items;
use C4::Koha;   # GetItemTypes
use C4::Branch; # GetBranches
use C4::Dates qw/format_date/;

my $query = new CGI;
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "circ/view_holdsqueue.tmpl",
        query           => $query,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { circulate => "circulate_remaining_permissions" },
        debug           => 1,
    }
);

my $params = $query->Vars;
my $run_report     = $params->{'run_report'};
my $branchlimit    = $params->{'branchlimit'};
my $itemtypeslimit = $params->{'itemtypeslimit'};

if ( $run_report ) {
    my $items = GetHoldsQueueItems($branchlimit, $itemtypeslimit);
    $template->param(
        branch     => $branchlimit,
        total      => scalar @$items,
        itemsloop  => $items,
        run_report => $run_report,
        dateformat => C4::Context->preference("dateformat"),
    );
}

# getting all itemtypes
my $itemtypes = &GetItemTypes();
my @itemtypesloop;
foreach my $thisitemtype ( sort keys %$itemtypes ) {
    push @itemtypesloop, {
        value       => $thisitemtype,
        description => $itemtypes->{$thisitemtype}->{'description'},
    };
}

$template->param(
     branchloop => GetBranchesLoop(C4::Context->userenv->{'branch'}),
   itemtypeloop => \@itemtypesloop,
);

sub GetHoldsQueueItems {
	my ($branchlimit,$itemtypelimit) = @_;
	my $dbh = C4::Context->dbh;

    my @bind_params = ();
	my $query = q/SELECT tmp_holdsqueue.*, biblio.author, items.ccode, items.location, items.enumchron, items.cn_sort, biblioitems.publishercode,biblio.copyrightdate,biblioitems.publicationyear,biblioitems.pages,biblioitems.size,biblioitems.publicationyear,biblioitems.isbn
                  FROM tmp_holdsqueue
                       JOIN biblio      USING (biblionumber)
				  LEFT JOIN biblioitems USING (biblionumber)
                  LEFT JOIN items       USING (  itemnumber)
                /;
    if ($branchlimit) {
	    $query .=" WHERE tmp_holdsqueue.holdingbranch = ?";
        push @bind_params, $branchlimit;
    }
    $query .= " ORDER BY ccode, location, cn_sort, author, title, pickbranch, reservedate";
	my $sth = $dbh->prepare($query);
	$sth->execute(@bind_params);
	my $items = [];
    while ( my $row = $sth->fetchrow_hashref ){
	$row->{reservedate} = format_date($row->{reservedate});
	my $record = GetMarcBiblio($row->{biblionumber});
    if ($record){
        $row->{subtitle} = GetRecordValue('subtitle',$record,'')->[0]->{subfield};
	    $row->{parts} = GetRecordValue('parts',$record,'')->[0]->{subfield};
	    $row->{numbers} = GetRecordValue('numbers',$record,'')->[0]->{subfield};
	}
        push @$items, $row;
    }
    return $items;
}
# writing the template
output_html_with_http_headers $query, $cookie, $template->output;
