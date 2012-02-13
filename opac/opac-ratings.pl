#!/usr/bin/perl

# Copyright 2010 KohaAloha, NZ
# Parts copyright 2011, Catalyst IT, NZ
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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA

=head1

opac-ratings.pl - API endpoint for setting rating values

This receives a POST containing biblionumber and rating. It
updates rating for the logged in user.

=cut

use strict;
use warnings;
use CGI;
use CGI::Cookie;    # need to check cookies before having CGI parse the POST request
use JSON;

use C4::Auth qw(:DEFAULT check_cookie_auth);
use C4::Context;
use C4::Debug;
use C4::Output 3.02 qw(:html :ajax pagination_bar);
use C4::Ratings;

use Data::Dumper;

my %ratings = ();
my %counts  = ();
my @errors  = ();

my $is_ajax = is_ajax();

my $query = ($is_ajax) ? &ajax_auth_cgi( {} ) : CGI->new();

my $biblionumber   = $query->param('biblionumber');
my $value;

foreach ( $query->param ) {
    if (/^rating(.*)/) {
        $value = $query->param($_);
        last;
    }
}

my ( $template, $loggedinuser, $cookie );

if ($is_ajax) {
    $loggedinuser = C4::Context->userenv->{'number'};
    add_rating( $biblionumber, $loggedinuser, $value );
    my $rating = get_rating($biblionumber, $loggedinuser);
    my $js_reply = "{total: $rating->{'total'}, value: $rating->{'value'}}";

    output_ajax_with_http_headers( $query, $js_reply );
    exit;
}

# Future enhancements could have this have its own template to
# display the users' ratings, or tie in with their reading history
# to get them to rate things they read recently.
( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {   template_name   => "opac-user.tmpl",
        query           => $query,
        type            => "opac",
        authnotrequired => 0,                  # auth required to add ratings
        debug           => 0,
    }
);

my $results = [];

( scalar @errors ) and $template->param( ERRORS => \@errors );

output_html_with_http_headers $query, $cookie, $template->output;

sub ajax_auth_cgi ($) {                            # returns CGI object
    my $needed_flags = shift;
    my %cookies      = fetch CGI::Cookie;
    my $input        = CGI->new;
    my $sessid       = $cookies{'CGISESSID'}->value || $input->param('CGISESSID');
    my ( $auth_status, $auth_sessid ) = check_cookie_auth( $sessid, $needed_flags );
    if ( $auth_status ne "ok" ) {
        output_ajax_with_http_headers $input, "window.alert('Your CGI session cookie ($sessid) is not current.  " . "Please refresh the page and try again.');\n";
        exit 0;
    }
    return $input;
}
