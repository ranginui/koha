#!/usr/bin/perl

# Copyright 2000-2002 Katipo Communications
# Copyright 2010 BibLibre
# Copyright 2010,2011 PTFS-Europe Ltd
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

=head1 pay.pl

 written 11/1/2000 by chris@katipo.oc.nz
 part of the koha library system, script to facilitate paying off fines

=cut

use strict;
use warnings;

use C4::Context;
use C4::Auth;
use C4::Output;
use CGI;
use C4::Members;
use C4::Accounts;
use C4::Stats;
use C4::Koha;
use C4::Overdues;
use C4::Branch;
use C4::Members::Attributes qw(GetBorrowerAttributes);

my $input = CGI->new;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {   template_name   => 'members/pay.tmpl',
        query           => $input,
        type            => 'intranet',
        authnotrequired => 0,
        flagsrequired   => { borrowers => 1, updatecharges => 1 },
        debug           => 1,
    }
);

my $writeoff_sth;
my $add_writeoff_sth;

my @names = $input->param;

my $borrowernumber = $input->param('borrowernumber');
if ( !$borrowernumber ) {
    $borrowernumber = $input->param('borrowernumber0');
}

# get borrower details
my $borrower = GetMember( borrowernumber => $borrowernumber );
my $user = $input->remote_user;
$user ||= q{};

my $branches = GetBranches();
my $branch = GetBranch( $input, $branches );

my $writeoff_item = $input->param('confirm_writeoff');
my $paycollect    = $input->param('paycollect');
if ($paycollect) {
    print $input->redirect(
        "/cgi-bin/koha/members/paycollect.pl?borrowernumber=$borrowernumber");
}
my $payselected = $input->param('payselected');
if ($payselected) {
    payselected(@names);
}

my $writeoff_all = $input->param('woall');    # writeoff all fines
if ($writeoff_all) {
    writeoff_all(@names);
} elsif ($writeoff_item) {
    my $accountno    = $input->param('accountno');
    my $itemno       = $input->param('itemnumber');
    my $account_type = $input->param('accounttype');
    my $amount       = $input->param('amount');
    writeoff( $accountno, $itemno, $account_type, $amount );
}

for (@names) {
    if (/^pay_indiv_(\d+)$/) {
        my $line_no = $1;
        redirect_to_paycollect( 'pay_individual', $line_no );
    } elsif (/^wo_indiv_(\d+)$/) {
        my $line_no = $1;
        redirect_to_paycollect( 'writeoff_individual', $line_no );
    }
}

add_accounts_to_template();

output_html_with_http_headers $input, $cookie, $template->output;

sub writeoff {
    my ( $accountnum, $itemnum, $accounttype, $amount ) = @_;
    my $manager_id = 0;
    $manager_id = C4::Context->userenv->{'number'} if C4::Context->userenv;

    # if no item is attached to fine, make sure to store it as a NULL
    $itemnum ||= undef;
    get_writeoff_sth();
    $writeoff_sth->execute( $accountnum, $borrowernumber );

    my $acct = getnextacctno($borrowernumber);
    $add_writeoff_sth->execute( $borrowernumber, $acct, $itemnum, $amount, $manager_id );

    UpdateStats( $branch, 'writeoff', $amount, q{}, q{}, q{}, $borrowernumber );

    return;
}

sub add_accounts_to_template {

    my ( $total, undef, undef ) = GetMemberAccountRecords($borrowernumber);
    my $accounts = [];
    my @notify   = NumberNotifyId($borrowernumber);

    my $notify_groups = [];
    for my $notify_id (@notify) {
        my ( $acct_total, $accountlines, undef ) =
          GetBorNotifyAcctRecord( $borrowernumber, $notify_id );
        if ( @{$accountlines} ) {
            my $totalnotify = AmountNotify( $notify_id, $borrowernumber );
            push @{$accounts},
              { accountlines => $accountlines,
                notify       => $notify_id,
                total        => $totalnotify,
              };
        }
    }
    borrower_add_additional_fields($borrower);
    $template->param(
        accounts => $accounts,
        borrower => $borrower,
        total    => $total,
    );
    return;

}

sub get_for_redirect {
    my ( $name, $name_in, $money ) = @_;
    my $s     = q{&} . $name . q{=};
    my $value = $input->param($name_in);
    if ( !defined $value ) {
        $value = ( $money == 1 ) ? 0 : q{};
    }
    if ($money) {
        $s .= sprintf '%.2f', $value;
    } else {
        $s .= $value;
    }
    return $s;
}

sub redirect_to_paycollect {
    my ( $action, $line_no ) = @_;
    my $redirect =
      "/cgi-bin/koha/members/paycollect.pl?borrowernumber=$borrowernumber";
    $redirect .= q{&};
    $redirect .= "$action=1";
    $redirect .= get_for_redirect( 'accounttype', "accounttype$line_no", 0 );
    $redirect .= get_for_redirect( 'amount', "amount$line_no", 1 );
    $redirect .=
      get_for_redirect( 'amountoutstanding', "amountoutstanding$line_no", 1 );
    $redirect .= get_for_redirect( 'accountno',    "accountno$line_no",    0 );
    $redirect .= get_for_redirect( 'description',  "description$line_no",  0 );
    $redirect .= get_for_redirect( 'title',        "title$line_no",        0 );
    $redirect .= get_for_redirect( 'itemnumber',   "itemnumber$line_no",   0 );
    $redirect .= get_for_redirect( 'notify_id',    "notify_id$line_no",    0 );
    $redirect .= get_for_redirect( 'notify_level', "notify_level$line_no", 0 );
    $redirect .= '&remote_user=';
    $redirect .= $user;
    return print $input->redirect($redirect);
}

sub writeoff_all {
    my @params = @_;
    my @wo_lines = grep { /^accountno\d+$/ } @params;
    for (@wo_lines) {
        if (/(\d+)/) {
            my $value       = $1;
            my $accounttype = $input->param("accounttype$value");

            #    my $borrowernum    = $input->param("borrowernumber$value");
            my $itemno    = $input->param("itemnumber$value");
            my $amount    = $input->param("amount$value");
            my $accountno = $input->param("accountno$value");
            writeoff( $accountno, $itemno, $accounttype, $amount );
        }
    }

    $borrowernumber = $input->param('borrowernumber');
    print $input->redirect(
        "/cgi-bin/koha/members/boraccount.pl?borrowernumber=$borrowernumber");
    return;
}

sub borrower_add_additional_fields {
    my $b_ref = shift;

# some borrower info is not returned in the standard call despite being assumed
# in a number of templates. It should not be the business of this script but in lieu of
# a revised api here it is ...
    if ( $b_ref->{category_type} eq 'C' ) {
        my ( $catcodes, $labels ) =
          GetborCatFromCatType( 'A', 'WHERE category_type = ?' );
        if ( @{$catcodes} ) {
            if ( @{$catcodes} > 1 ) {
                $b_ref->{CATCODE_MULTI} = 1;
            } elsif ( @{$catcodes} == 1 ) {
                $b_ref->{catcode} = $catcodes->[0];
            }
        }
    } elsif ( $b_ref->{category_type} eq 'A' ) {
        $b_ref->{adultborrower} = 1;
    }
    my ( $picture, $dberror ) = GetPatronImage( $b_ref->{cardnumber} );
    if ($picture) {
        $b_ref->{has_picture} = 1;
    }

    if (C4::Context->preference('ExtendedPatronAttributes')) {
        $b_ref->{extendedattributes} = GetBorrowerAttributes($borrowernumber);
        $template->param(
            ExtendedPatronAttributes => 1,
        );
    }

    $b_ref->{branchname} = GetBranchName( $b_ref->{branchcode} );
    return;
}

sub payselected {
    my @params = @_;
    my $amt    = 0;
    my @lines_to_pay;
    foreach (@params) {
        if (/^incl_par_(\d+)$/) {
            my $index = $1;
            push @lines_to_pay, $input->param("accountno$index");
            $amt += $input->param("amountoutstanding$index");
        }
    }
    $amt = '&amt=' . $amt;
    my $sel = '&selected=' . join ',', @lines_to_pay;
    my $redirect =
        "/cgi-bin/koha/members/paycollect.pl?borrowernumber=$borrowernumber"
      . $amt
      . $sel;

    print $input->redirect($redirect);
    return;
}

sub get_writeoff_sth {

    # lets prepare these statement handles only once
    if ($writeoff_sth) {
        return;
    } else {
        my $dbh = C4::Context->dbh;

        # Do we need to validate accounttype
        my $sql = 'Update accountlines set amountoutstanding=0 '
          . 'WHERE accountno=? and borrowernumber=?';
        $writeoff_sth = $dbh->prepare($sql);
        my $insert =
q{insert into accountlines (borrowernumber,accountno,itemnumber,date,amount,description,accounttype,manager_id)}
          . q{values (?,?,?,now(),?,'Writeoff','W',?)};
        $add_writeoff_sth = $dbh->prepare($insert);
    }
    return;
}
