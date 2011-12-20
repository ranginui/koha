package C4::Bookseller;

# Copyright 2000-2002 Katipo Communications
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

use strict;
use warnings;

use base qw( Exporter );

# set the version for version checking
our $VERSION   = 4.01;
our @EXPORT_OK = qw(
  GetBookSeller GetBooksellersWithLateOrders GetBookSellerFromId
  ModBookseller
  DelBookseller
  AddBookseller
);

=head1 NAME

C4::Bookseller - Koha functions for dealing with booksellers.

=head1 SYNOPSIS

use C4::Bookseller;

=head1 DESCRIPTION

The functions in this module deal with booksellers. They allow to
add a new bookseller, to modify it or to get some informations around
a bookseller.

=head1 FUNCTIONS

=head2 GetBookSeller

@results = GetBookSeller($searchstring);

Looks up a book seller. C<$searchstring> may be either a book seller
ID, or a string to look for in the book seller's name.

C<@results> is an array of hash_refs whose keys are the fields of of the
aqbooksellers table in the Koha database.

=cut

sub GetBookSeller {
    my $searchstring = shift;
    $searchstring = q{%} . $searchstring . q{%};
    my $query =
'select aqbooksellers.*, count(*) as basketcount from aqbooksellers left join aqbasket '
      . 'on aqbasket.booksellerid = aqbooksellers.id where name like ? group by aqbooksellers.id order by name';

    my $dbh           = C4::Context->dbh;
    my $sth           = $dbh->prepare($query);
    $sth->execute($searchstring);
    my $resultset_ref = $sth->fetchall_arrayref( {} );
    return @{$resultset_ref};
}

sub GetBookSellerFromId {
    my $id = shift or return;
    my $dbh = C4::Context->dbh;
    my $vendor =
      $dbh->selectrow_hashref( 'SELECT * FROM aqbooksellers WHERE id = ?',
        {}, $id );
    if ($vendor) {
        ( $vendor->{basketcount} ) = $dbh->selectrow_array(
            'SELECT count(*) FROM aqbasket where booksellerid = ?',
            {}, $id );
    }
    return $vendor;
}

#-----------------------------------------------------------------#

=head2 GetBooksellersWithLateOrders

%results = GetBooksellersWithLateOrders($delay);

Searches for suppliers with late orders.

=cut

sub GetBooksellersWithLateOrders {
    my $delay = shift;
    my $dbh   = C4::Context->dbh;

    # TODO delay should be verified
    my $query_string =
      "SELECT DISTINCT aqbasket.booksellerid, aqbooksellers.name
    FROM aqorders LEFT JOIN aqbasket ON aqorders.basketno=aqbasket.basketno
    LEFT JOIN aqbooksellers ON aqbasket.booksellerid = aqbooksellers.id
    WHERE (closedate < DATE_SUB(CURDATE( ),INTERVAL $delay DAY)
    AND (datereceived = '' OR datereceived IS NULL))";

    my $sth = $dbh->prepare($query_string);
    $sth->execute;
    my %supplierlist;
    while ( my ( $id, $name ) = $sth->fetchrow ) {
        $supplierlist{$id} = $name;
    }

    return %supplierlist;
}

#--------------------------------------------------------------------#

=head2 AddBookseller

$id = &AddBookseller($bookseller);

Creates a new bookseller. C<$bookseller> is a reference-to-hash whose
keys are the fields of the aqbooksellers table in the Koha database.
All fields must be present.

Returns the ID of the newly-created bookseller.

=cut

sub AddBookseller {
    my ($data) = @_;
    my $dbh    = C4::Context->dbh;
    my $query  = q|
        INSERT INTO aqbooksellers
            (
                name,      address1,      address2,   address3,      address4,
                postal,    phone,         accountnumber,   fax,      url,           
                contact,
                contpos,   contphone,     contfax,    contaltphone,  contemail,
                contnotes, active,        listprice,  invoiceprice,  gstreg,
                listincgst,invoiceincgst, gstrate,    discount,
                notes
            )
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) |
      ;
    my $sth = $dbh->prepare($query);
    $sth->execute(
        $data->{'name'},         $data->{'address1'},
        $data->{'address2'},     $data->{'address3'},
        $data->{'address4'},     $data->{'postal'},
        $data->{'phone'},        $data->{'accountnumber'},
        $data->{'fax'},
        $data->{'url'},          $data->{'contact'},
        $data->{'contpos'},      $data->{'contphone'},
        $data->{'contfax'},      $data->{'contaltphone'},
        $data->{'contemail'},    $data->{'contnotes'},
        $data->{'active'},       $data->{'listprice'},
        $data->{'invoiceprice'}, $data->{'gstreg'},
        $data->{'listincgst'},   $data->{'invoiceincgst'},
        $data->{'gstrate'},
        $data->{'discount'},     $data->{'notes'}
    );

    # return the id of this new supplier
    return $dbh->{'mysql_insertid'};
}

#-----------------------------------------------------------------#

=head2 ModBookseller

ModBookseller($bookseller);

Updates the information for a given bookseller. C<$bookseller> is a
reference-to-hash whose keys are the fields of the aqbooksellers table
in the Koha database. It must contain entries for all of the fields.
The entry to modify is determined by C<$bookseller-E<gt>{id}>.

The easiest way to get all of the necessary fields is to look up a
book seller with C<&GetBookseller>, modify what's necessary, then call
C<&ModBookseller> with the result.

=cut

sub ModBookseller {
    my ($data) = @_;
    my $dbh    = C4::Context->dbh;
    my $query  = 'UPDATE aqbooksellers
        SET name=?,address1=?,address2=?,address3=?,address4=?,
            postal=?,phone=?,accountnumber=?,fax=?,url=?,contact=?,contpos=?,
            contphone=?,contfax=?,contaltphone=?,contemail=?,
            contnotes=?,active=?,listprice=?, invoiceprice=?,
            gstreg=?,listincgst=?,invoiceincgst=?,
            discount=?,notes=?,gstrate=?
        WHERE id=?';
    my $sth = $dbh->prepare($query);
    $sth->execute(
        $data->{'name'},         $data->{'address1'},
        $data->{'address2'},     $data->{'address3'},
        $data->{'address4'},     $data->{'postal'},
        $data->{'phone'},        $data->{'accountnumber'},
        $data->{'fax'},
        $data->{'url'},          $data->{'contact'},
        $data->{'contpos'},      $data->{'contphone'},
        $data->{'contfax'},      $data->{'contaltphone'},
        $data->{'contemail'},    $data->{'contnotes'},
        $data->{'active'},       $data->{'listprice'},
        $data->{'invoiceprice'}, $data->{'gstreg'},
        $data->{'listincgst'},   $data->{'invoiceincgst'},
        $data->{'discount'},     $data->{'notes'},
        $data->{'gstrate'},      $data->{'id'}
    );
    return;
}

=head2 DelBookseller

DelBookseller($booksellerid);

delete the supplier record identified by $booksellerid
This sub assumes it is called only if the supplier has no order.

=cut

sub DelBookseller {
    my $id  = shift;
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare('DELETE FROM aqbooksellers WHERE id=?');
    $sth->execute($id);
    return;
}

1;

__END__

=head1 AUTHOR

Koha Development Team <http://koha-community.org/>

=cut
