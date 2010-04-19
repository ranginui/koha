#!/usr/bin/perl

# script to show a breakdown of committed and spent budgets

# needs to be templated at some point

use C4::Context;
use C4::Auth;
use C4::Interface::CGI::Output;
use strict;
use CGI;

my $dbh      = C4::Context->dbh;
my $input    = new CGI;
my $bookfund = $input->param('bookfund');
my $start    = $input->param('start');
my $end      = $input->param('end');

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "acqui/spent.tmpl",
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
    quantity-quantityreceived as tleft,
    aqorders.ordernumber
    as ordnum,entrydate,budgetdate,booksellerid,aqbasket.basketno
    from (aqorders,aqorderbreakdown,aqbasket)
    left join biblioitems on  biblioitems.biblioitemnumber=aqorders.biblioitemnumber 
    where bookfundid=? and
    aqorders.ordernumber=aqorderbreakdown.ordernumber and
    aqorders.basketno=aqbasket.basketno
   and (
        (datereceived >= ? and datereceived < ?))
    and (datecancellationprinted is NULL or
           datecancellationprinted='0000-00-00')


  ";
my $sth = $dbh->prepare($query);
$sth->execute( $bookfund, $start, $end );

my $total = 0;
my $toggle;
my @spent_loop;
while ( my $data = $sth->fetchrow_hashref ) {
    my $recv = $data->{'qrev'};
    if ( $recv > 0 ) {
        my $subtotal = $recv * $data->{'unitprice'};
        $data->{'subtotal'}  =   sprintf ("%.2f",  $subtotal); 
        $data->{'unitprice'} =   sprintf ("%.2f",   $data->{'unitprice'}  ); 
        $total               += $subtotal;

        $total =   sprintf ("%.2f",  $total); 

        if ($toggle) {
            $toggle = 0;
        }
        else {
            $toggle = 1;
        }
        $data->{'toggle'} = $toggle;
        push @spent_loop, $data;
    }

}

$template->param(
    SPENTLOOP => \@spent_loop,
    total     => $total
);
$sth->finish;

$dbh->disconnect;
output_html_with_http_headers $input, $cookie, $template->output;
