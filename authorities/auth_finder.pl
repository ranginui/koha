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
use C4::Output;
use C4::Auth;
use C4::Context;
use C4::AuthoritiesMarc;
use C4::Acquisition;
use C4::Koha;
use C4::Search;
use C4::Search::Query;
use Data::Pagination;

my $query        = new CGI;
my $authtypecode = $query->param('authtypecode') || '';
my $index        = $query->param('index');
my $tagid        = $query->param('tagid');
my $resultstring = $query->param('result');
my $dbh          = C4::Context->dbh;

my ( $template, $loggedinuser, $cookie );

my $authtypes = getauthtypes;
my @authtypesloop = map { {
    value        => $_,
    selected     => ( $_ eq $authtypecode ),
    authtypetext => $authtypes->{$_}->{'authtypetext'},
    index        => $index,
} } keys %$authtypes;

if ( $query->param('op') eq 'do_search' ) {
    my $orderby     = $query->param('orderby') || 'score desc';
    my $page        = $query->param('page') || 1;
    my $count       = 20;

    ( $template, $loggedinuser, $cookie ) = get_template_and_user( {
        template_name   => "authorities/searchresultlist-auth.tmpl",
        query           => $query,
        type            => 'intranet',
        authnotrequired => 0,
        flagsrequired   => { catalogue => 1 },
    } );

    my @searchtypes = ('authority_search', 'main_heading', 'all_headings');

    my $indexes;
    my $value;
    my $operands;
    my $operators;
    for my $searchtype (@searchtypes) {
        if ( $query->param($searchtype) ) {
            push @$indexes, @{GetIndexesBySearchtype($searchtype, $authtypecode)};
            my $value = $query->param($searchtype) || '[* TO *]';
            for (@$indexes) {
                push @$operands, $value;
                push @$operators, 'AND';
            }
            $template->param($searchtype => $query->param($searchtype));
        }
    }

    if ( not $indexes ) {
        push @$indexes, @{GetIndexesBySearchtype('all_headings', $authtypecode)};
        for (@$indexes) {
            push @$operands, '[* TO *]';
        }
    }

    my $filters = {
        recordtype => 'authority',
    };
    my $authtype_index = C4::Search::Query::getIndexName('auth-type');
    $filters->{$authtype_index} = $authtypecode if $authtypecode;

    my $q = C4::Search::Query->buildQuery( $indexes, $operands, $operators );
    my $results = SimpleSearch( $q, $filters, $page, $count, $orderby );

    my @resultdatas = map {
        my $record = GetAuthority( $_->{'values'}->{'recordid'} );
        {
            authid  => $_->{'values'}->{'recordid'},
            summary => BuildSummary( $record, $_->{'values'}->{'recordid'}, $_->{'values'}->{$authtype_index} ),
            used    => CountUsage( $_->{'values'}->{'recordid'} ),
        }
    } @{ $results->{items} };

    my $pager = Data::Pagination->new(
        $results->{'pager'}->{'total_entries'},
        $count,
        20,
        $page,
    );

    my $pager_params = [
        { ind => 'index'        , val => $index        },
        { ind => 'authtypecode' , val => $authtypecode },
        { ind => 'order_by'     , val => $orderby      },
    ];

    $template->param(
        previous_page  => $pager->{'prev_page'},
        next_page      => $pager->{'next_page'},
        PAGE_NUMBERS   => [ map { { page => $_, current => $_ == $page } } @{ $pager->{'numbers_of_set'} } ],
        current_page   => $page,
        total          => $pager->{'total_entries'},
        pager_params   => $pager_params,
        result         => \@resultdatas,
        orderby        => $orderby,
        authtypecode   => $authtypecode,
    );
} else {
    ( $template, $loggedinuser, $cookie ) = get_template_and_user( {
        template_name   => "authorities/auth_finder.tmpl",
        query           => $query,
        type            => 'intranet',
        authnotrequired => 0,
        flagsrequired   => { catalogue => 1 },
    } );

    $template->param( resultstring => $resultstring, );
}

$template->param(
    tagid         => $tagid,
    index         => $index,
    authtypesloop => \@authtypesloop,
    authtypecode  => $authtypecode,
    name_index_name => C4::Search::Query::getIndexName('auth-name'),
    usedinxbiblios_index_name => C4::Search::Query::getIndexName('usedinxbiblios'),
);

# Print the page
output_html_with_http_headers $query, $cookie, $template->output;
