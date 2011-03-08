#!/usr/bin/perl

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
#use warnings; FIXME - Bug 2505
use CGI;
use C4::Context;
use C4::Output;
use C4::Auth;
use C4::Budgets;

=head1 DESCRIPTION

This script checks the amount unallocated from the new parent budget , or the period - if no parent_id is given

This script is called from aqbudgets.pl during an 'add' or 'mod' budget, from the JSscript Check() function, 
to determine whether the new parent budget (or period) has enough unallocated funds for the save to complete.

=cut

my $dbh = C4::Context->dbh;
my $input = new CGI;

my $total     = $input->param('total');
my $budget_id = $input->param('budget_id');
my $parent_id = $input->param('parent_id');
my $period_id = $input->param('period_id');
my $returncode;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {   template_name   => "acqui/ajax.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        debug           => 0,
    }
);
my ($period, $parent , $budget);
$period = GetBudgetPeriod($period_id) if $period_id;
$parent = GetBudget($parent_id)       if defined $parent_id;
$budget = GetBudget($budget_id)       if defined $budget_id;

# CHECK THE PARENT BUDGET FOR ENOUGHT AMOUNT UNALLOCATED,  IF NOT THEN RETURN 1
my ($sub_unalloc , $period_sum, $budget_period_unalloc);

if ($parent) {
    my $query = "  SELECT SUM(budget_amount) as sum FROM aqbudgets where budget_parent_id = ? ";
    my $sth   = $dbh->prepare($query);
    $sth->execute( $parent->{'budget_id'} );
    my $sum = $sth->fetchrow_hashref;
    $sth->finish;
    
    $sub_unalloc = $parent->{'budget_amount'} - $sum->{sum};
        
#    TRICKY.. , IF THE PARENT IS THE CURRENT PARENT  - THEN SUBSTRACT CURRENT BUDGET FROM TOTAL
    $sub_unalloc           += $budget->{'budget_amount'} if ( $budget->{'budget_parent_id'} == $parent_id ) ;
}

# ELSE , IF NO PARENT PASSED, THEN CHECK UNALLOCATED FOR PERIOD, IF NOT THEN RETURN 2
else {
    my $query = qq| SELECT SUM(budget_amount) as sum
                FROM aqbudgets WHERE budget_period_id = ? and budget_parent_id IS NULL|;

    my $sth   = $dbh->prepare($query);
    $sth->execute(  $period_id  ); 
    $period_sum = $sth->fetchrow_hashref;
    $sth->finish;
    $budget_period_unalloc = $period->{'budget_period_total'} - $period_sum->{'sum'} if $period->{'budget_period_total'};
}

if ( $parent_id) {
    if ( ($total > $sub_unalloc ) && $sub_unalloc )  {
        $returncode = 1;
    }
} elsif ( ( $total > $budget_period_unalloc ) && $budget_period_unalloc ) {
    $returncode = 2;

} else {
    $returncode = 0;
}


output_html_with_http_headers $input, $cookie, $returncode;
1;
