#!/usr/bin/perl

#script to show display basket of orders

# Copyright 2000 - 2004 Katipo
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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA

use strict;
use warnings;
use C4::Auth;
use C4::Koha;
use C4::Output;
use CGI;
use C4::Acquisition;
use C4::Budgets;

use C4::Bookseller;
use C4::Dates qw/format_date/;
use C4::Debug;

use C4::Members qw/GetMember/;  #needed for permissions checking for changing basketgroup of a basket
=head1 NAME

basket.pl

=head1 DESCRIPTION

 This script display all informations about basket for the supplier given
 on input arg.  Moreover, it allows us to add a new order for this supplier from
 an existing record, a suggestion or a new record.

=head1 CGI PARAMETERS

=over 4

=item $basketno

The basket number.

=item supplierid

the supplier this script have to display the basket.

=item order

=back

=cut

my $query        = new CGI;
my $basketno     = $query->param('basketno');
my $booksellerid = $query->param('supplierid');

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "acqui/basket.tmpl",
        query           => $query,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { acquisition => 'order_manage' },
        debug           => 1,
    }
);

my $basket = GetBasket($basketno);

# FIXME : what about the "discount" percentage?
# FIXME : the query->param('supplierid') below is probably useless. The bookseller is always known from the basket
# if no booksellerid in parameter, get it from basket
# warn "=>".$basket->{booksellerid};
$booksellerid = $basket->{booksellerid} unless $booksellerid;
my ($bookseller) = GetBookSellerFromId($booksellerid);
my $op = $query->param('op');

if ( $op eq 'delete_confirm' ) {
    my $basketno = $query->param('basketno');
    DelBasket($basketno);
    $template->param( delete_confirmed => 1 );
} elsif ( !$bookseller ) {
    $template->param( NO_BOOKSELLER => 1 );
} elsif ( $op eq 'del_basket') {
    $template->param( delete_confirm => 1 );
    if ( C4::Context->preference("IndependantBranches") ) {
        my $userenv = C4::Context->userenv;
        unless ( $userenv->{flags} == 1 ) {
            my $validtest = ( $basket->{creationdate} eq '' )
              || ( $userenv->{branch} eq $basket->{branch} )
              || ( $userenv->{branch} eq '' )
              || ( $basket->{branch}  eq '' );
            unless ($validtest) {
                print $query->redirect("../mainpage.pl");
                exit 1;
            }
        }
    }
    $basket->{creationdate} = ""            unless ( $basket->{creationdate} );
    $basket->{authorisedby} = $loggedinuser unless ( $basket->{authorisedby} );
    my $contract = &GetContract($basket->{contractnumber});
    my $count = scalar GetOrders( $basketno);
    $template->param(
        basketno             => $basketno,
        basketname           => $basket->{'basketname'},
        basketnote           => $basket->{note},
        basketbooksellernote => $basket->{booksellernote},
        basketcontractno     => $basket->{contractnumber},
        basketcontractname   => $contract->{contractname},
        creationdate         => format_date( $basket->{creationdate} ),
        authorisedby         => $basket->{authorisedby},
        authorisedbyname     => $basket->{authorisedbyname},
        closedate            => format_date( $basket->{closedate} ),
        active               => $bookseller->{'active'},
        booksellerid         => $bookseller->{'id'},
        name                 => $bookseller->{'name'},
        address1             => $bookseller->{'address1'},
        address2             => $bookseller->{'address2'},
        address3             => $bookseller->{'address3'},
        address4             => $bookseller->{'address4'},
        count               =>     $count,
      );
} elsif ($op eq 'attachbasket' && $template->{'param_map'}->{'CAN_user_acquisition_group_manage'} == 1) {
      print $query->redirect('/cgi-bin/koha/acqui/basketgroup.pl?basketno=' . $basket->{'basketno'} . '&op=attachbasket&booksellerid=' . $booksellerid);
    # check if we have to "close" a basket before building page
} elsif ($op eq 'export') {
    print $query->header(
        -type       => 'text/csv',
        -attachment => 'basket' . $basket->{'basketno'} . '.csv',
    );
    print GetBasketAsCSV($query->param('basketno'));
    exit;
} elsif ($op eq 'close') {
    my $confirm = $query->param('confirm');
    if ($confirm) {
        my $basketno = $query->param('basketno');
        my $booksellerid = $query->param('booksellerid');
        $basketno =~ /^\d+$/ and CloseBasket($basketno);
        # if requested, create basket group, close it and attach the basket
        if ($query->param('createbasketgroup')) {
            my $basketgroupid = NewBasketgroup( { name => $basket->{basketname},
                            booksellerid => $booksellerid,
                            closed => 1,
                            });
            ModBasket( { basketno => $basketno,
                         basketgroupid => $basketgroupid } );
            print $query->redirect('/cgi-bin/koha/acqui/basketgroup.pl?booksellerid='.$booksellerid);
        } else {
            print $query->redirect('/cgi-bin/koha/acqui/basketgroup.pl?basketno='.$basketno.'&amp;op=attachbasket&amp;booksellerid=' . $booksellerid);
        }
        exit;
    } else {
    $template->param(confirm_close => "1",
            booksellerid    => $booksellerid,
            basketno        => $basket->{'basketno'},
                basketname      => $basket->{'basketname'},
            basketgroupname => $basket->{'basketname'});
        
    }
} elsif ($query->param('op') eq 'reopen') {
    my $basket;
    $basket->{basketno} = $query->param('basketno');
    $basket->{closedate} = undef;
    ModBasket($basket);
    print $query->redirect('/cgi-bin/koha/acqui/basket.pl?basketno='.$basket->{'basketno'})
} else {
    # get librarian branch...
    if ( C4::Context->preference("IndependantBranches") ) {
        my $userenv = C4::Context->userenv;
        unless ( $userenv->{flags} == 1 ) {
            my $validtest = ( $basket->{creationdate} eq '' )
              || ( $userenv->{branch} eq $basket->{branch} )
              || ( $userenv->{branch} eq '' )
              || ( $basket->{branch}  eq '' );
            unless ($validtest) {
                print $query->redirect("../mainpage.pl");
                exit 1;
            }
        }
    }
#if the basket is closed,and the user has the permission to edit basketgroups, display a list of basketgroups
    my $basketgroups;
    my $member = GetMember($loggedinuser, "borrowernumber");
    if ($basket->{closedate} && haspermission({ flagsrequired   => { acquisition => 'group_manage'} })) {
        $basketgroups = GetBasketgroups($basket->{booksellerid});
        for (my $i=0; $i < scalar(@$basketgroups); $i++) {
            if ($basket->{basketgroupid} == @$basketgroups[$i]->{id}){
                @$basketgroups[$i]->{default} = 1;
            }
        }
        my %emptygroup = ( id   =>   undef,
                           name =>   "No group");
        if ( ! $basket->{basketgroupid} ) {
            $emptygroup{default} = 1;
        }
        unshift( @$basketgroups, \%emptygroup );
    }
    # if new basket, pre-fill infos
    $basket->{creationdate} = ""            unless ( $basket->{creationdate} );
    $basket->{authorisedby} = $loggedinuser unless ( $basket->{authorisedby} );
    $debug
      and warn sprintf
      "loggedinuser: $loggedinuser; creationdate: %s; authorisedby: %s",
      $basket->{creationdate}, $basket->{authorisedby};

    my @results = GetOrders( $basketno );
    my $count = scalar @results;
    
	my $gist = $bookseller->{gstrate} || C4::Context->preference("gist") || 0;
	my $discount = $bookseller->{'discount'} / 100;
    my $total_rrp;      # RRP Total, its value will be assigned to $total_rrp_gsti or $total_rrp_gste depending of $bookseller->{'listincgst'}
	my $total_rrp_gsti; # RRP Total, GST included
	my $total_rrp_gste; # RRP Total, GST excluded
	my $gist_rrp;
	
    my $qty_total;
    my @books_loop;

    for ( my $i = 0 ; $i < $count ; $i++ ) {
        my $rrp = $results[$i]->{'listprice'};
		my $qty = $results[$i]->{'quantity'} || 0;

        my $budget = GetBudget(  $results[$i]->{'budget_id'} );
        $rrp = ConvertCurrency( $results[$i]->{'currency'}, $rrp );

        $total_rrp += $qty * $results[$i]->{'rrp'};
        my $line_total = $qty * $results[$i]->{'ecost'};
		# FIXME: what about the "actual cost" field?
        $qty_total += $qty;
        my %line = %{ $results[$i] };
		($i%2) and $line{toggle} = 1;

        $line{order_received} = ( $qty eq $results[$i]->{'quantityreceived'} );
        $line{basketno}       = $basketno;
        $line{i}              = $i;
        $line{budget_name}    = $budget->{budget_name};
        $line{rrp}            = sprintf( "%.2f", $line{'rrp'} );
        $line{ecost}          = sprintf( "%.2f", $line{'ecost'} );
        $line{line_total}     = sprintf( "%.2f", $line_total );
        $line{odd}            = $i % 2;
        if ($line{uncertainprice}) {
            $template->param( unclosable => 1 );
            for my $key (qw/ecost line_total rrp/) {
                $line{$key} .= '??';
            }
        }
	if ($line{'title'}){
	    my $volume = $results[$i]->{'volume'};
	    my $seriestitle = $results[$i]->{'seriestitle'};
	    $line{'title'} .= " / $seriestitle" if $seriestitle;
	    $line{'title'} .= " / $volume" if $volume;
	} else {
	    $line{'title'} = "Deleted bibliographic notice, can't find title.";
	}
        push @books_loop, \%line;
    }

	if ($bookseller->{'listincgst'}) {                        # if prices already includes GST
		$total_rrp_gsti = $total_rrp;                         # we know $total_rrp_gsti
		$total_rrp_gste = $total_rrp_gsti / ($gist + 1);      # and can reverse compute other values
		$gist_rrp       = $total_rrp_gsti - $total_rrp_gste;  #
	} else {                                                  # if prices does not include GST
		$total_rrp_gste = $total_rrp;                         # then we use the common way to compute other values
		$gist_rrp = $total_rrp_gste * $gist;                  #
		$total_rrp_gsti = $total_rrp_gste + $gist_rrp;        #
	}
	# These vars are estimated totals and GST, taking in account the booksellet discount
	my $total_est_gsti = $total_rrp_gsti - ($total_rrp_gsti * $discount);
	my $gist_est       = $gist_rrp       - ($gist_rrp * $discount);
	my $total_est_gste = $total_rrp_gste - ($total_rrp_gste * $discount);

    my $contract = &GetContract($basket->{contractnumber});
    $template->param(
        basketno             => $basketno,
        basketname           => $basket->{'basketname'},
        basketnote           => $basket->{note},
        basketbooksellernote => $basket->{booksellernote},
        basketcontractno     => $basket->{contractnumber},
        basketcontractname   => $contract->{contractname},
        creationdate         => C4::Dates->new($basket->{creationdate},'iso')->output,
        authorisedby         => $basket->{authorisedby},
        authorisedbyname     => $basket->{authorisedbyname},
        closedate            => C4::Dates->new($basket->{closedate},'iso')->output,
        active               => $bookseller->{'active'},
        booksellerid         => $bookseller->{'id'},
        name                 => $bookseller->{'name'},
        entrydate            => C4::Dates->new($results[0]->{'entrydate'},'iso')->output,
        books_loop           => \@books_loop,
        count                => $count,
        gist_rate            => sprintf( "%.2f", $gist * 100 ) . '%',
        total_rrp_gste       => sprintf( "%.2f", $total_rrp_gste ),
        total_est_gste       => sprintf( "%.2f", $total_est_gste ),
        gist_est             => sprintf( "%.2f", $gist_est ),
        gist_rrp             => sprintf( "%.2f", $gist_rrp ),        
        total_rrp_gsti       => sprintf( "%.2f", $total_rrp_gsti ),
        total_est_gsti       => sprintf( "%.2f", $total_est_gsti ),
        currency             => $bookseller->{'listprice'},
        qty_total            => $qty_total,
        GST                  => $gist,
        basketgroups         => $basketgroups,
        grouped              => $basket->{basketgroupid},
    );
}

output_html_with_http_headers $query, $cookie, $template->output;
