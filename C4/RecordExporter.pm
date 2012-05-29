package C4::RecordExporter;

# Copyright 2012 Catalyst IT Limited
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
use C4::Context;
use File::Temp qw/ tempfile /;
use C4::Context;
use C4::Biblio;
use C4::Record;
use MIME::Lite;

use vars qw($VERSION @ISA @EXPORT);

BEGIN {

    # set the version for version checking
    $VERSION = 3.01;
    require Exporter;
    @ISA    = qw(Exporter);
    @EXPORT = qw(&export_and_mail_new
    export_and_mail_deleted);
}

=head1 NAME

C4::ExportRecord - Koha module for dealing with exporting records to a file

=head1 SYNOPSIS

  use C4::ExportRecord;

=head1 DESCRIPTION

The functions in this module deal with creating and emailing marc files

=head1 FUNCTIONS

=cut

=head2 export_and_mail_new

  export_and_mail_new($date,$to,$verbose, $export_items)

Given a date and an email address this will export all records created since the date
and mail them as an attachment to the $to address

=cut

sub export_and_mail_new {
    my ( $date, $to, $verbose, $export_items ) = @_;
    return unless $to;    # bail if we have no email address
    my $filename = export_newrecords($date, $verbose, $export_items);
    my $subject = "Records created since $date";
    _mail( $filename, $to ,$subject);
}

=head2 export_and_mail_deleted

  export_and_mail_deleted($date,$address,$verbose,$lost);

Given a date and a mailing address this will export all biblio deleted since the date
and mail them to the address. If $lost is set, it will also include all biblio who have all their items lost

=cut

sub export_and_mail_deleted {
    my ($date,$to,$verbose,$lost) = @_;
    return unless $to;
    my $filename = export_deletedrecords ($date,$verbose,$lost);
    my $subject = "Records deleted since $date";
    _mail( $filename, $to, $subject);
}

=head2 export_newcords {

  my $filename = export_newrecords($date,$verbose, $export_items);

Given a date, it will export all records created since then to a temp file and return the filename of
the file. If export_items is set it will attach the item data also

=cut

sub export_newrecords {
    my ($date,$verbose, $export_items)    = @_;
    my $context = C4::Context->new();
    my $dbh     = $context->dbh();

    my $query = "SELECT biblionumber FROM biblio WHERE datecreated >= ?";
    my $sth   = $dbh->prepare($query);
    $sth->execute($date)
      || die $sth->err_str;  # no point trying to do anything else, bail out now
    my ( $fh, $filename ) = tempfile();
    binmode( $fh, ":encoding(UTF-8)" );
    while ( my $biblionumber = $sth->fetchrow_hashref() ) {
        my $record;
        eval { $record = GetMarcBiblio( $biblionumber->{'biblionumber'} ); };

     # FIXME: decide how to handle records GetMarcBiblio can't parse or retrieve
        if ($@) {
            print "Biblio number "
              . $biblionumber->{'biblionumber'}
              . " can not be retrieved $@ \n"
              if $verbose;
            next;
        }
        if ( not defined $record ) {
            print "Biblio number "
              . $biblionumber->{'biblionumber'}
              . " can not be retrieved \n"
              if $verbose;
            next;
        }
        C4::Biblio::EmbedItemsInMarcBiblio( $record, $biblionumber )
          if $export_items;

        #         if ( $output_format eq "xml" ) {
        #                         print $record->as_xml_record($marcflavour);
        #                     }
        #               else {
        print $fh $record->as_usmarc();

        #                           }

    }
    return $filename;
}

=head2 export_deletedcords {

  my $filename = export_deletedrecords ($date,$verbose,$lost);

Given a date, it will export all records deleted since then to a temp file and return the filename of
the file. If $lost is set it will also export those with all items marked lost

=cut

sub export_deletedrecords {
    my ($date,$verbose, $export_items)    = @_;
    my $context = C4::Context->new();
    my $dbh     = $context->dbh();

    my $query = "SELECT biblionumber,marcxml FROM deletedbiblioitems WHERE timestamp >= ?";


    my $sth   = $dbh->prepare($query);
    $sth->execute($date)
      || die $sth->err_str;  # no point trying to do anything else, bail out now
    my ( $fh, $filename ) = tempfile();
    binmode( $fh, ":encoding(UTF-8)" );
    while ( my $biblio = $sth->fetchrow_hashref() ) {
	my ($error,$record) = marcxml2marc($biblio->{'marcxml'},'UTF-8');
        #         if ( $output_format eq "xml" ) {
        #                         print $record->as_xml_record($marcflavour);
        #                     }
        #               else {
        print $fh $record->as_usmarc();
        # }
    }
    return $filename;
}

sub _mail {
    my ( $filename, $to, $subject ) = @_;
    my $context = C4::Context->new();
    my $msg = MIME::Lite->new(
        From    => $context->preference('KohaAdminEmailAddress'),
        To      => $to,
        Subject => $subject,
        Type    => 'multipart/mixed',
    );
    $msg->attach(
        Type => 'TEXT',
        Data => 'Here is the MARC file'
    );
    $msg->attach(
        Type        => 'bin',
        Path        => $filename,
        Filename    => 'Koha.marc',
        Disposition => 'attachement'
    );
    $msg->send_by_sendmail(FromSender => $context->preference('KohaAdminEmailAddress'))
}

1;
__END__

=head1 AUTHOR

Koha Development Team <http://koha-community.org/>

=head1 SEE ALSO

C4::Biblio(3)

=cut
