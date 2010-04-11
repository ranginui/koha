#!/usr/bin/perl

# This is a completely new Z3950 clients search using async ZOOM -TG 02/11/06
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

use warnings;
use strict;
use CGI;

use C4::Auth;
use C4::Output;
use C4::Biblio;
use C4::Context;
use C4::Breeding;
use C4::Koha;
use C4::Charset;
use ZOOM;

my $input        = new CGI;
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "acqui/z3950_search.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 1,
        flagsrequired   => { acquisition => 'order_manage' },
        debug           => 1,
    }
);

my $dbh          = C4::Context->dbh;
my $error        = $input->param('error');
my $biblionumber = $input->param('biblionumber');
$biblionumber = 0 unless $biblionumber;
my $frameworkcode = $input->param('frameworkcode');
warn($frameworkcode);
my $title         = $input->param('title');
my $author        = $input->param('author');
my $isbn          = $input->param('isbn');
my $issn          = $input->param('issn');
my $lccn          = $input->param('lccn');
my $subject= $input->param('subject');
my $dewey = $input->param('dewey');
my $op            = $input->param('op');
my $booksellerid = $input->param('booksellerid');
my $basketno = $input->param('basketno');
my $noconnection;
my $numberpending;
my $attr = '';
my $term;
my $host;
my $server;
my $database;
my $port;
my $marcdata;
my @encoding;
my @results;
my $count;
my $toggle;
my $record;
my $oldbiblio;
my $errmsg;
my @serverhost;
my @servername;
my @breeding_loop = ();
my $random        = $input->param('random');
unless ($random)
{    # this var is not useful anymore just kept to keep rel2_2 compatibility
    $random = rand(1000000000);
}

my $DEBUG = 0;    # if set to 1, many debug message are send on syslog.

# get framework list
my $frameworks = getframeworks;
my @frameworkcodeloop;
foreach my $thisframeworkcode ( keys %$frameworks ) {
    my %row = (
        value         => $thisframeworkcode,
        frameworktext => $frameworks->{$thisframeworkcode}->{'frameworktext'},
    );
    if ( %row->{'value'} eq $frameworkcode){
        %row->{'active'} = 'true';
    }
    push @frameworkcodeloop, \%row;
}

$template->param( frameworkcode => $frameworkcode, 
                                    frameworkcodeloop => \@frameworkcodeloop,
                                    booksellerid => $booksellerid,
                                    basketno => $basketno);


if ( $op ne "do_search" ) {
    my $sth = $dbh->prepare("select id,host,name,checked from z3950servers  order by host");
    $sth->execute();
    my $serverloop = $sth->fetchall_arrayref( {} );
    $template->param(
        isbn         => $isbn,
        issn         => $issn,
        lccn         => $lccn,
        title        => $title,
        author       => $author,
        serverloop   => $serverloop,
        opsearch     => "search",
        biblionumber => $biblionumber,
    );
    output_html_with_http_headers $input, $cookie, $template->output;
}
else {
    my @id = $input->param('id');
    my @oConnection;
    my @oResult;
    my $s = 0;
    my $query;
    my $nterms;
    if ($isbn || $issn) {
        $term=$isbn if ($isbn);
        $term=$issn if ($issn);
        $query .= " \@or \@attr 1=8 \"$term\" \@attr 1=7 \"$term\" ";
        $nterms++;
    }
    if ($title) {
        utf8::decode($title);
        $query .= " \@attr 1=4 \"$title\" ";
        $nterms++;
    }
    if ($author) {
        utf8::decode($author);
        $query .= " \@attr 1=1003 \"$author\" ";
        $nterms++;
    }
    if ($dewey) {
        $query .= " \@attr 1=16 \"$dewey\" ";
        $nterms++;
    }
    if ($subject) {
        utf8::decode($subject);
        $query .= " \@attr 1=21 \"$subject\" ";
        $nterms++;
    }
	if ($lccn) {	
        $query .= " \@attr 1=9 $lccn ";
        $nterms++;
    }
for my $i (1..$nterms-1) {
    $query = "\@and " . $query;
}
warn "query ".$query  if $DEBUG;

    foreach my $servid (@id) {
        my $sth = $dbh->prepare("select * from z3950servers where id=?");
        $sth->execute($servid);
        while ( $server = $sth->fetchrow_hashref ) {
            warn "serverinfo ".join(':',%$server) if $DEBUG;
            my $noconnection = 0;
            my $option1      = new ZOOM::Options();
            $option1->option( 'async' => 1 );
            $option1->option( 'elementSetName', 'F' );
            $option1->option( 'databaseName',   $server->{db} );
            $option1->option( 'user', $server->{userid} ) if $server->{userid};
            $option1->option( 'password', $server->{password} )
              if $server->{password};
            $option1->option( 'preferredRecordSyntax', $server->{syntax} );
            $oConnection[$s] = create ZOOM::Connection($option1)
              || $DEBUG
              && warn( "" . $oConnection[$s]->errmsg() );
            warn( "server data", $server->{name}, $server->{port} ) if $DEBUG;
            $oConnection[$s]->connect( $server->{host}, $server->{port} )
              || $DEBUG
              && warn( "" . $oConnection[$s]->errmsg() );
            $serverhost[$s] = $server->{host};
            $servername[$s] = $server->{name};
            $encoding[$s]   = ($server->{encoding}?$server->{encoding}:"iso-5426");
            $s++;
        }    ## while fetch
    }    # foreach
    my $nremaining  = $s;
    my $firstresult = 1;

    for ( my $z = 0 ; $z < $s ; $z++ ) {
        warn "doing the search" if $DEBUG;
        $oResult[$z] = $oConnection[$z]->search_pqf($query)
          || $DEBUG
          && warn( "somthing went wrong: " . $oConnection[$s]->errmsg() );

        # $oResult[$z] = $oConnection[$z]->search_pqf($query);
    }

sub displayresults {
    my $k;
    my $event;
    while ( ( $k = ZOOM::event( \@oConnection ) ) != 0 ) {
        $event = $oConnection[ $k - 1 ]->last_event();
        warn( "connection ", $k - 1, ": event $event (",
            ZOOM::event_str($event), ")\n" )
          if $DEBUG;
        last if $event == ZOOM::Event::ZEND;
    }

    if ( $k != 0 ) {
        $k--;
        warn $serverhost[$k] if $DEBUG;
        my ( $error, $errmsg, $addinfo, $diagset ) =
          $oConnection[$k]->error_x();
        if ($error) {
            warn "$k $serverhost[$k] error $query: $errmsg ($error) $addinfo\n"
              if $DEBUG;

        }
        else {
            my $numresults = $oResult[$k]->size();
            my $i;
            my $result = '';
            if ( $numresults > 0 ) {
                for (
                    $i = 0 ;
                    $i < ( ( $numresults < 20 ) ? ($numresults) : (20) ) ;
                    $i++
                  )
                {
                    my $rec = $oResult[$k]->record($i);
                    if ($rec) {
                        my $marcrecord;
                        $marcdata   = $rec->raw();

                        my ($charset_result, $charset_errors);
                        ($marcrecord, $charset_result, $charset_errors) = 
                          MarcToUTF8Record($marcdata, C4::Context->preference('marcflavour'), $encoding[$k]);
####WARNING records coming from Z3950 clients are in various character sets MARC8,UTF8,UNIMARC etc
## In HEAD i change everything to UTF-8
# In rel2_2 i am not sure what encoding is so no character conversion is done here
##Add necessary encoding changes to here -TG
                        my $oldbiblio = TransformMarcToKoha( $dbh, $marcrecord, "" );
                        $oldbiblio->{isbn}   =~ s/ |-|\.//g,
                          $oldbiblio->{issn} =~ s/ |-|\.//g,
                          my (
                            $notmarcrecord, $alreadyindb, $alreadyinfarm,
                            $imported,      $breedingid
                          )
                          = ImportBreeding( $marcdata, 2, $serverhost[$k], $encoding[$k], $random, 'z3950' );
                        my %row_data;
                        if ( $i % 2 ) {
                            $toggle = 1;
                        }
                        else {
                            $toggle = 0;
                        }
                        $row_data{toggle}       = $toggle;
                        $row_data{server}       = $servername[$k];
                        $row_data{isbn}         = $oldbiblio->{isbn};
                        $row_data{lccn}         = $oldbiblio->{lccn};
                        $row_data{title}        = $oldbiblio->{title};
                        $row_data{author}       = $oldbiblio->{author};
                        $row_data{breedingid}   = $breedingid;
                        $row_data{biblionumber} = $biblionumber;
                        push( @breeding_loop, \%row_data );
		            
                    } else {
                        push(@breeding_loop,{'toggle'=>($i % 2)?1:0,'server'=>$servername[$k],'title'=>join(': ',$oConnection[$k]->error_x()),'breedingid'=>-1,'biblionumber'=>-1});
                    } # $rec
                }    # upto 5 results
            }    #$numresults
        }
    }    # if $k !=0
    $numberpending = $nremaining - 1;
    $template->param(
        breeding_loop => \@breeding_loop,
        server        => $servername[$k],
        numberpending => $numberpending,
    );
    
    output_html_with_http_headers $input, $cookie, $template->output if $numberpending == 0;

    #  	print  $template->output  if $firstresult !=1;
    $firstresult++;
}
displayresults();
if ( --$nremaining > 0 ) {
        displayresults();
    }
}    ## if op=search
