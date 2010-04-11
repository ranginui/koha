#!/usr/bin/perl

#script to add a new item and to mark orders as received
#written 1/3/00 by chris@katipo.co.nz

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
use C4::Auth;
use C4::Output;
use C4::Context;
use C4::Acquisition;
use C4::Biblio;
use C4::Items;
use C4::Search;
use List::MoreUtils qw/any/;

my $input=new CGI;
my $flagsrequired = {acquisition => 'order_receive'};
my ($loggedinuser, $cookie, $sessionID) = checkauth($input, 0, $flagsrequired, 'intranet');
my $user=$input->remote_user;
my $biblionumber = $input->param('biblionumber');
my $biblioitemnumber=$input->param('biblioitemnumber');
my $ordernumber=$input->param('ordernumber');
my $origquantityrec=$input->param('origquantityrec');
my $quantityrec=$input->param('quantityrec');
my $quantity=$input->param('quantity');
my $unitprice=$input->param('cost');
my $invoiceno=$input->param('invoice');
my $datereceived=$input->param('datereceived');
my $replacement=$input->param('rrp');
my $gst=$input->param('gst');
my $freight=$input->param('freight');
my $supplierid = $input->param('supplierid');
my $cnt=0;
my $error_url_str;
my $ecost = $input->param('ecost');
my $note = $input->param("note");

my %tplorder = ( 'quantity'                  =>     $input->param('quantity') || '',
                             'quantityreceived'   =>     $input->param('quantityrec') || '',
                             'notes'                      =>      $input->param("note") || '',
                             'rrp'                          =>      $input->param('rrp') || '',
                             'ecost'                      =>      $input->param('ecost') || '',
                             'unitprice'                =>      $input->param('cost') || '',
                     );
my $order = GetOrder($ordernumber);
if ( any { $order->{$_} ne $tplorder{$_} } qw(quantity quantityreceived notes rrp ecost unitprice) ) {
    $order->{quantity} = $tplorder{quantity} if $tplorder{quantity};
    $order->{quantityreceived} = $tplorder{quantityreceived} if $tplorder{quantityreceived};
    $order->{notes} = $tplorder{notes} if $tplorder{notes};
    $order->{rrp} = $tplorder{rrp} if $tplorder{rrp};
    $order->{ecost} = $tplorder{ecost} if $tplorder{ecost};
    $order->{unitprice} = $tplorder{unitprice} if $tplorder{unitprice};
    ModOrder($order);
}

#need old recievedate if we update the order, parcel.pl only shows the right parcel this way FIXME
if ($quantityrec > $origquantityrec ) {
    # now, add items if applicable
    if (C4::Context->preference('AcqCreateItem') eq 'receiving') {
        my @tags         = $input->param('tag');
        my @subfields    = $input->param('subfield');
        my @field_values = $input->param('field_value');
        my @serials      = $input->param('serial');
        my @itemid       = $input->param('itemid');
        my @ind_tag      = $input->param('ind_tag');
        my @indicator    = $input->param('indicator');
        #Rebuilding ALL the data for items into a hash
        # parting them on $itemid.
        my %itemhash;
        my $countdistinct;
        my $range=scalar(@itemid);
        for (my $i=0; $i<$range; $i++){
            unless ($itemhash{$itemid[$i]}){
            $countdistinct++;
            }
            push @{$itemhash{$itemid[$i]}->{'tags'}},$tags[$i];
            push @{$itemhash{$itemid[$i]}->{'subfields'}},$subfields[$i];
            push @{$itemhash{$itemid[$i]}->{'field_values'}},$field_values[$i];
            push @{$itemhash{$itemid[$i]}->{'ind_tag'}},$ind_tag[$i];
            push @{$itemhash{$itemid[$i]}->{'indicator'}},$indicator[$i];
        }
        foreach my $item (keys %itemhash){
            my $xml = TransformHtmlToXml( $itemhash{$item}->{'tags'},
                                    $itemhash{$item}->{'subfields'},
                                    $itemhash{$item}->{'field_values'},
                                    $itemhash{$item}->{'ind_tag'},
                                    $itemhash{$item}->{'indicator'},'ITEM');
            my $record=MARC::Record::new_from_xml($xml, 'UTF-8');
            my ($biblionumber,$bibitemnum,$itemnumber) = AddItemFromMarc($record,$biblionumber);
        }
    }
    
    # save the quantity received.
	if( $quantityrec > 0 ) {
    	$datereceived = ModReceiveOrder($biblionumber,$ordernumber, $quantityrec ,$user,$unitprice,$invoiceno,$freight,$replacement,undef,$datereceived);
	}
}
    print $input->redirect("/cgi-bin/koha/acqui/parcel.pl?invoice=$invoiceno&supplierid=$supplierid&freight=$freight&gst=$gst&datereceived=$datereceived$error_url_str");
