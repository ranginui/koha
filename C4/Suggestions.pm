package C4::Suggestions;

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


use strict;
#use warnings; FIXME - Bug 2505
use CGI;

use C4::Context;
use C4::Output;
use C4::Dates qw(format_date);
use C4::SQLHelper qw(:all);
use C4::Debug;
use C4::Letters;
use List::MoreUtils qw<any>;
use C4::Dates qw(format_date_in_iso);
use base qw(Exporter);
our $VERSION = 3.01;
our @EXPORT  = qw<
    ConnectSuggestionAndBiblio
    CountSuggestion
    DelSuggestion
    GetSuggestion
    GetSuggestionByStatus
    GetSuggestionFromBiblionumber
    ModStatus
    ModSuggestion
    NewSuggestion
    SearchSuggestion
>;


=head1 NAME

C4::Suggestions - Some useful functions for dealings with aqorders.

=head1 SYNOPSIS

use C4::Suggestions;

=head1 DESCRIPTION

The functions in this module deal with the aqorders in OPAC and in librarian interface

A suggestion is done in the OPAC. It has the status "ASKED"

When a librarian manages the suggestion, he can set the status to "REJECTED" or "ACCEPTED".

When the book is ordered, the suggestion status becomes "ORDERED"

When a book is ordered and arrived in the library, the status becomes "AVAILABLE"

All aqorders of a borrower can be seen by the borrower itself.
Suggestions done by other borrowers can be seen when not "AVAILABLE"

=head1 FUNCTIONS

=head2 SearchSuggestion

(\@array) = &SearchSuggestion($suggestionhashref_to_search)

searches for a suggestion

return :
C<\@array> : the aqorders found. Array of hash.
Note the status is stored twice :
* in the status field
* as parameter ( for example ASKED => 1, or REJECTED => 1) . This is for template & translation purposes.

=cut

sub SearchSuggestion  {
    my ($suggestion)=@_;
    my $dbh = C4::Context->dbh;
    my @sql_params;
    my @query = (
    q{ SELECT suggestions.*,
        U1.branchcode   AS branchcodesuggestedby,
        B1.branchname   AS branchnamesuggestedby,
        U1.surname   AS surnamesuggestedby,
        U1.firstname AS firstnamesuggestedby,
        U1.email AS emailsuggestedby,
        U1.borrowernumber AS borrnumsuggestedby,
        U1.categorycode AS categorycodesuggestedby,
        C1.description AS categorydescriptionsuggestedby,
        U2.surname   AS surnamemanagedby,
        U2.firstname AS firstnamemanagedby,
        B2.branchname   AS branchnamesuggestedby,
        U2.email AS emailmanagedby,
        U2.branchcode AS branchcodemanagedby,
        U2.borrowernumber AS borrnummanagedby
    FROM suggestions
    LEFT JOIN borrowers AS U1 ON suggestedby=U1.borrowernumber
    LEFT JOIN branches AS B1 ON B1.branchcode=U1.branchcode
    LEFT JOIN categories AS C1 ON C1.categorycode = U1.categorycode
    LEFT JOIN borrowers AS U2 ON managedby=U2.borrowernumber
    LEFT JOIN branches AS B2 ON B2.branchcode=U2.branchcode
    LEFT JOIN categories AS C2 ON C2.categorycode = U2.categorycode
    WHERE STATUS NOT IN ('CLAIMED')
    } , map {
        if ( my $s = $suggestion->{$_} ) {
        push @sql_params,'%'.$s.'%'; 
        " and suggestions.$_ like ? ";
        } else { () }
    } qw( title author isbn publishercode collectiontitle )
    );

    my $userenv = C4::Context->userenv;
    if (C4::Context->preference('IndependantBranches')) {
            if ($userenv) {
                if (($userenv->{flags} % 2) != 1 && !$suggestion->{branchcode}){
                push @sql_params,$$userenv{branch};
                push @query,q{ and (branchcode = ? or branchcode ='')};
                }
            }
    }

    foreach my $field (grep { my $fieldname=$_;
        any {$fieldname eq $_ } qw<
    STATUS branchcode itemtype suggestedby managedby acceptedby
    bookfundid biblionumber
    >} keys %$suggestion
    ) {
        if ($$suggestion{$field}){
            push @sql_params,$suggestion->{$field};
            push @query, " and suggestions.$field=?";
        } 
        else {
            push @query, " and (suggestions.$field='' OR suggestions.$field IS NULL)";
        }
    }

    $debug && warn "@query";
    my $sth=$dbh->prepare("@query");
    $sth->execute(@sql_params);
    my @results;
    while ( my $data=$sth->fetchrow_hashref ){
        $$data{$$data{STATUS}} = 1;
        push(@results,$data);
    }
    return (\@results);
}

=head2 GetSuggestion

\%sth = &GetSuggestion($ordernumber)

this function get the detail of the suggestion $ordernumber (input arg)

return :
    the result of the SQL query as a hash : $sth->fetchrow_hashref.

=cut

sub GetSuggestion {
    my ($ordernumber) = @_;
    my $dbh = C4::Context->dbh;
    my $query = "
        SELECT *
        FROM   suggestions
        WHERE  suggestionid=?
    ";
    my $sth = $dbh->prepare($query);
    $sth->execute($ordernumber);
    return($sth->fetchrow_hashref);
}

=head2 GetSuggestionFromBiblionumber

$ordernumber = &GetSuggestionFromBiblionumber($biblionumber)

Get a suggestion from it's biblionumber.

return :
the id of the suggestion which is related to the biblionumber given on input args.

=cut

sub GetSuggestionFromBiblionumber {
    my ($biblionumber) = @_;
    my $query = q{
        SELECT suggestionid
        FROM   suggestions
        WHERE  biblionumber=?
    };
    my $dbh=C4::Context->dbh;
    my $sth = $dbh->prepare($query);
    $sth->execute($biblionumber);
    my ($ordernumber) = $sth->fetchrow;
    return $ordernumber;
}

=head2 GetSuggestionByStatus

$aqorders = &GetSuggestionByStatus($status,[$branchcode])

Get a suggestion from it's status

return :
all the suggestion with C<$status>

=cut

sub GetSuggestionByStatus {
    my $status = shift;
    my $branchcode = shift;
    my $dbh = C4::Context->dbh;
    my @sql_params=($status);  
    my $query = qq(SELECT suggestions.*,
                        U1.surname   AS surnamesuggestedby,
                        U1.firstname AS firstnamesuggestedby,
                        U1.branchcode AS branchcodesuggestedby,
                        B1.branchname AS branchnamesuggestedby,
                        U1.borrowernumber AS borrnumsuggestedby,
                        U1.categorycode AS categorycodesuggestedby,
                        C1.description AS categorydescriptionsuggestedby,
                        U2.surname   AS surnamemanagedby,
                        U2.firstname AS firstnamemanagedby,
                        U2.borrowernumber AS borrnummanagedby
                        FROM suggestions
                        LEFT JOIN borrowers AS U1 ON suggestedby=U1.borrowernumber
                        LEFT JOIN borrowers AS U2 ON managedby=U2.borrowernumber
                        LEFT JOIN categories AS C1 ON C1.categorycode=U1.categorycode
                        LEFT JOIN branches AS B1 on B1.branchcode = U1.branchcode
                        WHERE status = ?);
    if (C4::Context->preference("IndependantBranches") || $branchcode) {
        my $userenv = C4::Context->userenv;
        if ($userenv) {
            unless ($userenv->{flags} % 2 == 1){
                push @sql_params,$userenv->{branch};
                $query .= " and (U1.branchcode = ? or U1.branchcode ='')";
            }
        }
        if ($branchcode) {
            push @sql_params,$branchcode;
            $query .= " and (U1.branchcode = ? or U1.branchcode ='')";
        }
    }
    
    my $sth = $dbh->prepare($query);
    $sth->execute(@sql_params);
    
    my $results;
    $results=  $sth->fetchall_arrayref({});
    return $results;
}

=head2 CountSuggestion

&CountSuggestion($status)

Count the number of aqorders with the status given on input argument.
the arg status can be :

=over 2

=item * ASKED : asked by the user, not dealed by the librarian

=item * ACCEPTED : accepted by the librarian, but not yet ordered

=item * REJECTED : rejected by the librarian (definitive status)

=item * ORDERED : ordered by the librarian (acquisition module)

=back

return :
the number of suggestion with this status.

=cut

sub CountSuggestion {
    my ($status) = @_;
    my $dbh = C4::Context->dbh;
    my $sth;
    if (C4::Context->preference("IndependantBranches")){
        my $userenv = C4::Context->userenv;
        if ($userenv->{flags} % 2 == 1){
            my $query = qq |
                SELECT count(*)
                FROM   suggestions
                WHERE  STATUS=?
            |;
            $sth = $dbh->prepare($query);
            $sth->execute($status);
        }
        else {
            my $query = qq |
                SELECT count(*)
                FROM suggestions LEFT JOIN borrowers ON borrowers.borrowernumber=suggestions.suggestedby
                WHERE STATUS=?
                AND (borrowers.branchcode='' OR borrowers.branchcode =?)
            |;
            $sth = $dbh->prepare($query);
            $sth->execute($status,$userenv->{branch});
        }
    }
    else {
        my $query = qq |
            SELECT count(*)
            FROM suggestions
            WHERE STATUS=?
        |;
        $sth = $dbh->prepare($query);
        $sth->execute($status);
    }
    my ($result) = $sth->fetchrow;
    return $result;
}

=head2 NewSuggestion


&NewSuggestion($suggestion);

Insert a new suggestion on database with value given on input arg.

=cut

sub NewSuggestion {
    my ($suggestion) = @_;
    $suggestion->{STATUS}="ASKED" unless $suggestion->{STATUS};
    return InsertInTable("suggestions",$suggestion); 
}

=head2 ModSuggestion

&ModSuggestion($suggestion)

Modify the suggestion according to the hash passed by ref.
The hash HAS to contain suggestionid
Data not defined is not updated unless it is a note or sort1 
Send a mail to notify the user that did the suggestion.

Note that there is no function to modify a suggestion. 

=cut

sub ModSuggestion {
    my ($suggestion)=@_;
    my $status_update_table=UpdateInTable("suggestions", $suggestion);

    if ($suggestion->{STATUS}) {
        # fetch the entire updated suggestion so that we can populate the letter
        my $full_suggestion = GetSuggestion($suggestion->{suggestionid});
        my $letter = C4::Letters::getletter('suggestions', $full_suggestion->{STATUS});
        if ($letter) {
            C4::Letters::parseletter($letter, 'branches',    $full_suggestion->{branchcode});
            C4::Letters::parseletter($letter, 'borrowers',   $full_suggestion->{suggestedby});
            C4::Letters::parseletter($letter, 'suggestions', $full_suggestion->{suggestionid});
            C4::Letters::parseletter($letter, 'biblio',      $full_suggestion->{biblionumber});
            my $enqueued = C4::Letters::EnqueueLetter({
                letter                  => $letter,
                borrowernumber          => $full_suggestion->{suggestedby},
                suggestionid            => $full_suggestion->{suggestionid},
                LibraryName             => C4::Context->preference("LibraryName"),
                message_transport_type  => 'email',
            });
            if (!$enqueued){warn "can't enqueue letter $letter";}
        }
    }
    return $status_update_table;
}

=head2 ConnectSuggestionAndBiblio

&ConnectSuggestionAndBiblio($ordernumber,$biblionumber)

connect a suggestion to an existing biblio

=cut

sub ConnectSuggestionAndBiblio {
    my ($suggestionid,$biblionumber) = @_;
    my $dbh=C4::Context->dbh;
    my $query = "
        UPDATE suggestions
        SET    biblionumber=?
        WHERE  suggestionid=?
    ";
    my $sth = $dbh->prepare($query);
    $sth->execute($biblionumber,$suggestionid);
}

=head2 DelSuggestion

&DelSuggestion($borrowernumber,$ordernumber)

Delete a suggestion. A borrower can delete a suggestion only if he is its owner.

=cut

sub DelSuggestion {
    my ($borrowernumber,$suggestionid,$type) = @_;
    my $dbh = C4::Context->dbh;
    # check that the suggestion comes from the suggestor
    my $query = "
        SELECT suggestedby
        FROM   suggestions
        WHERE  suggestionid=?
    ";
    my $sth = $dbh->prepare($query);
    $sth->execute($suggestionid);
    my ($suggestedby) = $sth->fetchrow;
    if ($type eq "intranet" || $suggestedby eq $borrowernumber ) {
        my $queryDelete = "
            DELETE FROM suggestions
            WHERE suggestionid=?
        ";
        $sth = $dbh->prepare($queryDelete);
        my $suggestiondeleted=$sth->execute($suggestionid);
        return $suggestiondeleted;  
    }
}

1;
__END__


=head1 AUTHOR

Koha Development Team <http://koha-community.org/>

=cut

