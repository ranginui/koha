#!/usr/bin/perl

# Copyright 2008 BibLibre, BibLibre, Paul POULAIN
#                SAN Ouest Provence
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

=head1 admin/aqbudgetperiods.pl

script to administer the budget periods table
 This software is placed under the gnu General Public License, v2 (http://www.gnu.org/licenses/gpl.html)

 ALGO :
 this script use an $op to know what to do.
 if $op is empty or none of the above values,
	- the default screen is build (with all records, or filtered datas).
	- the   user can clic on add, modify or delete record.
 if $op=add_form
	- if primkey exists, this is a modification,so we read the $primkey record
	- builds the add/modify form
 if $op=add_validate
	- the user has just send datas, so we create/modify the record
 if $op=delete_confirm
	- we show the record having primkey=$primkey and ask for deletion validation form
 if $op=delete_confirmed
	- we delete the record having primkey=$primkey

=cut

## modules
use strict;
use Number::Format qw(format_price);
use CGI;
use List::Util qw/min/;
use C4::Dates qw/format_date format_date_in_iso/;
use C4::Koha;
use C4::Context;
use C4::Auth;
use C4::Output;
use C4::Acquisition;
use C4::Budgets;
use C4::Debug;

my $dbh = C4::Context->dbh;

my $input       = new CGI;

my $searchfield          = $input->param('searchfield');
my $budget_period_id     = $input->param('budget_period_id');
my $op                   = $input->param('op')||"else";
my $check_duplicate      = $input->param('confirm_not_duplicate')||0;

my $budget_period_hashref= $input->Vars;
#my $sort1_authcat = $input->param('sort1_authcat');
#my $sort2_authcat = $input->param('sort2_authcat');

my $pagesize    = 20;
$searchfield =~ s/\,//g;

my ($template, $borrowernumber, $cookie, $staff_flags ) = get_template_and_user(
	{   template_name   => "admin/aqbudgetperiods.tmpl",
		query           => $input,
		type            => "intranet",
		authnotrequired => 0,
		flagsrequired   => { acquisition => 'period_manage' },
		debug           => 1,
	}
);


my $cur = GetCurrency();
$template->param( cur => $cur->{symbol} );
my $cur_format = C4::Context->preference("CurrencyFormat");
my $num;

if ( $cur_format eq 'US' ) {
    $num = new Number::Format(
        'int_curr_symbol'   => '',
        'mon_thousands_sep' => ',',
        'mon_decimal_point' => '.'
    );
} elsif ( $cur_format eq 'FR' ) {
    $num = new Number::Format(
        'decimal_fill'      => '2',
        'decimal_point'     => ',',
        'int_curr_symbol'   => '',
        'mon_thousands_sep' => ' ',
        'thousands_sep'     => ' ',
        'mon_decimal_point' => ','
    );
}


# ADD OR MODIFY A BUDGET PERIOD - BUILD SCREEN
if ( $op eq 'add_form' ) {
    ## add or modify a budget period (preparation)
    ## get information about the budget period that must be modified


    if ($budget_period_id) {    # MOD
		my $budgetperiod_hash=GetBudgetPeriod($budget_period_id);
        # get dropboxes
		FormatData($budgetperiod_hash);
        $$budgetperiod_hash{budget_period_total}= $num->format_price($$budgetperiod_hash{'budget_period_total'});  
        $template->param(
			%$budgetperiod_hash
        );
    } # IF-MOD
    $template->param( DHTMLcalendar_dateformat 	=> C4::Dates->DHTMLcalendar(),);
    $template->param( confirm_not_duplicate		=> $check_duplicate     	  );
}

elsif ( $op eq 'add_validate' ) {
## add or modify a budget period (confirmation)

	## update budget period data
	if ( $budget_period_id ne '' ) {
		$$budget_period_hashref{$_}||=0 for qw(budget_period_active budget_period_locked);
		my $status=ModBudgetPeriod($budget_period_hashref);
	} 
	else {    # ELSE ITS AN ADD
		unless ($check_duplicate){
			my $candidates=GetBudgetPeriods({ 
									 		budget_period_startdate	=> $$budget_period_hashref{budget_period_startdate}
									 		, budget_period_enddate	=> $$budget_period_hashref{budget_period_enddate}
									 		});
			if (@$candidates){
				my @duplicates=map{
									{ dupid 			   => $$_{budget_period_id}
									, duplicateinformation =>
											$$_{budget_period_description}." ".$$_{budget_period_startdate}." ".$$_{budget_period_enddate}
									}
								  } @$candidates;
				$template->param(url			  => "aqbudgetperiods.pl", 
								field_name		  => "budget_period_id",
								action_dup_yes_url=> "aqbudgets.pl",
								action_dup_no_url => "aqbudgetperiods.pl?op=add_validate",
								confirm_not_duplicate	  => 0
									);
				delete $$budget_period_hashref{budget_period_id};
				$template->param(duplicates=>\@duplicates,%$budget_period_hashref);
				$template->param("add_form"=>1);
				output_html_with_http_headers $input, $cookie, $template->output;
				exit;
			}
		}
		my $budget_period_id=AddBudgetPeriod($budget_period_hashref);
	}
	$op='else';
}

#--------------------------------------------------
elsif ( $op eq 'delete_confirm' ) {
## delete a budget period (preparation)
    my $dbh = C4::Context->dbh;
    ## $total = number of records linked to the record that must be deleted
    my $total = 0;
    my $data = GetBudgetPeriod( $budget_period_id);

	FormatData($data);
	$$data{'budget_period_total'}=$num->format_price(  $data->{'budget_period_total'});
    $template->param(
		%$data
    );
}

elsif ( $op eq 'delete_confirmed' ) {
## delete the budget period record

    my $data = GetBudgetPeriod( $budget_period_id);
    DelBudgetPeriod($budget_period_id);
	$op='else';
}

# DEFAULT - DISPLAY AQPERIODS TABLE
# -------------------------------------------------------------------
# display the list of budget periods
    my $results = GetBudgetPeriods();
	$template->param( period_button_only => 1 ) unless (@$results) ;
    my $page = $input->param('page') || 1;
    my $first = ( $page - 1 ) * $pagesize;
    # if we are on the last page, the number of the last word to display
    # must not exceed the length of the results array
    my $last = min( $first + $pagesize - 1, scalar @{$results} - 1, );
    my $toggle = 0;
    my @period_loop;
    foreach my $result ( @{$results}[ $first .. $last ] ) {
        my $budgetperiod = $result;
		FormatData($budgetperiod);
        $budgetperiod->{'budget_period_total'}     = $num->format_price( $budgetperiod->{'budget_period_total'} );
        $budgetperiod->{budget_active} = 1;
        push( @period_loop, $budgetperiod );
    }
    my $budget_period_dropbox = GetBudgetPeriodsDropbox();

    $template->param(
        budget_period_dropbox => $budget_period_dropbox,
        period_loop           => \@period_loop,
		pagination_bar		  => pagination_bar("aqbudgetperiods.pl",getnbpages(scalar(@$results),$pagesize),$page),
    );

$template->param($op=>1);
output_html_with_http_headers $input, $cookie, $template->output;
