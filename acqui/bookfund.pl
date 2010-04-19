#!/usr/bin/perl -w

use C4::Context;
use strict;
use CGI;
use C4::Auth;
use C4::Interface::CGI::Output;

my $dbh      = C4::Context->dbh;
my $input    = new CGI;
my $bookfund = $input->param('bookfund');
my $start    = $input->param('start');
my $end      = $input->param('end');

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "acqui/bookfund.tmpl",
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
