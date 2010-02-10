package C4::Recommendations;

# Copyright 2009 Catalyst IT
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
use C4::Context;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use C4::Recommendations ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(

          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
build_recommendations get_recommendations
    
);

our $VERSION = '0.01';

sub build_recommendations {
    my $dbh = C4::Context->dbh;
#    $dbh->do("TRUNCATE recommendations");
    my $query = "SELECT max(updated) AS updated_time FROM recommendations";
    my $sth = $dbh->prepare($query);
    my $max = $sth->fetchrow_hashref();
    $sth->finish;
    $query =
"SELECT biblio.biblionumber,borrowernumber FROM old_issues,biblio,items WHERE old_issues.itemnumber=items.itemnumber AND items.biblionumber=biblio.biblionumber AND old_issues.issuedate > ?";
    $sth = $dbh->prepare($query);
    $sth->execute($max->{'updated_time'});
    my $query2 =
"SELECT  biblio.biblionumber,borrowernumber FROM old_issues,biblio,items WHERE old_issues.itemnumber=items.itemnumber AND items.biblionumber=biblio.biblionumber AND old_issues.borrowernumber = ? AND old_issues.issuedate > ?";
    my $sth2                   = $dbh->prepare($query2);
    my $recommendations_select = $dbh->prepare(
        "SELECT * FROM recommendations WHERE biblio_one = ? AND biblio_two = ?"
    );
    my $recommendations_update = $dbh->prepare(
"UPDATE recommendations SET hit_count = ?,updated=now() WHERE biblio_one = ? AND biblio_two = ?"
    );
    my $recommendations_insert = $dbh->prepare(
"INSERT INTO recommendations (biblio_one,biblio_two,hit_count,updated) VALUES (?,?,?,now())"
    );

    while ( my $issue = $sth->fetchrow_hashref() ) {
#	warn $issue->{'borrowernumber'};
        $sth2->execute( $issue->{'borrowernumber'}, $max->{'updated_time'} );
        while ( my $borrowers_issue = $sth2->fetchrow_hashref() ) {
#	    warn $borrowers_issue->{'biblionumber'};
	    if ($issue->{'biblionumber'} == $borrowers_issue->{'biblionumber'}){
		next;
	    }
            $recommendations_select->execute( $issue->{'biblionumber'},
                $borrowers_issue->{'biblionumber'} );
            if ( my $recommendation = $recommendations_select->fetchrow_hashref() )
            {
                $recommendation->{'hit_count'}++;
                $recommendations_update->execute(
                    $recommendation->{'hit_count'},
                    $issue->{'biblionumber'},
                    $borrowers_issue->{'biblionumber'}
                );
            }
            else {
                $recommendations_insert->execute(                   
                    $issue->{'biblionumber'},
                    $borrowers_issue->{'biblionumber'},
		    1
                );
            }
        }

    }
}

sub get_recommendations {
    my $biblionumber = shift;
    my $dbh = C4::Context->dbh();
    my $sth = $dbh->prepare("SELECT biblio.biblionumber,biblio.title,hit_count FROM biblio,recommendations WHERE biblio_two = biblio.biblionumber AND biblio_one = ? ORDER BY hit_count DESC LIMIT 10");
    $sth->execute($biblionumber);
    return $sth->fetchall_arrayref({});
}

1;
__END__


=head1 NAME

C4::Recommendations - Perl extension for Generating reading recommendations

=head1 SYNOPSIS

  use C4::Recommendations;
  

=head1 DESCRIPTION


=head2 EXPORT

None by default.

=head1 AUTHOR

Chris Cormack, E<lt>chrisc@catalyst.net.nzE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Catalyst IT

This file is part of Koha.

Koha is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.
Koha is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
Suite 330, Boston, MA  02111-1307 USA


=cut
