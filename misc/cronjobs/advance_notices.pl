#!/usr/bin/perl

# Copyright 2008 LibLime
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

advance_notices.pl - cron script to put item due reminders into message queue

=head1 SYNOPSIS

./advance_notices.pl -c

or, in crontab:
0 1 * * * advance_notices.pl -c

=head1 DESCRIPTION

This script prepares pre-due and item due reminders to be sent to
patrons. It queues them in the message queue, which is processed by
the process_message_queue.pl cronjob. The type and timing of the
messages can be configured by the patrons in their "My Alerts" tab in
the OPAC.

=cut

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
BEGIN {
    # find Koha's Perl modules
    # test carefully before changing this
    use FindBin;
    eval { require "$FindBin::Bin/../kohalib.pl" };
}
use C4::Biblio;
use C4::Context;
use C4::Letters;
use C4::Members;
use C4::Members::Messaging;
use C4::Overdues;
use C4::Dates qw/format_date/;


# These are defaults for command line options.
my $confirm;                                                        # -c: Confirm that the user has read and configured this script.
# my $confirm     = 1;                                                # -c: Confirm that the user has read and configured this script.
my $nomail;                                                         # -n: No mail. Will not send any emails.
my $mindays     = 0;                                                # -m: Maximum number of days in advance to send notices
my $maxdays     = 30;                                               # -e: the End of the time period
my $fromaddress = C4::Context->preference('KohaAdminEmailAddress'); # -f: From address for the emails
my $verbose     = 0;                                                # -v: verbose
my $itemscontent = join(',',qw( issuedate title barcode author ));

GetOptions( 'c'              => \$confirm,
            'n'              => \$nomail,
            'm:i'            => \$maxdays,
            'f:s'            => \$fromaddress,
            'v'              => \$verbose,
            'itemscontent=s' => \$itemscontent,
       );
my $usage = << 'ENDUSAGE';

This script prepares pre-due and item due reminders to be sent to
patrons. It queues them in the message queue, which is processed by
the process_message_queue.pl cronjob.
See the comments in the script for directions on changing the script.
This script has the following parameters :
	-c Confirm and remove this help & warning
        -m maximum number of days in advance to send advance notices.
        -f from address for the emails. Defaults to KohaAdminEmailAddress system preference
	-n send No mail. Instead, all mail messages are printed on screen. Usefull for testing purposes.
        -v verbose
        -i csv list of fields that get substituted into templates in places
           of the E<lt>E<lt>items.contentE<gt>E<gt> placeholder.  Defaults to
           issuedate,title,barcode,author
ENDUSAGE

# Since advance notice options are not visible in the web-interface
# unless EnhancedMessagingPreferences is on, let the user know that
# this script probably isn't going to do much
if ( ! C4::Context->preference('EnhancedMessagingPreferences') ) {
    warn <<'END_WARN';

The "EnhancedMessagingPreferences" syspref is off.
Therefore, it is unlikely that this script will actually produce any messages to be sent.
To change this, edit the "EnhancedMessagingPreferences" syspref.

END_WARN
}

unless ($confirm) {
    print $usage;
    print "Do you wish to continue? (y/n)";
    chomp($_ = <STDIN>);
    exit unless (/^y/i);
	
}

# The fields that will be substituted into <<items.content>>
my @item_content_fields = split(/,/,$itemscontent);

warn 'getting upcoming due issues' if $verbose;
my $upcoming_dues = C4::Circulation::GetUpcomingDueIssues( { days_in_advance => $maxdays } );
warn 'found ' . scalar( @$upcoming_dues ) . ' issues' if $verbose;

# hash of borrowernumber to number of items upcoming
# for patrons wishing digests only.
my $upcoming_digest;
my $due_digest;

my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare(<<'END_SQL');
SELECT biblio.*, items.*, issues.*
  FROM issues,items,biblio
  WHERE items.itemnumber=issues.itemnumber
    AND biblio.biblionumber=items.biblionumber
    AND issues.borrowernumber = ?
    AND issues.itemnumber = ?
    AND (TO_DAYS(date_due)-TO_DAYS(NOW()) = ?)
END_SQL

UPCOMINGITEM: foreach my $upcoming ( @$upcoming_dues ) {
    warn 'examining ' . $upcoming->{'itemnumber'} . ' upcoming due items' if $verbose;
    # warn( Data::Dumper->Dump( [ $upcoming ], [ 'overdue' ] ) );

    my $letter;
    my $borrower_preferences;
    if ( 0 == $upcoming->{'days_until_due'} ) {
        # This item is due today. Send an 'item due' message.
        $borrower_preferences = C4::Members::Messaging::GetMessagingPreferences( { borrowernumber => $upcoming->{'borrowernumber'},
                                                                                   message_name   => 'item due' } );
        # warn( Data::Dumper->Dump( [ $borrower_preferences ], [ 'borrower_preferences' ] ) );
        next DUEITEM unless $borrower_preferences;
        
        if ( $borrower_preferences->{'wants_digest'} ) {
            # cache this one to process after we've run through all of the items.
            $due_digest->{$upcoming->{'borrowernumber'}}++;
        } else {
            my $biblio = C4::Biblio::GetBiblioFromItemNumber( $upcoming->{'itemnumber'} );
            my $letter_type = 'DUE';
            $letter = C4::Letters::getletter( 'circulation', $letter_type );
            die "no letter of type '$letter_type' found. Please see sample_notices.sql" unless $letter;
            $sth->execute($upcoming->{'borrowernumber'},$upcoming->{'itemnumber'},'0');
            my $titles = "";
            while ( my $item_info = $sth->fetchrow_hashref()) {
              my @item_info = map { $_ =~ /^date|date$/ ? format_date($item_info->{$_}) : $item_info->{$_} || '' } @item_content_fields;
              $titles .= join("\t",@item_info) . "\n";
            }
        
            $letter = parse_letter( { letter         => $letter,
                                      borrowernumber => $upcoming->{'borrowernumber'},
                                      branchcode     => $upcoming->{'branchcode'},
                                      biblionumber   => $biblio->{'biblionumber'},
                                      substitute     => { 'items.content' => $titles }
                                    } );
        }
    } else {
        $borrower_preferences = C4::Members::Messaging::GetMessagingPreferences( { borrowernumber => $upcoming->{'borrowernumber'},
                                                                                   message_name   => 'advance notice' } );
        # warn( Data::Dumper->Dump( [ $borrower_preferences ], [ 'borrower_preferences' ] ) );
        next UPCOMINGITEM unless $borrower_preferences && exists $borrower_preferences->{'days_in_advance'};
        next UPCOMINGITEM unless $borrower_preferences->{'days_in_advance'} == $upcoming->{'days_until_due'};

        if ( $borrower_preferences->{'wants_digest'} ) {
            # cache this one to process after we've run through all of the items.
            $upcoming_digest->{$upcoming->{'borrowernumber'}}++;
        } else {
            my $biblio = C4::Biblio::GetBiblioFromItemNumber( $upcoming->{'itemnumber'} );
            my $letter_type = 'PREDUE';
            $letter = C4::Letters::getletter( 'circulation', $letter_type );
            die "no letter of type '$letter_type' found. Please see sample_notices.sql" unless $letter;
            $sth->execute($upcoming->{'borrowernumber'},$upcoming->{'itemnumber'},$maxdays);
            my $titles = "";
            while ( my $item_info = $sth->fetchrow_hashref()) {
              my @item_info = map { $_ =~ /^date|date$/ ? format_date($item_info->{$_}) : $item_info->{$_} || '' } @item_content_fields;
              $titles .= join("\t",@item_info) . "\n";
            }
        
            $letter = parse_letter( { letter         => $letter,
                                      borrowernumber => $upcoming->{'borrowernumber'},
                                      branchcode     => $upcoming->{'branchcode'},
                                      biblionumber   => $biblio->{'biblionumber'},
                                      substitute     => { 'items.content' => $titles }
                                    } );
        }
    }

    # If we have prepared a letter, send it.
    if ($letter) {
      if ($nomail) {
        local $, = "\f";
        print $letter->{'content'};
      }
      else {
        foreach my $transport ( @{$borrower_preferences->{'transports'}} ) {
            C4::Letters::EnqueueLetter( { letter                 => $letter,
                                          borrowernumber         => $upcoming->{'borrowernumber'},
                                          message_transport_type => $transport } );
        }
      }
    }
}


# warn( Data::Dumper->Dump( [ $upcoming_digest ], [ 'upcoming_digest' ] ) );

# Now, run through all the people that want digests and send them

$sth = $dbh->prepare(<<'END_SQL');
SELECT biblio.*, items.*, issues.*
  FROM issues,items,biblio
  WHERE items.itemnumber=issues.itemnumber
    AND biblio.biblionumber=items.biblionumber
    AND issues.borrowernumber = ?
    AND (TO_DAYS(date_due)-TO_DAYS(NOW()) = ?)
END_SQL

PATRON: while ( my ( $borrowernumber, $count ) = each %$upcoming_digest ) {
    my $borrower_preferences = C4::Members::Messaging::GetMessagingPreferences( { borrowernumber => $borrowernumber,
                                                                                  message_name   => 'advance notice' } );
    # warn( Data::Dumper->Dump( [ $borrower_preferences ], [ 'borrower_preferences' ] ) );
    next PATRON unless $borrower_preferences; # how could this happen?


    my $letter_type = 'PREDUEDGST';
    my $letter = C4::Letters::getletter( 'circulation', $letter_type );
    die "no letter of type '$letter_type' found. Please see sample_notices.sql" unless $letter;
    $sth->execute($borrowernumber,$maxdays);
    my $titles = "";
    while ( my $item_info = $sth->fetchrow_hashref()) {
      my @item_info = map { $_ =~ /^date|date$/ ? format_date($item_info->{$_}) : $item_info->{$_} || '' } @item_content_fields;
      $titles .= join("\t",@item_info) . "\n";
    }
    $letter = parse_letter( { letter         => $letter,
                              borrowernumber => $borrowernumber,
                              substitute     => { count => $count,
                                                  'items.content' => $titles
                                                }
                         } );
    if ($nomail) {
      local $, = "\f";
      print $letter->{'content'};
    }
    else {
      foreach my $transport ( @{$borrower_preferences->{'transports'}} ) {
        C4::Letters::EnqueueLetter( { letter                 => $letter,
                                      borrowernumber         => $borrowernumber,
                                      message_transport_type => $transport } );
      }
    }
}

# Now, run through all the people that want digests and send them
PATRON: while ( my ( $borrowernumber, $count ) = each %$due_digest ) {
    my $borrower_preferences = C4::Members::Messaging::GetMessagingPreferences( { borrowernumber => $borrowernumber,
                                                                                  message_name   => 'item due' } );
    # warn( Data::Dumper->Dump( [ $borrower_preferences ], [ 'borrower_preferences' ] ) );
    next PATRON unless $borrower_preferences; # how could this happen?

    my $letter_type = 'DUEDGST';
    my $letter = C4::Letters::getletter( 'circulation', $letter_type );
    die "no letter of type '$letter_type' found. Please see sample_notices.sql" unless $letter;
    $sth->execute($borrowernumber,'0');
    my $titles = "";
    while ( my $item_info = $sth->fetchrow_hashref()) {
      my @item_info = map { $_ =~ /^date|date$/ ? format_date($item_info->{$_}) : $item_info->{$_} || '' } @item_content_fields;
      $titles .= join("\t",@item_info) . "\n";
    }
    $letter = parse_letter( { letter         => $letter,
                              borrowernumber => $borrowernumber,
                              substitute     => { count => $count,
                                                  'items.content' => $titles
                                                }
                         } );

    if ($nomail) {
      local $, = "\f";
      print $letter->{'content'};
    }
    else {
      foreach my $transport ( @{$borrower_preferences->{'transports'}} ) {
        C4::Letters::EnqueueLetter( { letter                 => $letter,
                                      borrowernumber         => $borrowernumber,
                                      message_transport_type => $transport } );
      }
    }
}

=head1 METHODS

=head2 parse_letter



=cut

sub parse_letter {
    my $params = shift;
    foreach my $required ( qw( letter borrowernumber ) ) {
        return unless exists $params->{$required};
    }

    if ( $params->{'substitute'} ) {
        while ( my ($key, $replacedby) = each %{$params->{'substitute'}} ) {
            my $replacefield = "<<$key>>";
            
            $params->{'letter'}->{title}   =~ s/$replacefield/$replacedby/g;
            $params->{'letter'}->{content} =~ s/$replacefield/$replacedby/g;
        }
    }

    C4::Letters::parseletter( $params->{'letter'}, 'borrowers',   $params->{'borrowernumber'} );

    if ( $params->{'branchcode'} ) {
        C4::Letters::parseletter( $params->{'letter'}, 'branches',    $params->{'branchcode'} );
    }
    
    if ( $params->{'biblionumber'} ) {
        C4::Letters::parseletter( $params->{'letter'}, 'biblio',      $params->{'biblionumber'} );
        C4::Letters::parseletter( $params->{'letter'}, 'biblioitems', $params->{'biblionumber'} );
    }

    return $params->{'letter'};
}

1;

__END__
