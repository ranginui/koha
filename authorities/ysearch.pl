#!/usr/bin/perl

# This software is placed under the gnu General Public License, v2 (http://www.gnu.org/licenses/gpl.html)

# Copyright 2007 Tamil s.a.r.l.
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

=head1 ysearch.pl


=cut

use strict;

use warnings;
use CGI;
use C4::Context;
use C4::AuthoritiesMarc;
use C4::Auth qw/check_cookie_auth/;
use Switch;
use C4::Search::Query;
use C4::Search;


my $query = new CGI;

binmode STDOUT, ":utf8";
print $query->header( -type => 'text/plain', -charset => 'UTF-8' );

my ( $auth_status, $sessionID ) = check_cookie_auth( $query->cookie('CGISESSID'), { } );
if ( $auth_status ne "ok" ) {
    exit 0;
}

my $authtypecode = $query->param('authtypecode') || "[* TO *]";
my $searchstr    = $query->param('query');
my $searchtype   = $query->param('searchtype') || 'all_headings';
my $orderby      = $query->param('orderby') || '';
my $page         = $query->param('page') || 1;
my $count        = 20;

my $index = GetIndexBySearchtype($searchtype);
my $indexes;
my $operands;
my $operators;
my @values;
if ( defined $searchstr ) {
    my $authoritysep = C4::Context->preference('authoritysep');
    $searchstr =~ s/$authoritysep//g;
    push @values, split(' ', $searchstr);
    $values[-1] = $values[-1] . '*';
} else {
    push @values, '[* TO *]';
}
push @$indexes, $index for @values;
push @$operands, $_ for @values;
push @$operators, 'AND' for @values;

my $authtype_indexname = C4::Search::Query::getIndexName('auth-type');
my $filters = {
    recordtype => 'authority',
    $authtype_indexname => $authtypecode
};
my $q = C4::Search::Query->buildQuery( $indexes, $operands, $operators );
my $results = SimpleSearch( $q, $filters, $page, $count, $orderby );

warn Data::Dumper::Dumper $results;

my $summary_index_name = C4::Search::Query::getIndexName('auth-summary');
map {
    my $record = GetAuthority( $_->{'values'}->{'recordid'} );
    my $summary = $_->{'values'}->{$summary_index_name};
    $summary =~ s/\n/ /g;
    $summary =~ s/<[^>]*>/ /g;
    print $summary . "\n" if $summary ne ' ';
} @{ $results->{items} };

