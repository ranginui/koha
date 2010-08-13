#!/usr/bin/perl
# WARNING: 4-character tab stops here

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
use C4::Output;
use C4::Auth;
use C4::Context;
use C4::AuthoritiesMarc;
use C4::Acquisition;
use C4::Koha;    # XXX subfield_is_koha_internal_p
use C4::Search;
use Data::Pagination;

my $query        = new CGI;
my $authtypecode = $query->param('authtypecode');
my $index        = $query->param('index');
my $tagid        = $query->param('tagid');
my $resultstring = $query->param('result');
my $dbh          = C4::Context->dbh;

my ( $template, $loggedinuser, $cookie );

my $authtypes = getauthtypes;
my @authtypesloop;
foreach my $thisauthtype ( keys %$authtypes ) {
    my %row = (
        value        => $thisauthtype,
        selected     => ( $thisauthtype eq $authtypecode ),
        authtypetext => $authtypes->{$thisauthtype}{'authtypetext'},
        index        => $index,
    );
    push @authtypesloop, \%row;
}

if ( $query->param('value_mainstr') ) {
    my $searchquery = $query->param('value_mainstr');
    my $authtype    = $query->param('authtypecode');
    my $orderby     = $query->param('orderby');
    my $page        = $query->param('page') || 1;
    my $resultsperpage = 20;
    
    my $filters = {
        recordtype => 'authority',
        authtype   => $authtype,
    };

    my $results = SimpleSearch( $searchquery, $filters, $page, $resultsperpage, $orderby );
    
    ( $template, $loggedinuser, $cookie ) = get_template_and_user(
        {   template_name   => "authorities/searchresultlist-auth.tmpl",
            query           => $query,
            type            => 'intranet',
            authnotrequired => 0,
            flagsrequired   => { catalogue => 1 },
        }
    );

    my @resultdatas;
    for (@{$results->{items}}) {
        my $record = GetAuthority($_->{values}->{recordid});
        push @resultdatas, {
            authid  => $_->{values}->{recordid},
            summary => BuildSummary($record, $_->{values}->{recordid}, $_->{values}->{sfield_authtype}),
            used    => CountUsage($_->{values}->{recordid}),
        };
    }

    my $pager = Data::Pagination->new(
                   $results->{pager}->{total_entries},
                   $resultsperpage,
                   20,
                   $page,
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

    
    $template->param( result => \@resultdatas ) if $results;
    $template->param(
        value_mainstr  => $searchquery,
        orderby        => $orderby,
        resultsperpage => $resultsperpage,
        authtypecode   => $authtypecode,
    );
} else {
    ( $template, $loggedinuser, $cookie ) = get_template_and_user(
        {   template_name   => "authorities/auth_finder.tmpl",
            query           => $query,
            type            => 'intranet',
            authnotrequired => 0,
            flagsrequired   => { catalogue => 1 },
        }
    );

    $template->param( resultstring => $resultstring, );
}

$template->param(
    value_mainstr => $query->param('value_mainstr') || "",
    value_main    => $query->param('value_main')    || "",
    value_any     => $query->param('value_any')     || "",
    tagid         => $tagid,
    index         => $index,
    authtypesloop => \@authtypesloop,
    authtypecode  => $authtypecode,
    value_mainstr => $query->param('value_mainstr') || "",
    value_main    => $query->param('value_main')    || "",
    value_any     => $query->param('value_any')     || "",
);

# Print the page
output_html_with_http_headers $query, $cookie, $template->output;

# Local Variables:
# tab-width: 4
# End:
