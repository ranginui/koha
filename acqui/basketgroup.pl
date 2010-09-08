#!/usr/bin/perl

#script to group (closed) baskets into basket groups for easier order management
#written by john.soros@biblibre.com 01/10/2008

# Copyright 2008 - 2009 BibLibre SARL
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

basketgroup.pl

=head1 DESCRIPTION

 This script lets the user group (closed) baskets into basket groups for easier order management. Note that the grouped baskets have to be from the same bookseller and
 have to be closed.

=head1 CGI PARAMETERS

=over 4

=item $booksellerid

The bookseller who we want to display the baskets (and basketgroups) of.

=back

=cut

use strict;
use warnings;

use C4::Input;
use C4::Auth;
use C4::Output;
use CGI;

use C4::Bookseller qw/GetBookSellerFromId/;
use C4::Acquisition qw/CloseBasketgroup ReOpenBasketgroup GetOrders GetBasketsByBasketgroup GetBasketsByBookseller ModBasketgroup NewBasketgroup DelBasketgroup GetBasketgroups ModBasket GetBasketgroup GetBasket/;
use C4::Bookseller qw/GetBookSellerFromId/;
use C4::Branch qw/GetBranches/;
use C4::Members qw/GetMember/;

my $input=new CGI;

my ($template, $loggedinuser, $cookie)
    = get_template_and_user({template_name => "acqui/basketgroup.tmpl",
			     query => $input,
			     type => "intranet",
			     authnotrequired => 0,
			     flagsrequired => {acquisition => 'group_manage'},
			     debug => 1,
                });

sub parseinputbaskets {
    my $booksellerid = shift;
    my $baskets = &GetBasketsByBookseller($booksellerid);
    for(my $i=0; $i < scalar @$baskets; ++$i) {
        if( @$baskets[$i] && ! @$baskets[$i]->{'closedate'} ) {
            splice(@$baskets, $i, 1);
            --$i;
        }
    }
    foreach my $basket (@$baskets){
#perl DBI uses value "undef" for the mysql "NULL" value, so i need to check everywhere where $basket->{'basketgroupid'} is used for undef ☹
        $basket->{'basketgroupid'} = $input->param($basket->{'basketno'}.'-group') || undef;
    }
    return $baskets;
}



sub parseinputbasketgroups {
    my $booksellerid = shift;
    my $baskets = shift;
    my $basketgroups = &GetBasketgroups($booksellerid);
    my $newbasketgroups;
    foreach my $basket (@$baskets){
        my $basketgroup;
        my $i = 0;
        my $exists;
        if(! $basket->{'basketgroupid'} || $basket->{'basketgroupid'} == 0){
            $exists = "true";
        } else {
            foreach my $basketgroup (@$basketgroups){
                if($basket->{'basketgroupid'} == $basketgroup->{'id'}){
                    $exists = "true";
                    push(@{$basketgroup->{'basketlist'}}, $basket->{'basketno'});
                    last;
                }
            }
        }
        if (! $exists){
#if the basketgroup doesn't exist yet
            $basketgroup = $newbasketgroups->{$basket->{'basketgroupid'}} || undef;
            $basketgroup->{'booksellerid'} = $booksellerid;
        } else {
            while($i < scalar @$basketgroups && @$basketgroups[$i]->{'id'} != $basket->{'basketgroupid'}){
                ++$i;
            }
            $basketgroup = @$basketgroups[$i];
        }
        $basketgroup->{'id'}=$basket->{'basketgroupid'};
        $basketgroup->{'name'}=$input->param('basketgroup-'.$basketgroup->{'id'}.'-name') || "";
        $basketgroup->{'closed'}= $input->param('basketgroup-'.$basketgroup->{'id'}.'-closed');
        push(@{$basketgroup->{'basketlist'}}, $basket->{'basketno'});
        if (! $exists){
            $newbasketgroups->{$basket->{'basketgroupid'}} = $basketgroup;
        } else {
            if($basketgroup->{'id'}){
                @$basketgroups[$i] = $basketgroup;
            }
        }
    }
    return($basketgroups, $newbasketgroups);
}

sub BasketTotal {
    my $basketno = shift;
    my $bookseller = shift;
    my $total = 0;
    my @orders = GetOrders($basketno);
    for my $order (@orders){
        $total = $total + ( $order->{ecost} * $order->{quantity} );
        if ($bookseller->{invoiceincgst} && ! $bookseller->{listincgst} && ( $bookseller->{gstrate} // C4::Context->preference("gist") )) {
            my $gst = $bookseller->{gstrate} // C4::Context->preference("gist");
            $total = $total * ( $gst / 100 +1);
        }
    }
    $total .= $bookseller->{invoiceprice};
    return $total;
}

#displays all basketgroups and all closed baskets (in their respective groups)
sub displaybasketgroups {
    my $basketgroups = shift;
    my $bookseller = shift;
    my $baskets = shift;
    if (scalar @$basketgroups != 0) {
        foreach my $basketgroup (@$basketgroups){
            my $i = 0;
            while($i < scalar(@$baskets)){
                my $basket = @$baskets[$i];
                if($basket->{'basketgroupid'} && $basket->{'basketgroupid'} == $basketgroup->{'id'}){
                    $basket->{total} = BasketTotal($basket->{basketno}, $bookseller);
                    push(@{$basketgroup->{'baskets'}}, $basket);
                    splice(@$baskets, $i, 1);
                    --$i;
                }
                ++$i;
            }
        }
        $template->param(basketgroups => $basketgroups);
    }
    for(my $i=0; $i < scalar @$baskets; ++$i) {
        if( ! @$baskets[$i]->{'closedate'} ) {
            splice(@$baskets, $i, 1);
            --$i;
        }else{
            @$baskets[$i]->{total} = BasketTotal(@$baskets[$i]->{basketno}, $bookseller);
        }
    }
    $template->param(baskets => $baskets);
    $template->param( booksellername => $bookseller ->{'name'});
}

sub printbasketgrouppdf{
    my ($basketgroupid) = @_;
    
    my $pdfformat = C4::Context->preference("OrderPdfFormat");
    eval "use $pdfformat" ;
    eval "use C4::Branch";
    
    my $basketgroup = GetBasketgroup($basketgroupid);
    my $bookseller = GetBookSellerFromId($basketgroup->{'booksellerid'});
    my $baskets = GetBasketsByBasketgroup($basketgroupid);
    
    my %orders;
    for my $basket (@$baskets) {
        my @ba_orders;
        my @ords = &GetOrders($basket->{basketno});
        for my $ord (@ords) {
            # ba_order is filled with : 
            # 0      1        2        3         4            5         6       7      8        9
            #isbn, itemtype, author, title, publishercode, quantity, listprice ecost discount gstrate
            my @ba_order;
            if ( $ord->{biblionumber} && $ord->{quantity}> 0 ) {
                eval "use C4::Biblio";
                eval "use C4::Koha";
                my $bib = GetBiblioData($ord->{biblionumber});
                my $itemtypes = GetItemTypes();
                if($ord->{isbn}){
                    push(@ba_order, $ord->{isbn});
                } else {
                    push(@ba_order, undef);
                }
                if ($ord->{itemtype}){
                    push(@ba_order, $itemtypes->{$bib->{itemtype}}->{description}) if $bib->{itemtype};
                } else {
                    push(@ba_order, undef);
                }
#             } else {
#                 push(@ba_order, undef, undef);
                for my $key (qw/author title publishercode quantity listprice ecost/) {
                    push(@ba_order, $ord->{$key});                                                  #Order lines
                }
                push(@ba_order, $bookseller->{discount});
                push(@ba_order, $bookseller->{gstrate}*100 // C4::Context->preference("gist") // 0);
                push(@ba_orders, \@ba_order);
                # Editor Number
                my $en;
                if (C4::Context->preference("marcflavour") eq 'UNIMARC') {
                    $en = MARC::Record::new_from_xml($ord->{marcxml},'UTF-8')->subfield('345',"b");
                } elsif (C4::Context->preference("marcflavour") eq 'MARC21') {
                    $en = MARC::Record::new_from_xml($ord->{marcxml},'UTF-8')->subfield('037',"a");
                }
                if($en){
                    push(@ba_order, $en);
                } else {
                    push(@ba_order, undef);
                }
            }
        }
        $orders{$basket->{basketno}}=\@ba_orders;
    }
    print $input->header(
        -type       => 'application/pdf',
        -attachment => ( $basketgroup->{name} || $basketgroupid ) . '.pdf'
    );
    my $pdf = printpdf($basketgroup, $bookseller, $baskets, \%orders, $bookseller->{gstrate} // C4::Context->preference("gist")) || die "pdf generation failed";
    print $pdf;
    exit;
}

my $op = $input->param('op');
my $booksellerid = $input->param('booksellerid');
$template->param(booksellerid => $booksellerid);

if ( $op eq "add" ) {
    if(! $booksellerid){
        $template->param( ungroupedlist => 1);
        my @booksellers = GetBookSeller('');
       for (my $i=0; $i < scalar @booksellers; $i++) {
            my $baskets = &GetBasketsByBookseller($booksellers[$i]->{id});
            for (my $j=0; $j < scalar @$baskets; $j++) {
                if(! @$baskets[$i]->{closedate} || @$baskets[$i]->{basketgroupid}) {
                    splice(@$baskets, $j, 1);
                    $j--;
                }
            }
            if (scalar @$baskets == 0){
                splice(@booksellers, $i, 1);
                $i--;
            }
        }
    } else {
        my $basketgroupid = $input->param('basketgroupid');
        my $billingplace;
        my $deliveryplace;
        if ( $basketgroupid ) {
            # Get the selected baskets in the basketgroup to display them
            my $selecteds = GetBasketsByBasketgroup($basketgroupid);
            foreach (@{$selecteds}){
                $_->{total} = BasketTotal($_->{basketno}, $_);
            }
            $template->param(basketgroupid => $basketgroupid,
                             selectedbaskets => $selecteds);

            # Get general informations about the basket group to prefill the form
            my $basketgroup = GetBasketgroup($basketgroupid);
            $template->param(
                name            => $basketgroup->{name},
                deliverycomment => $basketgroup->{deliverycomment},
            );
            $billingplace  = $basketgroup->{billingplace};
            $deliveryplace = $basketgroup->{deliveryplace};
        }

        # determine default billing and delivery places depending on librarian homebranch and existing basketgroup data
        my $borrower = GetMember( ( 'borrowernumber' => $loggedinuser ) );
        $billingplace  = $billingplace  || $borrower->{'branchcode'};
        $deliveryplace = $deliveryplace || $borrower->{'branchcode'};
        
        my $branches = GetBranches;
        
        # Build the combobox to select the billing place
        my @billingplaceloop;
        for (sort keys %$branches) {
            my $selected = 1 if $_ eq $billingplace;
            my %row = (
                value      => $_,
                selected   => $selected,
                branchname => $branches->{$_}->{branchname},
            );
            push @billingplaceloop, \%row;
        }
        $template->param( billingplaceloop => \@billingplaceloop );
        
        # Build the combobox to select the delivery place
        my @deliveryplaceloop;
        for (sort keys %$branches) {
            my $selected = 1 if $_ eq $deliveryplace;
            my %row = (
                value      => $_,
                selected   => $selected,
                branchname => $branches->{$_}->{branchname},
            );
            push @deliveryplaceloop, \%row;
        }
        $template->param( deliveryplaceloop => \@deliveryplaceloop );

        $template->param( booksellerid => $booksellerid );
    }
    $template->param(grouping => 1);
    my $basketgroups = &GetBasketgroups($booksellerid);
    my $bookseller = &GetBookSellerFromId($booksellerid);
    my $baskets = &GetBasketsByBookseller($booksellerid);

    displaybasketgroups($basketgroups, $bookseller, $baskets);
} elsif ($op eq 'mod_basket') {
#we want to modify an individual basket's group
  my $basketno=$input->param('basketno');
  my $basketgroupid=$input->param('basketgroupid');
  ModBasket( { basketno => $basketno,
                         basketgroupid => $basketgroupid } );
  print $input->redirect("basket.pl?basketno=" . $basketno);
} elsif ($op eq 'validate') {
    if(! $booksellerid){
        $template->param( booksellererror => 1);
    } else {
        $template->param( booksellerid => $booksellerid );
    }
    my $baskets = parseinputbaskets($booksellerid);
    my ($basketgroups, $newbasketgroups) = parseinputbasketgroups($booksellerid, $baskets);
    foreach my $nbgid (keys %$newbasketgroups){
#javascript just picks an ID that's higher than anything else, the ID might not be correct..chenge it and change all the basket's basketgroupid as well
        my $bgid = NewBasketgroup($newbasketgroups->{$nbgid});
        ${$newbasketgroups->{$nbgid}}->{'id'} = $bgid;
        ${$newbasketgroups->{$nbgid}}->{'oldid'} = $nbgid;
    }
    foreach my $basket (@$baskets){
#if the basket was added to a new basketgroup, first change the groupid to the groupid of the basket in mysql, because it contains the id from javascript otherwise.
        if ( $basket->{'basketgroupid'} && $newbasketgroups->{$basket->{'basketgroupid'}} ){
            $basket->{'basketgroupid'} = ${$newbasketgroups->{$basket->{'basketgroupid'}}}->{'id'};
        }
        ModBasket($basket);
    }
    foreach my $basketgroup (@$basketgroups){
        if(! $basketgroup->{'id'}){
            foreach my $basket (@{$basketgroup->{'baskets'}}){
                if($input->param('basket'.$basket->{'basketno'}.'changed')){
                    ModBasket($basket);
                }
            }
        } elsif ($input->param('basketgroup-'.$basketgroup->{'id'}.'-changed')){
            ModBasketgroup($basketgroup);
        }
    }
    $basketgroups = &GetBasketgroups($booksellerid);
    my $bookseller = &GetBookSellerFromId($booksellerid);
    $baskets = &GetBasketsByBookseller($booksellerid);

    displaybasketgroups($basketgroups, $bookseller, $baskets);
} elsif ( $op eq 'closeandprint') {
    my $basketgroupid = $input->param('basketgroupid');
    
    CloseBasketgroup($basketgroupid);
    
    printbasketgrouppdf($basketgroupid);
}elsif ($op eq 'print'){
    my $basketgroupid = $input->param('basketgroupid');
    
    printbasketgrouppdf($basketgroupid);
}elsif( $op eq "delete"){
    my $basketgroupid = $input->param('basketgroupid');
    DelBasketgroup($basketgroupid);
    print $input->redirect('/cgi-bin/koha/acqui/basketgroup.pl?booksellerid=' . $booksellerid);
    
}elsif ( $op eq 'reopen'){
    my $basketgroupid   = $input->param('basketgroupid');
    my $booksellerid    = $input->param('booksellerid');
    
    ReOpenBasketgroup($basketgroupid);
        
    print $input->redirect('/cgi-bin/koha/acqui/basketgroup.pl?booksellerid=' . $booksellerid . '#closed');
    
} elsif ( $op eq 'attachbasket') {
    
    # Getting parameters
    my $basketgroup = {};
    my @baskets         = $input->param('basket');
    my $basketgroupid   = $input->param('basketgroupid');
    my $basketgroupname = $input->param('basketgroupname');
    my $booksellerid    = $input->param('booksellerid');
    my $billingplace    = $input->param('billingplace');
    my $deliveryplace   = $input->param('deliveryplace');
    my $deliverycomment = $input->param('deliverycomment');
    my $close           = $input->param('close') ? 1 : 0;
    # If we got a basketgroupname, we create a basketgroup
    if ($basketgroupid) {
        $basketgroup = {
              name            => $basketgroupname,
              id              => $basketgroupid,
              basketlist      => \@baskets,
              billingplace    => $billingplace,
              deliveryplace   => $deliveryplace,
              deliverycomment => $deliverycomment,
              closed          => $close,
        };
        ModBasketgroup($basketgroup);
        if($close){
            
        }
    }else{
        $basketgroup = {
            name            => $basketgroupname,
            booksellerid    => $booksellerid,
            basketlist      => \@baskets,
            deliveryplace   => $deliveryplace,
            deliverycomment => $deliverycomment,
            closed          => $close,
        };
        $basketgroupid = NewBasketgroup($basketgroup);
    }
   
    my $url = '/cgi-bin/koha/acqui/basketgroup.pl?booksellerid=' . $booksellerid;
    $url .= "&closed=1" if ($input->param("closed")); 
    print $input->redirect($url);
    
}else{
    my $basketgroups = &GetBasketgroups($booksellerid);
    my $bookseller = &GetBookSellerFromId($booksellerid);
    my $baskets = &GetBasketsByBookseller($booksellerid);

    displaybasketgroups($basketgroups, $bookseller, $baskets);
}
$template->param(closed => $input->param("closed"));
#prolly won't use all these, maybe just use print, the rest can be done inside validate
output_html_with_http_headers $input, $cookie, $template->output;
