#!/usr/bin/perl

use strict;

#use warnings;

use Encode;
use ZOOM;
use Text::CSV_XS;

# Koha modules used
use C4::Context;

#use C4::Charset;
use C4::Biblio;
use Getopt::Long;

use MARC::Record;
use MARC::Field;
use MARC::Charset;

#use URI::Find::Simple qw( list_uris );
use File::Slurp;

MARC::Charset->ignore_errors(1);
MARC::Charset->assume_unicode(1);

#use Smart::Comments -ENV, qw(####);
# use Data::Dumper;

my $dbh          = C4::Context->dbh();
my $auto_barcode = 1000000000;

binmode( STDOUT, ":utf8" );

# open the isbn file
#my $contents=`cat isbns.txt`;
my @isbns = read_file('isbns.txt');
## ## @isbns

my $sth = $dbh->prepare("select * from biblio where  biblionumber = ? ");

my $sth_bi =
  $dbh->prepare("select * from biblioitems where  biblionumber = ? ");
my $sth_item =
  $dbh->prepare("select * from items where  biblioitemnumber = ? ");
open( MARCOUT, '> record.dat' ) or die "\nFail- open marcoutput: $!";
my $cnt;
my @marcdata;
my $i = 0;

#@isbns = @isbns[0...50];
## ## @isbns

foreach my $isbn (@isbns) {

    $i++;
    print ".";
    print "\r$i" unless $i % 100;

    chomp $isbn;
    warn "$i -  $isbn";
    #### $isbn;

    # my $conn = new ZOOM::Connection('nlnzcat.natlib.govt.nz:7190/Voyager');

    my ( $conn, $q, $rs, $n, $rec, $raw );
    eval {
#        $conn = new ZOOM::Connection('NBD.NATLIB.GOVT.NZ:57090/Voyager');
        $conn = new ZOOM::Connection('localhost:11001/biblios'); 
        $conn->option( preferredRecordSyntax => "usmarc" );

        $q  = " \@or \@attr 1=8 \"$isbn\" \@attr 1=7 \"$isbn\" ";
	warn $q;
        $rs = $conn->search_pqf($q);

        $n = $rs->size();

        next if $n == 0;

        $rec = $rs->record();
        print $rec->render();
        $raw = $rec->raw();
        $conn->destroy();

    };
    if ($@) {
        print "Error ", $@->code(), ": ", $@->message(), "\n";
        next;
    }

    # ###  $raw

    my $z39marc = new_from_usmarc MARC::Record($raw);
    ## ## $z39marc
    #    $z39marc  = $rec->render("charset=latin1,utf8");
    ## ## $z39marc

    my @z39_fields = $z39marc->fields();
    ## ##  @z39_fields

    my $sth_isbn = $dbh->prepare(
        "select biblionumber from biblioitems where isbn = ? limit 1");

    #    $sth->{TraceLevel} = 3;

    $sth_isbn->execute($isbn);
    my $bi_isbn = $sth_isbn->fetchrow_hashref();
    ####  $bi_isbn

    my $sth = $dbh->prepare("select * from biblio where  biblionumber = ? ");

    #    $sth->{TraceLevel} = 3;
    $sth->execute( $bi_isbn->{'biblionumber'} );
    my $bib = $sth->fetchrow_hashref();

    ## ##  $bib
    next if not defined $bib;

    #get bibid

#    my $sth_bibid = $dbh->prepare("select bibid as bibid from marc_biblio  where  biblionumber = ? ");
#    $sth_bibid->execute( $bib->{'biblionumber'} );
#    my $bibid = $sth_bibid->fetchrow_hashref();

    my ( @marcfields, @marcfields_orig );

    #    my $record = MARC::Record->new();
    my $record = $z39marc->clone;

    #    $record->encoding('utf-8');
    #    $record->insert_fields_ordered( @z39_fields );
## ##     $record

    my @tags;

    #-------------------------------------------------------------------
    my $mref = {};

    my $biblionumber = $bib->{'biblionumber'};

    $mref->{"999"} = MARC::Field->new( '999', '', '', xxx => '' );
    $mref->{'999'}->add_subfields( 'c' => $biblionumber )
      if defined $biblionumber;    #bibnum
    $mref->{'999'}->add_subfields( 'd' => $biblionumber )
      if defined $biblionumber;    # bibnum is now bib too!!!

    #-----------------------------------

    # BIB ITEM shizz

#    my $sth_bi = $dbh->prepare("select * from biblioitems where  biblionumber = ?");

    #        $sth_bi->{TraceLevel} = "3";

    $sth_bi->execute($biblionumber);

    while ( my $bi = $sth_bi->fetchrow_hashref() ) {

        my $biblioitemnumber = $bi->{'biblioitemnumber'};

#        $mref->{'999'}->add_subfields( 'd' => $bib->{'biblionumber'} );   #REMAP  - bibitem-num now re-mapped to bibnumber

#-----------------------------------
#        my $sth_item = $dbh->prepare("select * from items where  biblioitemnumber = ?");

#### 'pp'
        #        $sth_item->{TraceLevel} = "3";
        $sth_item->execute($biblioitemnumber);

        while ( my $item = $sth_item->fetchrow_hashref() ) {

            ## ## $item
            while ( my ( $key, $value ) = each(%$item) ) {
                $value =~ s/^[ \t]+|[ \t]+$//g;
            }

         #        $mref->{"$tag"} = MARC::Field->new( $tag, '', '', xxx => '' );

     #            $mref->{'999'}->add_subfields( 'a' => $item->{'itemnumber'} );

            my $item_mrc = MARC::Field->new( 952, '', '', xxx => '' );

            $item_mrc->add_subfields( '7' => $item->{'notforloan'} )
              if defined $item->{'notforloan'};
            $item_mrc->add_subfields( '9' => $item->{'itemnumber'} )
              if defined $item->{'itemnumber'};

#            $item_mrc->add_subfields( 'a' => $item->{'homebranch'} )      if defined $item->{'homebranch'};
#           $item_mrc->add_subfields( 'b' => $item->{'holdingbranch'} )   if defined $item->{'holdingbranch'};

            $item_mrc->add_subfields( 'a' => 'L' );
            $item_mrc->add_subfields( 'b' => 'L' );

            $item_mrc->add_subfields( 'd' => $item->{'dateaccessioned'} )
              if defined $item->{'dateaccessioned'};
            $item_mrc->add_subfields( 'e' => $item->{'booksellerid'} )
              if defined $item->{'booksellerid'};
            $item_mrc->add_subfields( 'g' => $item->{'price'} )
              if defined $item->{'price'};
            $item_mrc->add_subfields( 'j' => $item->{'stack'} )
              if defined $item->{'stack'};

            $item_mrc->add_subfields( 'o' => $bi->{'dewey'} )
              if defined $bi->{'dewey'};

            $item_mrc->add_subfields( 'p' => $item->{'barcode'} )
              if defined $item->{'barcode'};
            $item_mrc->add_subfields( 'r' => $item->{'datelastseen'} )
              if defined $item->{'datelastseen'};
            $item_mrc->add_subfields( 's' => $item->{'datelastborrowed'} )
              if defined $item->{'datelastborrowed'};
            $item_mrc->add_subfields( 'u' => $bi->{'url'} )
              if defined $bi->{'url'};
            $item_mrc->add_subfields( 'v' => $item->{'replacementprice'} )
              if defined $item->{'replacementprice'};
            $item_mrc->add_subfields( 'y' => $bi->{'itemtype'} )
              if defined $bi->{'itemtype'};

        #            $item_mrc->add_subfields( 'zzz' => $item->{'itemnumber'} );

            #### $item_mrc;

            push @marcfields, $item_mrc;

        }

        #-----------------------------------

    }

    while ( my ( $key, $value ) = each(%$mref) ) {
        push @marcfields, $value;
    }

### $mref

    $record->insert_fields_ordered(@marcfields);

    #    $record = strip_blank_subfields($record);

    #    my $cntmrc = push @marcdata, ($record);
    print MARCOUT $record->as_usmarc();
}

foreach (@marcdata) {
    print MARCOUT $_->as_usmarc();
}

sub strip_blank_subfields {
    my ($record) = @_;

    my @fields = $record->fields();
    foreach my $field (@fields) {

        if ( $field->{'_tag'} >= 10 ) {
            $field->delete_subfield( code => 'xxx' );
            my @subs = $field->subfields();

            my $subcnt = scalar(@subs);
            ###  $subcnt

            if ( $subcnt == 0 ) {
                $record->delete_field($field);
            }
            else {
                foreach my $sub (@subs) {
                    my $name  = $$sub[0];
                    my $value = $$sub[1];
                    if ( !$value && $value ne '0' ) {
                        $field->delete_subfield( code => $name );
                    }
                }
            }
        }
    }
### $record
    return $record;
}
## Please see file perltidy.ERR
