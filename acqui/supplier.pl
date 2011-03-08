#!/usr/bin/perl

# Copyright 2000-2002 Katipo Communications
# Copyright 2008-2009 BibLibre SARL
# Copyright 2010 PTFS Europe Ltd
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

supplier.pl

=head1 DESCRIPTION

this script shows the details for a bookseller given on input arg.
It allows to edit & save information about this bookseller.

=head1 CGI PARAMETERS

=over 4

=item supplierid

To know the bookseller this script has to display details.

=back

=cut

use strict;
use warnings;
use C4::Auth;
use C4::Contract qw/GetContract/;
use C4::Biblio;
use C4::Output;
use C4::Dates qw/format_date /;
use CGI;

use C4::Bookseller;
use C4::Budgets;

my $query    = CGI->new;
my $id       = $query->param('supplierid');
my $supplier = {};
if ($id) {
    $supplier = GetBookSellerFromId($id);
}
my $op = $query->param('op') || 'display';
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {   template_name   => 'acqui/supplier.tmpl',
        query           => $query,
        type            => 'intranet',
        authnotrequired => 0,
        flagsrequired   => { acquisition => 'vendors_manage' },
        debug           => 1,
    }
);
my $seller_gstrate = $supplier->{'gstrate'};

# ensure the scalar isn't flagged as a string
$seller_gstrate = ( defined $seller_gstrate ) ? $seller_gstrate + 0 : undef;
my $tax_rate = $seller_gstrate // C4::Context->preference('gist') // 0;
$tax_rate *= 100;
#build array for currencies
if ( $op eq 'display' ) {

    my $contracts = GetContract( { booksellerid => $id } );

    for ( @{$contracts} ) {
        $_->{contractstartdate} = format_date( $_->{contractstartdate} );
        $_->{contractenddate}   = format_date( $_->{contractenddate} );
    }

    $template->param(
        id            => $id,
        name          => $supplier->{'name'},
        postal        => $supplier->{'postal'},
        address1      => $supplier->{'address1'},
        address2      => $supplier->{'address2'},
        address3      => $supplier->{'address3'},
        address4      => $supplier->{'address4'},
        phone         => $supplier->{'phone'},
        fax           => $supplier->{'fax'},
        url           => $supplier->{'url'},
        contact       => $supplier->{'contact'},
        contpos       => $supplier->{'contpos'},
        contphone     => $supplier->{'contphone'},
        contaltphone  => $supplier->{'contaltphone'},
        contfax       => $supplier->{'contfax'},
        contemail     => $supplier->{'contemail'},
        contnotes     => $supplier->{'contnotes'},
        notes         => $supplier->{'notes'},
        active        => $supplier->{'active'},
        gstreg        => $supplier->{'gstreg'},
        listincgst    => $supplier->{'listincgst'},
        invoiceincgst => $supplier->{'invoiceincgst'},
        discount      => $supplier->{'discount'},
        invoiceprice  => $supplier->{'invoiceprice'},
        listprice     => $supplier->{'listprice'},
        GST           => $tax_rate,
        default_tax   => defined($seller_gstrate),
        basketcount   => $supplier->{'basketcount'},
        contracts     => $contracts,
    );
} elsif ( $op eq 'delete' ) {
    DelBookseller($id);
    print $query->redirect('/cgi-bin/koha/acqui/acqui-home.pl');
    exit;
} else {
    my @currencies = GetCurrencies();
    my $loop_currency;
    for (@currencies) {
        push @{$loop_currency},
          { currency     => $_->{currency},
            listprice    => ( $_->{currency} eq $supplier->{listprice} ),
            invoiceprice => ( $_->{currency} eq $supplier->{invoiceprice} ),
          };
    }

    my $default_gst_rate = (C4::Context->preference('gist') * 100) || '0.0';

    my $gstrate = defined $supplier->{gstrate} ? $supplier->{gstrate} * 100 : '';
    $template->param(
        id           => $id,
        name         => $supplier->{'name'},
        postal       => $supplier->{'postal'},
        address1     => $supplier->{'address1'},
        address2     => $supplier->{'address2'},
        address3     => $supplier->{'address3'},
        address4     => $supplier->{'address4'},
        phone        => $supplier->{'phone'},
        fax          => $supplier->{'fax'},
        url          => $supplier->{'url'},
        contact      => $supplier->{'contact'},
        contpos      => $supplier->{'contpos'},
        contphone    => $supplier->{'contphone'},
        contaltphone => $supplier->{'contaltphone'},
        contfax      => $supplier->{'contfax'},
        contemail    => $supplier->{'contemail'},
        contnotes    => $supplier->{'contnotes'},
        notes        => $supplier->{'notes'},
        # set active ON by default for supplier add (id empty for add)
        active       => $id ? $supplier->{'active'} : 1,
        gstreg        => $supplier->{'gstreg'},
        listincgst    => $supplier->{'listincgst'},
        invoiceincgst => $supplier->{'invoiceincgst'},
        gstrate       => $gstrate,
        discount      => $supplier->{'discount'},
        loop_currency => $loop_currency,
        GST           => $tax_rate,
        enter         => 1,
        default_gst_rate => $default_gst_rate,
    );
}

output_html_with_http_headers $query, $cookie, $template->output;
