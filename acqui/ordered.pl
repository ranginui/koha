#!/usr/bin/perl

# Copyright 2008 - 2009 BibLibre SARL
# Copyright 2010 Catalyst IT Limited
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

committed.pl
  
=head1 DESCRIPTION

this script is to show orders ordered but not yet received
  
=cut


use C4::Context;
use strict;
use warnings;
use CGI;
use C4::Auth;
use C4::Output;

my $dbh      = C4::Context->dbh;
my $input    = new CGI;
my $fund_id = $input->param('fund');
my $start    = $input->param('start');
my $end      = $input->param('end');

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "acqui/ordered.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { acquisition => 1 },
        debug           => 1,
    }
);

my $query = <<EOQ;
SELECT
    aqorders.basketno, aqorders.ordernumber, 
    quantity-quantityreceived AS tleft,
    ecost, budgetdate,
    aqbasket.booksellerid,
    itype,
    title
FROM (aqorders, aqbasket)
LEFT JOIN items ON
    items.biblioitemnumber=aqorders.biblioitemnumber
LEFT JOIN biblio ON
    biblio.biblionumber=aqorders.biblionumber
LEFT JOIN aqorders_items ON
    aqorders.ordernumber=aqorders_items.ordernumber
WHERE 
    aqorders.basketno=aqbasket.basketno AND
    budget_id=? AND
    (budgetdate >= ? AND budgetdate < ?) AND
    (datecancellationprinted IS NULL OR 
        datecancellationprinted='0000-00-00') AND
    (quantity > quantityreceived OR quantityreceived IS NULL)
EOQ

my $sth = $dbh->prepare($query);

$sth->execute( $fund_id, $start, $end );
if ($sth->err) {
    die "Error occurred fetching records: ".$sth->errstr;
}
my @ordered;

my $total = 0;
while ( my $data = $sth->fetchrow_hashref ) {
    my $left = $data->{'tleft'};
    if ( !$left || $left eq '' ) {
        $left = $data->{'quantity'};
    }
    if ( $left && $left > 0 ) {
        my $subtotal = $left * $data->{'ecost'};
        $data->{subtotal} =  sprintf ("%.2f",  $subtotal);
        $data->{'left'} = $left;
        push @ordered, $data;
        $total += $subtotal;
    }
}
$total =   sprintf ("%.2f",  $total);
$template->param(
    ordered     => \@ordered,
    total       => $total
);
$sth->finish;
$dbh->disconnect;

output_html_with_http_headers $input, $cookie, $template->output;
