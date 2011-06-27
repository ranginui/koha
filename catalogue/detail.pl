#!/usr/bin/perl

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

use CGI;
use C4::Auth;
use C4::Dates qw/format_date/;
use C4::Koha;
use C4::Serials;    #uses getsubscriptionfrom biblionumber
use C4::Output;
use C4::Biblio;
use C4::Items;
use C4::Circulation;
use C4::Branch;
use C4::Reserves;
use C4::Members; # to use GetMember
use C4::Serials;
use C4::XISBN qw(get_xisbns get_biblionumber_from_isbn);
use C4::External::Amazon;
use C4::Search;		# enabled_staff_search_views
use C4::VirtualShelves;
use C4::XSLT;

# use Smart::Comments;

my $query = CGI->new();
my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => "catalogue/detail.tmpl",
        query           => $query,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { catalogue => 1 },
    }
);

my $biblionumber = $query->param('biblionumber');
my $record       = GetMarcBiblio($biblionumber);

if ( not defined $record ) {
    # biblionumber invalid -> report and exit
    $template->param( unknownbiblionumber => 1,
                      biblionumber => $biblionumber );
    output_html_with_http_headers $query, $cookie, $template->output;
    exit;
}

if($query->cookie("holdfor")){ 
    my $holdfor_patron = GetMember('borrowernumber' => $query->cookie("holdfor"));
    $template->param(
        holdfor => $query->cookie("holdfor"),
        holdfor_surname => $holdfor_patron->{'surname'},
        holdfor_firstname => $holdfor_patron->{'firstname'},
        holdfor_cardnumber => $holdfor_patron->{'cardnumber'},
    );
}

my $fw           = GetFrameworkCode($biblionumber);
my $showallitems = $query->param('showallitems');
my $marcflavour  = C4::Context->preference("marcflavour");

# XSLT processing of some stuff
if (C4::Context->preference("XSLTDetailsDisplay") ) {
    $template->param('XSLTDetailsDisplay' =>'1',
        'XSLTBloc' => XSLTParse4Display($biblionumber, $record, 'Detail','intranet') );
}

$template->param( 'SpineLabelShowPrintOnBibDetails' => C4::Context->preference("SpineLabelShowPrintOnBibDetails") );

# some useful variables for enhanced content;
# in each case, we're grabbing the first value we find in
# the record and normalizing it
my $upc = GetNormalizedUPC($record,$marcflavour);
my $ean = GetNormalizedEAN($record,$marcflavour);
my $oclc = GetNormalizedOCLCNumber($record,$marcflavour);
my $isbn = GetNormalizedISBN(undef,$record,$marcflavour);

$template->param(
    normalized_upc => $upc,
    normalized_ean => $ean,
    normalized_oclc => $oclc,
    normalized_isbn => $isbn,
);

my $marcnotesarray   = GetMarcNotes( $record, $marcflavour );
my $marcisbnsarray   = GetMarcISBN( $record, $marcflavour );
my $marcauthorsarray = GetMarcAuthors( $record, $marcflavour );
my $marcsubjctsarray = GetMarcSubjects( $record, $marcflavour );
my $marcseriesarray  = GetMarcSeries($record,$marcflavour);
my $marcurlsarray    = GetMarcUrls    ($record,$marcflavour);
my $subtitle         = GetRecordValue('subtitle', $record, $fw);

# Get Branches, Itemtypes and Locations
my $branches = GetBranches();
my $itemtypes = GetItemTypes();
my $dbh = C4::Context->dbh;

my @all_items = GetItemsInfo( $biblionumber );
my @items;
for my $itm (@all_items) {
    push @items, $itm unless ( $itm->{itemlost} && GetHideLostItemsPreference($borrowernumber) && !$showallitems);
}
my $dat = &GetBiblioData($biblionumber);

# get count of holds
my ( $holdcount, $holds ) = GetReservesFromBiblionumber($biblionumber,1);

#coping with subscriptions
my $subscriptionsnumber = CountSubscriptionFromBiblionumber($biblionumber);
my @subscriptions       = GetSubscriptions( $dat->{title}, $dat->{issn}, $biblionumber );
my @subs;

foreach my $subscription (@subscriptions) {
    my %cell;
	my $serials_to_display;
    $cell{subscriptionid}    = $subscription->{subscriptionid};
    $cell{subscriptionnotes} = $subscription->{notes};
    $cell{branchcode}        = $subscription->{branchcode};
    $cell{branchname}        = GetBranchName($subscription->{branchcode});
    $cell{hasalert}          = $subscription->{hasalert};
    #get the three latest serials.
	$serials_to_display = $subscription->{staffdisplaycount};
	$serials_to_display = C4::Context->preference('StaffSerialIssueDisplayCount') unless $serials_to_display;
	$cell{staffdisplaycount} = $serials_to_display;
    $cell{latestserials} =
      GetLatestSerials( $subscription->{subscriptionid}, $serials_to_display );
    push @subs, \%cell;
}

if ( defined $dat->{'itemtype'} ) {
    $dat->{imageurl} = getitemtypeimagelocation( 'intranet', $itemtypes->{ $dat->{itemtype} }{imageurl} );
}

$dat->{'count'} = scalar @all_items;
$dat->{'showncount'} = scalar @items;
$dat->{'hiddencount'} = scalar @all_items - scalar @items;

my $shelflocations = GetKohaAuthorisedValues('items.location', $fw);
my $collections    = GetKohaAuthorisedValues('items.ccode'   , $fw);
my (@itemloop, %itemfields);
my $norequests = 1;
my $authvalcode_items_itemlost = GetAuthValCode('items.itemlost',$fw);
my $authvalcode_items_damaged  = GetAuthValCode('items.damaged', $fw);
foreach my $item (@items) {

    $item->{homebranch}        = GetBranchName($item->{homebranch});

    # can place holds defaults to yes
    $norequests = 0 unless ( ( $item->{'notforloan'} > 0 ) || ( $item->{'itemnotforloan'} > 0 ) );

    # format some item fields for display
    if ( defined $item->{'publictype'} ) {
        $item->{ $item->{'publictype'} } = 1;
    }
    $item->{imageurl} = defined $item->{itype} ? getitemtypeimagelocation('intranet', $itemtypes->{ $item->{itype} }{imageurl})
                                               : '';

	foreach (qw(datedue datelastseen onloan)) {
		$item->{$_} = format_date($item->{$_});
	}
    # item damaged, lost, withdrawn loops
    $item->{itemlostloop} = GetAuthorisedValues($authvalcode_items_itemlost, $item->{itemlost}) if $authvalcode_items_itemlost;
    if ($item->{damaged}) {
        $item->{itemdamagedloop} = GetAuthorisedValues($authvalcode_items_damaged, $item->{damaged}) if $authvalcode_items_damaged;
    }
    #get shelf location and collection code description if they are authorised value.
    my $shelfcode = $item->{'location'};
    $item->{'location'} = $shelflocations->{$shelfcode} if ( defined( $shelfcode ) && defined($shelflocations) && exists( $shelflocations->{$shelfcode} ) );
    my $ccode = $item->{'ccode'};
    $item->{'ccode'} = $collections->{$ccode} if ( defined( $ccode ) && defined($collections) && exists( $collections->{$ccode} ) );
    foreach (qw(ccode enumchron copynumber itemnotes uri)) {
        $itemfields{$_} = 1 if ( $item->{$_} );
    }

    # checking for holds
    my ($reservedate,$reservedfor,$expectedAt) = GetReservesFromItemnumber($item->{itemnumber});
    my $ItemBorrowerReserveInfo = GetMemberDetails( $reservedfor, 0);
    
    if (C4::Context->preference('HidePatronName')){
	$item->{'hidepatronname'} = 1;
    }

    if ( defined $reservedate ) {
        $item->{backgroundcolor} = 'reserved';
        $item->{reservedate}     = format_date($reservedate);
        $item->{ReservedForBorrowernumber}     = $reservedfor;
        $item->{ReservedForSurname}     = $ItemBorrowerReserveInfo->{'surname'};
        $item->{ReservedForFirstname}   = $ItemBorrowerReserveInfo->{'firstname'};
        $item->{ExpectedAtLibrary}      = $branches->{$expectedAt}{branchname};
	$item->{Reservedcardnumber}             = $ItemBorrowerReserveInfo->{'cardnumber'};
    }

	# Check the transit status
    my ( $transfertwhen, $transfertfrom, $transfertto ) = GetTransfers($item->{itemnumber});
    if ( defined( $transfertwhen ) && ( $transfertwhen ne '' ) ) {
        $item->{transfertwhen} = format_date($transfertwhen);
        $item->{transfertfrom} = $branches->{$transfertfrom}{branchname};
        $item->{transfertto}   = $branches->{$transfertto}{branchname};
        $item->{nocancel} = 1;
    }

    # FIXME: move this to a pm, check waiting status for holds
    my $sth2 = $dbh->prepare("SELECT * FROM reserves WHERE borrowernumber=? AND itemnumber=? AND found='W'");
    $sth2->execute($item->{ReservedForBorrowernumber},$item->{itemnumber});
    while (my $wait_hashref = $sth2->fetchrow_hashref) {
        $item->{waitingdate} = format_date($wait_hashref->{waitingdate});
    }

    push @itemloop, $item;
}

$template->param( norequests => $norequests );
$template->param(
	MARCNOTES   => $marcnotesarray,
	MARCSUBJCTS => $marcsubjctsarray,
	MARCAUTHORS => $marcauthorsarray,
	MARCSERIES  => $marcseriesarray,
	MARCURLS => $marcurlsarray,
    MARCISBNS => $marcisbnsarray,
	subtitle    => $subtitle,
	itemdata_ccode      => $itemfields{ccode},
	itemdata_enumchron  => $itemfields{enumchron},
	itemdata_uri        => $itemfields{uri},
	itemdata_copynumber => $itemfields{copynumber},
	volinfo				=> $itemfields{enumchron},
    itemdata_itemnotes  => $itemfields{itemnotes},
	z3950_search_params	=> C4::Search::z3950_search_args($dat),
    holdcount           => $holdcount,
	C4::Search::enabled_staff_search_views,
);

if (C4::Context->preference("AlternateHoldingsField") && scalar @items == 0) {
    my $fieldspec = C4::Context->preference("AlternateHoldingsField");
    my $subfields = substr $fieldspec, 3;
    my $holdingsep = C4::Context->preference("AlternateHoldingsSeparator") || ' ';
    my @alternateholdingsinfo = ();
    my @holdingsfields = $record->field(substr $fieldspec, 0, 3);

    for my $field (@holdingsfields) {
        my %holding = ( holding => '' );
        my $havesubfield = 0;
        for my $subfield ($field->subfields()) {
            if ((index $subfields, $$subfield[0]) >= 0) {
                $holding{'holding'} .= $holdingsep if (length $holding{'holding'} > 0);
                $holding{'holding'} .= $$subfield[1];
                $havesubfield++;
            }
        }
        if ($havesubfield) {
            push(@alternateholdingsinfo, \%holding);
        }
    }

    $template->param(
        ALTERNATEHOLDINGS   => \@alternateholdingsinfo,
        );
}

my @results = ( $dat, );
foreach ( keys %{$dat} ) {
    $template->param( "$_" => defined $dat->{$_} ? $dat->{$_} : '' );
}

# does not work: my %views_enabled = map { $_ => 1 } $template->query(loop => 'EnableViews');
# method query not found?!?!

$template->param(
    itemloop        => \@itemloop,
    biblionumber        => $biblionumber,
    detailview => 1,
    subscriptions       => \@subs,
    subscriptionsnumber => $subscriptionsnumber,
    subscriptiontitle   => $dat->{title},
);

# $debug and $template->param(debug_display => 1);

# Lists

if (C4::Context->preference("virtualshelves") ) {
   $template->param( 'GetShelves' => GetBibliosShelves( $biblionumber ) );
}

# XISBN Stuff
if (C4::Context->preference("FRBRizeEditions")==1) {
    eval {
        $template->param(
            XISBNS => get_xisbns($isbn)
        );
    };
    if ($@) { warn "XISBN Failed $@"; }
}
if ( C4::Context->preference("AmazonEnabled") == 1 ) {
    $template->param( AmazonTld => get_amazon_tld() );
    my $amazon_reviews  = C4::Context->preference("AmazonReviews");
    my $amazon_similars = C4::Context->preference("AmazonSimilarItems");
    my @services;
    if ( $amazon_reviews ) {
        $template->param( AmazonReviews => 1 );
        push( @services, 'EditorialReview' );
    }
    if ( $amazon_similars ) {
        $template->param( AmazonSimilarItems => 1 );
        push( @services, 'Similarities' );
    }
    my $amazon_details = &get_amazon_details( $isbn, $record, $marcflavour, \@services );
    if ( $amazon_similars ) {
        my $similar_products_exist;
        my @similar_products;
        for my $similar_product (@{$amazon_details->{Items}->{Item}->[0]->{SimilarProducts}->{SimilarProduct}}) {
            # do we have any of these isbns in our collection?
            my $similar_biblionumbers = get_biblionumber_from_isbn($similar_product->{ASIN});
            # verify that there is at least one similar item
		    if (scalar(@$similar_biblionumbers)){            
			    $similar_products_exist++ if ($similar_biblionumbers && $similar_biblionumbers->[0]);
                push @similar_products, +{ similar_biblionumbers => $similar_biblionumbers, title => $similar_product->{Title}, ASIN => $similar_product->{ASIN}  };
            }
        }
        $template->param( AmazonSimilarItems       => $similar_products_exist );
        $template->param( AMAZON_SIMILAR_PRODUCTS  => \@similar_products      );
    }
    if ( $amazon_reviews ) {
        my $item = $amazon_details->{Items}->{Item}->[0];
        my $editorial_reviews = \@{ $item->{EditorialReviews}->{EditorialReview} };
        #my $customer_reviews  = \@{$amazon_details->{Items}->{Item}->[0]->{CustomerReviews}->{Review}};
        #my $average_rating = $amazon_details->{Items}->{Item}->[0]->{CustomerReviews}->{AverageRating} || 0;
        #$template->param( amazon_average_rating    => $average_rating * 20    );
        #$template->param( AMAZON_CUSTOMER_REVIEWS  => $customer_reviews       );
        $template->param( AMAZON_EDITORIAL_REVIEWS => $editorial_reviews      );
    }
}

# Get OPAC URL
if (C4::Context->preference('OPACBaseURL')){
     $template->param( OpacUrl => C4::Context->preference('OPACBaseURL') );
}

output_html_with_http_headers $query, $cookie, $template->output;
