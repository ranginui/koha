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

=head1 NAME

subscription-bib-search.pl

=head1 DESCRIPTION

this script search among all existing subscriptions.

=head1 PARAMETERS

=over 4

=item op
op use to know the operation to do on this template.
 * do_search : to search the subscription.

Note that if op = do_search there are some others params specific to the search :
    marclist,and_or,excluding,operator,value

=item startfrom
to multipage gestion.


=back

=cut

use strict;
use warnings;

use CGI;
use C4::Koha;
use C4::Auth;
use C4::Context;
use C4::Output;
use C4::Search;
use C4::Biblio;
use C4::Debug;
use Data::Pagination;

my $input                 = new CGI;
my $op                    = $input->param('op');
my $query                 = $input->param('q') || '*:*';
my $dbh                   = C4::Context->dbh;
my $count                 = 20;
my $page                  = $input->param('page') || 1;
my $advanced_search_types = C4::Context->preference("AdvancedSearchTypes");
my $itype_or_itemtype     = C4::Context->preference("item-level_itypes") ? 'str_itype' : 'str_itemtype';

my ( $template, $loggedinuser, $cookie );

# don't run the search if no search term !
if ( $op eq "do_search" && $query ) {

    my $filters = { recordtype => 'biblio' };

    # add the itemtype limit if applicable
    my $itemtypelimit = $input->param('itemtypelimit');
    if ( $itemtypelimit ) {
        if ( ! $advanced_search_types or $advanced_search_types eq 'itemtypes' ) {
            $filters->{$itype_or_itemtype} = "\"$itemtypelimit\"";
        } else {
            $filters->{$advanced_search_types} = "\"$itemtypelimit\"";
        }
    }

    my $res = SimpleSearch( $query, $filters, $page, $count);
    my @results = map { GetBiblio $_->{'values'}->{'recordid'} } @{ $res->items };

    my $pager = Data::Pagination->new(
        $res->{'pager'}->{'total_entries'},
        $count,
        20,
        $page,
    );

    ( $template, $loggedinuser, $cookie ) = get_template_and_user( {
        template_name   => "serials/result.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { serials   => 1 },
        flagsrequired   => { catalogue => 1 },
        debug           => 1,
    } );

    $template->param(
        query          => $query,
        resultsloop    => \@results,
        total          => $res->{'pager'}->{'total_entries'},
        PAGE_NUMBERS  => [ map { { page => $_, current => $_ == $page } } @{ $pager->{'numbers_of_set'} } ],
        pager_params  => [ { ind => 'op'           , val => $op            },
                           { ind => 'q'            , val => $query         },
                           { ind => 'itemtypelimit', val => $itemtypelimit } ],
    );

} else {
    my @itemtypesloop;

    if ( !$advanced_search_types or $advanced_search_types eq 'itemtypes' ) {

        my $itemtypes = GetItemTypes;
        @itemtypesloop = map { {
            code        => $_,
            description => $itemtypes->{$_}->{'description'},
        } } keys %$itemtypes;

    } else {

        my $advsearchtypes = GetAuthorisedValues( $advanced_search_types );
        @itemtypesloop = map { {
            code        => $_->{authorised_value},
            description => $_->{'lib'},
        } } @$advsearchtypes;

    }

    ( $template, $loggedinuser, $cookie ) = get_template_and_user( {
        template_name   => "serials/subscription-bib-search.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { catalogue => 1, serials => 1 },
        debug           => 1,
    } );

    $template->param( itemtypeloop => \@itemtypesloop );
}

output_html_with_http_headers $input, $cookie, $template->output;
