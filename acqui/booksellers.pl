#!/usr/bin/perl

#script to show suppliers and orders

# Copyright 2000-2002 Katipo Communications
# Copyright 2008-2009 BibLibre SARL
# Copyright 2010 PTFS Europe
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

booksellers.pl

=head1 DESCRIPTION

this script displays the list of suppliers & baskets like C<$supplier> given on input arg.
thus, this page brings differents features like to display supplier's details,
to add an order for a specific supplier or to just add a new supplier.

=head1 CGI PARAMETERS

=over 4

=item supplier

C<$supplier> is the string with which we search for a supplier

=back

=item id or supplierid

The id of the supplier whose baskets we will display

=back

=cut

use strict;
use warnings;
use C4::Auth;
use C4::Biblio;
use C4::Output;
use CGI;

use C4::Dates qw/format_date/;
use C4::Bookseller qw/ GetBookSellerFromId GetBookSeller /;
use C4::Members qw/GetMember/;
use C4::Context;

my $query = CGI->new;
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {   template_name   => 'acqui/booksellers.tmpl',
        query           => $query,
        type            => 'intranet',
        authnotrequired => 0,
        flagsrequired   => { acquisition => '*' },
        debug           => 1,
    }
);

#parameters
my $supplier = $query->param('supplier');
my $id = $query->param('id') || $query->param('supplierid');
my @suppliers;

if ($id) {
    push @suppliers, GetBookSellerFromId($id);
} else {
    @suppliers = GetBookSeller($supplier);
}

my $supplier_count = @suppliers;
if ( $supplier_count == 1 ) {
    $template->param(
        supplier_name => $suppliers[0]->{'name'},
        id            => $suppliers[0]->{'id'}
    );
}

my $uid;
if ($loggedinuser) {
    $uid = GetMember( borrowernumber => $loggedinuser )->{userid};
}

my $userenv = C4::Context::userenv;
my $viewbaskets = C4::Context->preference('AcqViewBaskets');

my $userbranch = $userenv->{branch};

#build result page
my $loop_suppliers = [];

for my $vendor (@suppliers) {
    my $baskets = get_vendors_baskets( $vendor->{id} );

    my $loop_basket = [];
    
    for my $basket ( @{$baskets} ) {
        my $authorisedby = $basket->{authorisedby};
        my $basketbranch = ''; # set a blank branch to start with
        if ( GetMember( borrowernumber => $authorisedby ) ) {
           # authorisedby may not be a valid borrowernumber; it's not foreign-key constrained!
           $basketbranch = GetMember( borrowernumber => $authorisedby )->{branchcode};
        }
        
        if ($userenv->{'flags'} & 1 || #user is superlibrarian
               (haspermission( $uid, { acquisition => q{*} } ) && #user has acq permissions and
                   ($viewbaskets eq 'all' || #user is allowed to see all baskets
                   ($viewbaskets eq 'branch' && $authorisedby && $userbranch eq $basketbranch) || #basket belongs to user's branch
                   ($basket->{authorisedby} &&  $viewbaskets == 'user' && $authorisedby == $loggedinuser) #user created this basket
                   ) 
                ) 
           ) { 
            for my $date_field (qw( creationdate closedate)) {
                if ( $basket->{$date_field} ) {
                    $basket->{$date_field} = format_date( $basket->{$date_field} );
                }
            }
            push @{$loop_basket}, $basket; 
        }
    }

    push @{$loop_suppliers},
      { loop_basket => $loop_basket,
        supplierid  => $vendor->{id},
        name        => $vendor->{name},
        active      => $vendor->{active},
      };

}
$template->param(
    loop_suppliers => $loop_suppliers,
    supplier       => ( $id || $supplier ),
    count          => $supplier_count,
);

output_html_with_http_headers $query, $cookie, $template->output;

sub get_vendors_baskets {
    my $supplier_id = shift;
    my $dbh         = C4::Context->dbh;
    my $sql         = <<'ENDSQL';
select aqbasket.*, count(*) as total,  borrowers.firstname, borrowers.surname
from aqbasket left join aqorders on aqorders.basketno = aqbasket.basketno
left join borrowers on aqbasket.authorisedby = borrowers.borrowernumber
where booksellerid = ?
AND ( aqorders.quantity > aqorders.quantityreceived OR quantityreceived IS NULL)
AND datecancellationprinted IS NULL
group by basketno
ENDSQL
    return $dbh->selectall_arrayref( $sql, { Slice => {} }, $supplier_id );
}
