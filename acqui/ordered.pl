#!/usr/bin/perl

# Copyright 2008 - 2009 BibLibre SARL
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
my $bookfund = $input->param('fund');
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

my $query =
"Select quantity,datereceived,freight,unitprice,listprice,ecost,quantityreceived
as qrev,subscription,title,itemtype,aqorders.biblionumber,aqorders.booksellerinvoicenumber,
quantity-quantityreceived as tleft,aqorders.ordernumber
as ordnum,entrydate,budgetdate,booksellerid,aqbasket.basketno
from (aqorders,aqorderbreakdown,aqbasket)
left join biblioitems on  biblioitems.biblioitemnumber=aqorders.biblioitemnumber
where bookfundid=? and aqorders.ordernumber=aqorderbreakdown.ordernumber and
aqorders.basketno=aqbasket.basketno and (budgetdate >= ? and budgetdate < ?)
and (datecancellationprinted is NULL or datecancellationprinted='0000-00-00')
  and (quantity > quantityreceived or quantityreceived is NULL)
";
warn $query;
my $sth = $dbh->prepare($query);

$sth->execute( $bookfund, $start, $end );
my @commited_loop;

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
        push @commited_loop, $data;
        $total += $subtotal;
    }
}

$template->param(
    COMMITEDLOOP => \@commited_loop,
    total        => $total
);
$sth->finish;
$dbh->disconnect;

output_html_with_http_headers $input, $cookie, $template->output;
