package C4::Circulation;

# Copyright 2000-2002 Katipo Communications
# copyright 2010 BibLibre
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
use C4::Context;
use C4::Stats;
use C4::Reserves;
use C4::Koha;
use C4::Biblio;
use C4::Items;
use C4::Members;
use C4::Dates;
use C4::Calendar;
use C4::Accounts;
use C4::ItemCirculationAlertPreference;
use C4::Dates qw(format_date);
use C4::Message;
use C4::Debug;
use Date::Calc qw(
  Today
  Today_and_Now
  Add_Delta_YM
  Add_Delta_DHMS
  Date_to_Days
  Day_of_Week
  Add_Delta_Days	
);
use POSIX qw(strftime);
use C4::Branch; # GetBranches
use C4::Log; # logaction

use Data::Dumper;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

BEGIN {
	require Exporter;
	$VERSION = 3.02;	# for version checking
	@ISA    = qw(Exporter);

	# FIXME subs that should probably be elsewhere
	push @EXPORT, qw(
		&FixOverduesOnReturn
		&barcodedecode
	);

	# subs to deal with issuing a book
	push @EXPORT, qw(
		&CanBookBeIssued
		&CanBookBeRenewed
		&AddIssue
		&AddRenewal
		&GetRenewCount
		&GetItemIssue
		&GetItemIssues
		&GetBorrowerIssues
		&GetIssuingCharges
		&GetIssuingRule
        &GetBranchBorrowerCircRule
        &GetBranchItemRule
		&GetBiblioIssues
		&GetOpenIssue
		&AnonymiseIssueHistory
	);

	# subs to deal with returns
	push @EXPORT, qw(
		&AddReturn
        &MarkIssueReturned
	);

	# subs to deal with transfers
	push @EXPORT, qw(
		&transferbook
		&GetTransfers
		&GetTransfersFromTo
		&updateWrongTransfer
		&DeleteTransfer
                &IsBranchTransferAllowed
                &CreateBranchTransferLimit
                &DeleteBranchTransferLimits
	);
}

=head1 NAME

C4::Circulation - Koha circulation module

=head1 SYNOPSIS

use C4::Circulation;

=head1 DESCRIPTION

The functions in this module deal with circulation, issues, and
returns, as well as general information about the library.
Also deals with stocktaking.

=head1 FUNCTIONS

=head2 barcodedecode

  $str = &barcodedecode($barcode, [$filter]);

Generic filter function for barcode string.
Called on every circ if the System Pref itemBarcodeInputFilter is set.
Will do some manipulation of the barcode for systems that deliver a barcode
to circulation.pl that differs from the barcode stored for the item.
For proper functioning of this filter, calling the function on the 
correct barcode string (items.barcode) should return an unaltered barcode.

The optional $filter argument is to allow for testing or explicit 
behavior that ignores the System Pref.  Valid values are the same as the 
System Pref options.

=cut

# FIXME -- the &decode fcn below should be wrapped into this one.
# FIXME -- these plugins should be moved out of Circulation.pm
#
sub barcodedecode {
    my ($barcode, $filter) = @_;
    my $branch = C4::Branch::mybranch();
    $filter = C4::Context->preference('itemBarcodeInputFilter') unless $filter;
    $filter or return $barcode;     # ensure filter is defined, else return untouched barcode
	if ($filter eq 'whitespace') {
		$barcode =~ s/\s//g;
	} elsif ($filter eq 'cuecat') {
		chomp($barcode);
	    my @fields = split( /\./, $barcode );
	    my @results = map( decode($_), @fields[ 1 .. $#fields ] );
	    ($#results == 2) and return $results[2];
	} elsif ($filter eq 'T-prefix') {
		if ($barcode =~ /^[Tt](\d)/) {
			(defined($1) and $1 eq '0') and return $barcode;
            $barcode = substr($barcode, 2) + 0;     # FIXME: probably should be substr($barcode, 1)
		}
        return sprintf("T%07d", $barcode);
        # FIXME: $barcode could be "T1", causing warning: substr outside of string
        # Why drop the nonzero digit after the T?
        # Why pass non-digits (or empty string) to "T%07d"?
	} elsif ($filter eq 'libsuite8') {
		unless($barcode =~ m/^($branch)-/i){	#if barcode starts with branch code its in Koha style. Skip it.
			if($barcode =~ m/^(\d)/i){	#Some barcodes even start with 0's & numbers and are assumed to have b as the item type in the libsuite8 software
                                $barcode =~ s/^[0]*(\d+)$/$branch-b-$1/i;
                        }else{
				$barcode =~ s/^(\D+)[0]*(\d+)$/$branch-$1-$2/i;
			}
		}
	}
    return $barcode;    # return barcode, modified or not
}

=head2 decode

  $str = &decode($chunk);

Decodes a segment of a string emitted by a CueCat barcode scanner and
returns it.

FIXME: Should be replaced with Barcode::Cuecat from CPAN
or Javascript based decoding on the client side.

=cut

sub decode {
    my ($encoded) = @_;
    my $seq =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-';
    my @s = map { index( $seq, $_ ); } split( //, $encoded );
    my $l = ( $#s + 1 ) % 4;
    if ($l) {
        if ( $l == 1 ) {
            # warn "Error: Cuecat decode parsing failed!";
            return;
        }
        $l = 4 - $l;
        $#s += $l;
    }
    my $r = '';
    while ( $#s >= 0 ) {
        my $n = ( ( $s[0] << 6 | $s[1] ) << 6 | $s[2] ) << 6 | $s[3];
        $r .=
            chr( ( $n >> 16 ) ^ 67 )
         .chr( ( $n >> 8 & 255 ) ^ 67 )
         .chr( ( $n & 255 ) ^ 67 );
        @s = @s[ 4 .. $#s ];
    }
    $r = substr( $r, 0, length($r) - $l );
    return $r;
}

=head2 transferbook

  ($dotransfer, $messages, $iteminformation) = &transferbook($newbranch, 
                                            $barcode, $ignore_reserves);

Transfers an item to a new branch. If the item is currently on loan, it is automatically returned before the actual transfer.

C<$newbranch> is the code for the branch to which the item should be transferred.

C<$barcode> is the barcode of the item to be transferred.

If C<$ignore_reserves> is true, C<&transferbook> ignores reserves.
Otherwise, if an item is reserved, the transfer fails.

Returns three values:

=over

=item $dotransfer 

is true if the transfer was successful.

=item $messages

is a reference-to-hash which may have any of the following keys:

=over

=item C<BadBarcode>

There is no item in the catalog with the given barcode. The value is C<$barcode>.

=item C<IsPermanent>

The item's home branch is permanent. This doesn't prevent the item from being transferred, though. The value is the code of the item's home branch.

=item C<DestinationEqualsHolding>

The item is already at the branch to which it is being transferred. The transfer is nonetheless considered to have failed. The value should be ignored.

=item C<WasReturned>

The item was on loan, and C<&transferbook> automatically returned it before transferring it. The value is the borrower number of the patron who had the item.

=item C<ResFound>

The item was reserved. The value is a reference-to-hash whose keys are fields from the reserves table of the Koha database, and C<biblioitemnumber>. It also has the key C<ResFound>, whose value is either C<Waiting> or C<Reserved>.

=item C<WasTransferred>

The item was eligible to be transferred. Barring problems communicating with the database, the transfer should indeed have succeeded. The value should be ignored.

=back

=back

=cut

sub transferbook {
    my ( $tbr, $barcode, $ignoreRs ) = @_;
    my $messages;
    my $dotransfer      = 1;
    my $branches        = GetBranches();
    my $itemnumber = GetItemnumberFromBarcode( $barcode );
    my $issue      = GetItemIssue($itemnumber);
    my $biblio = GetBiblioFromItemNumber($itemnumber);

    # bad barcode..
    if ( not $itemnumber ) {
        $messages->{'BadBarcode'} = $barcode;
        $dotransfer = 0;
    }

    # get branches of book...
    my $hbr = $biblio->{'homebranch'};
    my $fbr = $biblio->{'holdingbranch'};

    # if using Branch Transfer Limits
    if ( C4::Context->preference("UseBranchTransferLimits") == 1 ) {
        if ( C4::Context->preference("item-level_itypes") && C4::Context->preference("BranchTransferLimitsType") eq 'itemtype' ) {
            if ( ! IsBranchTransferAllowed( $tbr, $fbr, $biblio->{'itype'} ) ) {
                $messages->{'NotAllowed'} = $tbr . "::" . $biblio->{'itype'};
                $dotransfer = 0;
            }
        } elsif ( ! IsBranchTransferAllowed( $tbr, $fbr, $biblio->{ C4::Context->preference("BranchTransferLimitsType") } ) ) {
            $messages->{'NotAllowed'} = $tbr . "::" . $biblio->{ C4::Context->preference("BranchTransferLimitsType") };
            $dotransfer = 0;
    	}
    }

    # if is permanent...
    if ( $hbr && $branches->{$hbr}->{'PE'} ) {
        $messages->{'IsPermanent'} = $hbr;
        $dotransfer = 0;
    }

    # can't transfer book if is already there....
    if ( $fbr eq $tbr ) {
        $messages->{'DestinationEqualsHolding'} = 1;
        $dotransfer = 0;
    }

    # check if it is still issued to someone, return it...
    if ($issue->{borrowernumber}) {
        AddReturn( $barcode, $fbr );
        $messages->{'WasReturned'} = $issue->{borrowernumber};
    }

    # find reserves.....
    # That'll save a database query.
    my ( $resfound, $resrec ) =
      CheckReserves( $itemnumber );
    if ( $resfound and not $ignoreRs ) {
        $resrec->{'ResFound'} = $resfound;

        #         $messages->{'ResFound'} = $resrec;
        $dotransfer = 1;
    }

    #actually do the transfer....
    if ($dotransfer) {
        ModItemTransfer( $itemnumber, $fbr, $tbr );

        # don't need to update MARC anymore, we do it in batch now
        $messages->{'WasTransfered'} = 1;

    }
    ModDateLastSeen( $itemnumber );
    return ( $dotransfer, $messages, $biblio );
}


sub TooMany {
    my $borrower        = shift;
    my $biblionumber = shift;
	my $item		= shift;
    my $cat_borrower    = $borrower->{'categorycode'};
    my $dbh             = C4::Context->dbh;
	my $branch;
	# Get which branchcode we need
	$branch = _GetCircControlBranch($item,$borrower);
	my $type = (C4::Context->preference('item-level_itypes')) 
  			? $item->{'itype'}         # item-level
			: $item->{'itemtype'};     # biblio-level
 
    # given branch, patron category, and item type, determine
    # applicable issuing rule
    my $issuing_rule = GetIssuingRule($cat_borrower, $type, $branch);

    # if a rule is found and has a loan limit set, count
    # how many loans the patron already has that meet that
    # rule
    if (defined($issuing_rule) and defined($issuing_rule->{'maxissueqty'})) {
        my @bind_params;
        my $count_query = "SELECT COUNT(*) FROM issues
                           JOIN items USING (itemnumber) ";

        my $rule_itemtype = $issuing_rule->{itemtype};
        if ($rule_itemtype eq "*") {
            # matching rule has the default item type, so count only
            # those existing loans that don't fall under a more
            # specific rule
            if (C4::Context->preference('item-level_itypes')) {
                $count_query .= " WHERE items.itype NOT IN (
                                    SELECT itemtype FROM issuingrules
                                    WHERE branchcode = ?
                                    AND   (categorycode = ? OR categorycode = ?)
                                    AND   itemtype <> '*'
                                  ) ";
            } else { 
                $count_query .= " JOIN  biblioitems USING (biblionumber) 
                                  WHERE biblioitems.itemtype NOT IN (
                                    SELECT itemtype FROM issuingrules
                                    WHERE branchcode = ?
                                    AND   (categorycode = ? OR categorycode = ?)
                                    AND   itemtype <> '*'
                                  ) ";
            }
            push @bind_params, $issuing_rule->{branchcode};
            push @bind_params, $issuing_rule->{categorycode};
            push @bind_params, $cat_borrower;
        } else {
            # rule has specific item type, so count loans of that
            # specific item type
            if (C4::Context->preference('item-level_itypes')) {
                $count_query .= " WHERE items.itype = ? ";
            } else { 
                $count_query .= " JOIN  biblioitems USING (biblionumber) 
                                  WHERE biblioitems.itemtype= ? ";
            }
            push @bind_params, $type;
        }

        $count_query .= " AND borrowernumber = ? ";
        push @bind_params, $borrower->{'borrowernumber'};
        my $rule_branch = $issuing_rule->{branchcode};
        if ($rule_branch ne "*") {
            if (C4::Context->preference('CircControl') eq 'PickupLibrary') {
                $count_query .= " AND issues.branchcode = ? ";
                push @bind_params, $branch;
            } elsif (C4::Context->preference('CircControl') eq 'PatronLibrary') {
                ; # if branch is the patron's home branch, then count all loans by patron
            } else {
                $count_query .= " AND items.homebranch = ? ";
                push @bind_params, $branch;
            }
        }

        my $count_sth = $dbh->prepare($count_query);
        $count_sth->execute(@bind_params);
        my ($current_loan_count) = $count_sth->fetchrow_array;

        my $max_loans_allowed = $issuing_rule->{'maxissueqty'};
        if ($current_loan_count >= $max_loans_allowed) {
            return ($current_loan_count, $max_loans_allowed);
        }
    }

    # Now count total loans against the limit for the branch
    my $branch_borrower_circ_rule = GetBranchBorrowerCircRule($branch, $cat_borrower);
    if (defined($branch_borrower_circ_rule->{maxissueqty})) {
        my @bind_params = ();
        my $branch_count_query = "SELECT COUNT(*) FROM issues 
                                  JOIN items USING (itemnumber)
                                  WHERE borrowernumber = ? ";
        push @bind_params, $borrower->{borrowernumber};

        if (C4::Context->preference('CircControl') eq 'PickupLibrary') {
            $branch_count_query .= " AND issues.branchcode = ? ";
            push @bind_params, $branch;
        } elsif (C4::Context->preference('CircControl') eq 'PatronLibrary') {
            ; # if branch is the patron's home branch, then count all loans by patron
        } else {
            $branch_count_query .= " AND items.homebranch = ? ";
            push @bind_params, $branch;
        }
        my $branch_count_sth = $dbh->prepare($branch_count_query);
        $branch_count_sth->execute(@bind_params);
        my ($current_loan_count) = $branch_count_sth->fetchrow_array;

        my $max_loans_allowed = $branch_borrower_circ_rule->{maxissueqty};
        if ($current_loan_count >= $max_loans_allowed) {
            return ($current_loan_count, $max_loans_allowed);
        }
    }

    # OK, the patron can issue !!!
    return;
}

=head2 itemissues

  @issues = &itemissues($biblioitemnumber, $biblio);

Looks up information about who has borrowed the bookZ<>(s) with the
given biblioitemnumber.

C<$biblio> is ignored.

C<&itemissues> returns an array of references-to-hash. The keys
include the fields from the C<items> table in the Koha database.
Additional keys include:

=over 4

=item C<date_due>

If the item is currently on loan, this gives the due date.

If the item is not on loan, then this is either "Available" or
"Cancelled", if the item has been withdrawn.

=item C<card>

If the item is currently on loan, this gives the card number of the
patron who currently has the item.

=item C<timestamp0>, C<timestamp1>, C<timestamp2>

These give the timestamp for the last three times the item was
borrowed.

=item C<card0>, C<card1>, C<card2>

The card number of the last three patrons who borrowed this item.

=item C<borrower0>, C<borrower1>, C<borrower2>

The borrower number of the last three patrons who borrowed this item.

=back

=cut

#'
sub itemissues {
    my ( $bibitem, $biblio ) = @_;
    my $dbh = C4::Context->dbh;
    my $sth =
      $dbh->prepare("Select * from items where items.biblioitemnumber = ?")
      || die $dbh->errstr;
    my $i = 0;
    my @results;

    $sth->execute($bibitem) || die $sth->errstr;

    while ( my $data = $sth->fetchrow_hashref ) {

        # Find out who currently has this item.
        # FIXME - Wouldn't it be better to do this as a left join of
        # some sort? Currently, this code assumes that if
        # fetchrow_hashref() fails, then the book is on the shelf.
        # fetchrow_hashref() can fail for any number of reasons (e.g.,
        # database server crash), not just because no items match the
        # search criteria.
        my $sth2 = $dbh->prepare(
            "SELECT * FROM issues
                LEFT JOIN borrowers ON issues.borrowernumber = borrowers.borrowernumber
                WHERE itemnumber = ?
            "
        );

        $sth2->execute( $data->{'itemnumber'} );
        if ( my $data2 = $sth2->fetchrow_hashref ) {
            $data->{'date_due'} = $data2->{'date_due'};
            $data->{'card'}     = $data2->{'cardnumber'};
            $data->{'borrower'} = $data2->{'borrowernumber'};
        }
        else {
            $data->{'date_due'} = ($data->{'wthdrawn'} eq '1') ? 'Cancelled' : 'Available';
        }


        # Find the last 3 people who borrowed this item.
        $sth2 = $dbh->prepare(
            "SELECT * FROM old_issues
                LEFT JOIN borrowers ON  issues.borrowernumber = borrowers.borrowernumber
                WHERE itemnumber = ?
                ORDER BY returndate DESC,timestamp DESC"
        );

        $sth2->execute( $data->{'itemnumber'} );
        for ( my $i2 = 0 ; $i2 < 2 ; $i2++ )
        {    # FIXME : error if there is less than 3 pple borrowing this item
            if ( my $data2 = $sth2->fetchrow_hashref ) {
                $data->{"timestamp$i2"} = $data2->{'timestamp'};
                $data->{"card$i2"}      = $data2->{'cardnumber'};
                $data->{"borrower$i2"}  = $data2->{'borrowernumber'};
            }    # if
        }    # for

        $results[$i] = $data;
        $i++;
    }

    return (@results);
}

=head2 CanBookBeIssued

  ( $issuingimpossible, $needsconfirmation ) =  CanBookBeIssued( $borrower, 
                                      $barcode, $duedatespec, $inprocess );

Check if a book can be issued.

C<$issuingimpossible> and C<$needsconfirmation> are some hashref.

=over 4

=item C<$borrower> hash with borrower informations (from GetMemberDetails)

=item C<$barcode> is the bar code of the book being issued.

=item C<$duedatespec> is a C4::Dates object.

=item C<$inprocess>

=back

Returns :

=over 4

=item C<$issuingimpossible> a reference to a hash. It contains reasons why issuing is impossible.
Possible values are :

=back

=head3 INVALID_DATE 

sticky due date is invalid

=head3 GNA

borrower gone with no address

=head3 CARD_LOST

borrower declared it's card lost

=head3 DEBARRED

borrower debarred

=head3 UNKNOWN_BARCODE

barcode unknown

=head3 NOT_FOR_LOAN

item is not for loan

=head3 WTHDRAWN

item withdrawn.

=head3 RESTRICTED

item is restricted (set by ??)

C<$needsconfirmation> a reference to a hash. It contains reasons why the loan 
could be prevented, but ones that can be overriden by the operator.

Possible values are :

=head3 DEBT

borrower has debts.

=head3 RENEW_ISSUE

renewing, not issuing

=head3 ISSUED_TO_ANOTHER

issued to someone else.

=head3 RESERVED

reserved for someone else.

=head3 INVALID_DATE

sticky due date is invalid or due date in the past

=head3 TOO_MANY

if the borrower borrows to much things

=cut

sub CanBookBeIssued {
    my ( $borrower, $barcode, $duedate, $inprocess ) = @_;
    my %needsconfirmation;    # filled with problems that needs confirmations
    my %issuingimpossible;    # filled with problems that causes the issue to be IMPOSSIBLE
    my $item = GetItem(GetItemnumberFromBarcode( $barcode ));
    my $issue = GetItemIssue($item->{itemnumber});
	my $biblioitem = GetBiblioItemData($item->{biblioitemnumber});
	$item->{'itemtype'}=$item->{'itype'}; 
    my $dbh             = C4::Context->dbh;

    # MANDATORY CHECKS - unless item exists, nothing else matters
    unless ( $item->{barcode} ) {
        $issuingimpossible{UNKNOWN_BARCODE} = 1;
    }
	return ( \%issuingimpossible, \%needsconfirmation ) if %issuingimpossible;

    #
    # DUE DATE is OK ? -- should already have checked.
    #
    unless ( $duedate ) {
        my $issuedate = strftime( "%Y-%m-%d", localtime );

        my $branch = _GetCircControlBranch($item,$borrower);
        my $itype = ( C4::Context->preference('item-level_itypes') ) ? $item->{'itype'} : $biblioitem->{'itemtype'};
        $duedate = CalcDateDue( C4::Dates->new( $issuedate, 'iso' ), $itype, $branch, $borrower );

        # Offline circ calls AddIssue directly, doesn't run through here
        #  So issuingimpossible should be ok.
    }
    if ($duedate) {
        $needsconfirmation{INVALID_DATE} = $duedate->output('syspref')
          unless $duedate->output('iso') ge C4::Dates->today('iso');
    } else {
        $issuingimpossible{INVALID_DATE} = $duedate->output('syspref');
    }

    #
    # BORROWER STATUS
    #
    if ( $borrower->{'category_type'} eq 'X' && (  $item->{barcode}  )) { 
    	# stats only borrower -- add entry to statistics table, and return issuingimpossible{STATS} = 1  .
        &UpdateStats(C4::Context->userenv->{'branch'},'localuse','','',$item->{'itemnumber'},$item->{'itemtype'},$borrower->{'borrowernumber'});
        ModDateLastSeen( $item->{'itemnumber'} );
        return( { STATS => 1 }, {});
    }
    if ( $borrower->{flags}->{GNA} ) {
        $issuingimpossible{GNA} = 1;
    }
    if ( $borrower->{flags}->{'LOST'} ) {
        $issuingimpossible{CARD_LOST} = 1;
    }
    if ( $borrower->{flags}->{'DBARRED'} ) {
        $issuingimpossible{DEBARRED} = 1;
    }
    if ( $borrower->{'dateexpiry'} eq '0000-00-00') {
        $issuingimpossible{EXPIRED} = 1;
    } else {
        my @expirydate=  split /-/,$borrower->{'dateexpiry'};
        if($expirydate[0]==0 || $expirydate[1]==0|| $expirydate[2]==0 ||
            Date_to_Days(Today) > Date_to_Days( @expirydate )) {
            $issuingimpossible{EXPIRED} = 1;                                   
        }
    }
    #
    # BORROWER STATUS
    #

    # DEBTS
    my ($amount) =
      C4::Members::GetMemberAccountRecords( $borrower->{'borrowernumber'}, '' && $duedate->output('iso') );
    my $amountlimit = C4::Context->preference("noissuescharge");
    my $allowfineoverride = C4::Context->preference("AllowFineOverride");
    my $allfinesneedoverride = C4::Context->preference("AllFinesNeedOverride");
    if ( C4::Context->preference("IssuingInProcess") ) {
        if ( $amount > $amountlimit && !$inprocess && !$allowfineoverride) {
            $issuingimpossible{DEBT} = sprintf( "%.2f", $amount );
        } elsif ( $amount > $amountlimit && !$inprocess && $allowfineoverride) {
            $needsconfirmation{DEBT} = sprintf( "%.2f", $amount );
        } elsif ( $allfinesneedoverride && $amount > 0 && $amount <= $amountlimit && !$inprocess ) {
            $needsconfirmation{DEBT} = sprintf( "%.2f", $amount );
        }
    }
    else {
        if ( $amount > $amountlimit && $allowfineoverride ) {
            $needsconfirmation{DEBT} = sprintf( "%.2f", $amount );
        } elsif ( $amount > $amountlimit && !$allowfineoverride) {
            $issuingimpossible{DEBT} = sprintf( "%.2f", $amount );
        } elsif ( $amount > 0 && $allfinesneedoverride ) {
            $needsconfirmation{DEBT} = sprintf( "%.2f", $amount );
        }
    }

    my ($blocktype, $count) = C4::Members::IsMemberBlocked($borrower->{'borrowernumber'});
    if ($blocktype == -1) {
        ## patron has outstanding overdue loans
	    if ( C4::Context->preference("OverduesBlockCirc") eq 'block'){
	        $issuingimpossible{USERBLOCKEDOVERDUE} = $count;
	    }
	    elsif ( C4::Context->preference("OverduesBlockCirc") eq 'confirmation'){
	        $needsconfirmation{USERBLOCKEDOVERDUE} = $count;
	    }
    } elsif($blocktype == 1) {
        # patron has accrued fine days
        $issuingimpossible{USERBLOCKEDREMAINING} = $count;
    }

#
    # JB34 CHECKS IF BORROWERS DONT HAVE ISSUE TOO MANY BOOKS
    #
	my ($current_loan_count, $max_loans_allowed) = TooMany( $borrower, $item->{biblionumber}, $item );
    # if TooMany max_loans_allowed returns 0 the user doesn't have permission to check out this book
    if ($max_loans_allowed eq 0) {
        $needsconfirmation{PATRON_CANT} = 1;
    } else {
        if($max_loans_allowed){
            $needsconfirmation{TOO_MANY} = 1;
            $needsconfirmation{current_loan_count} = $current_loan_count;
            $needsconfirmation{max_loans_allowed} = $max_loans_allowed;
        }
    }

    #
    # ITEM CHECKING
    #
    if (   $item->{'notforloan'}
        && $item->{'notforloan'} > 0 )
    {
        if(!C4::Context->preference("AllowNotForLoanOverride")){
            $issuingimpossible{NOT_FOR_LOAN} = 1;
        }else{
            $needsconfirmation{NOT_FOR_LOAN_FORCING} = 1;
        }
    }
    elsif ( !$item->{'notforloan'} ){
        # we have to check itemtypes.notforloan also
        if (C4::Context->preference('item-level_itypes')){
            # this should probably be a subroutine
            my $sth = $dbh->prepare("SELECT notforloan FROM itemtypes WHERE itemtype = ?");
            $sth->execute($item->{'itemtype'});
            my $notforloan=$sth->fetchrow_hashref();
            $sth->finish();
            if ($notforloan->{'notforloan'}) {
                if (!C4::Context->preference("AllowNotForLoanOverride")) {
                    $issuingimpossible{NOT_FOR_LOAN} = 1;
                } else {
                    $needsconfirmation{NOT_FOR_LOAN_FORCING} = 1;
                }
            }
        }
        elsif ($biblioitem->{'notforloan'} == 1){
            if (!C4::Context->preference("AllowNotForLoanOverride")) {
                $issuingimpossible{NOT_FOR_LOAN} = 1;
            } else {
                $needsconfirmation{NOT_FOR_LOAN_FORCING} = 1;
            }
        }
    }
    if ( $item->{'wthdrawn'} && $item->{'wthdrawn'} == 1 )
    {
        $issuingimpossible{WTHDRAWN} = 1;
    }
    if (   $item->{'restricted'}
        && $item->{'restricted'} == 1 )
    {
        $issuingimpossible{RESTRICTED} = 1;
    }
    if ( C4::Context->preference("IndependantBranches") ) {
        my $userenv = C4::Context->userenv;
        if ( ($userenv) && ( $userenv->{flags} % 2 != 1 ) ) {
            $issuingimpossible{ITEMNOTSAMEBRANCH} = 1
              if ( $item->{C4::Context->preference("HomeOrHoldingBranch")} ne $userenv->{branch} );
            $needsconfirmation{BORRNOTSAMEBRANCH} = GetBranchName( $borrower->{'branchcode'} )
              if ( $borrower->{'branchcode'} ne $userenv->{branch} );
        }
    }

    #
    # CHECK IF BOOK ALREADY ISSUED TO THIS BORROWER
    #
    if ( $issue->{borrowernumber} && $issue->{borrowernumber} eq $borrower->{'borrowernumber'} )
    {

        # Already issued to current borrower. Ask whether the loan should
        # be renewed.
        my ($CanBookBeRenewed,$renewerror) = CanBookBeRenewed(
            $borrower->{'borrowernumber'},
            $item->{'itemnumber'}
        );
        if ( $CanBookBeRenewed == 0 ) {    # no more renewals allowed
            $issuingimpossible{NO_MORE_RENEWALS} = 1;
        }
        else {
            $needsconfirmation{RENEW_ISSUE} = 1;
        }
    }
    elsif ($issue->{borrowernumber}) {

        # issued to someone else
        my $currborinfo =    C4::Members::GetMemberDetails( $issue->{borrowernumber} );

#        warn "=>.$currborinfo->{'firstname'} $currborinfo->{'surname'} ($currborinfo->{'cardnumber'})";
        $needsconfirmation{ISSUED_TO_ANOTHER} = 1;
        $needsconfirmation{issued_firstname} = $currborinfo->{'firstname'};
        $needsconfirmation{issued_surname} = $currborinfo->{'surname'};
        $needsconfirmation{issued_cardnumber} = $currborinfo->{'cardnumber'};
        $needsconfirmation{issued_borrowernumber} = $currborinfo->{'borrowernumber'};
    }

    # See if the item is on reserve.
    my ( $restype, $res ) = C4::Reserves::CheckReserves( $item->{'itemnumber'} );
    if ($restype) {
		my $resbor = $res->{'borrowernumber'};
		my ( $resborrower ) = C4::Members::GetMemberDetails( $resbor, 0 );
		my $branches  = GetBranches();
		my $branchname = $branches->{ $res->{'branchcode'} }->{'branchname'};
        if ( $resbor ne $borrower->{'borrowernumber'} && $restype eq "Waiting" )
        {
            # The item is on reserve and waiting, but has been
            # reserved by some other patron.
            $needsconfirmation{RESERVE_WAITING} = 1;
            $needsconfirmation{'resfirstname'} = $resborrower->{'firstname'};
            $needsconfirmation{'ressurname'} = $resborrower->{'surname'};
            $needsconfirmation{'rescardnumber'} = $resborrower->{'cardnumber'};
            $needsconfirmation{'resborrowernumber'} = $resborrower->{'borrowernumber'};
            $needsconfirmation{'resbranchname'} = $branchname;
            $needsconfirmation{'reswaitingdate'} = format_date($res->{'waitingdate'});
        }
        elsif ( $restype eq "Reserved" ) {
            # The item is on reserve for someone else.
            $needsconfirmation{RESERVED} = 1;
            $needsconfirmation{'resfirstname'} = $resborrower->{'firstname'};
            $needsconfirmation{'ressurname'} = $resborrower->{'surname'};
            $needsconfirmation{'rescardnumber'} = $resborrower->{'cardnumber'};
            $needsconfirmation{'resborrowernumber'} = $resborrower->{'borrowernumber'};
            $needsconfirmation{'resbranchname'} = $branchname;
            $needsconfirmation{'resreservedate'} = format_date($res->{'reservedate'});
        }
    }
	return ( \%issuingimpossible, \%needsconfirmation );
}

=head2 AddIssue

  &AddIssue($borrower, $barcode, [$datedue], [$cancelreserve], [$issuedate])

Issue a book. Does no check, they are done in CanBookBeIssued. If we reach this sub, it means the user confirmed if needed.

=over 4

=item C<$borrower> is a hash with borrower informations (from GetMemberDetails).

=item C<$barcode> is the barcode of the item being issued.

=item C<$datedue> is a C4::Dates object for the max date of return, i.e. the date due (optional).
Calculated if empty.

=item C<$cancelreserve> is 1 to override and cancel any pending reserves for the item (optional).

=item C<$issuedate> is the date to issue the item in iso (YYYY-MM-DD) format (optional).
Defaults to today.  Unlike C<$datedue>, NOT a C4::Dates object, unfortunately.

AddIssue does the following things :

  - step 01: check that there is a borrowernumber & a barcode provided
  - check for RENEWAL (book issued & being issued to the same patron)
      - renewal YES = Calculate Charge & renew
      - renewal NO  =
          * BOOK ACTUALLY ISSUED ? do a return if book is actually issued (but to someone else)
          * RESERVE PLACED ?
              - fill reserve if reserve to this patron
              - cancel reserve or not, otherwise
          * TRANSFERT PENDING ?
              - complete the transfert
          * ISSUE THE BOOK

=back

=cut

sub AddIssue {
    my ( $borrower, $barcode, $datedue, $cancelreserve, $issuedate, $sipmode) = @_;
    my $dbh = C4::Context->dbh;
	my $barcodecheck=CheckValidBarcode($barcode);
    # $issuedate defaults to today.
    if ( ! defined $issuedate ) {
        $issuedate = strftime( "%Y-%m-%d", localtime );
        # TODO: for hourly circ, this will need to be a C4::Dates object
        # and all calls to AddIssue including issuedate will need to pass a Dates object.
    }
	if ($borrower and $barcode and $barcodecheck ne '0'){
		# find which item we issue
		my $item = GetItem('', $barcode) or return undef;	# if we don't get an Item, abort.
		my $branch = _GetCircControlBranch($item,$borrower);
		
		# get actual issuing if there is one
		my $actualissue = GetItemIssue( $item->{itemnumber});
		
		# get biblioinformation for this item
		my $biblio = GetBiblioFromItemNumber($item->{itemnumber});
		
		#
		# check if we just renew the issue.
		#
		if ($actualissue->{borrowernumber} eq $borrower->{'borrowernumber'}) {
			$datedue = AddRenewal(
				$borrower->{'borrowernumber'},
				$item->{'itemnumber'},
				$branch,
				$datedue,
                $issuedate, # here interpreted as the renewal date
			);
		}
		else {
        # it's NOT a renewal
			if ( $actualissue->{borrowernumber}) {
				# This book is currently on loan, but not to the person
				# who wants to borrow it now. mark it returned before issuing to the new borrower
				AddReturn(
					$item->{'barcode'},
					C4::Context->userenv->{'branch'}
				);
			}

			# See if the item is on reserve.
			my ( $restype, $res ) =
			  C4::Reserves::CheckReserves( $item->{'itemnumber'} );
			if ($restype) {
				my $resbor = $res->{'borrowernumber'};
				if ( $resbor eq $borrower->{'borrowernumber'} ) {
					# The item is reserved by the current patron
					ModReserveFill($res);
				}
				elsif ( $restype eq "Waiting" ) {
					# warn "Waiting";
					# The item is on reserve and waiting, but has been
					# reserved by some other patron.
				}
				elsif ( $restype eq "Reserved" ) {
					# warn "Reserved";
					# The item is reserved by someone else.
					if ($cancelreserve) { # cancel reserves on this item
						CancelReserve(0, $res->{'itemnumber'}, $res->{'borrowernumber'});
					}
				}
				if ($cancelreserve) {
					CancelReserve($res->{'biblionumber'}, 0, $res->{'borrowernumber'});
				}
				else {
					# set waiting reserve to first in reserve queue as book isn't waiting now
					ModReserve(1,
						$res->{'biblionumber'},
						$res->{'borrowernumber'},
						$res->{'branchcode'}
					);
				}
			}

			# Starting process for transfer job (checking transfert and validate it if we have one)
            my ($datesent) = GetTransfers($item->{'itemnumber'});
            if ($datesent) {
        # 	updating line of branchtranfert to finish it, and changing the to branch value, implement a comment for visibility of this case (maybe for stats ....)
                my $sth =
                    $dbh->prepare(
                    "UPDATE branchtransfers 
                        SET datearrived = now(),
                        tobranch = ?,
                        comments = 'Forced branchtransfer'
                    WHERE itemnumber= ? AND datearrived IS NULL"
                    );
                $sth->execute(C4::Context->userenv->{'branch'},$item->{'itemnumber'});
            }

        # Record in the database the fact that the book was issued.
        my $sth =
          $dbh->prepare(
                "INSERT INTO issues 
                    (borrowernumber, itemnumber,issuedate, date_due, branchcode)
                VALUES (?,?,?,?,?)"
          );
        unless ($datedue) {
            my $itype = ( C4::Context->preference('item-level_itypes') ) ? $biblio->{'itype'} : $biblio->{'itemtype'};
            $datedue = CalcDateDue( C4::Dates->new( $issuedate, 'iso' ), $itype, $branch, $borrower );

        }
        $sth->execute(
            $borrower->{'borrowernumber'},      # borrowernumber
            $item->{'itemnumber'},              # itemnumber
            $issuedate,                         # issuedate
            $datedue->output('iso'),            # date_due
            C4::Context->userenv->{'branch'}    # branchcode
        );
        $sth->finish;
        if ( C4::Context->preference('ReturnToShelvingCart') ) { ## ReturnToShelvingCart is on, anything issued should be taken off the cart.
          CartToShelf( $item->{'itemnumber'} );
        }
        $item->{'issues'}++;
        ModItem({ issues           => $item->{'issues'},
                  holdingbranch    => C4::Context->userenv->{'branch'},
                  itemlost         => 0,
                  datelastborrowed => C4::Dates->new()->output('iso'),
                  onloan           => $datedue->output('iso'),
                }, $item->{'biblionumber'}, $item->{'itemnumber'});
        ModDateLastSeen( $item->{'itemnumber'} );

        # If it costs to borrow this book, charge it to the patron's account.
        my ( $charge, $itemtype ) = GetIssuingCharges(
            $item->{'itemnumber'},
            $borrower->{'borrowernumber'}
        );
        if ( $charge > 0 ) {
            AddIssuingCharge(
                $item->{'itemnumber'},
                $borrower->{'borrowernumber'}, $charge
            );
            $item->{'charge'} = $charge;
        }

        # Record the fact that this book was issued.
        &UpdateStats(
            C4::Context->userenv->{'branch'},
            'issue', $charge,
            ($sipmode ? "SIP-$sipmode" : ''), $item->{'itemnumber'},
            $item->{'itype'}, $borrower->{'borrowernumber'}
        );

        # Send a checkout slip.
        my $circulation_alert = 'C4::ItemCirculationAlertPreference';
        my %conditions = (
            branchcode   => $branch,
            categorycode => $borrower->{categorycode},
            item_type    => $item->{itype},
            notification => 'CHECKOUT',
        );
        if ($circulation_alert->is_enabled_for(\%conditions)) {
            SendCirculationAlert({
                type     => 'CHECKOUT',
                item     => $item,
                borrower => $borrower,
                branch   => $branch,
            });
        }
    }

    logaction("CIRCULATION", "ISSUE", $borrower->{'borrowernumber'}, $biblio->{'biblionumber'})
        if C4::Context->preference("IssueLog");
  }
  return ($datedue);	# not necessarily the same as when it came in!
}

=head2 GetLoanLength

  my $loanlength = &GetLoanLength($borrowertype,$itemtype,branchcode)

Get loan length for an itemtype, a borrower type and a branch

=cut

sub GetLoanLength {
    my ( $borrowertype, $itemtype, $branchcode ) = @_;
    my $dbh = C4::Context->dbh;
    my $sth =
      $dbh->prepare(
"select issuelength from issuingrules where categorycode=? and itemtype=? and branchcode=? and issuelength is not null"
      );
# warn "in get loan lenght $borrowertype $itemtype $branchcode ";
# try to find issuelength & return the 1st available.
# check with borrowertype, itemtype and branchcode, then without one of those parameters
    $sth->execute( $borrowertype, $itemtype, $branchcode );
    my $loanlength = $sth->fetchrow_hashref;
    return $loanlength->{issuelength}
      if defined($loanlength) && $loanlength->{issuelength} ne 'NULL';

    $sth->execute( $borrowertype, "*", $branchcode );
    $loanlength = $sth->fetchrow_hashref;
    return $loanlength->{issuelength}
      if defined($loanlength) && $loanlength->{issuelength} ne 'NULL';

    $sth->execute( "*", $itemtype, $branchcode );
    $loanlength = $sth->fetchrow_hashref;
    return $loanlength->{issuelength}
      if defined($loanlength) && $loanlength->{issuelength} ne 'NULL';

    $sth->execute( "*", "*", $branchcode );
    $loanlength = $sth->fetchrow_hashref;
    return $loanlength->{issuelength}
      if defined($loanlength) && $loanlength->{issuelength} ne 'NULL';

    $sth->execute( $borrowertype, $itemtype, "*" );
    $loanlength = $sth->fetchrow_hashref;
    return $loanlength->{issuelength}
      if defined($loanlength) && $loanlength->{issuelength} ne 'NULL';

    $sth->execute( $borrowertype, "*", "*" );
    $loanlength = $sth->fetchrow_hashref;
    return $loanlength->{issuelength}
      if defined($loanlength) && $loanlength->{issuelength} ne 'NULL';

    $sth->execute( "*", $itemtype, "*" );
    $loanlength = $sth->fetchrow_hashref;
    return $loanlength->{issuelength}
      if defined($loanlength) && $loanlength->{issuelength} ne 'NULL';

    $sth->execute( "*", "*", "*" );
    $loanlength = $sth->fetchrow_hashref;
    return $loanlength->{issuelength}
      if defined($loanlength) && $loanlength->{issuelength} ne 'NULL';

    # if no rule is set => 21 days (hardcoded)
    return 21;
}


=head2 GetHardDueDate

  my ($hardduedate,$hardduedatecompare) = &GetHardDueDate($borrowertype,$itemtype,branchcode)

Get the Hard Due Date and it's comparison for an itemtype, a borrower type and a branch

=cut

sub GetHardDueDate {
    my ( $borrowertype, $itemtype, $branchcode ) = @_;
    my $dbh = C4::Context->dbh;
    my $sth =
      $dbh->prepare(
"select hardduedate, hardduedatecompare from issuingrules where categorycode=? and itemtype=? and branchcode=?"
      );
    $sth->execute( $borrowertype, $itemtype, $branchcode );
    my $results = $sth->fetchrow_hashref;
    return (C4::Dates->new($results->{hardduedate}, 'iso'),$results->{hardduedatecompare})
      if defined($results) && $results->{hardduedate} ne 'NULL';

    $sth->execute( $borrowertype, "*", $branchcode );
    $results = $sth->fetchrow_hashref;
    return (C4::Dates->new($results->{hardduedate}, 'iso'),$results->{hardduedatecompare})
      if defined($results) && $results->{hardduedate} ne 'NULL';

    $sth->execute( "*", $itemtype, $branchcode );
    $results = $sth->fetchrow_hashref;
    return (C4::Dates->new($results->{hardduedate}, 'iso'),$results->{hardduedatecompare})
      if defined($results) && $results->{hardduedate} ne 'NULL';

    $sth->execute( "*", "*", $branchcode );
    $results = $sth->fetchrow_hashref;
    return (C4::Dates->new($results->{hardduedate}, 'iso'),$results->{hardduedatecompare})
      if defined($results) && $results->{hardduedate} ne 'NULL';

    $sth->execute( $borrowertype, $itemtype, "*" );
    $results = $sth->fetchrow_hashref;
    return (C4::Dates->new($results->{hardduedate}, 'iso'),$results->{hardduedatecompare})
      if defined($results) && $results->{hardduedate} ne 'NULL';

    $sth->execute( $borrowertype, "*", "*" );
    $results = $sth->fetchrow_hashref;
    return (C4::Dates->new($results->{hardduedate}, 'iso'),$results->{hardduedatecompare})
      if defined($results) && $results->{hardduedate} ne 'NULL';

    $sth->execute( "*", $itemtype, "*" );
    $results = $sth->fetchrow_hashref;
    return (C4::Dates->new($results->{hardduedate}, 'iso'),$results->{hardduedatecompare})
      if defined($results) && $results->{hardduedate} ne 'NULL';

    $sth->execute( "*", "*", "*" );
    $results = $sth->fetchrow_hashref;
    return (C4::Dates->new($results->{hardduedate}, 'iso'),$results->{hardduedatecompare})
      if defined($results) && $results->{hardduedate} ne 'NULL';

    # if no rule is set => return undefined
    return (undef, undef);
}

=head2 GetIssuingRule

  my $irule = &GetIssuingRule($borrowertype,$itemtype,branchcode)

FIXME - This is a copy-paste of GetLoanLength
as a stop-gap.  Do not wish to change API for GetLoanLength 
this close to release, however, Overdues::GetIssuingRules is broken.

Get the issuing rule for an itemtype, a borrower type and a branch
Returns a hashref from the issuingrules table.

=cut

sub GetIssuingRule {
    my ( $borrowertype, $itemtype, $branchcode ) = @_;
    my $dbh = C4::Context->dbh;
    my $sth =  $dbh->prepare( "select * from issuingrules where categorycode=? and itemtype=? and branchcode=? and issuelength is not null"  );
    my $irule;

	$sth->execute( $borrowertype, $itemtype, $branchcode );
    $irule = $sth->fetchrow_hashref;
    return $irule if defined($irule) ;

    $sth->execute( $borrowertype, "*", $branchcode );
    $irule = $sth->fetchrow_hashref;
    return $irule if defined($irule) ;

    $sth->execute( "*", $itemtype, $branchcode );
    $irule = $sth->fetchrow_hashref;
    return $irule if defined($irule) ;

    $sth->execute( "*", "*", $branchcode );
    $irule = $sth->fetchrow_hashref;
    return $irule if defined($irule) ;

    $sth->execute( $borrowertype, $itemtype, "*" );
    $irule = $sth->fetchrow_hashref;
    return $irule if defined($irule) ;

    $sth->execute( $borrowertype, "*", "*" );
    $irule = $sth->fetchrow_hashref;
    return $irule if defined($irule) ;

    $sth->execute( "*", $itemtype, "*" );
    $irule = $sth->fetchrow_hashref;
    return $irule if defined($irule) ;

    $sth->execute( "*", "*", "*" );
    $irule = $sth->fetchrow_hashref;
    return $irule if defined($irule) ;

    # if no rule matches,
    return undef;
}

=head2 GetBranchBorrowerCircRule

  my $branch_cat_rule = GetBranchBorrowerCircRule($branchcode, $categorycode);

Retrieves circulation rule attributes that apply to the given
branch and patron category, regardless of item type.  
The return value is a hashref containing the following key:

maxissueqty - maximum number of loans that a
patron of the given category can have at the given
branch.  If the value is undef, no limit.

This will first check for a specific branch and
category match from branch_borrower_circ_rules. 

If no rule is found, it will then check default_branch_circ_rules
(same branch, default category).  If no rule is found,
it will then check default_borrower_circ_rules (default 
branch, same category), then failing that, default_circ_rules
(default branch, default category).

If no rule has been found in the database, it will default to
the buillt in rule:

maxissueqty - undef

C<$branchcode> and C<$categorycode> should contain the
literal branch code and patron category code, respectively - no
wildcards.

=cut

sub GetBranchBorrowerCircRule {
    my $branchcode = shift;
    my $categorycode = shift;

    my $branch_cat_query = "SELECT maxissueqty
                            FROM branch_borrower_circ_rules
                            WHERE branchcode = ?
                            AND   categorycode = ?";
    my $dbh = C4::Context->dbh();
    my $sth = $dbh->prepare($branch_cat_query);
    $sth->execute($branchcode, $categorycode);
    my $result;
    if ($result = $sth->fetchrow_hashref()) {
        return $result;
    }

    # try same branch, default borrower category
    my $branch_query = "SELECT maxissueqty
                        FROM default_branch_circ_rules
                        WHERE branchcode = ?";
    $sth = $dbh->prepare($branch_query);
    $sth->execute($branchcode);
    if ($result = $sth->fetchrow_hashref()) {
        return $result;
    }

    # try default branch, same borrower category
    my $category_query = "SELECT maxissueqty
                          FROM default_borrower_circ_rules
                          WHERE categorycode = ?";
    $sth = $dbh->prepare($category_query);
    $sth->execute($categorycode);
    if ($result = $sth->fetchrow_hashref()) {
        return $result;
    }
  
    # try default branch, default borrower category
    my $default_query = "SELECT maxissueqty
                          FROM default_circ_rules";
    $sth = $dbh->prepare($default_query);
    $sth->execute();
    if ($result = $sth->fetchrow_hashref()) {
        return $result;
    }
    
    # built-in default circulation rule
    return {
        maxissueqty => undef,
    };
}

=head2 GetBranchItemRule

  my $branch_item_rule = GetBranchItemRule($branchcode, $itemtype);

Retrieves circulation rule attributes that apply to the given
branch and item type, regardless of patron category.

The return value is a hashref containing the following key:

holdallowed => Hold policy for this branch and itemtype. Possible values:
  0: No holds allowed.
  1: Holds allowed only by patrons that have the same homebranch as the item.
  2: Holds allowed from any patron.

This searches branchitemrules in the following order:

  * Same branchcode and itemtype
  * Same branchcode, itemtype '*'
  * branchcode '*', same itemtype
  * branchcode and itemtype '*'

Neither C<$branchcode> nor C<$categorycode> should be '*'.

=cut

sub GetBranchItemRule {
    my ( $branchcode, $itemtype ) = @_;
    my $dbh = C4::Context->dbh();
    my $result = {};

    my @attempts = (
        ['SELECT holdallowed
            FROM branch_item_rules
            WHERE branchcode = ?
              AND itemtype = ?', $branchcode, $itemtype],
        ['SELECT holdallowed
            FROM default_branch_circ_rules
            WHERE branchcode = ?', $branchcode],
        ['SELECT holdallowed
            FROM default_branch_item_rules
            WHERE itemtype = ?', $itemtype],
        ['SELECT holdallowed
            FROM default_circ_rules'],
    );

    foreach my $attempt (@attempts) {
        my ($query, @bind_params) = @{$attempt};

        # Since branch/category and branch/itemtype use the same per-branch
        # defaults tables, we have to check that the key we want is set, not
        # just that a row was returned
        return $result if ( defined( $result->{'holdallowed'} = $dbh->selectrow_array( $query, {}, @bind_params ) ) );
    }
    
    # built-in default circulation rule
    return {
        holdallowed => 2,
    };
}

=head2 AddReturn

  ($doreturn, $messages, $iteminformation, $borrower) =
      &AddReturn($barcode, $branch, $exemptfine, $dropbox);

Returns a book.

=over 4

=item C<$barcode> is the bar code of the book being returned.

=item C<$branch> is the code of the branch where the book is being returned.

=item C<$exemptfine> indicates that overdue charges for the item will be
removed.

=item C<$dropbox> indicates that the check-in date is assumed to be
yesterday, or the last non-holiday as defined in C4::Calendar .  If
overdue charges are applied and C<$dropbox> is true, the last charge
will be removed.  This assumes that the fines accrual script has run
for _today_.

=back

C<&AddReturn> returns a list of four items:

C<$doreturn> is true iff the return succeeded.

C<$messages> is a reference-to-hash giving feedback on the operation.
The keys of the hash are:

=over 4

=item C<BadBarcode>

No item with this barcode exists. The value is C<$barcode>.

=item C<NotIssued>

The book is not currently on loan. The value is C<$barcode>.

=item C<IsPermanent>

The book's home branch is a permanent collection. If you have borrowed
this book, you are not allowed to return it. The value is the code for
the book's home branch.

=item C<wthdrawn>

This book has been withdrawn/cancelled. The value should be ignored.

=item C<Wrongbranch>

This book has was returned to the wrong branch.  The value is a hashref
so that C<$messages->{Wrongbranch}->{Wrongbranch}> and C<$messages->{Wrongbranch}->{Rightbranch}>
contain the branchcode of the incorrect and correct return library, respectively.

=item C<ResFound>

The item was reserved. The value is a reference-to-hash whose keys are
fields from the reserves table of the Koha database, and
C<biblioitemnumber>. It also has the key C<ResFound>, whose value is
either C<Waiting>, C<Reserved>, or 0.

=back

C<$iteminformation> is a reference-to-hash, giving information about the
returned item from the issues table.

C<$borrower> is a reference-to-hash, giving information about the
patron who last borrowed the book.

=cut

sub AddReturn {
    my ( $barcode, $branch, $exemptfine, $dropbox ) = @_;
    if ($branch and not GetBranchDetail($branch)) {
        warn "AddReturn error: branch '$branch' not found.  Reverting to " . C4::Context->userenv->{'branch'};
        undef $branch;
    }
    $branch = C4::Context->userenv->{'branch'} unless $branch;  # we trust userenv to be a safe fallback/default
    my $messages;
    my $borrower;
    my $biblio;
    my $doreturn       = 1;
    my $validTransfert = 0;
    
    # get information on item
    my $itemnumber = GetItemnumberFromBarcode( $barcode );
    unless ($itemnumber) {
        return (0, { BadBarcode => $barcode }); # no barcode means no item or borrower.  bail out.
    }
    my $issue  = GetItemIssue($itemnumber);
#   warn Dumper($iteminformation);
    if ($issue and $issue->{borrowernumber}) {
        $borrower = C4::Members::GetMemberDetails($issue->{borrowernumber})
            or die "Data inconsistency: barcode $barcode (itemnumber:$itemnumber) claims to be issued to non-existant borrowernumber '$issue->{borrowernumber}'\n"
                . Dumper($issue) . "\n";
    } else {
        $messages->{'NotIssued'} = $barcode;
        # even though item is not on loan, it may still be transferred;  therefore, get current branch info
        $doreturn = 0;
        # No issue, no borrowernumber.  ONLY if $doreturn, *might* you have a $borrower later.
    }

    my $item = GetItem($itemnumber) or die "GetItem($itemnumber) failed";
        # full item data, but no borrowernumber or checkout info (no issue)
        # we know GetItem should work because GetItemnumberFromBarcode worked
    my $hbr      = C4::Context->preference("HomeOrHoldingBranchReturn") || "homebranch";
    $hbr = $item->{$hbr} || '';
        # item must be from items table -- issues table has branchcode and issuingbranch, not homebranch nor holdingbranch

    my $borrowernumber = $borrower->{'borrowernumber'} || undef;    # we don't know if we had a borrower or not

    # check if the book is in a permanent collection....
    # FIXME -- This 'PE' attribute is largely undocumented.  afaict, there's no user interface that reflects this functionality.
    if ( $hbr ) {
        my $branches = GetBranches();    # a potentially expensive call for a non-feature.
        $branches->{$hbr}->{PE} and $messages->{'IsPermanent'} = $hbr;
    }

    # if indy branches and returning to different branch, refuse the return
    if ($hbr ne $branch && C4::Context->preference("IndependantBranches")){
        $messages->{'Wrongbranch'} = {
            Wrongbranch => $branch,
            Rightbranch => $hbr,
        };
        $doreturn = 0;
        # bailing out here - in this case, current desired behavior
        # is to act as if no return ever happened at all.
        # FIXME - even in an indy branches situation, there should
        # still be an option for the library to accept the item
        # and transfer it to its owning library.
        return ( $doreturn, $messages, $issue, $borrower );
    }

    if ( $item->{'wthdrawn'} ) { # book has been cancelled
        $messages->{'wthdrawn'} = 1;
        $doreturn = 0;
    }

    # case of a return of document (deal with issues and holdingbranch)
    if ($doreturn) {
        $borrower or warn "AddReturn without current borrower";
		my $circControlBranch;
        if ($dropbox) {
            # define circControlBranch only if dropbox mode is set
            # don't allow dropbox mode to create an invalid entry in issues (issuedate > today)
            # FIXME: check issuedate > returndate, factoring in holidays
            $circControlBranch = _GetCircControlBranch($item,$borrower) unless ( $item->{'issuedate'} eq C4::Dates->today('iso') );;
        }

        if ($borrowernumber) {
            MarkIssueReturned($borrowernumber, $item->{'itemnumber'}, $circControlBranch, '', $borrower->{'privacy'});
            $messages->{'WasReturned'} = 1;    # FIXME is the "= 1" right?  This could be the borrower hash.
        }

        ModItem({ onloan => undef }, $issue->{'biblionumber'}, $item->{'itemnumber'});
    }

    # the holdingbranch is updated if the document is returned to another location.
    # this is always done regardless of whether the item was on loan or not
    if ($item->{'holdingbranch'} ne $branch) {
        UpdateHoldingbranch($branch, $item->{'itemnumber'});
        $item->{'holdingbranch'} = $branch; # update item data holdingbranch too
    }
    ModDateLastSeen( $item->{'itemnumber'} );

    # check if we have a transfer for this document
    my ($datesent,$frombranch,$tobranch) = GetTransfers( $item->{'itemnumber'} );

    # if we have a transfer to do, we update the line of transfers with the datearrived
    if ($datesent) {
        if ( $tobranch eq $branch ) {
            my $sth = C4::Context->dbh->prepare(
                "UPDATE branchtransfers SET datearrived = now() WHERE itemnumber= ? AND datearrived IS NULL"
            );
            $sth->execute( $item->{'itemnumber'} );
            # if we have a reservation with valid transfer, we can set it's status to 'W'
            C4::Reserves::ModReserveStatus($item->{'itemnumber'}, 'W');
        } else {
            $messages->{'WrongTransfer'}     = $tobranch;
            $messages->{'WrongTransferItem'} = $item->{'itemnumber'};
        }
        $validTransfert = 1;
    }

    # fix up the accounts.....
    if ($item->{'itemlost'}) {
        _FixAccountForLostAndReturned($item->{'itemnumber'}, $borrowernumber, $barcode);    # can tolerate undef $borrowernumber
        $messages->{'WasLost'} = 1;
    }

    # fix up the overdues in accounts...
    if ($borrowernumber) {
        my $fix = _FixOverduesOnReturn($borrowernumber, $item->{itemnumber}, $exemptfine, $dropbox);
        defined($fix) or warn "_FixOverduesOnReturn($borrowernumber, $item->{itemnumber}...) failed!";  # zero is OK, check defined
    }

    # find reserves.....
    # if we don't have a reserve with the status W, we launch the Checkreserves routine
    my ($resfound, $resrec) = C4::Reserves::CheckReserves( $item->{'itemnumber'} );
    if ($resfound) {
          $resrec->{'ResFound'} = $resfound;
        $messages->{'ResFound'} = $resrec;
    }

    # update stats?
    # Record the fact that this book was returned.
    UpdateStats(
        $branch, 'return', '0', '',
        $item->{'itemnumber'},
        $biblio->{'itemtype'},
        $borrowernumber
    );

    # Send a check-in slip. # NOTE: borrower may be undef.  probably shouldn't try to send messages then.
    my $circulation_alert = 'C4::ItemCirculationAlertPreference';
    my %conditions = (
        branchcode   => $branch,
        categorycode => $borrower->{categorycode},
        item_type    => $item->{itype},
        notification => 'CHECKIN',
    );
    if ($doreturn && $circulation_alert->is_enabled_for(\%conditions)) {
        SendCirculationAlert({
            type     => 'CHECKIN',
            item     => $item,
            borrower => $borrower,
            branch   => $branch,
        });
    }
    
    logaction("CIRCULATION", "RETURN", $borrowernumber, $item->{'biblionumber'})
        if C4::Context->preference("ReturnLog");
    
    # FIXME: make this comment intelligible.
    #adding message if holdingbranch is non equal a userenv branch to return the document to homebranch
    #we check, if we don't have reserv or transfert for this document, if not, return it to homebranch .

    if (($doreturn or $messages->{'NotIssued'}) and !$resfound and ($branch ne $hbr) and not $messages->{'WrongTransfer'}){
        if ( C4::Context->preference("AutomaticItemReturn"    ) or
            (C4::Context->preference("UseBranchTransferLimits") and
             ! IsBranchTransferAllowed($branch, $hbr, $item->{C4::Context->preference("BranchTransferLimitsType")} )
           )) {
            $debug and warn sprintf "about to call ModItemTransfer(%s, %s, %s)", $item->{'itemnumber'},$branch, $hbr;
            $debug and warn "item: " . Dumper($item);
            ModItemTransfer($item->{'itemnumber'}, $branch, $hbr);
            $messages->{'WasTransfered'} = 1;
        } else {
            $messages->{'NeedsTransfer'} = 1;   # TODO: instead of 1, specify branchcode that the transfer SHOULD go to, $item->{homebranch}
        }
    }
    return ( $doreturn, $messages, $issue, $borrower );
}

=head2 MarkIssueReturned

  MarkIssueReturned($borrowernumber, $itemnumber, $dropbox_branch, $returndate, $privacy);

Unconditionally marks an issue as being returned by
moving the C<issues> row to C<old_issues> and
setting C<returndate> to the current date, or
the last non-holiday date of the branccode specified in
C<dropbox_branch> .  Assumes you've already checked that 
it's safe to do this, i.e. last non-holiday > issuedate.

if C<$returndate> is specified (in iso format), it is used as the date
of the return. It is ignored when a dropbox_branch is passed in.

C<$privacy> contains the privacy parameter. If the patron has set privacy to 2,
the old_issue is immediately anonymised

Ideally, this function would be internal to C<C4::Circulation>,
not exported, but it is currently needed by one 
routine in C<C4::Accounts>.

=cut

sub MarkIssueReturned {
    my ( $borrowernumber, $itemnumber, $dropbox_branch, $returndate, $privacy ) = @_;
    my $dbh   = C4::Context->dbh;
    my $query = "UPDATE issues SET returndate=";
    my @bind;
    if ($dropbox_branch) {
        my $calendar = C4::Calendar->new( branchcode => $dropbox_branch );
        my $dropboxdate = $calendar->addDate( C4::Dates->new(), -1 );
        $query .= " ? ";
        push @bind, $dropboxdate->output('iso');
    } elsif ($returndate) {
        $query .= " ? ";
        push @bind, $returndate;
    } else {
        $query .= " now() ";
    }
    $query .= " WHERE  borrowernumber = ?  AND itemnumber = ?";
    push @bind, $borrowernumber, $itemnumber;
    # FIXME transaction
    my $sth_upd  = $dbh->prepare($query);
    $sth_upd->execute(@bind);
    my $sth_copy = $dbh->prepare("INSERT INTO old_issues SELECT * FROM issues 
                                  WHERE borrowernumber = ?
                                  AND itemnumber = ?");
    $sth_copy->execute($borrowernumber, $itemnumber);
    # anonymise patron checkout immediately if $privacy set to 2 and AnonymousPatron is set to a valid borrowernumber
    if ( $privacy == 2) {
        # The default of 0 does not work due to foreign key constraints
        # The anonymisation will fail quietly if AnonymousPatron is not a valid entry
        my $anonymouspatron = (C4::Context->preference('AnonymousPatron')) ? C4::Context->preference('AnonymousPatron') : 0;
        my $sth_ano = $dbh->prepare("UPDATE old_issues SET borrowernumber=?
                                  WHERE borrowernumber = ?
                                  AND itemnumber = ?");
       $sth_ano->execute($anonymouspatron, $borrowernumber, $itemnumber);
    }
    my $sth_del  = $dbh->prepare("DELETE FROM issues
                                  WHERE borrowernumber = ?
                                  AND itemnumber = ?");
    $sth_del->execute($borrowernumber, $itemnumber);
}

=head2 _FixOverduesOnReturn

   &_FixOverduesOnReturn($brn,$itm, $exemptfine, $dropboxmode);

C<$brn> borrowernumber

C<$itm> itemnumber

C<$exemptfine> BOOL -- remove overdue charge associated with this issue. 
C<$dropboxmode> BOOL -- remove lastincrement on overdue charge associated with this issue.

Internal function, called only by AddReturn

=cut

sub _FixOverduesOnReturn {
    my ($borrowernumber, $item);
    unless ($borrowernumber = shift) {
        warn "_FixOverduesOnReturn() not supplied valid borrowernumber";
        return;
    }
    unless ($item = shift) {
        warn "_FixOverduesOnReturn() not supplied valid itemnumber";
        return;
    }
    my ($exemptfine, $dropbox) = @_;
    my $dbh = C4::Context->dbh;

    # check for overdue fine
    my $sth = $dbh->prepare(
"SELECT * FROM accountlines WHERE (borrowernumber = ?) AND (itemnumber = ?) AND (accounttype='FU' OR accounttype='O')"
    );
    $sth->execute( $borrowernumber, $item );

    # alter fine to show that the book has been returned
    my $data = $sth->fetchrow_hashref;
    return 0 unless $data;    # no warning, there's just nothing to fix

    my $uquery;
    my @bind = ($borrowernumber, $item, $data->{'accountno'});
    if ($exemptfine) {
        $uquery = "update accountlines set accounttype='FFOR', amountoutstanding=0";
        if (C4::Context->preference("FinesLog")) {
            &logaction("FINES", 'MODIFY',$borrowernumber,"Overdue forgiven: item $item");
        }
    } elsif ($dropbox && $data->{lastincrement}) {
        my $outstanding = $data->{amountoutstanding} - $data->{lastincrement} ;
        my $amt = $data->{amount} - $data->{lastincrement} ;
        if (C4::Context->preference("FinesLog")) {
            &logaction("FINES", 'MODIFY',$borrowernumber,"Dropbox adjustment $amt, item $item");
        }
         $uquery = "update accountlines set accounttype='F' ";
         if($outstanding  >= 0 && $amt >=0) {
            $uquery .= ", amount = ? , amountoutstanding=? ";
            unshift @bind, ($amt, $outstanding) ;
        }
    } else {
        $uquery = "update accountlines set accounttype='F' ";
    }
    $uquery .= " where (borrowernumber = ?) and (itemnumber = ?) and (accountno = ?)";
    my $usth = $dbh->prepare($uquery);
    return $usth->execute(@bind);
}

=head2 _FixAccountForLostAndReturned

  &_FixAccountForLostAndReturned($itemnumber, [$borrowernumber, $barcode]);

Calculates the charge for a book lost and returned.

Internal function, not exported, called only by AddReturn.

FIXME: This function reflects how inscrutable fines logic is.  Fix both.
FIXME: Give a positive return value on success.  It might be the $borrowernumber who received credit, or the amount forgiven.

=cut

sub _FixAccountForLostAndReturned {
    my $itemnumber     = shift or return;
    my $borrowernumber = @_ ? shift : undef;
    my $item_id        = @_ ? shift : $itemnumber;  # Send the barcode if you want that logged in the description
    my $dbh = C4::Context->dbh;
    # check for charge made for lost book
    my $sth = $dbh->prepare("SELECT * FROM accountlines WHERE (itemnumber = ?) AND (accounttype='L' OR accounttype='Rep') ORDER BY date DESC");
    $sth->execute($itemnumber);
    my $data = $sth->fetchrow_hashref;
    $data or return;    # bail if there is nothing to do

    # writeoff this amount
    my $offset;
    my $amount = $data->{'amount'};
    my $acctno = $data->{'accountno'};
    my $amountleft;                                             # Starts off undef/zero.
    if ($data->{'amountoutstanding'} == $amount) {
        $offset     = $data->{'amount'};
        $amountleft = 0;                                        # Hey, it's zero here, too.
    } else {
        $offset     = $amount - $data->{'amountoutstanding'};   # Um, isn't this the same as ZERO?  We just tested those two things are ==
        $amountleft = $data->{'amountoutstanding'} - $amount;   # Um, isn't this the same as ZERO?  We just tested those two things are ==
    }
    my $usth = $dbh->prepare("UPDATE accountlines SET accounttype = 'LR',amountoutstanding='0'
        WHERE (borrowernumber = ?)
        AND (itemnumber = ?) AND (accountno = ?) ");
    $usth->execute($data->{'borrowernumber'},$itemnumber,$acctno);      # We might be adjusting an account for some OTHER borrowernumber now.  Not the one we passed in.  
    #check if any credit is left if so writeoff other accounts
    my $nextaccntno = getnextacctno($data->{'borrowernumber'});
    $amountleft *= -1 if ($amountleft < 0);
    if ($amountleft > 0) {
        my $msth = $dbh->prepare("SELECT * FROM accountlines WHERE (borrowernumber = ?)
                            AND (amountoutstanding >0) ORDER BY date");     # might want to order by amountoustanding ASC (pay smallest first)
        $msth->execute($data->{'borrowernumber'});
        # offset transactions
        my $newamtos;
        my $accdata;
        while (($accdata=$msth->fetchrow_hashref) and ($amountleft>0)){
            if ($accdata->{'amountoutstanding'} < $amountleft) {
                $newamtos = 0;
                $amountleft -= $accdata->{'amountoutstanding'};
            }  else {
                $newamtos = $accdata->{'amountoutstanding'} - $amountleft;
                $amountleft = 0;
            }
            my $thisacct = $accdata->{'accountno'};
            # FIXME: move prepares outside while loop!
            my $usth = $dbh->prepare("UPDATE accountlines SET amountoutstanding= ?
                    WHERE (borrowernumber = ?)
                    AND (accountno=?)");
            $usth->execute($newamtos,$data->{'borrowernumber'},'$thisacct');    # FIXME: '$thisacct' is a string literal!
            $usth = $dbh->prepare("INSERT INTO accountoffsets
                (borrowernumber, accountno, offsetaccount,  offsetamount)
                VALUES
                (?,?,?,?)");
            $usth->execute($data->{'borrowernumber'},$accdata->{'accountno'},$nextaccntno,$newamtos);
        }
        $msth->finish;  # $msth might actually have data left
    }
    $amountleft *= -1 if ($amountleft > 0);
    my $desc = "Item Returned " . $item_id;
    $usth = $dbh->prepare("INSERT INTO accountlines
        (borrowernumber,accountno,date,amount,description,accounttype,amountoutstanding)
        VALUES (?,?,now(),?,?,'CR',?)");
    $usth->execute($data->{'borrowernumber'},$nextaccntno,0-$amount,$desc,$amountleft);
    if ($borrowernumber) {
        # FIXME: same as query above.  use 1 sth for both
        $usth = $dbh->prepare("INSERT INTO accountoffsets
            (borrowernumber, accountno, offsetaccount,  offsetamount)
            VALUES (?,?,?,?)");
        $usth->execute($borrowernumber, $data->{'accountno'}, $nextaccntno, $offset);
    }
    ModItem({ paidfor => '' }, undef, $itemnumber);
    return;
}

=head2 _GetCircControlBranch

   my $circ_control_branch = _GetCircControlBranch($iteminfos, $borrower);

Internal function : 

Return the library code to be used to determine which circulation
policy applies to a transaction.  Looks up the CircControl and
HomeOrHoldingBranch system preferences.

C<$iteminfos> is a hashref to iteminfo. Only {homebranch or holdingbranch} is used.

C<$borrower> is a hashref to borrower. Only {branchcode} is used.

=cut

sub _GetCircControlBranch {
    my ($item, $borrower) = @_;
    my $circcontrol = C4::Context->preference('CircControl');
    my $branch;

    if ($circcontrol eq 'PickupLibrary') {
        $branch= C4::Context->userenv->{'branch'} if C4::Context->userenv;
    } elsif ($circcontrol eq 'PatronLibrary') {
        $branch=$borrower->{branchcode};
    } else {
        my $branchfield = C4::Context->preference('HomeOrHoldingBranch') || 'homebranch';
        $branch = $item->{$branchfield};
        # default to item home branch if holdingbranch is used
        # and is not defined
        if (!defined($branch) && $branchfield eq 'holdingbranch') {
            $branch = $item->{homebranch};
        }
    }
    return $branch;
}






=head2 GetItemIssue

  $issue = &GetItemIssue($itemnumber);

Returns patron currently having a book, or undef if not checked out.

C<$itemnumber> is the itemnumber.

C<$issue> is a hashref of the row from the issues table.

=cut

sub GetItemIssue {
    my ($itemnumber) = @_;
    return unless $itemnumber;
    my $sth = C4::Context->dbh->prepare(
        "SELECT *
        FROM issues 
        LEFT JOIN items ON issues.itemnumber=items.itemnumber
        WHERE issues.itemnumber=?");
    $sth->execute($itemnumber);
    my $data = $sth->fetchrow_hashref;
    return unless $data;
    $data->{'overdue'} = ($data->{'date_due'} lt C4::Dates->today('iso')) ? 1 : 0;
    return ($data);
}

=head2 GetOpenIssue

  $issue = GetOpenIssue( $itemnumber );

Returns the row from the issues table if the item is currently issued, undef if the item is not currently issued

C<$itemnumber> is the item's itemnumber

Returns a hashref

=cut

sub GetOpenIssue {
  my ( $itemnumber ) = @_;

  my $dbh = C4::Context->dbh;  
  my $sth = $dbh->prepare( "SELECT * FROM issues WHERE itemnumber = ? AND returndate IS NULL" );
  $sth->execute( $itemnumber );
  my $issue = $sth->fetchrow_hashref();
  return $issue;
}

=head2 GetItemIssues

  $issues = &GetItemIssues($itemnumber, $history);

Returns patrons that have issued a book

C<$itemnumber> is the itemnumber
C<$history> is false if you just want the current "issuer" (if any)
and true if you want issues history from old_issues also.

Returns reference to an array of hashes

=cut

sub GetItemIssues {
    my ( $itemnumber, $history ) = @_;
    
    my $today = C4::Dates->today('iso');  # get today date
    my $sql = "SELECT * FROM issues 
              JOIN borrowers USING (borrowernumber)
              JOIN items     USING (itemnumber)
              WHERE issues.itemnumber = ? ";
    if ($history) {
        $sql .= "UNION ALL
                 SELECT * FROM old_issues 
                 LEFT JOIN borrowers USING (borrowernumber)
                 JOIN items USING (itemnumber)
                 WHERE old_issues.itemnumber = ? ";
    }
    $sql .= "ORDER BY date_due DESC";
    my $sth = C4::Context->dbh->prepare($sql);
    if ($history) {
        $sth->execute($itemnumber, $itemnumber);
    } else {
        $sth->execute($itemnumber);
    }
    my $results = $sth->fetchall_arrayref({});
    foreach (@$results) {
        $_->{'overdue'} = ($_->{'date_due'} lt $today) ? 1 : 0;
    }
    return $results;
}

=head2 GetBiblioIssues

  $issues = GetBiblioIssues($biblionumber);

this function get all issues from a biblionumber.

Return:
C<$issues> is a reference to array which each value is ref-to-hash. This ref-to-hash containts all column from
tables issues and the firstname,surname & cardnumber from borrowers.

=cut

sub GetBiblioIssues {
    my $biblionumber = shift;
    return undef unless $biblionumber;
    my $dbh   = C4::Context->dbh;
    my $query = "
        SELECT issues.*,items.barcode,biblio.biblionumber,biblio.title, biblio.author,borrowers.cardnumber,borrowers.surname,borrowers.firstname
        FROM issues
            LEFT JOIN borrowers ON borrowers.borrowernumber = issues.borrowernumber
            LEFT JOIN items ON issues.itemnumber = items.itemnumber
            LEFT JOIN biblioitems ON items.itemnumber = biblioitems.biblioitemnumber
            LEFT JOIN biblio ON biblio.biblionumber = items.biblionumber
        WHERE biblio.biblionumber = ?
        UNION ALL
        SELECT old_issues.*,items.barcode,biblio.biblionumber,biblio.title, biblio.author,borrowers.cardnumber,borrowers.surname,borrowers.firstname
        FROM old_issues
            LEFT JOIN borrowers ON borrowers.borrowernumber = old_issues.borrowernumber
            LEFT JOIN items ON old_issues.itemnumber = items.itemnumber
            LEFT JOIN biblioitems ON items.itemnumber = biblioitems.biblioitemnumber
            LEFT JOIN biblio ON biblio.biblionumber = items.biblionumber
        WHERE biblio.biblionumber = ?
        ORDER BY timestamp
    ";
    my $sth = $dbh->prepare($query);
    $sth->execute($biblionumber, $biblionumber);

    my @issues;
    while ( my $data = $sth->fetchrow_hashref ) {
        push @issues, $data;
    }
    return \@issues;
}

=head2 GetUpcomingDueIssues

  my $upcoming_dues = GetUpcomingDueIssues( { days_in_advance => 4 } );

=cut

sub GetUpcomingDueIssues {
    my $params = shift;

    $params->{'days_in_advance'} = 7 unless exists $params->{'days_in_advance'};
    my $dbh = C4::Context->dbh;

    my $statement = <<END_SQL;
SELECT issues.*, items.itype as itemtype, items.homebranch, TO_DAYS( date_due )-TO_DAYS( NOW() ) as days_until_due, branches.branchemail
FROM issues 
LEFT JOIN items USING (itemnumber)
LEFT OUTER JOIN branches USING (branchcode)
WhERE returndate is NULL
AND ( TO_DAYS( NOW() )-TO_DAYS( date_due ) ) < ?
END_SQL

    my @bind_parameters = ( $params->{'days_in_advance'} );
    
    my $sth = $dbh->prepare( $statement );
    $sth->execute( @bind_parameters );
    my $upcoming_dues = $sth->fetchall_arrayref({});
    $sth->finish;

    return $upcoming_dues;
}

=head2 CanBookBeRenewed

  ($ok,$error) = &CanBookBeRenewed($borrowernumber, $itemnumber[, $override_limit]);

Find out whether a borrowed item may be renewed.

C<$dbh> is a DBI handle to the Koha database.

C<$borrowernumber> is the borrower number of the patron who currently
has the item on loan.

C<$itemnumber> is the number of the item to renew.

C<$override_limit>, if supplied with a true value, causes
the limit on the number of times that the loan can be renewed
(as controlled by the item type) to be ignored.

C<$CanBookBeRenewed> returns a true value iff the item may be renewed. The
item must currently be on loan to the specified borrower; renewals
must be allowed for the item's type; and the borrower must not have
already renewed the loan. $error will contain the reason the renewal can not proceed

=cut

sub CanBookBeRenewed {

    # check renewal status
    my ( $borrowernumber, $itemnumber, $override_limit ) = @_;
    my $dbh       = C4::Context->dbh;
    my $renews    = 1;
    my $renewokay = 0;
	my $error;

    # Look in the issues table for this item, lent to this borrower,
    # and not yet returned.

    # Look in the issues table for this item, lent to this borrower,
    # and not yet returned.
    my %branch = (
            'ItemHomeLibrary' => 'items.homebranch',
            'PickupLibrary'   => 'items.holdingbranch',
            'PatronLibrary'   => 'borrowers.branchcode'
            );
    my $controlbranch = $branch{C4::Context->preference('CircControl')};
    my $itype         = C4::Context->preference('item-level_itypes') ? 'items.itype' : 'biblioitems.itemtype';
    
    my $sthcount = $dbh->prepare("
                   SELECT 
                    borrowers.categorycode, biblioitems.itemtype, issues.renewals, renewalsallowed, $controlbranch
                   FROM  issuingrules, 
                   issues 
                   LEFT JOIN items USING (itemnumber) 
                   LEFT JOIN borrowers USING (borrowernumber) 
                   LEFT JOIN biblioitems USING (biblioitemnumber)
                   
                   WHERE
                    (issuingrules.categorycode = borrowers.categorycode OR issuingrules.categorycode = '*')
                   AND
                    (issuingrules.itemtype = $itype OR issuingrules.itemtype = '*')
                   AND
                    (issuingrules.branchcode = $controlbranch OR issuingrules.branchcode = '*') 
                   AND 
                    borrowernumber = ? 
                   AND
                    itemnumber = ?
                   ORDER BY
                    issuingrules.categorycode desc,
                    issuingrules.itemtype desc,
                    issuingrules.branchcode desc
                   LIMIT 1;
                  ");

    $sthcount->execute( $borrowernumber, $itemnumber );
    if ( my $data1 = $sthcount->fetchrow_hashref ) {
        
        if ( ( $data1->{renewalsallowed} && $data1->{renewalsallowed} > $data1->{renewals} ) || $override_limit ) {
            $renewokay = 1;
        }
        else {
			$error="too_many";
		}
		
        my ( $resfound, $resrec ) = C4::Reserves::CheckReserves($itemnumber);
        if ($resfound) {
            $renewokay = 0;
			$error="on_reserve"
        }

    }
    return ($renewokay,$error);
}

=head2 AddRenewal

  &AddRenewal($borrowernumber, $itemnumber, $branch, [$datedue], [$lastreneweddate]);

Renews a loan.

C<$borrowernumber> is the borrower number of the patron who currently
has the item.

C<$itemnumber> is the number of the item to renew.

C<$branch> is the library where the renewal took place (if any).
           The library that controls the circ policies for the renewal is retrieved from the issues record.

C<$datedue> can be a C4::Dates object used to set the due date.

C<$lastreneweddate> is an optional ISO-formatted date used to set issues.lastreneweddate.  If
this parameter is not supplied, lastreneweddate is set to the current date.

If C<$datedue> is the empty string, C<&AddRenewal> will calculate the due date automatically
from the book's item type.

=cut

sub AddRenewal {
    my $borrowernumber  = shift or return undef;
    my $itemnumber      = shift or return undef;
    my $branch          = shift;
    my $datedue         = shift;
    my $lastreneweddate = shift || C4::Dates->new()->output('iso');
    my $item   = GetItem($itemnumber) or return undef;
    my $biblio = GetBiblioFromItemNumber($itemnumber) or return undef;

    my $dbh = C4::Context->dbh;
    # Find the issues record for this book
    my $sth =
      $dbh->prepare("SELECT * FROM issues
                        WHERE borrowernumber=? 
                        AND itemnumber=?"
      );
    $sth->execute( $borrowernumber, $itemnumber );
    my $issuedata = $sth->fetchrow_hashref;
    $sth->finish;
    if($datedue && ! $datedue->output('iso')){
        warn "Invalid date passed to AddRenewal.";
        return undef;
    }
    # If the due date wasn't specified, calculate it by adding the
    # book's loan length to today's date or the current due date
    # based on the value of the RenewalPeriodBase syspref.
    unless ($datedue) {

        my $borrower = C4::Members::GetMemberDetails( $borrowernumber, 0 ) or return undef;
        my $itemtype = (C4::Context->preference('item-level_itypes')) ? $biblio->{'itype'} : $biblio->{'itemtype'};

        $datedue = (C4::Context->preference('RenewalPeriodBase') eq 'date_due') ?
                                        C4::Dates->new($issuedata->{date_due}, 'iso') :
                                        C4::Dates->new();
        $datedue =  CalcDateDue($datedue,$itemtype,$issuedata->{'branchcode'},$borrower);
    }

    # Update the issues record to have the new due date, and a new count
    # of how many times it has been renewed.
    my $renews = $issuedata->{'renewals'} + 1;
    $sth = $dbh->prepare("UPDATE issues SET date_due = ?, renewals = ?, lastreneweddate = ?
                            WHERE borrowernumber=? 
                            AND itemnumber=?"
    );
    $sth->execute( $datedue->output('iso'), $renews, $lastreneweddate, $borrowernumber, $itemnumber );
    $sth->finish;

    # Update the renewal count on the item, and tell zebra to reindex
    $renews = $biblio->{'renewals'} + 1;
    ModItem({ renewals => $renews, onloan => $datedue->output('iso') }, $biblio->{'biblionumber'}, $itemnumber);

    # Charge a new rental fee, if applicable?
    my ( $charge, $type ) = GetIssuingCharges( $itemnumber, $borrowernumber );
    if ( $charge > 0 ) {
        my $accountno = getnextacctno( $borrowernumber );
        my $item = GetBiblioFromItemNumber($itemnumber);
        $sth = $dbh->prepare(
                "INSERT INTO accountlines
                    (date,
					borrowernumber, accountno, amount,
                    description,
					accounttype, amountoutstanding, itemnumber
					)
                    VALUES (now(),?,?,?,?,?,?,?)"
        );
        $sth->execute( $borrowernumber, $accountno, $charge,
            "Renewal of Rental Item $item->{'title'} $item->{'barcode'}",
            'Rent', $charge, $itemnumber );
        $sth->finish;
    }
    # Log the renewal
    UpdateStats( $branch, 'renew', $charge, '', $itemnumber, $item->{itype}, $borrowernumber);
	return $datedue;
}

sub GetRenewCount {
    # check renewal status
    my ( $bornum, $itemno ) = @_;
    my $dbh           = C4::Context->dbh;
    my $renewcount    = 0;
    my $renewsallowed = 0;
    my $renewsleft    = 0;

    my $borrower = C4::Members::GetMemberDetails($bornum);
    my $item     = GetItem($itemno); 

    # Look in the issues table for this item, lent to this borrower,
    # and not yet returned.

    # FIXME - I think this function could be redone to use only one SQL call.
    my $sth = $dbh->prepare(
        "select * from issues
                                where (borrowernumber = ?)
                                and (itemnumber = ?)"
    );
    $sth->execute( $bornum, $itemno );
    my $data = $sth->fetchrow_hashref;
    $renewcount = $data->{'renewals'} if $data->{'renewals'};
    $sth->finish;
    # $item and $borrower should be calculated
    my $branchcode = _GetCircControlBranch($item, $borrower);
    
    my $issuingrule = GetIssuingRule($borrower->{categorycode}, $item->{itype}, $branchcode);
    
    $renewsallowed = $issuingrule->{'renewalsallowed'};
    $renewsleft    = $renewsallowed - $renewcount;
    if($renewsleft < 0){ $renewsleft = 0; }
    return ( $renewcount, $renewsallowed, $renewsleft );
}

=head2 GetIssuingCharges

  ($charge, $item_type) = &GetIssuingCharges($itemnumber, $borrowernumber);

Calculate how much it would cost for a given patron to borrow a given
item, including any applicable discounts.

C<$itemnumber> is the item number of item the patron wishes to borrow.

C<$borrowernumber> is the patron's borrower number.

C<&GetIssuingCharges> returns two values: C<$charge> is the rental charge,
and C<$item_type> is the code for the item's item type (e.g., C<VID>
if it's a video).

=cut

sub GetIssuingCharges {

    # calculate charges due
    my ( $itemnumber, $borrowernumber ) = @_;
    my $charge = 0;
    my $dbh    = C4::Context->dbh;
    my $item_type;

    # Get the book's item type and rental charge (via its biblioitem).
    my $charge_query = 'SELECT itemtypes.itemtype,rentalcharge FROM items
        LEFT JOIN biblioitems ON biblioitems.biblioitemnumber = items.biblioitemnumber';
    $charge_query .= (C4::Context->preference('item-level_itypes'))
        ? ' LEFT JOIN itemtypes ON items.itype = itemtypes.itemtype'
        : ' LEFT JOIN itemtypes ON biblioitems.itemtype = itemtypes.itemtype';

    $charge_query .= ' WHERE items.itemnumber =?';

    my $sth = $dbh->prepare($charge_query);
    $sth->execute($itemnumber);
    if ( my $item_data = $sth->fetchrow_hashref ) {
        $item_type = $item_data->{itemtype};
        $charge    = $item_data->{rentalcharge};
        my $branch = C4::Branch::mybranch();
        my $discount_query = q|SELECT rentaldiscount,
            issuingrules.itemtype, issuingrules.branchcode
            FROM borrowers
            LEFT JOIN issuingrules ON borrowers.categorycode = issuingrules.categorycode
            WHERE borrowers.borrowernumber = ?
            AND (issuingrules.itemtype = ? OR issuingrules.itemtype = '*')
            AND (issuingrules.branchcode = ? OR issuingrules.branchcode = '*')|;
        my $discount_sth = $dbh->prepare($discount_query);
        $discount_sth->execute( $borrowernumber, $item_type, $branch );
        my $discount_rules = $discount_sth->fetchall_arrayref({});
        if (@{$discount_rules}) {
            # We may have multiple rules so get the most specific
            my $discount = _get_discount_from_rule($discount_rules, $branch, $item_type);
            $charge = ( $charge * ( 100 - $discount ) ) / 100;
        }
    }

    $sth->finish; # we havent _explicitly_ fetched all rows
    return ( $charge, $item_type );
}

# Select most appropriate discount rule from those returned
sub _get_discount_from_rule {
    my ($rules_ref, $branch, $itemtype) = @_;
    my $discount;

    if (@{$rules_ref} == 1) { # only 1 applicable rule use it
        $discount = $rules_ref->[0]->{rentaldiscount};
        return (defined $discount) ? $discount : 0;
    }
    # could have up to 4 does one match $branch and $itemtype
    my @d = grep { $_->{branchcode} eq $branch && $_->{itemtype} eq $itemtype } @{$rules_ref};
    if (@d) {
        $discount = $d[0]->{rentaldiscount};
        return (defined $discount) ? $discount : 0;
    }
    # do we have item type + all branches
    @d = grep { $_->{branchcode} eq q{*} && $_->{itemtype} eq $itemtype } @{$rules_ref};
    if (@d) {
        $discount = $d[0]->{rentaldiscount};
        return (defined $discount) ? $discount : 0;
    }
    # do we all item types + this branch
    @d = grep { $_->{branchcode} eq $branch && $_->{itemtype} eq q{*} } @{$rules_ref};
    if (@d) {
        $discount = $d[0]->{rentaldiscount};
        return (defined $discount) ? $discount : 0;
    }
    # so all and all (surely we wont get here)
    @d = grep { $_->{branchcode} eq q{*} && $_->{itemtype} eq q{*} } @{$rules_ref};
    if (@d) {
        $discount = $d[0]->{rentaldiscount};
        return (defined $discount) ? $discount : 0;
    }
    # none of the above
    return 0;
}

=head2 AddIssuingCharge

  &AddIssuingCharge( $itemno, $borrowernumber, $charge )

=cut

sub AddIssuingCharge {
    my ( $itemnumber, $borrowernumber, $charge ) = @_;
    my $dbh = C4::Context->dbh;
    my $nextaccntno = getnextacctno( $borrowernumber );
    my $query ="
        INSERT INTO accountlines
            (borrowernumber, itemnumber, accountno,
            date, amount, description, accounttype,
            amountoutstanding)
        VALUES (?, ?, ?,now(), ?, 'Rental', 'Rent',?)
    ";
    my $sth = $dbh->prepare($query);
    $sth->execute( $borrowernumber, $itemnumber, $nextaccntno, $charge, $charge );
    $sth->finish;
}

=head2 GetTransfers

  GetTransfers($itemnumber);

=cut

sub GetTransfers {
    my ($itemnumber) = @_;

    my $dbh = C4::Context->dbh;

    my $query = '
        SELECT datesent,
               frombranch,
               tobranch
        FROM branchtransfers
        WHERE itemnumber = ?
          AND datearrived IS NULL
        ';
    my $sth = $dbh->prepare($query);
    $sth->execute($itemnumber);
    my @row = $sth->fetchrow_array();
    $sth->finish;
    return @row;
}

=head2 GetTransfersFromTo

  @results = GetTransfersFromTo($frombranch,$tobranch);

Returns the list of pending transfers between $from and $to branch

=cut

sub GetTransfersFromTo {
    my ( $frombranch, $tobranch ) = @_;
    return unless ( $frombranch && $tobranch );
    my $dbh   = C4::Context->dbh;
    my $query = "
        SELECT itemnumber,datesent,frombranch
        FROM   branchtransfers
        WHERE  frombranch=?
          AND  tobranch=?
          AND datearrived IS NULL
    ";
    my $sth = $dbh->prepare($query);
    $sth->execute( $frombranch, $tobranch );
    my @gettransfers;

    while ( my $data = $sth->fetchrow_hashref ) {
        push @gettransfers, $data;
    }
    $sth->finish;
    return (@gettransfers);
}

=head2 DeleteTransfer

  &DeleteTransfer($itemnumber);

=cut

sub DeleteTransfer {
    my ($itemnumber) = @_;
    my $dbh          = C4::Context->dbh;
    my $sth          = $dbh->prepare(
        "DELETE FROM branchtransfers
         WHERE itemnumber=?
         AND datearrived IS NULL "
    );
    $sth->execute($itemnumber);
    $sth->finish;
}

=head2 AnonymiseIssueHistory

  $rows = AnonymiseIssueHistory($date,$borrowernumber)

This function write NULL instead of C<$borrowernumber> given on input arg into the table issues.
if C<$borrowernumber> is not set, it will delete the issue history for all borrower older than C<$date>.

If c<$borrowernumber> is set, it will delete issue history for only that borrower, regardless of their opac privacy
setting (force delete).

return the number of affected rows.

=cut

sub AnonymiseIssueHistory {
    my $date           = shift;
    my $borrowernumber = shift;
    my $dbh            = C4::Context->dbh;
    my $query          = "
        UPDATE old_issues
        SET    borrowernumber = ?
        WHERE  returndate < ?
          AND borrowernumber IS NOT NULL
    ";

    # The default of 0 does not work due to foreign key constraints
    # The anonymisation will fail quietly if AnonymousPatron is not a valid entry
    my $anonymouspatron = (C4::Context->preference('AnonymousPatron')) ? C4::Context->preference('AnonymousPatron') : 0;
    my @bind_params = ($anonymouspatron, $date);
    if (defined $borrowernumber) {
       $query .= " AND borrowernumber = ?";
       push @bind_params, $borrowernumber;
    } else {
       $query .= " AND (SELECT privacy FROM borrowers WHERE borrowers.borrowernumber=old_issues.borrowernumber) <> 0";
    }
    my $sth = $dbh->prepare($query);
    $sth->execute(@bind_params);
    my $rows_affected = $sth->rows;  ### doublecheck row count return function
    return $rows_affected;
}

=head2 SendCirculationAlert

Send out a C<check-in> or C<checkout> alert using the messaging system.

B<Parameters>:

=over 4

=item type

Valid values for this parameter are: C<CHECKIN> and C<CHECKOUT>.

=item item

Hashref of information about the item being checked in or out.

=item borrower

Hashref of information about the borrower of the item.

=item branch

The branchcode from where the checkout or check-in took place.

=back

B<Example>:

    SendCirculationAlert({
        type     => 'CHECKOUT',
        item     => $item,
        borrower => $borrower,
        branch   => $branch,
    });

=cut

sub SendCirculationAlert {
    my ($opts) = @_;
    my ($type, $item, $borrower, $branch) =
        ($opts->{type}, $opts->{item}, $opts->{borrower}, $opts->{branch});
    my %message_name = (
        CHECKIN  => 'Item_Check_in',
        CHECKOUT => 'Item_Checkout',
    );
    my $borrower_preferences = C4::Members::Messaging::GetMessagingPreferences({
        borrowernumber => $borrower->{borrowernumber},
        message_name   => $message_name{$type},
    });
    my $letter = C4::Letters::getletter('circulation', $type);
    C4::Letters::parseletter($letter, 'biblio',      $item->{biblionumber});
    C4::Letters::parseletter($letter, 'biblioitems', $item->{biblionumber});
    C4::Letters::parseletter($letter, 'borrowers',   $borrower->{borrowernumber});
    C4::Letters::parseletter($letter, 'branches',    $branch);
    my @transports = @{ $borrower_preferences->{transports} };
    # warn "no transports" unless @transports;
    for (@transports) {
        # warn "transport: $_";
        my $message = C4::Message->find_last_message($borrower, $type, $_);
        if (!$message) {
            #warn "create new message";
            C4::Message->enqueue($letter, $borrower, $_);
        } else {
            #warn "append to old message";
            $message->append($letter);
            $message->update;
        }
    }
    $letter;
}

=head2 updateWrongTransfer

  $items = updateWrongTransfer($itemNumber,$borrowernumber,$waitingAtLibrary,$FromLibrary);

This function validate the line of brachtransfer but with the wrong destination (mistake from a librarian ...), and create a new line in branchtransfer from the actual library to the original library of reservation 

=cut

sub updateWrongTransfer {
	my ( $itemNumber,$waitingAtLibrary,$FromLibrary ) = @_;
	my $dbh = C4::Context->dbh;	
# first step validate the actual line of transfert .
	my $sth =
        	$dbh->prepare(
			"update branchtransfers set datearrived = now(),tobranch=?,comments='wrongtransfer' where itemnumber= ? AND datearrived IS NULL"
          	);
        	$sth->execute($FromLibrary,$itemNumber);
        	$sth->finish;

# second step create a new line of branchtransfer to the right location .
	ModItemTransfer($itemNumber, $FromLibrary, $waitingAtLibrary);

#third step changing holdingbranch of item
	UpdateHoldingbranch($FromLibrary,$itemNumber);
}

=head2 UpdateHoldingbranch

  $items = UpdateHoldingbranch($branch,$itmenumber);

Simple methode for updating hodlingbranch in items BDD line

=cut

sub UpdateHoldingbranch {
	my ( $branch,$itemnumber ) = @_;
    ModItem({ holdingbranch => $branch }, undef, $itemnumber);
}

=head2 CalcDateDue

$newdatedue = CalcDateDue($startdate,$itemtype,$branchcode,$borrower);

this function calculates the due date given the start date and configured circulation rules,
checking against the holidays calendar as per the 'useDaysMode' syspref.
C<$startdate>   = C4::Dates object representing start date of loan period (assumed to be today)
C<$itemtype>  = itemtype code of item in question
C<$branch>  = location whose calendar to use
C<$borrower> = Borrower object

=cut

sub CalcDateDue { 
	my ($startdate,$itemtype,$branch,$borrower) = @_;
	my $datedue;
        my $loanlength = GetLoanLength($borrower->{'categorycode'},$itemtype, $branch);

	# if globalDueDate ON the datedue is set to that date
	if ( C4::Context->preference('globalDueDate')
             && ( C4::Context->preference('globalDueDate') =~ C4::Dates->regexp('syspref') ) ) {
            $datedue = C4::Dates->new( C4::Context->preference('globalDueDate') );
	} else {
	# otherwise, calculate the datedue as normal
		if(C4::Context->preference('useDaysMode') eq 'Days') {  # ignoring calendar
			my $timedue = time + ($loanlength) * 86400;
		#FIXME - assumes now even though we take a startdate 
			my @datearr  = localtime($timedue);
			$datedue = C4::Dates->new( sprintf("%04d-%02d-%02d", 1900 + $datearr[5], $datearr[4] + 1, $datearr[3]), 'iso');
		} else {
			my $calendar = C4::Calendar->new(  branchcode => $branch );
			$datedue = $calendar->addDate($startdate, $loanlength);
		}
	}

	# if Hard Due Dates are used, retreive them and apply as necessary
        my ($hardduedate, $hardduedatecompare) = GetHardDueDate($borrower->{'categorycode'},$itemtype, $branch);
	if ( $hardduedate && $hardduedate->output('iso') && $hardduedate->output('iso') ne '0000-00-00') {
            # if the calculated due date is after the 'before' Hard Due Date (ceiling), override
            if ( $datedue->output( 'iso' ) gt $hardduedate->output( 'iso' ) && $hardduedatecompare == -1) {
                $datedue = $hardduedate;
            # if the calculated date is before the 'after' Hard Due Date (floor), override
            } elsif ( $datedue->output( 'iso' ) lt $hardduedate->output( 'iso' ) && $hardduedatecompare == 1) {
                $datedue = $hardduedate;               
            # if the hard due date is set to 'exactly', overrride
            } elsif ( $hardduedatecompare == 0) {
                $datedue = $hardduedate;
            }
            # in all other cases, keep the date due as it is
	}

	# if ReturnBeforeExpiry ON the datedue can't be after borrower expirydate
	if ( C4::Context->preference('ReturnBeforeExpiry') && $datedue->output('iso') gt $borrower->{dateexpiry} ) {
	    $datedue = C4::Dates->new( $borrower->{dateexpiry}, 'iso' );
	}

	return $datedue;
}

=head2 CheckValidDatedue

  $newdatedue = CheckValidDatedue($date_due,$itemnumber,$branchcode);

This function does not account for holiday exceptions nor does it handle the 'useDaysMode' syspref .
To be replaced by CalcDateDue() once C4::Calendar use is tested.

this function validates the loan length against the holidays calendar, and adjusts the due date as per the 'useDaysMode' syspref.
C<$date_due>   = returndate calculate with no day check
C<$itemnumber>  = itemnumber
C<$branchcode>  = location of issue (affected by 'CircControl' syspref)
C<$loanlength>  = loan length prior to adjustment

=cut

sub CheckValidDatedue {
my ($date_due,$itemnumber,$branchcode)=@_;
my @datedue=split('-',$date_due->output('iso'));
my $years=$datedue[0];
my $month=$datedue[1];
my $day=$datedue[2];
# die "Item# $itemnumber ($branchcode) due: " . ${date_due}->output() . "\n(Y,M,D) = ($years,$month,$day)":
my $dow;
for (my $i=0;$i<2;$i++){
    $dow=Day_of_Week($years,$month,$day);
    ($dow=0) if ($dow>6);
    my $result=CheckRepeatableHolidays($itemnumber,$dow,$branchcode);
    my $countspecial=CheckSpecialHolidays($years,$month,$day,$itemnumber,$branchcode);
    my $countspecialrepeatable=CheckRepeatableSpecialHolidays($month,$day,$itemnumber,$branchcode);
        if (($result ne '0') or ($countspecial ne '0') or ($countspecialrepeatable ne '0') ){
        $i=0;
        (($years,$month,$day) = Add_Delta_Days($years,$month,$day, 1))if ($i ne '1');
        }
    }
    my $newdatedue=C4::Dates->new(sprintf("%04d-%02d-%02d",$years,$month,$day),'iso');
return $newdatedue;
}


=head2 CheckRepeatableHolidays

  $countrepeatable = CheckRepeatableHoliday($itemnumber,$week_day,$branchcode);

This function checks if the date due is a repeatable holiday

C<$date_due>   = returndate calculate with no day check
C<$itemnumber>  = itemnumber
C<$branchcode>  = localisation of issue 

=cut

sub CheckRepeatableHolidays{
my($itemnumber,$week_day,$branchcode)=@_;
my $dbh = C4::Context->dbh;
my $query = qq|SELECT count(*)  
	FROM repeatable_holidays 
	WHERE branchcode=?
	AND weekday=?|;
my $sth = $dbh->prepare($query);
$sth->execute($branchcode,$week_day);
my $result=$sth->fetchrow;
$sth->finish;
return $result;
}


=head2 CheckSpecialHolidays

  $countspecial = CheckSpecialHolidays($years,$month,$day,$itemnumber,$branchcode);

This function check if the date is a special holiday

C<$years>   = the years of datedue
C<$month>   = the month of datedue
C<$day>     = the day of datedue
C<$itemnumber>  = itemnumber
C<$branchcode>  = localisation of issue 

=cut

sub CheckSpecialHolidays{
my ($years,$month,$day,$itemnumber,$branchcode) = @_;
my $dbh = C4::Context->dbh;
my $query=qq|SELECT count(*) 
	     FROM `special_holidays`
	     WHERE year=?
	     AND month=?
	     AND day=?
             AND branchcode=?
	    |;
my $sth = $dbh->prepare($query);
$sth->execute($years,$month,$day,$branchcode);
my $countspecial=$sth->fetchrow ;
$sth->finish;
return $countspecial;
}

=head2 CheckRepeatableSpecialHolidays

  $countspecial = CheckRepeatableSpecialHolidays($month,$day,$itemnumber,$branchcode);

This function check if the date is a repeatble special holidays

C<$month>   = the month of datedue
C<$day>     = the day of datedue
C<$itemnumber>  = itemnumber
C<$branchcode>  = localisation of issue 

=cut

sub CheckRepeatableSpecialHolidays{
my ($month,$day,$itemnumber,$branchcode) = @_;
my $dbh = C4::Context->dbh;
my $query=qq|SELECT count(*) 
	     FROM `repeatable_holidays`
	     WHERE month=?
	     AND day=?
             AND branchcode=?
	    |;
my $sth = $dbh->prepare($query);
$sth->execute($month,$day,$branchcode);
my $countspecial=$sth->fetchrow ;
$sth->finish;
return $countspecial;
}



sub CheckValidBarcode{
my ($barcode) = @_;
my $dbh = C4::Context->dbh;
my $query=qq|SELECT count(*) 
	     FROM items 
             WHERE barcode=?
	    |;
my $sth = $dbh->prepare($query);
$sth->execute($barcode);
my $exist=$sth->fetchrow ;
$sth->finish;
return $exist;
}

=head2 IsBranchTransferAllowed

  $allowed = IsBranchTransferAllowed( $toBranch, $fromBranch, $code );

Code is either an itemtype or collection doe depending on the pref BranchTransferLimitsType

=cut

sub IsBranchTransferAllowed {
	my ( $toBranch, $fromBranch, $code ) = @_;

	if ( $toBranch eq $fromBranch ) { return 1; } ## Short circuit for speed.
        
	my $limitType = C4::Context->preference("BranchTransferLimitsType");   
	my $dbh = C4::Context->dbh;
            
	my $sth = $dbh->prepare("SELECT * FROM branch_transfer_limits WHERE toBranch = ? AND fromBranch = ? AND $limitType = ?");
	$sth->execute( $toBranch, $fromBranch, $code );
	my $limit = $sth->fetchrow_hashref();
                        
	## If a row is found, then that combination is not allowed, if no matching row is found, then the combination *is allowed*
	if ( $limit->{'limitId'} ) {
		return 0;
	} else {
		return 1;
	}
}                                                        

=head2 CreateBranchTransferLimit

  CreateBranchTransferLimit( $toBranch, $fromBranch, $code );

$code is either itemtype or collection code depending on what the pref BranchTransferLimitsType is set to.

=cut

sub CreateBranchTransferLimit {
   my ( $toBranch, $fromBranch, $code ) = @_;

   my $limitType = C4::Context->preference("BranchTransferLimitsType");
   
   my $dbh = C4::Context->dbh;
   
   my $sth = $dbh->prepare("INSERT INTO branch_transfer_limits ( $limitType, toBranch, fromBranch ) VALUES ( ?, ?, ? )");
   $sth->execute( $code, $toBranch, $fromBranch );
}

=head2 DeleteBranchTransferLimits

  DeleteBranchTransferLimits();

=cut

sub DeleteBranchTransferLimits {
   my $dbh = C4::Context->dbh;
   my $sth = $dbh->prepare("TRUNCATE TABLE branch_transfer_limits");
   $sth->execute();
}


  1;

__END__

=head1 AUTHOR

Koha Development Team <http://koha-community.org/>

=cut

