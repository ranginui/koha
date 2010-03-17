#!/usr/bin/perl


#written 18/1/2000 by chris@katipo.co.nz
#script to renew items from the web


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
use warnings;
use CGI;
use C4::Circulation;
use C4::Auth;
use C4::Dates qw/format_date_in_iso/;
use C4::Context;
use C4::Members;
use C4::Items;
use JSON;
use C4::Reserves;
my $input = new CGI;

#Set Up User_env
# And assures user is loggedin  and has correct accreditations.

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "members/moremember.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { borrowers => 1 },
        debug           => 1,
    }
);

#
# find items to renew, all items or a selection of items
#

my @data;
if ($input->param('renew_all')) {
    @data = $input->param('all_items[]');
}
else {
    @data = $input->param('items[]');
}

my @barcodes;
if ($input->param('return_all')) {
    @barcodes = $input->param('all_barcodes[]');
} else {
    @barcodes = $input->param('barcodes[]');
}

my $branch=$input->param('branch');
my $datedue;
if ($input->param('newduedate')){
    $datedue=C4::Dates->new($input->param('newduedate'));
}

# warn "barcodes : @barcodes";
#
# renew items
#
my $cardnumber = $input->param("cardnumber");
my $borrowernumber = $input->param("borrowernumber");
my $exemptfine = $input->param("exemptfine") || 0;
my $override_limit = $input->param("override_limit") || 0;
my $failedrenews;
foreach my $itemno (@data) {
    # check status before renewing issue
	my ($renewokay,$error) = CanBookBeRenewed($borrowernumber,$itemno);
    if ($renewokay||$override_limit){
        AddRenewal($borrowernumber,$itemno,$branch,$datedue);
    }
	else {
		$failedrenews.="&failedrenew=$itemno&renewerror=".encode_json($error);
	}
}
my $failedreturn;
foreach my $barcode (@barcodes) {
    # check status before renewing issue
   my ( $returned, $messages, $issueinformation, $borrower ) = 
    AddReturn($barcode, $branch, $exemptfine);
    my $itemnumber=GetItemnumberFromBarcode($barcode);
    if ($returned){
        if (my ($reservetype,$reserve)=C4::Reserves::CheckReserves(undef,$barcode)){
            if ($reservetype eq "Waiting" || $reservetype eq "Reserved"){
                my $transfer=C4::Context->userenv->{branch} ne $reserve->{branchcode};
                ModReserveAffect($itemnumber,$reserve->{borrowernumber},$transfer);
                my ( $message_reserve, $nextreservinfo ) = GetOtherReserves($itemnumber);

                my ($borr) = GetMemberDetails( $nextreservinfo, 0 );
                my $name   = $borr->{'surname'} . ", " . $borr->{'title'} . " " . $borr->{'firstname'};
                if ( $message_reserve->{'transfert'} ) {
                    $messages->{more}={
                        itemtitle      => $reserve->{'title'},
                        itembiblionumber => $reserve->{'biblionumber'},
                        iteminfo       => $reserve->{'author'},
                        tobranchname   => GetBranchName($messages->{'transfert'}),
                        name           => $name,
                        borrowernumber => $borrowernumber,
                        borcnum        => $borr->{'cardnumber'},
                        borfirstname   => $borr->{'firstname'},
                        borsurname     => $borr->{'surname'},
                        diffbranch     => 1,
                    };
                }
                
            }
        }
    }
    if (!$returned ||$messages){
        $failedreturn.="&failedreturn=$barcode&returnerror=".encode_json($messages);
    }
}

#
# redirection to the referrer page
#
if ($input->param('destination') eq "circ"){
    warn ($failedreturn);
    print $input->redirect(
        '/cgi-bin/koha/circ/circulation.pl?findborrower='.$cardnumber.$failedrenews.$failedreturn
    );
}
else {
    print $input->redirect(
        '/cgi-bin/koha/members/moremember.pl?borrowernumber='.$borrowernumber.$failedrenews.$failedreturn
    );
}
