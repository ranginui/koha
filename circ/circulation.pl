#!/usr/bin/perl

# written 8/5/2002 by Finlay
# script to execute issuing of books

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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA

use strict;
# use warnings;  # FIXME
use CGI;
use C4::Output;
use C4::Print;
use C4::Auth qw/:DEFAULT get_session/;
use C4::Dates qw/format_date/;
use C4::Branch; # GetBranches
use C4::Koha;   # GetPrinter
use C4::Circulation;
use C4::Members;
use C4::Biblio;
use C4::Reserves;
use C4::Context;
use CGI::Session;

use Date::Calc qw(
  Today
  Add_Delta_YM
  Add_Delta_Days
  Date_to_Days
);


#
# PARAMETERS READING
#
my $query = new CGI;

my $sessionID = $query->cookie("CGISESSID") ;
my $session = get_session($sessionID);

# branch and printer are now defined by the userenv
# but first we have to check if someone has tried to change them

my $branch = $query->param('branch');
if ($branch){
    # update our session so the userenv is updated
    $session->param('branch', $branch);
    $session->param('branchname', GetBranchName($branch));
}

my $printer = $query->param('printer');
if ($printer){
    # update our session so the userenv is updated
    $session->param('branchprinter', $printer);
}

if (!C4::Context->userenv && !$branch){
    if ($session->param('branch') eq 'NO_LIBRARY_SET'){
        # no branch set we can't issue
        print $query->redirect("/cgi-bin/koha/circ/selectbranchprinter.pl");
        exit;
    }
}

my ( $template, $loggedinuser, $cookie ) = get_template_and_user (
    {
        template_name   => 'circ/circulation.tmpl',
        query           => $query,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { circulate => 'circulate_remaining_permissions' },
    }
);

my $branches = GetBranches();

my @failedrenews = $query->param('failedrenew');    # expected to be itemnumbers 
my %renew_failed;
for (@failedrenews) { $renew_failed{$_} = 1; }

my $findborrower = $query->param('findborrower');
$findborrower =~ s|,| |g;
#$findborrower =~ s|'| |g;
my $borrowernumber = $query->param('borrowernumber');

$branch  = C4::Context->userenv->{'branch'};  
$printer = C4::Context->userenv->{'branchprinter'};


# If AutoLocation is not activated, we show the Circulation Parameters to chage settings of librarian
if (C4::Context->preference("AutoLocation") ne 1) { # FIXME: string comparison to number
    $template->param(ManualLocation => 1);
}

if (C4::Context->preference("DisplayClearScreenButton")) {
    $template->param(DisplayClearScreenButton => 1);
}

my $barcode        = $query->param('barcode') || '';
$barcode =~  s/^\s*|\s*$//g; # remove leading/trailing whitespace

$barcode = barcodedecode($barcode) if( $barcode && C4::Context->preference('itemBarcodeInputFilter'));
my $stickyduedate  = $query->param('stickyduedate') || $session->param('stickyduedate');
my $duedatespec    = $query->param('duedatespec')   || $session->param('stickyduedate');
my $issueconfirmed = $query->param('issueconfirmed');
my $cancelreserve  = $query->param('cancelreserve');
my $organisation   = $query->param('organisations');
my $print          = $query->param('print');
my $newexpiry      = $query->param('dateexpiry');
my $debt_confirmed = $query->param('debt_confirmed') || 0; # Don't show the debt error dialog twice

# Check if stickyduedate is turned off
if ( $barcode ) {
    # was stickyduedate loaded from session?
    if ( $stickyduedate && ! $query->param("stickyduedate") ) {
        $session->clear( 'stickyduedate' );
        $stickyduedate  = $query->param('stickyduedate');
        $duedatespec    = $query->param('duedatespec');
    }
}

#set up cookie.....
# my $branchcookie;
# my $printercookie;
# if ($query->param('setcookies')) {
#     $branchcookie = $query->cookie(-name=>'branch', -value=>"$branch", -expires=>'+1y');
#     $printercookie = $query->cookie(-name=>'printer', -value=>"$printer", -expires=>'+1y');
# }
#

my ($datedue,$invalidduedate,$globalduedate);

if(C4::Context->preference('globalDueDate') && (C4::Context->preference('globalDueDate') =~ C4::Dates->regexp('syspref'))){
        $globalduedate = C4::Dates->new(C4::Context->preference('globalDueDate'));
}
my $duedatespec_allow = C4::Context->preference('SpecifyDueDate');
if($duedatespec_allow){
    if ($duedatespec) {
    	if ($duedatespec =~ C4::Dates->regexp('syspref')) {
    		my $tempdate = C4::Dates->new($duedatespec);
    		if ($tempdate and $tempdate->output('iso') gt C4::Dates->new()->output('iso')) {
    			# i.e., it has to be later than today/now
    			$datedue = $tempdate;
    		} else {
    			$invalidduedate = 1;
    			$template->param(IMPOSSIBLE=>1, INVALID_DATE=>$duedatespec);
    		}
    	} else {
    		$invalidduedate = 1;
    		$template->param(IMPOSSIBLE=>1, INVALID_DATE=>$duedatespec);
    	}
    } else {
        # pass global due date to tmpl if specifyduedate is true 
        # and we have no barcode (loading circ page but not checking out)
        if($globalduedate &&  ! $barcode ){
            $duedatespec = $globalduedate->output();
            $stickyduedate = 1;
        }
    }
} else {
    $datedue = $globalduedate if ($globalduedate);
}

my $todaysdate = C4::Dates->new->output('iso');

# check and see if we should print
if ( $barcode eq '' && $print eq 'maybe' ) {
    $print = 'yes';
}

my $inprocess = ($barcode eq '') ? '' : $query->param('inprocess');
if ( $barcode eq '' && $query->param('charges') eq 'yes' ) {
    $template->param(
        PAYCHARGES     => 'yes',
        borrowernumber => $borrowernumber
    );
}

if ( $print eq 'yes' && $borrowernumber ne '' ) {
    printslip( $borrowernumber );
    $query->param( 'borrowernumber', '' );
    $borrowernumber = '';
}

#
# STEP 2 : FIND BORROWER
# if there is a list of find borrowers....
#
my $borrowerslist;
my $message;
if ($findborrower) {
    my ($count, $borrowers) = SearchMember($findborrower, 'cardnumber', 'web');
    my @borrowers = @$borrowers;
    if (C4::Context->preference("AddPatronLists")) {
        $template->param(
            "AddPatronLists_".C4::Context->preference("AddPatronLists")=> "1",
        );
        if (C4::Context->preference("AddPatronLists")=~/code/){
            my $categories = GetBorrowercategoryList;
            $categories->[0]->{'first'} = 1;
            $template->param(categories=>$categories);
        }
    }
    if ( $#borrowers == -1 ) {
        $query->param( 'findborrower', '' );
        $message = "'$findborrower'";
    }
    elsif ( $#borrowers == 0 ) {
        $query->param( 'borrowernumber', $borrowers[0]->{'borrowernumber'} );
        $query->param( 'barcode',           '' );
        $borrowernumber = $borrowers[0]->{'borrowernumber'};
    }
    else {
        $borrowerslist = \@borrowers;
    }
}

# get the borrower information.....
my $borrower;
if ($borrowernumber) {
    $borrower = GetMemberDetails( $borrowernumber, 0 );
    my ( $od, $issue, $fines ) = GetMemberIssuesAndFines( $borrowernumber );

    # Warningdate is the date that the warning starts appearing
    my (  $today_year,   $today_month,   $today_day) = Today();
    my ($warning_year, $warning_month, $warning_day) = split /-/, $borrower->{'dateexpiry'};
    my (  $enrol_year,   $enrol_month,   $enrol_day) = split /-/, $borrower->{'dateenrolled'};
    # Renew day is calculated by adding the enrolment period to today
    my (  $renew_year,   $renew_month,   $renew_day) =
      Add_Delta_YM( $enrol_year, $enrol_month, $enrol_day,
        0 , $borrower->{'enrolmentperiod'}) if ($enrol_year*$enrol_month*$enrol_day>0);
    # if the expiry date is before today ie they have expired
    if ( $warning_year*$warning_month*$warning_day==0 
        || Date_to_Days($today_year,     $today_month, $today_day  ) 
         > Date_to_Days($warning_year, $warning_month, $warning_day) )
    {
        #borrowercard expired, no issues
        $template->param(
            flagged  => "1",
            noissues => "1",
            expired     => format_date($borrower->{dateexpiry}),
            renewaldate => format_date("$renew_year-$renew_month-$renew_day")
        );
    }
    # check for NotifyBorrowerDeparture
    elsif ( C4::Context->preference('NotifyBorrowerDeparture') &&
            Date_to_Days(Add_Delta_Days($warning_year,$warning_month,$warning_day,- C4::Context->preference('NotifyBorrowerDeparture'))) <
            Date_to_Days( $today_year, $today_month, $today_day ) ) 
    {
        # borrower card soon to expire warn librarian
        $template->param("warndeparture" => format_date($borrower->{dateexpiry}),
        flagged       => "1",);
        if (C4::Context->preference('ReturnBeforeExpiry')){
            $template->param("returnbeforeexpiry" => 1);
        }
    }
    $template->param(
        overduecount => $od,
        issuecount   => $issue,
        finetotal    => $fines
    );
}

#
# STEP 3 : ISSUING
#
#
if ($barcode) {
  # always check for blockers on issuing
  my ( $error, $question ) =
    CanBookBeIssued( $borrower, $barcode, $datedue , $inprocess );
  my $blocker = $invalidduedate ? 1 : 0;

  delete $question->{'DEBT'} if ($debt_confirmed);
  foreach my $impossible ( keys %$error ) {
            $template->param(
                $impossible => $$error{$impossible},
                IMPOSSIBLE  => 1
            );
            $blocker = 1;
        }
    if( !$blocker ){
        my $confirm_required = 0;
    	unless($issueconfirmed){
            #  Get the item title for more information
            my $getmessageiteminfo  = GetBiblioFromItemNumber(undef,$barcode);
		    $template->param( itemhomebranch => $getmessageiteminfo->{'homebranch'} );

		    # pass needsconfirmation to template if issuing is possible and user hasn't yet confirmed.
       	    foreach my $needsconfirmation ( keys %$question ) {
       	        $template->param(
       	            $needsconfirmation => $$question{$needsconfirmation},
       	            getTitleMessageIteminfo => $getmessageiteminfo->{'title'},
       	            NEEDSCONFIRMATION  => 1
       	        );
       	        $confirm_required = 1;
       	    }
		}
        unless($confirm_required) {
            AddIssue( $borrower, $barcode, $datedue, $cancelreserve );
			$inprocess = 1;
            if($globalduedate && ! $stickyduedate && $duedatespec_allow ){
                $duedatespec = $globalduedate->output();
                $stickyduedate = 1;
            }
		}
    }
    
    # FIXME If the issue is confirmed, we launch another time GetMemberIssuesAndFines, now display the issue count after issue 
    my ( $od, $issue, $fines ) = GetMemberIssuesAndFines( $borrowernumber );
    $template->param( issuecount   => $issue );
}

# reload the borrower info for the sake of reseting the flags.....
if ($borrowernumber) {
    $borrower = GetMemberDetails( $borrowernumber, 0 );
}

##################################################################################
# BUILD HTML
# show all reserves of this borrower, and the position of the reservation ....
my $borrowercategory;
my $category_type;
if ($borrowernumber) {

    # new op dev
    # now we show the status of the borrower's reservations
    my @borrowerreserv = GetReservesFromBorrowernumber($borrowernumber );
    my @reservloop;
    my @WaitingReserveLoop;
    
    foreach my $num_res (@borrowerreserv) {
        my %getreserv;
        my %getWaitingReserveInfo;
        my $getiteminfo  = GetBiblioFromItemNumber( $num_res->{'itemnumber'} );
        my $itemtypeinfo = getitemtypeinfo( (C4::Context->preference('item-level_itypes')) ? $getiteminfo->{'itype'} : $getiteminfo->{'itemtype'} );
        my ( $transfertwhen, $transfertfrom, $transfertto ) =
          GetTransfers( $num_res->{'itemnumber'} );

        $getreserv{waiting}       = 0;
        $getreserv{transfered}    = 0;
        $getreserv{nottransfered} = 0;

        $getreserv{reservedate}    = format_date( $num_res->{'reservedate'} );
        $getreserv{title}          = $getiteminfo->{'title'};
        $getreserv{itemtype}       = $itemtypeinfo->{'description'};
        $getreserv{author}         = $getiteminfo->{'author'};
        $getreserv{barcodereserv}  = $getiteminfo->{'barcode'};
        $getreserv{itemcallnumber} = $getiteminfo->{'itemcallnumber'};
        $getreserv{biblionumber}   = $getiteminfo->{'biblionumber'};
        $getreserv{waitingat}      = GetBranchName( $num_res->{'branchcode'} );
        #         check if we have a waiting status for reservations
        if ( $num_res->{'found'} eq 'W' ) {
            $getreserv{color}   = 'reserved';
            $getreserv{waiting} = 1;
#     genarate information displaying only waiting reserves
        $getWaitingReserveInfo{title}        = $getiteminfo->{'title'};
        $getWaitingReserveInfo{biblionumber} = $getiteminfo->{'biblionumber'};
        $getWaitingReserveInfo{itemtype}     = $itemtypeinfo->{'description'};
        $getWaitingReserveInfo{author}       = $getiteminfo->{'author'};
        $getWaitingReserveInfo{reservedate}  = format_date( $num_res->{'reservedate'} );
        $getWaitingReserveInfo{waitingat}    = GetBranchName( $num_res->{'branchcode'} );
        $getWaitingReserveInfo{waitinghere}  = 1 if $num_res->{'branchcode'} eq $branch;
        }
        #         check transfers with the itemnumber foud in th reservation loop
        if ($transfertwhen) {
            $getreserv{color}      = 'transfered';
            $getreserv{transfered} = 1;
            $getreserv{datesent}   = format_date($transfertwhen);
            $getreserv{frombranch} = GetBranchName($transfertfrom);
        } elsif ($getiteminfo->{'holdingbranch'} ne $num_res->{'branchcode'}) {
            $getreserv{nottransfered}   = 1;
            $getreserv{nottransferedby} = GetBranchName( $getiteminfo->{'holdingbranch'} );
        }

#         if we don't have a reserv on item, we put the biblio infos and the waiting position
        if ( $getiteminfo->{'title'} eq '' ) {
            my $getbibinfo = GetBiblioData( $num_res->{'biblionumber'} );
            my $getbibtype = getitemtypeinfo( $getbibinfo->{'itemtype'} );  # fixme - we should have item-level reserves here ?
            $getreserv{color}           = 'inwait';
            $getreserv{title}           = $getbibinfo->{'title'};
            $getreserv{nottransfered}   = 0;
            $getreserv{itemtype}        = $getbibtype->{'description'};
            $getreserv{author}          = $getbibinfo->{'author'};
            $getreserv{biblionumber}    = $num_res->{'biblionumber'};
        }
        $getreserv{waitingposition} = $num_res->{'priority'};
        push( @reservloop, \%getreserv );

#         if we have a reserve waiting, initiate waitingreserveloop
        if ($getreserv{waiting} eq 1) {
        push (@WaitingReserveLoop, \%getWaitingReserveInfo)
        }
      
    }

    # return result to the template
    $template->param( 
        countreserv => scalar @reservloop,
        reservloop  => \@reservloop ,
        WaitingReserveLoop  => \@WaitingReserveLoop,
    );
    $template->param( adultborrower => 1 ) if ( $borrower->{'category_type'} eq 'A' );
}

# make the issued books table.
my $todaysissues = '';
my $previssues   = '';
my @todaysissues;
my @previousissues;
## ADDED BY JF: new itemtype issuingrules counter stuff
my $issued_itemtypes_count;
my @issued_itemtypes_count_loop;
my $totalprice = 0;

if ($borrower) {
# get each issue of the borrower & separate them in todayissues & previous issues
    my ($issueslist) = GetPendingIssues($borrower->{'borrowernumber'});
    # split in 2 arrays for today & previous
    foreach my $it ( @$issueslist ) {
        my $itemtypeinfo = getitemtypeinfo( (C4::Context->preference('item-level_itypes')) ? $it->{'itype'} : $it->{'itemtype'} );
        # set itemtype per item-level_itype syspref - FIXME this is an ugly hack
        $it->{'itemtype'} = ( C4::Context->preference( 'item-level_itypes' ) ) ? $it->{'itype'} : $it->{'itemtype'};

        ($it->{'charge'}, $it->{'itemtype_charge'}) = GetIssuingCharges(
            $it->{'itemnumber'}, $borrower->{'borrowernumber'}
        );
        $it->{'charge'} = sprintf("%.2f", $it->{'charge'});
        my ($can_renew, $can_renew_error) = CanBookBeRenewed( 
            $borrower->{'borrowernumber'},$it->{'itemnumber'}
        );
        $it->{"renew_error_${can_renew_error}"} = 1 if defined $can_renew_error;
        my ( $restype, $reserves ) = CheckReserves( $it->{'itemnumber'} );
		$it->{'can_renew'} = $can_renew;
		$it->{'can_confirm'} = !$can_renew && !$restype;
		$it->{'renew_error'} = $restype;
	    $it->{'checkoutdate'} = C4::Dates->new($it->{'issuedate'},'iso')->output('syspref');

	    $totalprice += $it->{'replacementprice'};
		$it->{'itemtype'} = $itemtypeinfo->{'description'};
		$it->{'itemtype_image'} = $itemtypeinfo->{'imageurl'};
        $it->{'dd'} = format_date($it->{'date_due'});
        $it->{'issuedate'} = format_date($it->{'issuedate'});
        $it->{'od'} = ( $it->{'date_due'} lt $todaysdate ) ? 1 : 0 ;
        ($it->{'author'} eq '') and $it->{'author'} = ' ';
        $it->{'renew_failed'} = $renew_failed{$it->{'itemnumber'}};
        # ADDED BY JF: NEW ITEMTYPE COUNT DISPLAY
        $issued_itemtypes_count->{ $it->{'itemtype'} }++;

        if ( $todaysdate eq $it->{'issuedate'} or $todaysdate eq $it->{'lastreneweddate'} ) {
            push @todaysissues, $it;
        } else {
            push @previousissues, $it;
        }
    }
    if ( C4::Context->preference( "todaysIssuesDefaultSortOrder" ) eq 'asc' ) {
        @todaysissues   = sort { $a->{'timestamp'} cmp $b->{'timestamp'} } @todaysissues;
    }
    else {
        @todaysissues   = sort { $b->{'timestamp'} cmp $a->{'timestamp'} } @todaysissues;
    }
    if ( C4::Context->preference( "previousIssuesDefaultSortOrder" ) eq 'asc' ){
        @previousissues = sort { $a->{'date_due'} cmp $b->{'date_due'} } @previousissues;
    }
    else {
        @previousissues = sort { $b->{'date_due'} cmp $a->{'date_due'} } @previousissues;
    }
}

#### ADDED BY JF FOR COUNTS BY ITEMTYPE RULES
# FIXME: This should utilize all the issuingrules options rather than just the defaults
# and it should be moved to a module
my $dbh = C4::Context->dbh;

# how many of each is allowed?
my $issueqty_sth = $dbh->prepare( "
SELECT itemtypes.description AS description,issuingrules.itemtype,maxissueqty
FROM issuingrules
  LEFT JOIN itemtypes ON (itemtypes.itemtype=issuingrules.itemtype)
  WHERE categorycode=?
" );
$issueqty_sth->execute("*");	# This is a literal asterisk, not a wildcard.

while ( my $data = $issueqty_sth->fetchrow_hashref() ) {

    # subtract how many of each this borrower has
    $data->{'count'} = $issued_itemtypes_count->{ $data->{'description'} };  
    $data->{'left'}  =
      ( $data->{'maxissueqty'} -
          $issued_itemtypes_count->{ $data->{'description'} } );

    # can't have a negative number of remaining
    if ( $data->{'left'} < 0 ) { $data->{'left'} = "0" }
    $data->{'flag'} = 1 unless ( $data->{'maxissueqty'} > $data->{'count'} );
    unless ( ( $data->{'maxissueqty'} < 1 )
        || ( $data->{'itemtype'} eq "*" )
        || ( $data->{'itemtype'} eq "CIRC" ) )
    {
        push @issued_itemtypes_count_loop, $data;
    }
}

#### / JF

my @values;
my %labels;
my $CGIselectborrower;
if ($borrowerslist) {
    foreach (
        sort {(lc $a->{'surname'} cmp lc $b->{'surname'} || lc $a->{'firstname'} cmp lc $b->{'firstname'})
        } @$borrowerslist
      )
    {
        push @values, $_->{'borrowernumber'};
        $labels{ $_->{'borrowernumber'} } =
"$_->{'surname'}, $_->{'firstname'} ... ($_->{'cardnumber'} - $_->{'categorycode'}) ...  $_->{'address'} ";
    }
    $CGIselectborrower = CGI::scrolling_list(
        -name     => 'borrowernumber',
        -class    => 'focus',
        -id       => 'borrowernumber',
        -values   => \@values,
        -labels   => \%labels,
	-onclick  => "window.location = '/cgi-bin/koha/circ/circulation.pl?borrowernumber=' + this.value;",
        -size     => 7,
        -tabindex => '',
        -multiple => 0
    );
}

#title
my $flags = $borrower->{'flags'};
foreach my $flag ( sort keys %$flags ) {
    $template->param( flagged=> 1);
    $flags->{$flag}->{'message'} =~ s#\n#<br />#g;
    if ( $flags->{$flag}->{'noissues'} ) {
        $template->param(
            flagged  => 1,
            noissues => 'true',
        );
        if ( $flag eq 'GNA' ) {
            $template->param( gna => 'true' );
        }
        elsif ( $flag eq 'LOST' ) {
            $template->param( lost => 'true' );
        }
        elsif ( $flag eq 'DBARRED' ) {
            $template->param( dbarred => 'true' );
        }
        elsif ( $flag eq 'CHARGES' ) {
            $template->param(
                charges    => 'true',
                chargesmsg => $flags->{'CHARGES'}->{'message'},
                chargesamount => $flags->{'CHARGES'}->{'amount'},
                charges_is_blocker => 1
            );
        }
        elsif ( $flag eq 'CREDITS' ) {
            $template->param(
                credits    => 'true',
                creditsmsg => $flags->{'CREDITS'}->{'message'}
            );
        }
    }
    else {
        if ( $flag eq 'CHARGES' ) {
            $template->param(
                charges    => 'true',
                flagged    => 1,
                chargesmsg => $flags->{'CHARGES'}->{'message'},
                chargesamount => $flags->{'CHARGES'}->{'amount'},
            );
        }
        elsif ( $flag eq 'CREDITS' ) {
            $template->param(
                credits    => 'true',
                creditsmsg => $flags->{'CREDITS'}->{'message'}
            );
        }
        elsif ( $flag eq 'ODUES' ) {
            $template->param(
                odues    => 'true',
                flagged  => 1,
                oduesmsg => $flags->{'ODUES'}->{'message'}
            );

            my $items = $flags->{$flag}->{'itemlist'};
# useless ???
#             {
#                 my @itemswaiting;
#                 foreach my $item (@$items) {
#                     my ($iteminformation) =
#                         getiteminformation( $item->{'itemnumber'}, 0 );
#                     push @itemswaiting, $iteminformation;
#                 }
#             }
            if ( ! $query->param('module') or $query->param('module') ne 'returns' ) {
                $template->param( nonreturns => 'true' );
            }
        }
        elsif ( $flag eq 'NOTES' ) {
            $template->param(
                notes    => 'true',
                flagged  => 1,
                notesmsg => $flags->{'NOTES'}->{'message'}
            );
        }
    }
}

my $amountold = $borrower->{flags}->{'CHARGES'}->{'message'} || 0;
$amountold =~ s/^.*\$//;    # remove upto the $, if any

my ( $total, $accts, $numaccts) = GetMemberAccountRecords( $borrowernumber );

if ( $borrower->{'category_type'} eq 'C') {
    my  ( $catcodes, $labels ) =  GetborCatFromCatType( 'A', 'WHERE category_type = ?' );
    my $cnt = scalar(@$catcodes);
    $template->param( 'CATCODE_MULTI' => 1) if $cnt > 1;
    $template->param( 'catcode' =>    $catcodes->[0])  if $cnt == 1;
}

my $CGIorganisations;
my $member_of_institution;
if ( C4::Context->preference("memberofinstitution") ) {
    my $organisations = get_institutions();
    my @orgs;
    my %org_labels;
    foreach my $organisation ( keys %$organisations ) {
        push @orgs, $organisation;
        $org_labels{$organisation} = $organisations->{$organisation}->{'surname'};
    }
    $member_of_institution = 1;
    $CGIorganisations      = CGI::popup_menu(
        -id     => 'organisations',
        -name   => 'organisations',
        -labels => \%org_labels,
        -values => \@orgs,
    );
}

$template->param(
    issued_itemtypes_count_loop => \@issued_itemtypes_count_loop,
    findborrower                => $findborrower,
    borrower                    => $borrower,
    borrowernumber              => $borrowernumber,
    branch                      => $branch,
    branchname                  => GetBranchName($borrower->{'branchcode'}),
    printer                     => $printer,
    printername                 => $printer,
    firstname                   => $borrower->{'firstname'},
    surname                     => $borrower->{'surname'},
    dateexpiry        => format_date($newexpiry),
    expiry            => format_date($borrower->{'dateexpiry'}),
    categorycode      => $borrower->{'categorycode'},
    categoryname      => $borrower->{description},
    address           => $borrower->{'address'},
    address2          => $borrower->{'address2'},
    email             => $borrower->{'email'},
    emailpro          => $borrower->{'emailpro'},
    borrowernotes     => $borrower->{'borrowernotes'},
    city              => $borrower->{'city'},
    zipcode	          => $borrower->{'zipcode'},
    country	          => $borrower->{'country'},
    phone             => $borrower->{'phone'} || $borrower->{'mobile'},
    cardnumber        => $borrower->{'cardnumber'},
    amountold         => $amountold,
    barcode           => $barcode,
    stickyduedate     => $stickyduedate,
    duedatespec       => $duedatespec,
    message           => $message,
    CGIselectborrower => $CGIselectborrower,
	totalprice => sprintf("%.2f", $totalprice),
    totaldue        => sprintf("%.2f", $total),
    todayissues       => \@todaysissues,
    previssues        => \@previousissues,
    inprocess         => $inprocess,
    memberofinstution => $member_of_institution,
    CGIorganisations  => $CGIorganisations,
	is_child          => ($borrower->{'category_type'} eq 'C'),
    circview => 1,
);

# save stickyduedate to session
if ($stickyduedate) {
    $session->param( 'stickyduedate', $duedatespec );
}

#if ($branchcookie) {
#$cookie=[$cookie, $branchcookie, $printercookie];
#}

my ($picture, $dberror) = GetPatronImage($borrower->{'cardnumber'});
$template->param( picture => 1 ) if $picture;


$template->param(
    debt_confirmed            => $debt_confirmed,
    SpecifyDueDate            => $duedatespec_allow,
    CircAutocompl             => C4::Context->preference("CircAutocompl"),
	AllowRenewalLimitOverride => C4::Context->preference("AllowRenewalLimitOverride"),
    dateformat                => C4::Context->preference("dateformat"),
    DHTMLcalendar_dateformat  => C4::Dates->DHTMLcalendar(),
);
output_html_with_http_headers $query, $cookie, $template->output;
