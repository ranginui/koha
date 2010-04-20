#!/usr/bin/perl

# Copyright 2008 - 2009 BibLibre SARL
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

=head1 NAME

acqui-home.pl

=head1 DESCRIPTION

this script is the main page for acqui

=cut

use strict;
use warnings;
use Number::Format;

use CGI;
use C4::Auth;
use C4::Output;
use C4::Acquisition;
use C4::Budgets;
use C4::Members;
use C4::Branch;
use C4::Debug;

my $query = CGI->new;
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {   template_name   => 'acqui/acqui-home.tmpl',
        query           => $query,
        type            => 'intranet',
        authnotrequired => 0,
        flagsrequired   => { acquisition => '*' },
        debug           => 1,
    }
);

my $user = GetMember( 'borrowernumber' => $loggedinuser );
my $branchname = GetBranchName($user->{branchcode});


my $num_formatter;

my $cur_format = C4::Context->preference("CurrencyFormat");
if ( $cur_format eq 'FR' ) {
    $num_formatter = Number::Format->new(
        'decimal_fill'      => '2',
        'decimal_point'     => ',',
        'int_curr_symbol'   => '',
        'mon_thousands_sep' => ' ',
        'thousands_sep'     => ' ',
        'mon_decimal_point' => ','
    );
} else {    # US by default..
    $num_formatter = Number::Format->new(
        'int_curr_symbol'   => '',
        'mon_thousands_sep' => ',',
        'mon_decimal_point' => '.'
    );
}

my $fund_arr =
  GetBudgetHierarchy( '', $user->{branchcode},
    $template->{param_map}->{'USER_INFO'}[0]->{'borrowernumber'} );

my $total      = 0;
my $totspent   = 0;
my $totordered = 0;
my $totcomtd   = 0;
my $totavail   = 0;
use Data::Dumper;
print STDERR Dumper($fund_arr);
foreach my $fund ( @{$fund_arr} ) {
    my $budget_period = GetBudgetPeriod($fund->{budget_period_id});
    print STDERR Dumper($budget_period);
    $fund->{budget_code_indent} =~ s/\ /\&nbsp\;/g;

    $fund->{'budget_branchname'} =
      GetBranchName( $fund->{'budget_branchcode'} );

    my $member = GetMember( borrowernumber => $fund->{budget_owner_id} );
    if ($member) {
        $fund->{budget_owner} =
          $member->{'firstname'} . ' ' . $member->{'surname'};
    }

    if ( !defined $fund->{budget_amount} ) {
        $fund->{budget_amount} = 0;
    }

    $fund->{'budget_ordered'} = GetBudgetOrdered( $fund->{'budget_id'} );
    $fund->{'budget_spent'}   = GetBudgetSpent( $fund->{'budget_id'} );
    $fund->{'budget_period_startdate'} = $budget_period->{'budget_period_startdate'};
    $fund->{'budget_period_enddate'} = $budget_period->{'budget_period_enddate'};
    if ( !defined $fund->{budget_spent} ) {
        $fund->{budget_spent} = 0;
    }
    if ( !defined $fund->{budget_ordered} ) {
        $fund->{budget_ordered} = 0;
    }
    $fund->{'budget_avail'} =
      $fund->{'budget_amount'} - ( $fund->{'budget_spent'} + $fund->{'budget_ordered'} );

    $total      += $fund->{'budget_amount'};
    $totspent   += $fund->{'budget_spent'};
    $totordered += $fund->{'budget_ordered'};
    $totavail   += $fund->{'budget_avail'};

    for my $field (qw( budget_amount budget_spent budget_ordered budget_avail ) ) {
        $fund->{$field} = $num_formatter->format_price( $fund->{$field} );
    }
}
print STDERR "Final: ".Dumper($fund_arr);

$template->param(

    type          => 'intranet',
    loop_budget   => $fund_arr,
    branchname    => $branchname,
    total         => $num_formatter->format_price($total),
    totspent      => $num_formatter->format_price($totspent),
    totordered    => $num_formatter->format_price($totordered),
    totcomtd      => $num_formatter->format_price($totcomtd),
    totavail      => $num_formatter->format_price($totavail),
);

output_html_with_http_headers $query, $cookie, $template->output;
