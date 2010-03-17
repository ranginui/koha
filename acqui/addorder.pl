#!/usr/bin/perl

#script to add an order into the system
#written 29/2/00 by chris@katipo.co.nz

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

addorder.pl

=head1 DESCRIPTION

this script allows to add an order.
It is called by :

=item neworderbiblio.pl to add an order from nothing.

=item neworderempty.pl to add an order from an existing biblio.

=item newordersuggestion.pl to add an order from an existing suggestion.

=head1 CGI PARAMETERS

All of the cgi parameters below are related to the new order.

=over 4

=item C<ordernumber>
the number of this new order.

=item C<basketno>
the number of this new basket

=item C<booksellerid>
the bookseller the librarian has to pay.

=item C<existing>

=item C<title>
the title of the record ordered.

=item C<author>
the author of the record ordered.

=item C<copyrightdate>
the copyrightdate of the record ordered.

=item C<ISBN>
the ISBN of the record ordered.

=item C<format>

=item C<quantity>
the quantity to order.

=item C<list_price>
the price of this order.

=item C<uncertainprice>
uncertain price, can't close basket until prices of all orders are known.

=item C<branch>
the branch where this order will be received.

=item C<series>

=item C<notes>
Notes on this basket.

=item C<budget_id>
budget_id used to pay this order.

=item C<sort1> & C<sort2>

=item C<rrp>

=item C<ecost>

=item C<GST>

=item C<budget>

=item C<cost>

=item C<sub>

=item C<invoice>
the number of the invoice for this order.

=item C<publishercode>

=item C<suggestionid>
if it is an order from an existing suggestion : the id of this suggestion.

=item C<donation>

=back

=cut

use strict;
use warnings;
use CGI;
use C4::Auth;			# get_template_and_user
use C4::Acquisition;	# NewOrder DelOrder ModOrder
use C4::Suggestions;	# ModStatus
use C4::Biblio;			# AddBiblio TransformKohaToMarc
use C4::Items;
use C4::Output;

### "-------------------- addorder.pl ----------"

# FIXME: This needs to do actual error checking and possibly return user to the same form,
# not just blindly call C4 functions and print a redirect.  

my $input = new CGI;
### $input 

# get_template_and_user used only to check auth & get user id
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "acqui/booksellers.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { acquisition => 'order_manage' },
        debug           => 1,
    }
);

# get CGI parameters
my $orderinfo					= $input->Vars;
$orderinfo->{'list_price'}    ||=  0;
#my $ordernumber        = $input->param('ordernumber');
#my $basketno      = $input->param('basketno');
#my $booksellerid  = $input->param('booksellerid');
#my $existing      = $input->param('existing');    # existing biblio, (not basket or order)
#my $title         = $input->param('title');
#my $author        = $input->param('author');
#my $publicationyear= $input->param('publicationyear');
#my $isbn          = $input->param('ISBN');
#my $itemtype      = $input->param('format');
#my $quantity      = $input->param('quantity');		# FIXME: else ERROR!
#my $branch        = $input->param('branch');
#my $series        = $input->param('series');
#my $notes         = $input->param('notes');
#my $budget_id     = $input->param('budget_id');
#my $sort1         = $input->param('sort1');
#my $sort2         = $input->param('sort2');
#my $rrp           = $input->param('rrp');
#my $ecost         = $input->param('ecost');
#my $gst           = $input->param('GST');
#my $budget        = $input->param('budget');
#my $cost          = $input->param('cost');
#my $sub           = $input->param('sub');
#my $purchaseorder = $input->param('purchaseordernumber');
#my $invoice       = $input->param('invoice');
#my $publishercode = $input->param('publishercode');
#my $suggestionid  = $input->param('suggestionid');
#my $biblionumber  = $input->param('biblionumber');
#my $uncertainprice = $input->param('uncertainprice');
#my $import_batch_id= $input->param('import_batch_id');
#
#my $createbibitem = $input->param('createbibitem');
#
my $user          = $input->remote_user;
# create, modify or delete biblio
# create if $quantity>=0 and $existing='no'
# modify if $quantity>=0 and $existing='yes'
# delete if $quantity has been set to 0 by the librarian
my $bibitemnum;
if ( $orderinfo->{quantity} ne '0' ) {
    #TODO:check to see if biblio exists
    unless ( $$orderinfo{biblionumber} ) {

        #if it doesnt create it
        my $record = TransformKohaToMarc(
            {
                "biblio.title"                => "$$orderinfo{title}",
                "biblio.author"               => "$$orderinfo{author}",
                "biblio.series"               => $$orderinfo{series}          ? $$orderinfo{series}        : "",
                "biblioitems.isbn"            => $$orderinfo{isbn}            ? $$orderinfo{isbn}          : "",
                "biblioitems.publishercode"   => $$orderinfo{publishercode}   ? $$orderinfo{publishercode} : "",
                "biblioitems.publicationyear" => $$orderinfo{publicationyear} ? $$orderinfo{publicationyear}: "",
            });
        # create the record in catalogue, with framework ''
        my ($biblionumber,$bibitemnum) = AddBiblio($record,'');
        # change suggestion status if applicable
        if ($$orderinfo{suggestionid}) {
            ModSuggestion( {suggestionid=>$$orderinfo{suggestionid}, status=>'ORDERED', biblionumber=>$biblionumber} );
        }
		$orderinfo->{biblioitemnumber}=$bibitemnum;
		$orderinfo->{biblionumber}=$biblionumber;
    }

    # if we already have $ordernumber, then it's an ordermodif
    if ($$orderinfo{ordernumber}) {
        ModOrder( $orderinfo);
    }
    else { # else, it's a new line
        @$orderinfo{qw(basketno ordernumber )} = NewOrder($orderinfo);
    }

    # now, add items if applicable
    if (C4::Context->preference('AcqCreateItem') eq 'ordering') {

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
                                    $itemhash{$item}->{'indicator'},
                                    'ITEM');
            my $record=MARC::Record::new_from_xml($xml, 'UTF-8');
            my ($biblionumber,$bibitemnum,$itemnumber) = AddItemFromMarc($record,$$orderinfo{biblionumber});
            NewOrderItem($itemnumber, $$orderinfo{ordernumber});

        }
    }

}

else { # qty=0, delete the line
    my $biblionumber = $input->param('biblionumber');
    DelOrder( $biblionumber, $$orderinfo{ordernumber} );
}
my $basketno=$$orderinfo{basketno};
my $booksellerid=$$orderinfo{booksellerid};
if (my $import_batch_id=$$orderinfo{import_batch_id}) {
    print $input->redirect("/cgi-bin/koha/acqui/addorderiso2709.pl?import_batch_id=$import_batch_id&basketno=$basketno&booksellerid=$booksellerid");
} else {
    print $input->redirect("/cgi-bin/koha/acqui/basket.pl?basketno=$basketno");
}
