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
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use warnings;
use CGI;
use C4::Auth;
use C4::Koha;
use C4::Dates qw/format_date/;
use C4::Serials;
use C4::Output;
use C4::Context;
use Date::Calc qw/Today Day_of_Year Week_of_Year Add_Delta_Days/;
use Carp;

my $query = new CGI;
my $op = $query->param('op') || q{};
my $issueconfirmed = $query->param('issueconfirmed');
my $dbh = C4::Context->dbh;
my ($template, $loggedinuser, $cookie, $hemisphere);
my $subscriptionid = $query->param('subscriptionid');
my $subs = GetSubscription($subscriptionid);

($template, $loggedinuser, $cookie)
= get_template_and_user({template_name => "serials/subscription-detail.tmpl",
                query => $query,
                type => "intranet",
                authnotrequired => 0,
                flagsrequired => {serials => 1},
                debug => 1,
                });

$$subs{enddate} ||= GetExpirationDate($subscriptionid);

if ($op eq 'del') {
	if ($$subs{'cannotedit'}){
		carp "Attempt to delete subscription $subscriptionid by ".C4::Context->userenv->{'id'}." not allowed";
		print $query->redirect("/cgi-bin/koha/serials/subscription-detail.pl?subscriptionid=$subscriptionid");
		exit;
	}
	
    # Asking for confirmation if the subscription has not strictly expired yet or if it has linked issues
    my $strictlyexpired = HasSubscriptionStrictlyExpired($subscriptionid);
    my $linkedissues = CountIssues($subscriptionid);
    my $countitems   = HasItems($subscriptionid);
    if ($strictlyexpired == 0 || $linkedissues > 0 || $countitems>0) {
		$template->param(NEEDSCONFIRMATION => 1);
		if ($strictlyexpired == 0) { $template->param("NOTEXPIRED" => 1); }
		if ($linkedissues     > 0) { $template->param("LINKEDISSUES" => 1); }
		if ($countitems       > 0) { $template->param("LINKEDITEMS"  => 1); }
    } else {
		$issueconfirmed = "1";
    }
    # If it's ok to delete the subscription, we do so
    if ($issueconfirmed eq "1") {
		&DelSubscription($subscriptionid);
		print "Content-Type: text/html\n\n<META HTTP-EQUIV=Refresh CONTENT=\"0; URL=serials-home.pl\"></html>";
		exit;
    }
}
my $hasRouting = check_routing($subscriptionid);
my ($totalissues,@serialslist) = GetSerials($subscriptionid);
$totalissues-- if $totalissues; # the -1 is to have 0 if this is a new subscription (only 1 issue)
# the subscription must be deletable if there is NO issues for a reason or another (should not happend, but...)

my ($user, $sessionID, $flags);
($user, $cookie, $sessionID, $flags)
    = checkauth($query, 0, {catalogue => 1}, "intranet");

# COMMENT hdl : IMHO, we should think about passing more and more data hash to template->param rather than duplicating code a new coding Guideline ?

for my $date qw(startdate enddate firstacquidate histstartdate histenddate){
    $$subs{$date}      = format_date($$subs{$date}) if $date && $$subs{$date};
}
$subs->{abouttoexpire}  = abouttoexpire($subs->{subscriptionid});

$template->param($subs);
$template->param(biblionumber_for_new_subscription => $subs->{bibnum});
my @irregular_issues = split /,/, $subs->{irregularity};

if (! $subs->{numberpattern}) {
    $subs->{numberpattern} = q{};
}
if (! $subs->{dow}) {
    $subs->{dow} = q{};
}
if (! $subs->{periodicity}) {
    $subs->{periodicity} = '0';
}
my $default_bib_view = get_default_view();
$template->param(
	subscriptionid => $subscriptionid,
    serialslist => \@serialslist,
    hasRouting  => $hasRouting,
    totalissues => $totalissues,
    hemisphere => $hemisphere,
    cannotedit =>(C4::Context->preference('IndependantBranches') &&
                C4::Context->userenv &&
                C4::Context->userenv->{flags} % 2 !=1  &&
                C4::Context->userenv->{branch} && $subs->{branchcode} &&
                (C4::Context->userenv->{branch} ne $subs->{branchcode})),
    'periodicity' . $subs->{periodicity} => 1,
    'arrival' . $subs->{dow} => 1,
    'numberpattern' . $subs->{numberpattern} => 1,
    intranetstylesheet => C4::Context->preference('intranetstylesheet'),
    intranetcolorstylesheet => C4::Context->preference('intranetcolorstylesheet'),
    irregular_issues => scalar @irregular_issues,
    default_bib_view => $default_bib_view,
    );

output_html_with_http_headers $query, $cookie, $template->output;

sub get_default_view {
    my $defaultview = C4::Context->preference('IntranetBiblioDefaultView');
    my $views = { C4::Search::enabled_staff_search_views };
    if ($defaultview eq 'isbd' && $views->{can_view_ISBD}) {
        return 'ISBDdetail';
    } elsif  ($defaultview eq 'marc' && $views->{can_view_MARC}) {
        return 'MARCdetail';
    } elsif  ($defaultview eq 'labeled_marc' && $views->{can_view_labeledMARC}) {
        return 'labeledMARCdetail';
    } else {
        return 'detail';
    }
}
