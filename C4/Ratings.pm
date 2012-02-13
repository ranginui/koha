package C4::Ratings;

# Copyright 2010 KohaAloha, NZ
# Parts copyright 2011, Catalyst IT, NZ.
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

=head1 C4::Ratings - the Koha API for dealing with star ratings for biblios

This provides an interface to the ratings system, in order to allow them
to be manipulated or queried.

=cut

use strict;
use warnings;
use Carp;
use Exporter;

use C4::Debug;
use C4::Context;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

BEGIN {
    $VERSION = 3.00;
    @ISA     = qw(Exporter);

    @EXPORT = qw(
      get_rating add_rating
    );

    #	%EXPORT_TAGS = ();
}

=head2 get_rating

    get_rating($biblionumber, $borrowernumber)

This returns the rating for the supplied biblionumber. It will also return
the rating that the supplied user gave to the provided biblio. If a particular
value can't be supplied, '0' is returned for that value.

=head 3 RETURNS

A hashref containing:

=over

=item total - the total number of ratings
=item avg - the average of the ratings
=item avgint - the integer form of the average
=item value - the user's rating

=back

=cut

my ($total_query_sth, $user_query_sth);
sub get_rating {
    my ( $biblionumber, $borrowernumber ) = @_;
    my $dbh = C4::Context->dbh;

    my $total_query = "
	SELECT    AVG(value) AS average,COUNT(value) AS total  FROM ratings
    WHERE       biblionumber = ?";
    $total_query_sth = $total_query_sth || $dbh->prepare($total_query);

    $total_query_sth->execute($biblionumber);
    my $total_query_res = $total_query_sth->fetchrow_hashref();

    my $user_rating = 0;
    if ($borrowernumber) {
        my $user_query = "
        SELECT    value  from ratings
        WHERE       biblionumber = ? and borrowernumber = ?";
        $user_query_sth ||= $dbh->prepare($user_query);

        $user_query_sth->execute( $biblionumber, $borrowernumber );
        my $user_query_res = $user_query_sth->fetchrow_hashref();
        $user_rating = $user_query_res->{value} || 0;
    }
    my ( $avg, $avgint ) = 0;
    $avg = $total_query_res->{average} || 0;
    $avgint = sprintf( "%.0f", $avg );

    my %rating_hash;
    $rating_hash{total}  = $total_query_res->{total} || 0;
    $rating_hash{avg}    = $avg;
    $rating_hash{avgint} = $avgint;
    $rating_hash{value}  = $user_rating;
    return \%rating_hash;
}

=head2 add_rating

    add_rating($biblionumber, $borrowernumber, $value)

This adds or updates a rating for a particular user on a biblio. If the value
is 0, then the rating will be deleted. If the value is out of the range of
0-5, nothing will happen.

=cut

my ($delete_query_sth, $insert_query_sth);
sub add_rating {
    my ( $biblionumber, $borrowernumber, $value ) = @_;
    if (!defined($biblionumber) || !defined($borrowernumber) ||
        $value < 0 || $value > 5) {
        # Seen this happen, want to know about it if it happens again.
        carp "Invalid input coming in to C4::Ratings::add_rating";
        return;
    }
    if ($borrowernumber == 0) {
	carp "Attempted to add a rating for borrower number 0";
	return;
    }
    my $dbh = C4::Context->dbh;
    my $delete_query = "DELETE FROM ratings WHERE borrowernumber = ? AND biblionumber = ? LIMIT 1";
    my $delete_query_sth ||= $dbh->prepare($delete_query);
    $delete_query_sth->execute( $borrowernumber, $biblionumber );
    return if $value == 0; # We don't add a rating for zero

    my $insert_query = "INSERT INTO ratings (borrowernumber,biblionumber,value)
    VALUES (?,?,?)";
    $insert_query_sth ||= $dbh->prepare($insert_query);
    $insert_query_sth->execute( $borrowernumber, $biblionumber, $value );
}

1;
