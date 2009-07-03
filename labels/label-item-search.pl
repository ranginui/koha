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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA

use strict;
use warnings;

use CGI;
use C4::Auth;
use HTML::Template::Pro;
use C4::Context;
use C4::Search;
use C4::Auth;
use C4::Output;
use C4::Biblio;
use C4::Items;
use C4::Acquisition;
use C4::Search;
use C4::Dates;
use C4::Koha;    # XXX subfield_is_koha_internal_p
use C4::Debug;
use List::Util qw( max min );
use POSIX;

#use Smart::Comments;
#use Data::Dumper;

BEGIN {
    $debug = $debug || $cgi_debug;
    if ($debug) {
        require Data::Dumper;
        import Data::Dumper qw(Dumper);
    }
}

# Creates a scrolling list with the associated default value.
# Using more than one scrolling list in a CGI assigns the same default value to all the
# scrolling lists on the page !?!? That's why this function was written.

my $query = new CGI;

my $type      = $query->param('type');
my $op        = $query->param('op') || '';
my $batch_id  = $query->param('batch_id');
my $ccl_query = $query->param('ccl_query');

my $dbh = C4::Context->dbh;

my $startfrom = $query->param('startfrom') || 1;
my ( $template, $loggedinuser, $cookie );
my (
    $total_hits,  $orderby, $results,  $total,  $error,
    $marcresults, $idx,     $datefrom, $dateto, $ccl_textbox
);

my $resultsperpage = C4::Context->preference('numSearchResults') || '20';

my $show_results = 0;

if ( $op eq "do_search" ) {
    $idx         = $query->param('idx');
    $ccl_textbox = $query->param('ccl_textbox');
    if ( $ccl_textbox && $idx ) {
        $ccl_query = "$idx=$ccl_textbox";
    }

    $datefrom = $query->param('datefrom');
    $dateto   = $query->param('dateto');

    ( $template, $loggedinuser, $cookie ) = get_template_and_user(
        {
            template_name   => "labels/search.tmpl",
            query           => $query,
            type            => "intranet",
            authnotrequired => 0,
            flagsrequired   => { catalogue => 1 },
            debug           => 1,
        }
    );

    if ($datefrom) {
        $datefrom = C4::Dates->new($datefrom);
        $ccl_query .= ' and ' if $ccl_textbox;
        $ccl_query .=
          "acqdate,st-date-normalized,ge=" . $datefrom->output("iso");
    }

    if ($dateto) {
        $dateto = C4::Dates->new($dateto);
        $ccl_query .= ' and ' if ( $ccl_textbox || $datefrom );
        $ccl_query .= "acqdate,st-date-normalized,le=" . $dateto->output("iso");
    }

    my $offset = $startfrom > 1 ? $startfrom - 1 : 0;
    ( $error, $marcresults, $total_hits ) =
      SimpleSearch( $ccl_query, $offset, $resultsperpage );

    if ($marcresults) {
        $show_results = scalar @$marcresults;
    }
    else {
        $debug and warn "ERROR label-item-search: no results from SimpleSearch";

        # leave $show_results undef
    }
}

# Print the page
$template->param( DHTMLcalendar_dateformat => C4::Dates->DHTMLcalendar(), );
output_html_with_http_headers $query, $cookie, $template->output;
