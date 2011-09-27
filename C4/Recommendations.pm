package C4::Recommendations;

# Copyright 2009,2011 Catalyst IT
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

=head1 NAME

    C4::Recommendations - Koha module for producing reading recommendations

=head1 SYNOPSIS

    use C4::Recommendations;

    build_recommendations();

    my $recommended_books = get_recommendations($biblio);

=head1 DESCRIPTION

This looks at the issue history, and counts how many times each particular book
has been taken out by someone who also has taken out another particular book,
recording that as a hit for each pair.

For example, if 3 people have taken out book A and book B, then this is
recorded as three "hits" for that combination, and so it'll show as a
recommendation with that strength.

=head1 EXPORT

None by default, however C<build_recommendations> and C<get_recommendations>
can be imported optionally.

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use C4::Context;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
our @EXPORT_OK = qw(
    build_recommendations 
    get_recommendations
);

our $VERSION = '0.01';

=head2 build_recommendations

    build_recommendations

This runs through all the issues and generates the tables of recommendations.
Note that it'll likely take a long time to run, and put stress on the database,
so do it at a low peak time.

=cut

sub build_recommendations {
    my $dbh = C4::Context->dbh;
    $dbh->do("TRUNCATE recommendations");
    my $all_issues_query = qq/
SELECT biblio.biblionumber,borrowernumber 
FROM old_issues,biblio,items 
WHERE old_issues.itemnumber=items.itemnumber 
AND items.biblionumber=biblio.biblionumber
    /;
    my $all_issues_sth = $dbh->prepare($all_issues_query);
    my $borrower_issues_query = qq/
SELECT  biblio.biblionumber,borrowernumber 
FROM old_issues,biblio,items 
WHERE old_issues.itemnumber=items.itemnumber 
AND items.biblionumber=biblio.biblionumber 
AND old_issues.borrowernumber = ?
AND items.biblionumber > ?
    /;
    my $borrower_issues_sth = $dbh->prepare($borrower_issues_query);
    my $recommendations_select = $dbh->prepare(qq/
SELECT * FROM recommendations 
WHERE biblio_one = ? AND 
biblio_two = ?
    /);
    my $recommendations_update = $dbh->prepare(qq/
UPDATE recommendations 
SET hit_count = ? 
WHERE biblio_one = ? 
AND biblio_two = ?
    /);
    my $recommendations_insert = $dbh->prepare(qq/
INSERT INTO recommendations (biblio_one,biblio_two,hit_count) VALUES (?,?,?)
    /);

    $all_issues_sth->execute();
    while ( my $issue = $all_issues_sth->fetchrow_hashref() ) {
#	warn $issue->{'borrowernumber'};
        $borrower_issues_sth->execute( $issue->{'borrowernumber'}, $issue->{biblionumber} );
        while ( my $borrowers_issue = $borrower_issues_sth->fetchrow_hashref() ) {
#	    warn $borrowers_issue->{'biblionumber'};
            $recommendations_select->execute( $issue->{'biblionumber'},
                $borrowers_issue->{'biblionumber'} );
            if ( my $recommendation = $recommendations_select->fetchrow_hashref() ) {
                $recommendation->{'hit_count'}++;
                $recommendations_update->execute(
                    $recommendation->{'hit_count'},
                    $issue->{'biblionumber'},
                    $borrowers_issue->{'biblionumber'}
                );
            } else {
                $recommendations_insert->execute(
                    $issue->{'biblionumber'},
                    $borrowers_issue->{'biblionumber'},
		            1
                );
            }
        }

    }
}

=head2 get_recommendations

    my $recommendations = get_recommendations($biblionumber, $limit)
    foreach my $rec (@$recommendations) {
    	print $rec->{biblionumber}.": ".$rec->{title}."\n";
    }

This gets the recommendations for a particular biblio, returning an array of
hashes containing C<biblionumber> and C<title>. The array is ordered from
most-recommended to least.

C<$limit> restrictes the amount of results returned. If it's not supplied,
it defaults to 100.

=cut

sub get_recommendations {
    my ($biblionumber, $limit) = @_;
    $limit ||= 100;

    my $dbh = C4::Context->dbh();

    # Two parts: first get the biblio_one side, then get the 
    # biblio_two side. I'd love to know how to squish this into one query.
    my $sth = $dbh->prepare(qq/
SELECT biblio.biblionumber,biblio.title, hit_count
FROM biblio,recommendations 
WHERE biblio.biblionumber = biblio_two
AND biblio_one = ?
ORDER BY hit_count DESC
LIMIT ?
    /);
    $sth->execute($biblionumber, $limit);
    my $res = $sth->fetchall_arrayref({});

    $sth = $dbh->prepare(qq/
SELECT biblio.biblionumber,biblio.title, hit_count
FROM biblio,recommendations 
WHERE biblio.biblionumber = biblio_one
AND biblio_two = ?
ORDER BY hit_count DESC
LIMIT ?
    /);
    $sth->execute($biblionumber, $limit);
    push @{ $res }, @{$sth->fetchall_arrayref({})};

    $res = \@{ @{$res}[0..$limit] } if (@$res > $limit);

    my @res = sort { $b->{hit_count} <=> $a->{hit_count} } @$res;
    return \@res;
}

1;
__END__

=head1 AUTHOR

=over

=item Chris Cormack, E<lt>chrisc@catalyst.net.nzE<gt>

=item Robin Sheat, E<lt>robin@catalyst.net.nzE<gt>

=back

