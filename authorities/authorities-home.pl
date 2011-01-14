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

use Modern::Perl;
use CGI;
use C4::Auth;
use C4::Context;
use C4::Output;
use C4::AuthoritiesMarc;
use C4::Koha;
use C4::Search;
use C4::Search::Query;
use Data::Pagination;

my $query        = new CGI;
my $op           = $query->param('op');
my $dbh          = C4::Context->dbh;
my $authtypecode = $query->param('authtypecode');

my ( $template, $loggedinuser, $cookie );

my $authtypes = getauthtypes;
my @authtypesloop = map { {
    value        => $_,
    selected     => $_ eq $authtypecode,
    authtypetext => $authtypes->{$_}{'authtypetext'},
} } keys %$authtypes;

if ( $op eq "do_search" ) {
    my $orderby      = $query->param('orderby') || 'score desc';
    my $value        = $query->param('value')   || '*:*';
    my $page         = $query->param('page')    || 1;
    my $count        = 20;

    my $filters = { recordtype => 'authority' };
    $filters->{C4::Search::Query::getIndexName('auth-type')} = $authtypecode if $authtypecode;

    my $indexes;
    my $operands;
    given ( $query->param('searchtype') ) {
        when ( 'authority_search' ) { # Chercher dans la vedette ($a)
            given ( $authtypecode ) {
                when ( 'CO' ) {
                    push @$indexes, 'auth-corporate-name-heading';
                }
                when ( 'NP' ) {
                    push @$indexes, 'auth-personal-name-heading';
                }
                when ( 'FAM' ) {
                    push @$indexes, 'auth-name-heading';
                }
                when ( 'SNG' ) {
                    push @$indexes, 'auth-name-geographic-heading';
                }
                when ( 'SAUTTIT' ) {
                    push @$indexes, 'auth-name-title-heading';
                }
                when ( 'SNC' ) {
                    push @$indexes, 'auth-subject-heading';
                }
                when ( 'EN3S' ) {
                    push @$indexes, 'auth-subject-heading';
                }
                when ( 'TU' ) {
                    push @$indexes, 'auth-title-uniform-heading';
                }

                default {
                    push @$indexes, 'auth-heading-main';
                }
            }
        }
        when ( 'main_heading' ) { # Recherche vedette
            given ( $authtypecode ) {
                when ( 'SNC' ) {
                    push @$indexes, 'auth-subject';
                }
                when ( 'ARCHI' ) {
                    push @$indexes, 'auth-subject';
                }
                when ( 'EN3S' ) {
                    push @$indexes, 'auth-subject';
                }
                when ( 'CO' ) {
                    push @$indexes, 'auth-corporate-name';
                }
                when ( 'NP' ) {
                    push @$indexes, 'auth-personal-name';
                }
                when ( 'FAM' ) {
                    push @$indexes, 'auth-name';
                }
                when ( 'SNG' ) {
                    push @$indexes, 'auth-name-geographic';
                }
                when ( 'SAUTTIT' ) {
                    push @$indexes, 'auth-name-title';
                }
                when ( 'TU' ) {
                    push @$indexes, 'auth-title-uniform';
                }
                default {
                    push @$indexes, 'auth-heading';
                }
            }
        }
        when ( 'all_headings' ) { # Rechercher toutes les vedettes
            given ( $authtypecode ) {
                when ( 'SNC' ) {
                    push @$indexes, 'auth-subject';
                    push @$indexes, 'auth-subject-parallel';
                    push @$indexes, 'auth-subject-see';
                    push @$indexes, 'auth-subject-see-also';
                }
                when ( 'ARCHI' ) {
                    push @$indexes, 'auth-subject';
                    push @$indexes, 'auth-subject-parallel';
                    push @$indexes, 'auth-subject-see';
                    push @$indexes, 'auth-subject-see-also';
                }
                when ( 'EN3S' ) {
                    push @$indexes, 'auth-subject';
                    push @$indexes, 'auth-subject-parallel';
                    push @$indexes, 'auth-subject-see';
                    push @$indexes, 'auth-subject-see-also';
                }
                when ( 'CO' ) {
                    push @$indexes, 'auth-corporate-name';
                    push @$indexes, 'auth-corporate-name-parallel';
                    push @$indexes, 'auth-corporate-name-see';
                    push @$indexes, 'auth-corporate-name-see-also';
                }
                when ( 'NP' ) {
                    push @$indexes, 'auth-personal-name';
                    push @$indexes, 'auth-personal-name-parallel';
                    push @$indexes, 'auth-personal-name-see';
                    push @$indexes, 'auth-personal-name-see-also';
                }
                when ( 'FAM' ) {
                    push @$indexes, 'auth-name';
                    push @$indexes, 'auth-name-parallel';
                    push @$indexes, 'auth-name-see';
                    push @$indexes, 'auth-name-see-also';
                }
                when ( 'SNG' ) {
                    push @$indexes, 'auth-name-geographic';
                    push @$indexes, 'auth-name-geographic-parallel';
                    push @$indexes, 'auth-name-geographic-see';
                    push @$indexes, 'auth-name-geographic-see-also';
                }
                when ( 'SAUTTIT' ) {
                    push @$indexes, 'auth-name-title';
                    push @$indexes, 'auth-name-title-parallel';
                    push @$indexes, 'auth-name-title-see';
                    push @$indexes, 'auth-name-title-see-also';

                }
                when ( 'TU' ) {
                    push @$indexes, 'auth-title-uniform';
                    push @$indexes, 'auth-title-uniform-parallel';
                    push @$indexes, 'auth-title-uniform-see';
                    push @$indexes, 'auth-title-uniform-see-also';
                }
                default {
                    push @$indexes, 'all_fields';
                }
            }
        }
    }

    for (@$indexes) {
        push @$operands, $value;
    }
    my $q = C4::Search::Query->buildQuery($indexes, $operands, ());

    my $results = SimpleSearch($q, $filters, $page, $count, $orderby);
    C4::Context->preference("DebugLevel") eq '2' && warn "AuthSolrSimpleSearch:q=$q:";

    my $pager = Data::Pagination->new(
        $results->{pager}->{total_entries},
        $count,
        20,
        $page,
    );

    ( $template, $loggedinuser, $cookie ) = get_template_and_user( {
        template_name     => "authorities/searchresultlist.tmpl",
        query             => $query,
        type              => 'intranet',
        authnotrequired   => 0,
        flagsrequired     => { catalogue => 1 },
        debug             => 1,
    } );

    $template->param(
        previous_page => $pager->{prev_page},
        next_page     => $pager->{next_page},
        PAGE_NUMBERS  => [ map { { page => $_, current => $_ == $page } } @{$pager->{numbers_of_set}} ],
        current_page  => $page,
        from          => $pager->{start_of_slice},
        to            => $pager->{end_of_slice},
        total         => $pager->{total_entries},
        value         => $value,
        orderby       => $orderby,
    );

    my $authid_index_name = C4::Search::Query::getIndexName('authid');
    my @resultrecords;
    for ( @{$results->{items}} ) {
        my $authrecord = GetAuthority( $_->{values}->{recordid} );

        my $authority  = {
           authid  => $_->{values}->{recordid},
           authid_index_name => $authid_index_name,
           summary => BuildSummary( $authrecord, $_->{values}->{recordid} ),
           used    => CountUsage( $_->{values}->{recordid} ),
        };

        push @resultrecords, $authority;
    }

    $template->param( result => \@resultrecords );

} elsif ( $op eq "delete" ) {

    my $authid = $query->param('authid');
    DelAuthority( $authid, 1 );

    ( $template, $loggedinuser, $cookie ) = get_template_and_user( {
        template_name   => "authorities/authorities-home.tmpl",
        query           => $query,
        type            => 'intranet',
        authnotrequired => 0,
        flagsrequired   => { catalogue => 1 },
        debug           => 1,
    } );

} else {

    ( $template, $loggedinuser, $cookie ) = get_template_and_user( {
        template_name   => "authorities/authorities-home.tmpl",
        query           => $query,
        type            => 'intranet',
        authnotrequired => 0,
        flagsrequired   => { catalogue => 1 },
        debug           => 1,
    } );
}

$template->param( 
    authtypesloop    => \@authtypesloop,
    name_index_name  => C4::Search::Query::getIndexName('auth_name'),
    usage_index_name => C4::Search::Query::getIndexName('usedinxbiblios')
);

# Print the page
output_html_with_http_headers $query, $cookie, $template->output;
