package C4::Ratings;

# Copyright 2011 KohaAloha, NZ
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

use strict;
use warnings;
use Carp;
use Exporter;
use POSIX;
use C4::Debug;
use C4::Context;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

BEGIN {
    $VERSION = 3.00;
    @ISA     = qw(Exporter);

    @EXPORT = qw(
      &GetRating
      &AddRating
      &ModRating
      &DelRating
    );
}

=head1 NAME

C4::Ratings - a module to manage user ratings of Koha biblios

=head1 DESCRIPTION

Ratings.pm provides simple functionality for a user to 'rate' a biblio, and to retrieve a biblio's rating info

the 4 subroutines allow a user to add, delete modify and retrieve rating info for a biblio.

The rating can be from 1 to 5 stars, (5 stars being the highest rating)

=head1 SYNOPSIS

Get a rating for a bib
 my $rating_hashref = GetRating( $biblionumber, undef );
 my $rating_hashref = GetRating( $biblionumber, $borrowernumber );

Add a rating for a bib
 my $rating_hashref = AddRating( $biblionumber, $borrowernumber, $rating_value );

Mod a rating for a bib
 my $rating_hashref = ModRating( $biblionumber, $borrowernumber, $rating_value );

Delete a rating for a bib
 my $rating_hashref = DelRating( $biblionumber, $borrowernumber );


All subroutines in Ratings.pm return a hashref which contain 4 keys

for example, after executing this statment below...

    my $rating_hashref = GetRating ( $biblionumber, $borrowernumber ) ;

$rating_hashref now contains a hashref that looks like this...

    $rating  = {
             rating_avg       => '2',
             rating_avg_int   => '2.3',
             rating_total     => '432',
             rating_value => '5'
    }

they 4 keys returned in the hashref are...

    rating_avg:            average rating of a biblio
    rating_avg_int:        average rating of a biblio, rounded to 1dp
    rating_total:          total number of ratings of a biblio
    rating_value:          logged-in user's rating of a biblio

=head1 BUGS

Please use bugs.koha-community.org for tracking bugs.

=head1 SOURCE AVAILABILITY

The source is available from the koha-community.org git server
L<http://git.koha-community.org>

=head1 AUTHOR

Original code: Mason James <mtj@kohaaloha.com>

=head1 COPYRIGHT

Copyright (c) 2011 Mason James <mtj@kohaaloha.com>

=head1 LICENSE

C4::Ratings is free software. You can redistribute it and/or
modify it under the same terms as Koha itself.

=head1 CREDITS

 Mason James <mtj@kohaaloha.com>
 Koha Dev Team <http://koha-community.org>


=head2 GetRating

    GetRating($biblionumber, [$borrowernumber])

Get a rating for a bib
 my $rating_hashref = GetRating( $biblionumber, undef );
 my $rating_hashref = GetRating( $biblionumber, $borrowernumber );

This returns the rating for the supplied biblionumber. It will also return
the rating that the supplied user gave to the provided biblio. If a particular
value can't be supplied, '0' is returned for that value.

=head3 RETURNS

A hashref containing:

=over

=item * rating_avg - average rating of a biblio
=item * rating_avg_int - average rating of a biblio, rounded to 1dp
=item * rating_total - total number of ratings of a biblio
=item * rating_value - logged-in user's rating of a biblio

=back

=cut

sub GetRating {
    my ( $biblionumber, $borrowernumber ) = @_;
    my $query = qq| SELECT COUNT(*) AS total, SUM(rating_value) AS sum
FROM ratings WHERE biblionumber = ? |;

    my $sth = C4::Context->dbh->prepare($query);
    $sth->execute($biblionumber);
    my $res = $sth->fetchrow_hashref();

    my ( $avg, $avg_int ) = 0;

    if ( $res->{sum} and $res->{total} ) {
        eval { $avg = $res->{sum} / $res->{total} };
    }

    $avg_int = sprintf( "%.1f", $avg );
    $avg     = sprintf( "%.0f", $avg );

    my %rating_hash;
    $rating_hash{rating_total}   = $res->{total} || 0;
    $rating_hash{rating_avg}     = $avg || 0;
    $rating_hash{rating_avg_int} = $avg_int ||0;

    if ($borrowernumber) {
        my $q2 = qq|
SELECT rating_value FROM ratings WHERE biblionumber = ? AND borrowernumber = ?|;
        my $sth1 = C4::Context->dbh->prepare($q2);
        $sth1->execute( $biblionumber, $borrowernumber );
        my $res1 = $sth1->fetchrow_hashref();
        $rating_hash{'rating_value'} = $res1->{"rating_value"};
    }
    else {
        $rating_hash{rating_borrowernumber} = undef;
        $rating_hash{rating_value}          = undef;
    }

#### %rating_hash
    return \%rating_hash;
}

=head2 AddRating

    my $rating_hashref = AddRating( $biblionumber, $borrowernumber, $rating_value );

Add a rating for a bib

This adds or updates a rating for a particular user on a biblio. If the value
is 0, then the rating will be deleted. If the value is out of the range of
0-5, nothing will happen.

=cut

sub AddRating {
    my ( $biblionumber, $borrowernumber, $rating_value ) = @_;
    my $query =
      qq| INSERT INTO ratings (borrowernumber,biblionumber,rating_value)
        VALUES (?,?,?)|;
    my $sth = C4::Context->dbh->prepare($query);
    $sth->execute( $borrowernumber, $biblionumber, $rating_value );
    my $rating = GetRating( $biblionumber, $borrowernumber );
    return $rating;
}

=head2 ModRating

    my $rating_hashref = ModRating( $biblionumber, $borrowernumber, $rating_value );

Mod a rating for a bib

=cut

sub ModRating {
    my ( $biblionumber, $borrowernumber, $rating_value ) = @_;
    my $query =
qq|UPDATE ratings SET rating_value = ? WHERE borrowernumber = ? AND biblionumber = ?|;
    my $sth = C4::Context->dbh->prepare($query);
    $sth->execute( $rating_value, $borrowernumber, $biblionumber );
    my $rating = GetRating( $biblionumber, $borrowernumber );
    return $rating;
}

=head2 DelRating

    my $rating_hashref = DelRating( $biblionumber, $borrowernumber );

Delete a rating for a bib

=cut

sub DelRating {
    my ( $biblionumber, $borrowernumber ) = @_;
    my $dbh = C4::Context->dbh;
    my $query =
      "delete from ratings where borrowernumber = ? and biblionumber = ?";
    my $sth    = C4::Context->dbh->prepare($query);
    my $rv     = $sth->execute( $borrowernumber, $biblionumber );
    my $rating = GetRating( $biblionumber, undef );
    return $rating;
}

1;
__END__
