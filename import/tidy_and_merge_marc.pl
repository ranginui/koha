#!/usr/bin/perl

use strict;

#use warnings;

use Data::Dumper;
use C4::Context;

# use C4::Debug;

use MARC::Record;
use MARC::Field;
use MARC::Charset;

#use URI::Find::Simple qw( list_uris );

#  use Smart::Comments;

MARC::Charset->ignore_errors(1);
MARC::Charset->assume_unicode(1);

my $dbh          = C4::Context->dbh();
my $auto_barcode = 1000000000;

my $map = q|1 ODD ODD
ART DEL DEL
BF  BF  BF
BF-p BF BF
BFP BF BF
Bf BF BF  
BFR BFR BF
BH BH BN
BHR BHR BN
BJ ODD ODD
BJbP BJBP BJP  
BJBP BJBP BJP
BJC BJCF BJF
BJCF BJCF BJF
BJCN BJCN BJN
BJCP BJCP BJP
BJF BJF BJF
BJFF BJF BJF
BJK BJK BJF
BJM BJM MAO
BJN BJN BJN
BJP BJP BJP
BJRN BJRN BJN
BsF BSF BF  
BJSF BSF BF
BJSN BSN BN
BJZP BJZP BJP
BJzP BJZP BJP  
BL BLF LP
BLF BLF LP
BLN BLN LP
BLP BLF LP
BM BM MAO
BN BN BN
BNF BN BN
BPF BPF BF
BR BR BN
BRH BHR BN
BRM BRM MAO
BRN BR BN
BSF BSF BF
BsN BSN BN
Bn BN BN  
BT BT MAO
BYF BYF BYF
BYN BYN BN
BYP BYP BYF
C C TB
CAS CAS
CD CD
CDM CDM
CDPM CDPM
CDRo CD
CJ CJ TB
CNJ CNJ TB
CNP CNP TB
CP CP TB
D D D
DJ DJ D
DP DP D
DT D D
DVD D D
DY DY D
DYP BYP D
F F 
Fic BF BF
FJ FJ
GWB GWB
JBB BJBP BJP
JFCA BJCF BJF
JFIC BJF BJF
JFK BJK BJK
JHCV FJ 
JIG JIG
Jig JIG  
JK BJK BJF
JN BJN BJN
JNF BJN BJN
JPB BJF BJF
JPC BJP BJP
JPic BJP BJP
JV VJ V
JVID VJ V
LP BLF LP
M M M
MAP MAP 
MP MP M
MR MR M
N TNP TB
NF BN BN
NF18 BN BN
NJ BJN BJN
Nj TNJ TB  
NJP TNJ TB
NP TNP TB
NT TNP TB
P M M
PB PB 
PHB BF BF
PHOT PHOT 
PIC BJP BJP
PJ MJ M
PL M M
POS DEL DEL
PP MP M
PPB BF BF
PY MY M
PYP MYP M
T T TB
TALK T TB
TB T TB
TEAO BM MAO
TJ TJ TB
TJP TJ TB
TNP TNP TB
TP TP TB
TREF BRM MAO
TY ODD ODD
V V V
VHS V V
VID V V
VJ VJ V
VJP VJ V
VP V V
VY VY V
VVP VY V
YA BYF BYF
YP MY M|;

my @skipped_itypes =
  qw/ J$ PCY IF R FICB Para JA PC PBK FOC STAC Fict FLC REFE REA ROM RLP KCDL MAOR JTF JTFI MA0 LPNF LCH LP OBG JF PAM JCC JNFM NF NNC chr BSMA BC B CD3 CC TEWM YPC 333 ADUL ACQ ACC F NI TBI TBC TBK /;

my @class_one =
  qw /BF BJCF BJF BJK BLF BPF BSF BYF BYP DEL M MJ MP MY MYP ODD/;
my %one = map { $_ => 1 } @class_one;

my @class_two = qw /C CJ CNJ CNP CP DJ DJP DY DYP GWB JIG MAP PB PHOT T TJ TNJ TNP TP VJ VY BFR /;
my %two = map { $_ => 1 } @class_two;

my @class_three = qw/BJBP BJCP BJM BJP BJZP/;
my %three = map { $_ => 1 } @class_three;

my @class_four =
  qw/BJRN BPN CAS MR/;
my %four = map { $_ => 1 } @class_four;

my @class_five = qw/D DP V/;
my %five = map { $_ => 1 } @class_five;

my @class_six = qw/CD CDM CDPM/;
my %six = map { $_ => 1 } @class_six;

my @class_seven = qw/BH BHR BJCN BJN BLN BM BN BRM BSN BT BYN F FJ/;
my %seven = map { $_ => 1 } @class_seven;

my @class_eight = qw/BR/;
my %eight = map { $_ => 1 } @class_eight;



my @map_arr;
my @m = split /\n/, $map;
foreach (@m) {
    my @maps = split( / +/, $_ );

    push @map_arr, \@maps

      # ###  @quad

}

my $sth = $dbh->prepare("select * from biblio,biblioitems where 
  biblioitems.biblionumber=biblio.biblionumber 
  and (biblioitems.itemtype <> 'M'
      and biblioitems.itemtype <> 'MJ'
      and biblioitems.itemtype <> 'MP'
      and biblioitems.itemtype <> 'MR'
      and biblioitems.itemtype <> 'MY'
      and biblioitems.itemtype <> 'PP'
      and biblioitems.itemtype <> 'PY'
      and biblioitems.itemtype <> 'PYP')
  order by biblio.biblionumber ");

# my $sth = $dbh->prepare("select * from biblio,biblioitems 
#  where biblioitems.biblionumber=biblio.biblionumber and biblio.biblionumber = 148719 ") ;

# my $sth = $dbh->prepare("select * from biblio where biblionumber <  100  ") ;
# my $sth = $dbh->prepare("select * from biblio where biblionumber >   34700  and  biblionumber <    34800  ") ;
# my $sth = $dbh->prepare("select * from biblio where biblionumber >=  34719 limit 5" ) ;
# my $sth = $dbh->prepare("select * from biblio where biblionumber =  34719" ) ;
# my $sth = $dbh->prepare("select * from biblio  ");
$sth->execute() or die $sth->errstr();

my $sth_bi =
  $dbh->prepare("select * from biblioitems where  biblioitemnumber = ? ");
my $sth_item =
  $dbh->prepare("select * from items where  biblioitemnumber = ? ");
my $sth4 = $dbh->prepare(
    "select count(*) as cnt from items where biblioitemnumber = ? ");

open( MARCOUT, '> /tmp/record.dat' ) or die "\nFail- open marcoutput: $!";
my $cnt;
my @marcdata;

my $i = 0;
my $oldbib;
BRECORD: while ( my $bib = $sth->fetchrow_hashref() ) {
    my $itmcnt = 0;

    $i++;
    print ".";
#    print "$i" unless $i % 100;

    ## ## $bib
#    my $sth3 = $dbh->prepare(
#        "select count(*) as cnt from biblioitems where biblionumber = ? ");

    #    $sth3->{TraceLevel} = 3;
#    $sth3->execute( $bib->{'biblionumber'} );
#    my $icnt = $sth3->fetchrow_hashref();

    # ###  $icnt
#    next if $icnt->{'cnt'} == 0;

    my $sth_bibid = $dbh->prepare(
        "select bibid as bibid from marc_biblio  where  biblionumber = ? ");
    $sth_bibid->execute( $bib->{'biblionumber'} );
    my $bibid = $sth_bibid->fetchrow_hashref();

    #get marc tags
    my $sth_tags =
      $dbh->prepare("select * from marc_subfield_table where  bibid  = ? ");

    #    $sth_tags->{TraceLevel} = "3";

    while ( my ( $key, $value ) = each(%$bib) ) {
        $value =~ s/^[ \t]+|[ \t]+$//g;

    }
    my ( @marcfields, @marcfields_orig );

    my $record = MARC::Record->new();
    $record->encoding('utf-8');

    my @tags;

    #-------------------------------------------------------------------
    my $mref = {};

#my @tags = qw/ 010 020 022 082 100 240 245 260 300 362 440 500 520 852 942 999 /;

    my @tags = qw/ 020 022 100 245 260 300 362 999 /;
    foreach my $tag (@tags) {
        $mref->{"$tag"} = MARC::Field->new( $tag, '', '', xxx => '' );
    }

    # bib shizz
    my $biblionumber  = $bib->{'biblionumber'};
    my $biblioitemnumber  = $bib->{'biblioitemnumber'};    
    my $author        = $bib->{'author'};
    my $title         = $bib->{'title'};
    my $unititle      = $bib->{'unititle'};
    my $notes         = $bib->{'notes'};
    my $serial        = $bib->{'serial'};
    my $seriestitle   = $bib->{'seriestitle'};
    my $copyrightdate = $bib->{'copyrightdate'};
    my $abstract      = $bib->{'abstract'};

        print "$bib->{'biblionumber'}\n";
    $sth_tags->execute( $bibid->{'bibid'} );

    my (@tags_arr);
    while ( my $tag = $sth_tags->fetchrow_hashref() ) {
        push @tags_arr, $tag;

    }

    # ### @tags_arr
## ## $mref
    foreach my $tag (@tags_arr) {
        next if ( $tag->{'tag'} =~ /952/ );
	next if ( $tag->{'tag'} =~ /300/ );
	next if ( $tag->{'tag'} =~ /260/ );
	next if ( $tag->{'tag'} =~ /362/ );
 #        next if ( $tag->{'tag'} =~ /942/ );  # old koha 2.2 item field, ignore
        next if ( $tag->{'tag'} =~ /852/ );    ## 852 is rubbish too

        next if ( $tag->{'tag'} =~ /\D/ );     ## ??

        next
          if (  !defined $tag->{'subfieldvalue'}
            and !defined $tag->{'valuebloblink'} );

        if ( $tag->{'tag'} eq '505' ) {

### $tag
        }

        my $tagcode  = ( $tag->{'tag'} );
        my $subcode  = ( $tag->{'subfieldcode'} );
        my $subvalue = ( $tag->{'subfieldvalue'} );
        my $bloblink = ( $tag->{'valuebloblink'} );

        if ($bloblink) {
### $bloblink
            my $sth_blob = $dbh->prepare(
"select subfieldvalue as s from marc_blob_subfield  where  blobidlink    = ? "
            );
            $sth_blob->execute($bloblink);
            my $blob = $sth_blob->fetchrow_hashref();
            ###  $blob

            $subvalue = $blob->{s};

        }

        my $indicator1 = substr( $tag->{'tag_indicator'}, 0, 1 );
        my $indicator2 = substr( $tag->{'tag_indicator'}, 1, 1 );

        # ### $tag;

        $subvalue =~ s/^[ \t]+|[ \t]+$//g;

        # ##        my $subvalue =~  s/^[ \t]+|[ \t]+$//;

        # control tags
        if ( $tag->{'tag'} < 10 ) {

            $mref->{"$tagcode"} = MARC::Field->new( $tagcode, $subvalue );
        }
        else {

            #or other tasg
            eval {
                $mref->{"$tagcode"}->add_subfields( $subcode => $subvalue );
            };
            if ($@) {
                $mref->{"$tagcode"} = MARC::Field->new(
                    $tagcode, $indicator1, $indicator2,
                    xxx      => '',
                    $subcode => $subvalue
                );
            }
        }

    }
    $mref->{'999'}->add_subfields( 'e' => $biblionumber ); # store the old number in case we need it
    if ($oldbib == $biblionumber){
	$biblionumber='';
    }
    else {
	$oldbib = $biblionumber;
    }

    $mref->{'999'}->add_subfields( 'c' => $biblionumber )
      if defined $biblionumber;    #bibnum
    $mref->{'999'}->add_subfields( 'd' => $biblionumber )
      if defined $biblionumber;    # bibnum is now bib too!!!

    #-----------------------------------
    #-----------------------------------
    #-----------------------------------
### qqqqqqqqqqqqqqqqqqqqqqq

# BIB ITEM shizz
#    my $sth_bi = $dbh->prepare("select * from biblioitems where  biblionumber = ?");
#        $sth_bi->{TraceLevel} = "3";
    $sth_bi->execute($biblioitemnumber);

  BIRECORD: while ( my $bi = $sth_bi->fetchrow_hashref() ) {
        ### $bi

        #        $sth4->{TraceLevel} = 3;
        $sth4->execute( $bi->{'biblioitemnumber'} );
        my $icnt = $sth4->fetchrow_hashref();

        # ###  $icnt
        next if $icnt->{'cnt'} == 0;

        while ( my ( $key, $value ) = each(%$bi) ) {
            $value =~ s/^[ \t]+|[ \t]+$//g;
        }
        ### e
        my $biblioitemnumber = $bi->{'biblioitemnumber'};    #REMAP!
        my $class            = $bi->{'classification'};
        my $dewey            = $bi->{'dewey'};
        my $illus            = $bi->{'illus'};
        my $isbn             = $bi->{'isbn'};
        my $issn             = $bi->{'issn'};
        my $itemtype         = $bi->{'itemtype'};            #i
        my $lccn             = $bi->{'lccn'};
        my $notes            = $bi->{'notes'};               #i
        my $number           = $bi->{'number'};              #i
        my $pages            = $bi->{'pages'};
        my $classification   = $bi->{'classification'};
        my $place            = $bi->{'place'};
        my $publicationyear  = $bi->{'publicationyear'};
        my $publishercode    = $bi->{'publishercode'};
        my $size             = $bi->{'size'};
        my $subclass         = $bi->{'subclass'};            #i
        my $url              = $bi->{'url'};                 #i
        my $volume           = $bi->{'volume'};
        my $volumeddesc      = $bi->{'volumeddesc'};

        
        # ITEMTYPE MAPPING
        # skip these itemtypes

#        foreach (@skipped_itypes) {
#            next BIRECORD if $itemtype eq $_;
#        }
### eeeeeee

#        $mref->{'999'}->add_subfields( 'd' => $bib->{'biblionumber'} );   #REMAP  - bibitem-num now re-mapped to bibnumber
#-----------------------------------
#        my $sth_item = $dbh->prepare("select * from items where  biblioitemnumber = ?");
#        $sth_item->{TraceLevel} = "3";

        # ### wwwwww
       
       my $title_check = $mref->{'245'}->subfield('a');
       my $author_check = $mref->{'100'}->subfield('a');
       my $isbn_check = $mref->{'020'}->subfield('a');
       my $issn_check = $mref->{'022'}->subfield('a');
      my $pubdate_check = $mref->{'260'}->subfield('c');
      my $publisher_check = $mref->{'260'}->subfield('b');
      my $place_check = $mref->{'260'}->subfield('a');
      my $illus_check = $mref->{'300'}->subfield('b');
      my $pages_check = $mref->{'300'}->subfield('a');
      my $size_check = $mref->{'300'}->subfield('c');
      my $volume_check = $mref->{'362'}->subfield('a');
       if (! $title_check){
	   $mref->{'245'}->add_subfields( 'a' => $title );
       }       
       if (! $isbn_check){
	   $mref->{'020'}->add_subfields( 'a' => $isbn );
       }
       if (! $author_check){
	   $mref->{'100'}->add_subfields( 'a' => $author );
       }
       if (! $issn_check){
	   $mref->{'022'}->add_subfields( 'a' => $issn );
       }
      if (! $pubdate_check){
	   $mref->{'260'}->add_subfields( 'c' => $publicationyear );
       } 
      if (! $publisher_check){
	   $mref->{'260'}->add_subfields( 'b' => $publishercode );
       }
      if (! $place_check){
	   $mref->{'260'}->add_subfields( 'b' => $place );
       }
      if (! $illus_check){
	   $mref->{'300'}->add_subfields( 'b' => $illus );
       }
      if (! $pages_check){
	   $mref->{'300'}->add_subfields( 'a' => $pages );
       }
      if (! $size_check){
	   $mref->{'300'}->add_subfields( 'c' => $size );
       }
      if (! $volume_check){
	   $mref->{'362'}->add_subfields( 'a' => $volumeddesc );
       }
      
      


        $sth_item->execute($biblioitemnumber);

        while ( my $item = $sth_item->fetchrow_hashref() ) {

### $item
            while ( my ( $key, $value ) = each(%$item) ) {
                $value =~ s/^[ \t]+|[ \t]+$//g;
                chomp $value;
            }
            my ( $ccode, $loc );

            #            my @dew_chop = split (/[\.|\n]/  , $dewey);

            #            if ( $itemtype eq 'BIO' ) {
            #                chomp $dewey;
            #                my @dew_chop = split( /[.| ]/, $dewey );
            #                if (    $dew_chop[0] > 920
            #                    and $dew_chop[0] < 929 ) {
            #                    $ccode = 'NFIC';
            #                    $loc   = 'GENEALOGY';
            #                } else {
            #                    $ccode = 'BIOG';
            #                    $loc   = 'BIO';
            #                }
            #                $itemtype = 'BK';
            #            } else {
            foreach my $m (@map_arr) {
                if ( $itemtype eq @$m[0] ) {
                    $itemtype = @$m[1];
                    $ccode    = @$m[2];

                    #                        $loc      = @$m[3];
                    last;
                }
            }

            #            }

         #        $mref->{"$tag"} = MARC::Field->new( $tag, '', '', xxx => '' );

            my @branches = qw/C F FM FP FS H L LP M P S SP T/;
            my $match;
            foreach (@branches) {
                if ( $item->{'homebranch'} eq $_ ) {
                    $match = 1;
                    last;
                }
            }
            $item->{'homebranch'} = 'L' if not $match;

            $mref->{'999'}->add_subfields( 'a' => $item->{'itemnumber'} );
            my $item_mrc = MARC::Field->new( 952, '', '', xxx => '' );

            my $dewey = $bi->{'dewey'};
            $dewey =~ s/\r//g;
            $dewey =~ s/^[ \t]+|[ \t]+$//g;
            chomp $dewey;

            #            warn $dewey;
            #            print  $dewey;

            $item_mrc->add_subfields( '9' => $item->{'itemnumber'} )
              if defined $item->{'itemnumber'};
            $item_mrc->add_subfields( 'a' => $item->{'homebranch'} )
              if defined $item->{'homebranch'};
            $item_mrc->add_subfields( 'b' => $item->{'holdingbranch'} )
              if defined $item->{'holdingbranch'};
            $item_mrc->add_subfields( 'd' => $item->{'dateaccessioned'} )
              if defined $item->{'dateaccessioned'};
            $item_mrc->add_subfields( 'e' => $item->{'booksellerid'} )
              if defined $item->{'booksellerid'};
            $item_mrc->add_subfields( 'g' => $item->{'price'} )
              if defined $item->{'price'};
            $item_mrc->add_subfields( 'j' => $item->{'stack'} )
              if defined $item->{'stack'};
	    
	    my @spl_author = split(/\,/,$author);
	    my $clean_author = $spl_author[0];
	    $clean_author =~ s/\W//g;
	    
	    my $clean_title = $title;
	    # get rid of stop words
	    $clean_title =~ s/^the //i;
	    $clean_title =~ s/^a //i;
	    $clean_title =~ s/^and //i;
	    $clean_title =~ s/\W//g;
#	    if ($dewey){
	    if ($classification eq 'Pb-Romance' || $classification eq 'PB-Romance' ||
		$classification eq 'PbRomance' || $classification eq 'PBRomace'){
		    $itemtype='BFR';
		 }
		if (exists $one{$itemtype}){
		    if ($author){
			$dewey = uc substr($clean_author,0,4);
		    }
		    else {
			$dewey = uc substr($clean_title,0,4);
		    }
		}
		elsif( exists $two{$itemtype}){
		    $dewey='';
		}
		elsif ( exists $three{$itemtype}){
		    if ($author){
			$dewey = uc substr($clean_author,0,1);
		    }
		    else {
			$dewey = uc substr($clean_title,0,1);
		    }
		}		    
		elsif ( exists $four{$itemtype}){
		    $dewey =~ s/^\D*//;          
		    if ($subclass){
			$dewey = $dewey . " " . $subclass;			
		    }
		    else {
			if ($author){
			    $dewey .= " " . uc substr($clean_author,0,4);
			}
			else {
			    $dewey .= " " . uc substr($clean_title,0,4);
			}
		    }
		}
		elsif ( exists $five{$itemtype}){
		    $dewey =~ s/^\D*//;
		    $dewey =~ s/\D*$//;
		    if ($dewey eq '791.43'){
			$dewey = "Movie";
		    }
		    if ($dewey eq '791.45'){
			$dewey = "TV";
		    }
		    if ($dewey =~ /781\.63.*/){
			$dewey = "MUSIC";
		    }
		    $dewey.= " " . uc substr($clean_title,0,4);
		}
		elsif ( exists $six{$itemtype}){
		    $dewey = $volumeddesc;
		}
	        elsif ( exists $seven{$itemtype}){
		    if ($dewey =~ /759/ || $dewey =~ /811/ || $dewey =~ /821/
			|| $dewey =~ /822/ || $dewey =~ /823/ || $dewey =~ /^92/){
			    $dewey =~ s/\D*$//;
			    $dewey = $dewey . " " . $subclass;
			}
		    else {
			$dewey =~ s/\D*$//;
			if ($author){
			    $dewey .= " " . uc substr($clean_author,0,4);
			}
			else {
			    $dewey .= " " . uc substr($clean_title,0,4);
			}
		    }
	        }
	        elsif ( exists $eight{$itemtype}){
		    if ($dewey =~ /629/){
			$dewey = $dewey . " " . $subclass;
		    }
		    else {
			if ($author){
			    $dewey .= " " . uc substr($clean_author,0,4);
			}
			else {
			    $dewey .= " " . uc substr($clean_title,0,4);
			}
		    }			
		}			
#	    }
	    
	    print "$title\t$itemtype\t$dewey\n";
            $item_mrc->add_subfields( 'o' => $dewey ) if $dewey;

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

            $item_mrc->add_subfields( 'y' => $itemtype );
            $item_mrc->add_subfields( 't' => $volumeddesc ) if defined $volumeddesc;
            $item_mrc->add_subfields( '8' => $ccode ) if defined $ccode;
            $item_mrc->add_subfields( 'c' => $loc ) if defined $loc; # shelv-LOC

            # adding item stat-fields too
            $item_mrc->add_subfields( 'l' => $item->{'issues'} )
              if defined $item->{'issues'};
            $item_mrc->add_subfields( '0' => $item->{'wthdrawn'} )
              if defined $item->{'wthdrawn'};
            $item_mrc->add_subfields( '1' => $item->{'itemlost'} )
              if defined $item->{'itemlost'};
            $item_mrc->add_subfields( '4' => $item->{'damaged'} )
              if defined $item->{'damaged'};
            $item_mrc->add_subfields( '7' => $item->{'notforloan'} )
              if defined $item->{'notforloan'};
            $item_mrc->add_subfields( 'm' => $item->{'renewals'} )
              if defined $item->{'renewals'};
            $item_mrc->add_subfields( 'n' => $item->{'reserves'} )
              if defined $item->{'reserves'};
            $item_mrc->add_subfields( '5' => $item->{'restricted'} )
              if defined $item->{'restricted'};

            push @marcfields, $item_mrc;
            $itmcnt++;
        }    ## while item
             #-----------------------------------
    }
### $itmcnt

#    next BRECORD if $itmcnt == 0;    # if not items skipp to next bib!!

    while ( my ( $key, $value ) = each(%$mref) ) {

        chomp $value;
        $value =~ s/^[ \t]+|[ \t]+$//g;

        push @marcfields, $value;
    }

    $record->insert_fields_ordered(@marcfields);
    ### $record

    $record = strip_blank_subfields($record);
    ### $record

    #    my $cntmrc = push @marcdata, ($record);
    print MARCOUT $record->as_usmarc();
#      print MARCOUT $record->as_formatted();  
}

#foreach (@marcdata) {
#    print MARCOUT $_->as_usmarc();
#}

sub strip_blank_subfields {
    my ($record) = @_;

    my @fields = $record->fields();
    foreach my $field (@fields) {

        if ( $field->{'_tag'} >= 10 ) {
            $field->delete_subfield( code => 'xxx' );
            my @subs = $field->subfields();

            my $subcnt = scalar(@subs);

            # ##  $subcnt

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

    # ## $record
    return $record;
}

