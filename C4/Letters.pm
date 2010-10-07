package C4::Letters;

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
use warnings;

use MIME::Lite;
use Mail::Sendmail;
use Encode;
use Carp;

use C4::Members;
use C4::Log;
use C4::SMS;
use C4::Debug;
use Date::Calc qw( Add_Delta_Days );
use Encode;
use Carp;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

BEGIN {
	require Exporter;
	# set the version for version checking
	$VERSION = 3.01;
	@ISA = qw(Exporter);
	@EXPORT = qw(
	&GetLetters &getletter &addalert &getalert &delalert &findrelatedto &SendAlerts GetPrintMessages
	);
}

=head1 NAME

C4::Letters - Give functions for Letters management

=head1 SYNOPSIS

  use C4::Letters;

=head1 DESCRIPTION

  "Letters" is the tool used in Koha to manage informations sent to the patrons and/or the library. This include some cron jobs like
  late issues, as well as other tasks like sending a mail to users that have subscribed to a "serial issue alert" (= being warned every time a new issue has arrived at the library)

  Letters are managed through "alerts" sent by Koha on some events. All "alert" related functions are in this module too.

=head2 GetLetters([$category])

  $letters = &GetLetters($category);
  returns informations about letters.
  if needed, $category filters for letters given category
  Create a letter selector with the following code

=head3 in PERL SCRIPT

my $letters = GetLetters($cat);
my @letterloop;
foreach my $thisletter (keys %$letters) {
    my $selected = 1 if $thisletter eq $letter;
    my %row =(
        value => $thisletter,
        selected => $selected,
        lettername => $letters->{$thisletter},
    );
    push @letterloop, \%row;
}
$template->param(LETTERLOOP => \@letterloop);

=head3 in TEMPLATE

    <select name="letter">
        <option value="">Default</option>
    <!-- TMPL_LOOP name="LETTERLOOP" -->
        <option value="<!-- TMPL_VAR name="value" -->" <!-- TMPL_IF name="selected" -->selected<!-- /TMPL_IF -->><!-- TMPL_VAR name="lettername" --></option>
    <!-- /TMPL_LOOP -->
    </select>

=cut

sub GetLetters (;$) {

    # returns a reference to a hash of references to ALL letters...
    my $cat = shift;
    my %letters;
    my $dbh = C4::Context->dbh;
    my $sth;
    if (defined $cat) {
        my $query = "SELECT * FROM letter WHERE module = ? ORDER BY name";
        $sth = $dbh->prepare($query);
        $sth->execute($cat);
    }
    else {
        my $query = "SELECT * FROM letter ORDER BY name";
        $sth = $dbh->prepare($query);
        $sth->execute;
    }
    while ( my $letter = $sth->fetchrow_hashref ) {
        $letters{ $letter->{'code'} } = $letter->{'name'};
    }
    return \%letters;
}

sub getletter ($$) {
    my ( $module, $code ) = @_;
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("select * from letter where module=? and code=?");
    $sth->execute( $module, $code );
    my $line = $sth->fetchrow_hashref;
    return $line;
}

=head2 addalert ($borrowernumber, $type, $externalid)

    parameters : 
    - $borrowernumber : the number of the borrower subscribing to the alert
    - $type : the type of alert.
    - $externalid : the primary key of the object to put alert on. For issues, the alert is made on subscriptionid.
    
    create an alert and return the alertid (primary key)

=cut

sub addalert ($$$) {
    my ( $borrowernumber, $type, $externalid ) = @_;
    my $dbh = C4::Context->dbh;
    my $sth =
      $dbh->prepare(
        "insert into alert (borrowernumber, type, externalid) values (?,?,?)");
    $sth->execute( $borrowernumber, $type, $externalid );

    # get the alert number newly created and return it
    my $alertid = $dbh->{'mysql_insertid'};
    return $alertid;
}

=head2 delalert ($alertid)

    parameters :
    - alertid : the alert id
    deletes the alert

=cut

sub delalert ($) {
    my $alertid = shift or die "delalert() called without valid argument (alertid)";    # it's gonna die anyway.
    $debug and warn "delalert: deleting alertid $alertid";
    my $sth = C4::Context->dbh->prepare("delete from alert where alertid=?");
    $sth->execute($alertid);
}

=head2 getalert ([$borrowernumber], [$type], [$externalid])

    parameters :
    - $borrowernumber : the number of the borrower subscribing to the alert
    - $type : the type of alert.
    - $externalid : the primary key of the object to put alert on. For issues, the alert is made on subscriptionid.
    all parameters NON mandatory. If a parameter is omitted, the query is done without the corresponding parameter. For example, without $externalid, returns all alerts for a borrower on a topic.

=cut

sub getalert (;$$$) {
    my ( $borrowernumber, $type, $externalid ) = @_;
    my $dbh   = C4::Context->dbh;
    my $query = "SELECT * FROM alert WHERE";
    my @bind;
    if ($borrowernumber and $borrowernumber =~ /^\d+$/) {
        $query .= " borrowernumber=? AND ";
        push @bind, $borrowernumber;
    }
    if ($type) {
        $query .= " type=? AND ";
        push @bind, $type;
    }
    if ($externalid) {
        $query .= " externalid=? AND ";
        push @bind, $externalid;
    }
    $query =~ s/ AND $//;
    my $sth = $dbh->prepare($query);
    $sth->execute(@bind);
    return $sth->fetchall_arrayref({});
}

=head2 findrelatedto($type, $externalid)

	parameters :
	- $type : the type of alert
	- $externalid : the id of the "object" to query
	
	In the table alert, a "id" is stored in the externalid field. This "id" is related to another table, depending on the type of the alert.
	When type=issue, the id is related to a subscriptionid and this sub returns the name of the biblio.

=cut
    
# outmoded POD:
# When type=virtual, the id is related to a virtual shelf and this sub returns the name of the sub

sub findrelatedto ($$) {
    my $type       = shift or return undef;
    my $externalid = shift or return undef;
    my $q = ($type eq 'issue'   ) ?
"select title as result from subscription left join biblio on subscription.biblionumber=biblio.biblionumber where subscriptionid=?" :
            ($type eq 'borrower') ?
"select concat(firstname,' ',surname) from borrowers where borrowernumber=?" : undef;
    unless ($q) {
        warn "findrelatedto(): Illegal type '$type'";
        return undef;
    }
    my $sth = C4::Context->dbh->prepare($q);
    $sth->execute($externalid);
    my ($result) = $sth->fetchrow;
    return $result;
}

=head2 SendAlerts

    parameters :
    - $type : the type of alert
    - $externalid : the id of the "object" to query
    - $letter : the letter to send.

    send an alert to all borrowers having put an alert on a given subject.

=cut

sub SendAlerts {
    my ( $type, $externalid, $letter ) = @_;
    my $dbh = C4::Context->dbh;
    if ( $type eq 'issue' ) {

        # 		warn "sending issues...";
        my $letter = getletter( 'serial', $letter );

        # prepare the letter...
        # search the biblionumber
        my $sth =
          $dbh->prepare(
            "SELECT biblionumber FROM subscription WHERE subscriptionid=?");
        $sth->execute($externalid);
        my ($biblionumber) = $sth->fetchrow;

        # parsing branch info
        my $userenv = C4::Context->userenv;
        parseletter( $letter, 'branches', $userenv->{branch} );

        # parsing librarian name
        $letter->{content} =~ s/<<LibrarianFirstname>>/$userenv->{firstname}/g;
        $letter->{content} =~ s/<<LibrarianSurname>>/$userenv->{surname}/g;
        $letter->{content} =~
          s/<<LibrarianEmailaddress>>/$userenv->{emailaddress}/g;

        # parsing biblio information
        parseletter( $letter, 'biblio',      $biblionumber );
        parseletter( $letter, 'biblioitems', $biblionumber );

        # find the list of borrowers to alert
        my $alerts = getalert( '', 'issue', $externalid );
        foreach (@$alerts) {

            # and parse borrower ...
            my $innerletter = $letter;
            my $borinfo = C4::Members::GetMember('borrowernumber' => $_->{'borrowernumber'});
            parseletter( $innerletter, 'borrowers', $_->{'borrowernumber'} );

            # ... then send mail
            if ( $borinfo->{email} ) {
                my %mail = (
                    To      => $borinfo->{email},
                    From    => $borinfo->{email},
                    Subject => "" . $innerletter->{title},
                    Message => "" . $innerletter->{content},
                    'Content-Type' => 'text/plain; charset="utf8"',
                    );
                sendmail(%mail) or carp $Mail::Sendmail::error;

# warn "sending to $mail{To} From $mail{From} subj $mail{Subject} Mess $mail{Message}";
            }
        }
    }
    elsif ( $type eq 'claimacquisition' ) {

        # 		warn "sending issues...";
        my $letter = getletter( 'claimacquisition', $letter );

        # prepare the letter...
        # search the biblionumber
        my $strsth =
"select aqorders.*,aqbasket.*,biblio.*,biblioitems.* from aqorders LEFT JOIN aqbasket on aqbasket.basketno=aqorders.basketno LEFT JOIN biblio on aqorders.biblionumber=biblio.biblionumber LEFT JOIN biblioitems on aqorders.biblioitemnumber=biblioitems.biblioitemnumber where aqorders.ordernumber IN ("
          . join( ",", @$externalid ) . ")";
        my $sthorders = $dbh->prepare($strsth);
        $sthorders->execute;
        my $dataorders = $sthorders->fetchall_arrayref( {} );
        parseletter( $letter, 'aqbooksellers',
            $dataorders->[0]->{booksellerid} );
        my $sthbookseller =
          $dbh->prepare("select * from aqbooksellers where id=?");
        $sthbookseller->execute( $dataorders->[0]->{booksellerid} );
        my $databookseller = $sthbookseller->fetchrow_hashref;

        # parsing branch info
        my $userenv = C4::Context->userenv;
        parseletter( $letter, 'branches', $userenv->{branch} );

        # parsing librarian name
        $letter->{content} =~ s/<<LibrarianFirstname>>/$userenv->{firstname}/g;
        $letter->{content} =~ s/<<LibrarianSurname>>/$userenv->{surname}/g;
        $letter->{content} =~
          s/<<LibrarianEmailaddress>>/$userenv->{emailaddress}/g;
        foreach my $data (@$dataorders) {
            my $line = $1 if ( $letter->{content} =~ m/(<<.*>>)/ );
            foreach my $field ( keys %$data ) {
                $line =~ s/(<<[^\.]+.$field>>)/$data->{$field}/;
            }
            $letter->{content} =~ s/(<<.*>>)/$line\n$1/;
        }
        $letter->{content} =~ s/<<[^>]*>>//g;
        my $innerletter = $letter;

        # ... then send mail
        if (   $databookseller->{bookselleremail}
            || $databookseller->{contemail} )
        {
            my %mail = (
                To => $databookseller->{bookselleremail}
                  . (
                    $databookseller->{contemail}
                    ? "," . $databookseller->{contemail}
                    : ""
                  ),
                From           => $userenv->{emailaddress},
                Subject        => "" . $innerletter->{title},
                Message        => "" . $innerletter->{content},
                'Content-Type' => 'text/plain; charset="utf8"',
            );
            sendmail(%mail) or carp $Mail::Sendmail::error;
        }
        if ( C4::Context->preference("LetterLog") ) {
            logaction(
                "ACQUISITION",
                "Send Acquisition claim letter",
                "",
                "order list : "
                  . join( ",", @$externalid )
                  . "\n$innerletter->{title}\n$innerletter->{content}"
            );
        }
    }
    elsif ( $type eq 'claimissues' ) {

        # 		warn "sending issues...";
        my $letter = getletter( 'claimissues', $letter );

        # prepare the letter...
        # search the biblionumber
        my $strsth =
"select serial.*,subscription.*, biblio.* from serial LEFT JOIN subscription on serial.subscriptionid=subscription.subscriptionid LEFT JOIN biblio on serial.biblionumber=biblio.biblionumber where serial.serialid IN ("
          . join( ",", @$externalid ) . ")";
        my $sthorders = $dbh->prepare($strsth);
        $sthorders->execute;
        my $dataorders = $sthorders->fetchall_arrayref( {} );
        parseletter( $letter, 'aqbooksellers',
            $dataorders->[0]->{aqbooksellerid} );
        my $sthbookseller =
          $dbh->prepare("select * from aqbooksellers where id=?");
        $sthbookseller->execute( $dataorders->[0]->{aqbooksellerid} );
        my $databookseller = $sthbookseller->fetchrow_hashref;

        # parsing branch info
        my $userenv = C4::Context->userenv;
        parseletter( $letter, 'branches', $userenv->{branch} );

        # parsing librarian name
        $letter->{content} =~ s/<<LibrarianFirstname>>/$userenv->{firstname}/g;
        $letter->{content} =~ s/<<LibrarianSurname>>/$userenv->{surname}/g;
        $letter->{content} =~
          s/<<LibrarianEmailaddress>>/$userenv->{emailaddress}/g;
        foreach my $data (@$dataorders) {
            my $line = $1 if ( $letter->{content} =~ m/(<<.*>>)/ );
            foreach my $field ( keys %$data ) {
                $line =~ s/(<<[^\.]+.$field>>)/$data->{$field}/;
            }
            $letter->{content} =~ s/(<<.*>>)/$line\n$1/;
        }
        $letter->{content} =~ s/<<[^>]*>>//g;
        my $innerletter = $letter;

        # ... then send mail
        if (   $databookseller->{bookselleremail}
            || $databookseller->{contemail} ) {
            my $mail_to = $databookseller->{bookselleremail};
            if ($databookseller->{contemail}) {
                if (!$mail_to) {
                    $mail_to = $databookseller->{contemail};
                } else {
                    $mail_to .= q|,|;
                    $mail_to .= $databookseller->{contemail};
                }
            }
            my $mail_subj = $innerletter->{title};
            my $mail_msg  = $innerletter->{content};
            $mail_msg  ||= q{};
            $mail_subj ||= q{};

            my %mail = (
                To => $mail_to,
                From    => $userenv->{emailaddress},
                Subject => $mail_subj,
                Message => $mail_msg,
                'Content-Type' => 'text/plain; charset="utf8"',
            );
            sendmail(%mail) or carp $Mail::Sendmail::error;
            logaction(
                "ACQUISITION",
                "CLAIM ISSUE",
                undef,
                "To="
                  . $databookseller->{contemail}
                  . " Title="
                  . $innerletter->{title}
                  . " Content="
                  . $innerletter->{content}
            ) if C4::Context->preference("LetterLog");
        }
    }    
   # send an "account details" notice to a newly created user 
    elsif ( $type eq 'members' ) {
        $letter->{content} =~ s/<<borrowers.title>>/$externalid->{'title'}/g;
        $letter->{content} =~ s/<<borrowers.firstname>>/$externalid->{'firstname'}/g;
        $letter->{content} =~ s/<<borrowers.surname>>/$externalid->{'surname'}/g;
        $letter->{content} =~ s/<<borrowers.userid>>/$externalid->{'userid'}/g;
        $letter->{content} =~ s/<<borrowers.password>>/$externalid->{'password'}/g;

        my %mail = (
                To      =>     $externalid->{'emailaddr'},
                From    =>  C4::Context->preference("KohaAdminEmailAddress"),
                Subject => $letter->{'title'}, 
                Message => $letter->{'content'},
                'Content-Type' => 'text/plain; charset="utf8"',
        );
        sendmail(%mail) or carp $Mail::Sendmail::error;
    }
}

=head2 parseletter($letter, $table, $pk)

    parameters :
    - $letter : a hash to letter fields (title & content useful)
    - $table : the Koha table to parse.
    - $pk : the primary key to query on the $table table
    parse all fields from a table, and replace values in title & content with the appropriate value
    (not exported sub, used only internally)

=cut

our %handles = ();
our %columns = ();

sub parseletter_sth {
    my $table = shift;
    unless ($table) {
        carp "ERROR: parseletter_sth() called without argument (table)";
        return;
    }
    # check cache first
    (defined $handles{$table}) and return $handles{$table};
    my $query = 
    ($table eq 'biblio'       ) ? "SELECT * FROM $table WHERE   biblionumber = ?"                      :
    ($table eq 'biblioitems'  ) ? "SELECT * FROM $table WHERE   biblionumber = ?"                      :
    ($table eq 'items'        ) ? "SELECT * FROM $table WHERE     itemnumber = ?"                      :
    ($table eq 'suggestions'  ) ? "SELECT * FROM $table WHERE borrowernumber = ? and biblionumber = ?" :
    ($table eq 'reserves'     ) ? "SELECT * FROM $table WHERE borrowernumber = ? and biblionumber = ?" :
    ($table eq 'borrowers'    ) ? "SELECT * FROM $table WHERE borrowernumber = ?"                      :
    ($table eq 'branches'     ) ? "SELECT * FROM $table WHERE     branchcode = ?"                      :
    ($table eq 'suggestions'  ) ? "SELECT * FROM $table WHERE borrowernumber = ? and biblionumber = ?" :
    ($table eq 'aqbooksellers') ? "SELECT * FROM $table WHERE             id = ?"                      : undef ;
    unless ($query) {
        warn "ERROR: No parseletter_sth query for table '$table'";
        return;     # nothing to get
    }
    unless ($handles{$table} = C4::Context->dbh->prepare($query)) {
        warn "ERROR: Failed to prepare query: '$query'";
        return;
    }
    return $handles{$table};    # now cache is populated for that $table
}

sub parseletter {
    my ( $letter, $table, $pk, $pk2 ) = @_;
    unless ($letter) {
        carp "ERROR: parseletter() 1st argument 'letter' empty";
        return;
    }
    my $sth = parseletter_sth($table);
    unless ($sth) {
        warn "parseletter_sth('$table') failed to return a valid sth.  No substitution will be done for that table.";
        return;
    }
    if ( $pk2 ) {
        $sth->execute($pk, $pk2);
    } else {
        $sth->execute($pk);
    }

    my $values = $sth->fetchrow_hashref;
    
    # TEMPORARY hack until the expirationdate column is added to reserves
    if ( $table eq 'reserves' && $values->{'waitingdate'} ) {
        my @waitingdate = split /-/, $values->{'waitingdate'};

        $values->{'expirationdate'} = C4::Dates->new(
            sprintf(
                '%04d-%02d-%02d',
                Add_Delta_Days( @waitingdate, C4::Context->preference( 'ReservesMaxPickUpDelay' ) )
            ),
            'iso'
        )->output();
    }


    # and get all fields from the table
    my $columns = C4::Context->dbh->prepare("SHOW COLUMNS FROM $table");
    $columns->execute;
    while ( ( my $field ) = $columns->fetchrow_array ) {
        my $replacefield = "<<$table.$field>>";
        $values->{$field} =~ s/\p{P}(?=$)//g if $values->{$field};
        my $replacedby   = $values->{$field} || '';
        ($letter->{title}  ) and $letter->{title}   =~ s/$replacefield/$replacedby/g;
        ($letter->{content}) and $letter->{content} =~ s/$replacefield/$replacedby/g;
    }
    return $letter;
}

=head2 EnqueueLetter

  my $success = EnqueueLetter( { letter => $letter, 
        borrowernumber => '12', message_transport_type => 'email' } )

places a letter in the message_queue database table, which will
eventually get processed (sent) by the process_message_queue.pl
cronjob when it calls SendQueuedMessages.

return true on success

=cut

sub EnqueueLetter ($) {
    my $params = shift or return undef;

    return unless exists $params->{'letter'};
    return unless exists $params->{'borrowernumber'};
    return unless exists $params->{'message_transport_type'};

    # If we have any attachments we should encode then into the body.
    if ( $params->{'attachments'} ) {
        $params->{'letter'} = _add_attachments(
            {   letter      => $params->{'letter'},
                attachments => $params->{'attachments'},
                message     => MIME::Lite->new( Type => 'multipart/mixed' ),
            }
        );
    }

    my $dbh       = C4::Context->dbh();
    my $statement = << 'ENDSQL';
INSERT INTO message_queue
( borrowernumber, subject, content, metadata, letter_code, message_transport_type, status, time_queued, to_address, from_address, content_type )
VALUES
( ?,              ?,       ?,       ?,        ?,           ?,                      ?,      NOW(),       ?,          ?,            ? )
ENDSQL

    my $sth    = $dbh->prepare($statement);
    my $result = $sth->execute(
        $params->{'borrowernumber'},              # borrowernumber
        $params->{'letter'}->{'title'},           # subject
        $params->{'letter'}->{'content'},         # content
        $params->{'letter'}->{'metadata'} || '',  # metadata
        $params->{'letter'}->{'code'}     || '',  # letter_code
        $params->{'message_transport_type'},      # message_transport_type
        'pending',                                # status
        $params->{'to_address'},                  # to_address
        $params->{'from_address'},                # from_address
        $params->{'letter'}->{'content-type'},    # content_type
    );
    return $result;
}

=head2 SendQueuedMessages ([$hashref]) 

  my $sent = SendQueuedMessages( { verbose => 1 } );

sends all of the 'pending' items in the message queue.

returns number of messages sent.

=cut

sub SendQueuedMessages (;$) {
    my $params = shift;

    my $unsent_messages = _get_unsent_messages();
    MESSAGE: foreach my $message ( @$unsent_messages ) {
        # warn Data::Dumper->Dump( [ $message ], [ 'message' ] );
        warn sprintf( 'sending %s message to patron: %s',
                      $message->{'message_transport_type'},
                      $message->{'borrowernumber'} || 'Admin' )
          if $params->{'verbose'} or $debug;
        # This is just begging for subclassing
        next MESSAGE if ( lc($message->{'message_transport_type'}) eq 'rss' );
        if ( lc( $message->{'message_transport_type'} ) eq 'email' ) {
            _send_message_by_email( $message );
        }
        elsif ( lc( $message->{'message_transport_type'} ) eq 'sms' ) {
            _send_message_by_sms( $message );
        }
    }
    return scalar( @$unsent_messages );
}

=head2 GetRSSMessages

  my $message_list = GetRSSMessages( { limit => 10, borrowernumber => '14' } )

returns a listref of all queued RSS messages for a particular person.

=cut

sub GetRSSMessages {
    my $params = shift;

    return unless $params;
    return unless ref $params;
    return unless $params->{'borrowernumber'};
    
    return _get_unsent_messages( { message_transport_type => 'rss',
                                   limit                  => $params->{'limit'},
                                   borrowernumber         => $params->{'borrowernumber'}, } );
}

=head2 GetPrintMessages

  my $message_list = GetPrintMessages( { borrowernumber => $borrowernumber } )

Returns a arrayref of all queued print messages (optionally, for a particular
person).

=cut

sub GetPrintMessages {
    my $params = shift || {};
    
    return _get_unsent_messages( { message_transport_type => 'print',
                                   borrowernumber         => $params->{'borrowernumber'}, } );
}

=head2 GetQueuedMessages ([$hashref])

  my $messages = GetQueuedMessage( { borrowernumber => '123', limit => 20 } );

fetches messages out of the message queue.

returns:
list of hashes, each has represents a message in the message queue.

=cut

sub GetQueuedMessages {
    my $params = shift;

    my $dbh = C4::Context->dbh();
    my $statement = << 'ENDSQL';
SELECT message_id, borrowernumber, subject, content, message_transport_type, status, time_queued
FROM message_queue
ENDSQL

    my @query_params;
    my @whereclauses;
    if ( exists $params->{'borrowernumber'} ) {
        push @whereclauses, ' borrowernumber = ? ';
        push @query_params, $params->{'borrowernumber'};
    }

    if ( @whereclauses ) {
        $statement .= ' WHERE ' . join( 'AND', @whereclauses );
    }

    if ( defined $params->{'limit'} ) {
        $statement .= ' LIMIT ? ';
        push @query_params, $params->{'limit'};
    }

    my $sth = $dbh->prepare( $statement );
    my $result = $sth->execute( @query_params );
    return $sth->fetchall_arrayref({});
}

=head2 _add_attachements

named parameters:
letter - the standard letter hashref
attachments - listref of attachments. each attachment is a hashref of:
  type - the mime type, like 'text/plain'
  content - the actual attachment
  filename - the name of the attachment.
message - a MIME::Lite object to attach these to.

returns your letter object, with the content updated.

=cut

sub _add_attachments {
    my $params = shift;

    return unless 'HASH' eq ref $params;
    foreach my $required_parameter (qw( letter attachments message )) {
        return unless exists $params->{$required_parameter};
    }
    return $params->{'letter'} unless @{ $params->{'attachments'} };

    # First, we have to put the body in as the first attachment
    $params->{'message'}->attach(
        Type => 'TEXT',
        Data => $params->{'letter'}->{'content'},
    );

    foreach my $attachment ( @{ $params->{'attachments'} } ) {
        $params->{'message'}->attach(
            Type     => $attachment->{'type'},
            Data     => $attachment->{'content'},
            Filename => $attachment->{'filename'},
        );
    }
    # we're forcing list context here to get the header, not the count back from grep.
    ( $params->{'letter'}->{'content-type'} ) = grep( /^Content-Type:/, split( /\n/, $params->{'message'}->header_as_string ) );
    $params->{'letter'}->{'content-type'} =~ s/^Content-Type:\s+//;
    $params->{'letter'}->{'content'} = $params->{'message'}->body_as_string;

    return $params->{'letter'};

}

sub _get_unsent_messages (;$) {
    my $params = shift;

    my $dbh = C4::Context->dbh();
    my $statement = << 'ENDSQL';
SELECT message_id, borrowernumber, subject, content, message_transport_type, status, time_queued, from_address, to_address, content_type
  FROM message_queue
 WHERE status = ?
ENDSQL

    my @query_params = ('pending');
    if ( ref $params ) {
        if ( $params->{'message_transport_type'} ) {
            $statement .= ' AND message_transport_type = ? ';
            push @query_params, $params->{'message_transport_type'};
        }
        if ( $params->{'borrowernumber'} ) {
            $statement .= ' AND borrowernumber = ? ';
            push @query_params, $params->{'borrowernumber'};
        }
        if ( $params->{'limit'} ) {
            $statement .= ' limit ? ';
            push @query_params, $params->{'limit'};
        }
    }
    $debug and warn "_get_unsent_messages SQL: $statement";
    $debug and warn "_get_unsent_messages params: " . join(',',@query_params);
    my $sth = $dbh->prepare( $statement );
    my $result = $sth->execute( @query_params );
    return $sth->fetchall_arrayref({});
}

sub _send_message_by_email ($;$$$) {
    my $message = shift or return;

    my $to_address = $message->{to_address};
    unless ($to_address) {
        my $member = C4::Members::GetMember( 'borrowernumber' => $message->{'borrowernumber'} );
        unless ($member) {
            warn "FAIL: No 'to_address' and INVALID borrowernumber ($message->{borrowernumber})";
            _set_message_status( { message_id => $message->{'message_id'},
                                   status     => 'failed' } );
            return;
        }
        my $which_address = C4::Context->preference('AutoEmailPrimaryAddress');
        # If the system preference is set to 'first valid' (value == OFF), look up email address
        if ($which_address eq 'OFF') {
            $to_address = GetFirstValidEmailAddress( $message->{'borrowernumber'} );
        } else {
            $to_address = $member->{$which_address};
        }
        unless ($to_address) {  
            # warn "FAIL: No 'to_address' and no email for " . ($member->{surname} ||'') . ", borrowernumber ($message->{borrowernumber})";
            # warning too verbose for this more common case?
            _set_message_status( { message_id => $message->{'message_id'},
                                   status     => 'failed' } );
            return;
        }
    }

	my $content = encode('utf8', $message->{'content'});
    my %sendmail_params = (
        To   => $to_address,
        From => $message->{'from_address'} || C4::Context->preference('KohaAdminEmailAddress'),
        Subject => $message->{'subject'},
        charset => 'utf8',
        Message => $content,
        'content-type' => $message->{'content_type'} || 'text/plain; charset="UTF-8"',
    );
    if ( my $bcc = C4::Context->preference('OverdueNoticeBcc') ) {
       $sendmail_params{ Bcc } = $bcc;
    }
    

    if ( sendmail( %sendmail_params ) ) {
        _set_message_status( { message_id => $message->{'message_id'},
                status     => 'sent' } );
        return 1;
    } else {
        _set_message_status( { message_id => $message->{'message_id'},
                status     => 'failed' } );
        carp $Mail::Sendmail::error;
        return;
    }
}

sub _send_message_by_sms ($) {
    my $message = shift or return undef;
    my $member = C4::Members::GetMember( 'borrowernumber' => $message->{'borrowernumber'} );
    return unless $member->{'smsalertnumber'};

    my $success = C4::SMS->send_sms( { destination => $member->{'smsalertnumber'},
                                       message     => $message->{'content'},
                                     } );
    _set_message_status( { message_id => $message->{'message_id'},
                           status     => ($success ? 'sent' : 'failed') } );
    return $success;
}

sub _set_message_status ($) {
    my $params = shift or return undef;

    foreach my $required_parameter ( qw( message_id status ) ) {
        return undef unless exists $params->{ $required_parameter };
    }

    my $dbh = C4::Context->dbh();
    my $statement = 'UPDATE message_queue SET status= ? WHERE message_id = ?';
    my $sth = $dbh->prepare( $statement );
    my $result = $sth->execute( $params->{'status'},
                                $params->{'message_id'} );
    return $result;
}


1;
__END__
