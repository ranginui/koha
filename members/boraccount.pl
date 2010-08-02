#!/usr/bin/perl


#writen 11/1/2000 by chris@katipo.oc.nz
#script to display borrowers account details


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

use C4::Auth;
use C4::Output;
use C4::Dates qw/format_date/;
use CGI;
use C4::Members;
use C4::Branch;
use C4::Accounts;

my $input=new CGI;


my ($template, $loggedinuser, $cookie)
    = get_template_and_user({template_name => "members/boraccount.tmpl",
                            query => $input,
                            type => "intranet",
                            authnotrequired => 0,
                            flagsrequired => {borrowers => 1, updatecharges => 1},
                            debug => 1,
                            });

my $borrowernumber=$input->param('borrowernumber');
my $action = $input->param('action') || '';

# The index of the first record to display
my $first_record = $input->param('first') || 0;
# The number of records to show
my $count_record = $input->param('count') || 20;

#get borrower details
my $data=GetMember('borrowernumber' => $borrowernumber);

if ( $action eq 'reverse' ) {
  ReversePayment( $borrowernumber, $input->param('accountno') );
}

if ( $data->{'category_type'} eq 'C') {
   my  ( $catcodes, $labels ) =  GetborCatFromCatType( 'A', 'WHERE category_type = ?' );
   my $cnt = scalar(@$catcodes);
   $template->param( 'CATCODE_MULTI' => 1) if $cnt > 1;
   $template->param( 'catcode' =>    $catcodes->[0])  if $cnt == 1;
}

#get account details
my ($total,$accts,$num_records)=GetMemberAccountRecords($borrowernumber);
my $totalcredit;
if($total <= 0){
        $totalcredit = 1;
}

# Validate the actual boundaries we need, if they're outside a useful range,
# just reset them to something we understand.
$first_record = 0  if ($first_record < 0 || $first_record >= @$accts);
$count_record = 20 if ($count_record < 0);
my $last_record = $first_record+$count_record-1;
$last_record = @$accts - 1 if ($last_record >= @$accts);

# Take an array slice
my @accts = @$accts[$first_record .. $last_record];

my ($show_back_link, $back_first_record) = (0, undef);
if ($first_record > 0) {
    $show_back_link = 1;
    $back_first_record = $first_record-$count_record;
    $back_first_record = 0 if ($back_first_record < 0);
}
my ($show_forward_link, $forward_first_record) = (0, undef);
if (@$accts > $first_record+$count_record) {
    $show_forward_link = 1;
    $forward_first_record = $first_record+$count_record;
}

my $reverse_col = 0; # Flag whether we need to show the reverse column
foreach my $accountline (@accts) {
    $accountline->{amount} += 0.00;
    if ($accountline->{amount} <= 0 ) {
        $accountline->{amountcredit} = 1;
    }
    $accountline->{amountoutstanding} += 0.00;
    if ( $accountline->{amountoutstanding} <= 0 ) {
        $accountline->{amountoutstandingcredit} = 1;
    }

    $accountline->{date} = format_date($accountline->{date});
    $accountline->{amount} = sprintf '%.2f', $accountline->{amount};
    $accountline->{amountoutstanding} = sprintf '%.2f', $accountline->{amountoutstanding};
    if ($accountline->{accounttype} eq 'Pay') {
        $accountline->{payment} = 1;
        $reverse_col = 1;
    }
    if ($accountline->{accounttype} ne 'F' && $accountline->{accounttype} ne 'FU'){
        $accountline->{printtitle} = 1;
    }
}

$template->param( adultborrower => 1 ) if ( $data->{'category_type'} eq 'A' );

my ($picture, $dberror) = GetPatronImage($data->{'cardnumber'});
$template->param( picture => 1 ) if $picture;

$template->param(
    finesview           => 1,
    firstname           => $data->{'firstname'},
    surname             => $data->{'surname'},
    borrowernumber      => $borrowernumber,
    cardnumber          => $data->{'cardnumber'},
    categorycode        => $data->{'categorycode'},
    category_type       => $data->{'category_type'},
    categoryname	=> $data->{'description'},
    address             => $data->{'address'},
    address2            => $data->{'address2'},
    city                => $data->{'city'},
    zipcode             => $data->{'zipcode'},
    country             => $data->{'country'},
    phone               => $data->{'phone'},
    email               => $data->{'email'},
    branchcode          => $data->{'branchcode'},
    branchname		=> GetBranchName($data->{'branchcode'}),
    total               => sprintf("%.2f",$total),
    totalcredit         => $totalcredit,
    is_child            => ($data->{'category_type'} eq 'C'),
    reverse_col         => $reverse_col,
    accounts            => [ @accts ],
    account_count       => $num_records,
    show_back_link      => $show_back_link,
    show_forward_link   => $show_forward_link,
    back_first_record   => $back_first_record,
    forward_first_record=> $forward_first_record,
    current_start       => ($first_record+1),
    current_last        => ($last_record+1),
);

output_html_with_http_headers $input, $cookie, $template->output;
