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
use warnings;

use CGI;
use C4::Auth;

use C4::Context;
use C4::Auth;
use C4::Output;
use C4::AuthoritiesMarc;
use C4::Acquisition;
use C4::Koha;    # XXX subfield_is_koha_internal_p
use C4::Biblio;
use C4::Search;
use Data::Pagination;

my $query = new CGI;
my $op    = $query->param('op');
$op ||= q{};
my $authtypecode = $query->param('authtypecode');
$authtypecode ||= q{};
my $dbh = C4::Context->dbh;

my $authid = $query->param('authid');
my ( $template, $loggedinuser, $cookie );

my $authtypes = getauthtypes;
my @authtypesloop;
foreach my $thisauthtype (
    sort { $authtypes->{$a}{'authtypetext'} cmp $authtypes->{$b}{'authtypetext'} }
    keys %$authtypes
  ) {
    my %row = (
        value        => $thisauthtype,
        selected     => $thisauthtype eq $authtypecode,
        authtypetext => $authtypes->{$thisauthtype}{'authtypetext'},
    );
    push @authtypesloop, \%row;
}

if ( $op eq "do_search" ) {
    my $orderby      = $query->param('orderby');
    my $value        = $query->param('value');
    my $authtypecode = $query->param('authtypecode');
    my $page         = $query->param('page') || 1;
    my $count        = 20;

    my $filters = { recordtype => 'authority' };
    $filters->{authtype} = $authtypecode if $authtypecode;

    my $results = SimpleSearch($value, $filters, $page, $count, $orderby);

    my $pager = Data::Pagination->new(
               $results->{pager}->{total_entries},
               $count,
               20,
               $page,
            );

    ( $template, $loggedinuser, $cookie ) = get_template_and_user(
        {   template_name   => "authorities/searchresultlist.tmpl",
            query           => $query,
            type            => 'intranet',
            authnotrequired => 0,
            flagsrequired   => { catalogue => 1 },
            debug           => 1,
        }
    );

    $template->param(
       previous_page => $pager->{prev_page},
       next_page     => $pager->{next_page},
       PAGE_NUMBERS  => [ map { { page => $_, current => $_ == $page } } @{$pager->{numbers_of_set}} ],
       current_page  => $page,
       from          => $pager->{start_of_slice},
       to            => $pager->{end_of_slice},
       total         => $pager->{total_entries},
    );

    $template->param(
       value   => $value,
       orderby => $orderby,
    );

    my @resultrecords;
    for ( @{$results->{items}} ) {
        my $authrecord = GetAuthority($_->{values}->{recordid});

        my $authority  = {
           authid  => $_->{values}->{recordid},
           summary => BuildSummary($authrecord, $_->{values}->{recordid}),
           used    => CountUsage( $_->{values}->{recordid} ),
        };

        push @resultrecords, $authority;
    }

    $template->param( result => \@resultrecords ) if \@resultrecords;

} elsif ( $op eq "delete" ) {

    &DelAuthority( $authid, 1 );

    ( $template, $loggedinuser, $cookie ) = get_template_and_user(
        {   template_name   => "authorities/authorities-home.tmpl",
            query           => $query,
            type            => 'intranet',
            authnotrequired => 0,
            flagsrequired   => { catalogue => 1 },
            debug           => 1,
        }
    );

    # 	$template->param("statements" => \@statements,
    # 						"nbstatements" => $nbstatements);
} else {
    ( $template, $loggedinuser, $cookie ) = get_template_and_user(
        {   template_name   => "authorities/authorities-home.tmpl",
            query           => $query,
            type            => 'intranet',
            authnotrequired => 0,
            flagsrequired   => { catalogue => 1 },
            debug           => 1,
        }
    );

}

$template->param( authtypesloop => \@authtypesloop, );

# Print the page
output_html_with_http_headers $query, $cookie, $template->output;
