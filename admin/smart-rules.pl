#!/usr/bin/perl
# vim: et ts=4 sw=4
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
use C4::Koha;
use C4::Debug;
use C4::Branch;
use C4::IssuingRules;
use C4::Circulation;

my $input = new CGI;
my $dbh = C4::Context->dbh;

my ($template, $loggedinuser, $cookie) = get_template_and_user({
    template_name   => "admin/smart-rules.tmpl",
    query           => $input,
    type            => "intranet",
    authnotrequired => 0,
    flagsrequired   => {parameters => 1},
    debug           => 1,
});

my $type       = $input->param('type');
my $branchcode = $input->param('branchcode') || ( C4::Branch::onlymine() ? ( C4::Branch::mybranch() || '*' ) : '*' );
my $op         = $input->param('op');
my $confirm    = $input->param('confirm'); 

# This block builds the branch list
my $branches = GetBranches();
my @branchloop;
for my $thisbranch (sort { $branches->{$a}->{'branchname'} cmp $branches->{$b}->{'branchname'} } keys %$branches) {
    my $selected = 1 if $thisbranch eq $branchcode;
    my %row =(value => $thisbranch,
                selected => $selected,
                branchname => $branches->{$thisbranch}->{'branchname'},
            );
    push @branchloop, \%row;
}

# Get the patron category list
my @category_loop = C4::Category->all;

# Get the item types list
my @itemtypes = C4::ItemType->all;

if ( $op eq 'delete' ) {
    DelIssuingRule({
        branchcode   => $branchcode,
        categorycode => $input->param('categorycode'),
        itemtype     => $input->param('itemtype'),
    });
}
# save the values entered
elsif ( $op eq 'add' ) {

    # Converts '' to undef, so we can have NULL in database fields
    my $issuingrule;
    for ( $input->param ) {
        my $v = $input->param($_);
        $issuingrule->{$_} = length $v ? $v : undef;
    }

    # We don't want op to be passed to the API
    delete $issuingrule->{'op'};

    # If the (branchcode,categorycode,itemtype) combination already exists...
    my @issuingrules = GetIssuingRules({
        branchcode      => $issuingrule->{'branchcode'},
        categorycode    => $issuingrule->{'categorycode'},
        itemtype        => $issuingrule->{'itemtype'},
    });

    # ...we modify the existing rule...
    if ( @issuingrules ) {
        ModIssuingRule( $issuingrule );
#    } elsif (@issuingrules){
#        $template->param(confirm=>1);
#        $template->param(%$issuingrule);
#        foreach (@category_loop) { 
#            $_->{selected}="selected" if ($_->{categorycode} eq $issuingrule->{categorycode});
#        }
#        foreach (@itemtypes) { 
#            $_->{selected}="selected" if ($_->{itemtype} eq $issuingrule->{itemtype});
#        }
    # ...else we add a new rule.
    } else {
        AddIssuingRule( $issuingrule );
    }
}

# Get the issuing rules list...
my @issuingrules = GetIssuingRulesByBranchCode($branchcode);

# ...and refine its data, row by row.
for my $rule ( @issuingrules ) {
    $rule->{'humanitemtype'}             ||= $rule->{'itemtype'};
    $rule->{'default_humanitemtype'}       = $rule->{'humanitemtype'} eq '*';
    $rule->{'humancategorycode'}         ||= $rule->{'categorycode'};
    $rule->{'default_humancategorycode'}   = $rule->{'humancategorycode'} eq '*';

    # This block is to show herited values in grey.
    # We juste compare keys from our raw rule, with keys from the computed rule.
    my $computedrule = GetIssuingRule($rule->{'categorycode'}, $rule->{'itemtype'}, $rule->{'branchcode'});
    for ( keys %$rule ) {
        if ( not defined $rule->{$_} ) {
            $rule->{$_} = $computedrule->{$_};
            $rule->{"herited_$_"} = 1;
        }
    }
}

# Get the issuing rules list...
my @issuingrules = GetIssuingRulesByBranchCode($branchcode);

# ...and refine its data, row by row.
for my $rule ( @issuingrules ) {
    $rule->{'humanitemtype'}             ||= $rule->{'itemtype'};
    $rule->{'default_humanitemtype'}       = $rule->{'humanitemtype'} eq '*';
    $rule->{'humancategorycode'}         ||= $rule->{'categorycode'};
    $rule->{'default_humancategorycode'}   = $rule->{'humancategorycode'} eq '*';

    # This block is to show herited values in grey.
    # We juste compare keys from our raw rule, with keys from the computed rule.
    my $computedrule = GetIssuingRule($rule->{'categorycode'}, $rule->{'itemtype'}, $rule->{'branchcode'});
    for ( keys %$rule ) {
        if ( not defined $rule->{$_} ) {
            $rule->{$_} = $computedrule->{$_};
            $rule->{"herited_$_"} = 1;
        }
    }

    $rule->{'fine'}                        = sprintf('%.2f', $rule->{'fine'});
}

$template->param(
    categoryloop  => \@category_loop,
    itemtypeloop  => \@itemtypes,
    rules         => \@issuingrules,
    branchloop    => \@branchloop,
    humanbranch   => ($branchcode ne '*' ? $branches->{$branchcode}->{branchname} : ''),
    branchcode    => $branchcode,
    definedbranch => scalar(@issuingrules) > 0,
);
output_html_with_http_headers $input, $cookie, $template->output;

exit 0;

