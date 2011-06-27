#!/usr/bin/perl

# Copyright 2009 SARL Biblibre
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

use CGI;
use Encode qw(encode);
use Carp;

use Mail::Sendmail;
use MIME::QuotedPrint;
use MIME::Base64;
use C4::Auth;
use C4::Biblio;
use C4::Items;
use C4::Output;
use C4::VirtualShelves;
use C4::Members;

my $query = new CGI;

my ( $template, $borrowernumber, $cookie ) = get_template_and_user (
    {
        template_name   => "opac-sendshelfform.tmpl",
        query           => $query,
        type            => "opac",
        authnotrequired => 1,
        flagsrequired   => { borrow => 1 },
    }
);

my $shelfid = $query->param('shelfid');
my $email   = $query->param('email');

my $dbh          = C4::Context->dbh;

if ( ShelfPossibleAction( (defined($borrowernumber) ? $borrowernumber : -1), $shelfid, 'view' ) ) {

if ( $email ) {
    my $email_from = C4::Context->preference('KohaAdminEmailAddress');
    my $comment    = $query->param('comment');

    my %mail = (
        To   => $email,
        From => $email_from
    );

    my ( $template2, $borrowernumber, $cookie ) = get_template_and_user(
        {
            template_name   => "opac-sendshelf.tmpl",
            query           => $query,
            type            => "opac",
            authnotrequired => 1,
            flagsrequired   => { borrow => 1 },
        }
    );

    my @shelf               = GetShelf($shelfid);
    my ($items, $totitems)  = GetShelfContents($shelfid);
    my $marcflavour         = C4::Context->preference('marcflavour');
    my $iso2709;
    my @results;

    # retrieve biblios from shelf
    foreach my $biblio (@$items) {
        my $biblionumber = $biblio->{biblionumber};

        my $dat              = GetBiblioData($biblionumber);
        my $record           = GetMarcBiblio($biblionumber);
        my $marcnotesarray   = GetMarcNotes( $record, $marcflavour );
        my $marcauthorsarray = GetMarcAuthors( $record, $marcflavour );
        my $marcsubjctsarray = GetMarcSubjects( $record, $marcflavour );

        my @items = GetItemsInfo( $biblionumber );

        $dat->{MARCNOTES}      = $marcnotesarray;
        $dat->{MARCSUBJCTS}    = $marcsubjctsarray;
        $dat->{MARCAUTHORS}    = $marcauthorsarray;
        $dat->{'biblionumber'} = $biblionumber;
        $dat->{ITEM_RESULTS}   = \@items;

        $iso2709 .= $record->as_usmarc();

        push( @results, $dat );
    }

    my $user = GetMember(borrowernumber => $borrowernumber); 

    $template2->param(
        BIBLIO_RESULTS => \@results,
        email_sender   => $email_from,
        comment        => $comment,
        shelfname      => $shelf[1],
        firstname      => $user->{firstname},
        surname        => $user->{surname},
    );

    # Getting template result
    my $template_res = $template2->output();
    my $body;

    # Analysing information and getting mail properties
    if ( $template_res =~ /<SUBJECT>\n(.*)\n<END_SUBJECT>/s ) {
        $mail{'subject'} = $1;
    }
    else { $mail{'subject'} = "no subject"; }

    my $email_header = "";
    if ( $template_res =~ /<HEADER>\n(.*)\n<END_HEADER>/s ) {
        $email_header = $1;
    }

    my $email_file = "basket.txt";
    if ( $template_res =~ /<FILENAME>\n(.*)\n<END_FILENAME>/s ) {
        $email_file = $1;
    }

    if ( $template_res =~ /<MESSAGE>\n(.*)\n<END_MESSAGE>/s ) { $body = encode_qp($1); }

    my $boundary = "====" . time() . "====";

    # We set and put the multipart content
    $mail{'content-type'} = "multipart/mixed; boundary=\"$boundary\"";

    my $isofile = encode_base64(encode("UTF-8", $iso2709));
    $boundary = '--' . $boundary;

    $mail{body} = <<END_OF_BODY;
$boundary
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: quoted-printable

$email_header
$body
$boundary
Content-Type: application/octet-stream; name="shelf.iso2709"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="shelf.iso2709"

$isofile
$boundary--
END_OF_BODY

    # Sending mail
    if ( sendmail %mail ) {
        # do something if it works....
        $template->param( SENT      => "1" );
    }
    else {
        # do something if it doesnt work....
        carp "Error sending mail: $Mail::Sendmail::error \n";
        $template->param( error => 1 );
    }

    $template->param( email => $email );
    output_html_with_http_headers $query, $cookie, $template->output;


}else{
    $template->param( shelfid => $shelfid,
                      url     => "/cgi-bin/koha/opac-sendshelf.pl",
                    );
    output_html_with_http_headers $query, $cookie, $template->output;
}

} else {
    $template->param( invalidlist => 1,
                      url     => "/cgi-bin/koha/opac-sendshelf.pl",
    );
    output_html_with_http_headers $query, $cookie, $template->output;
}