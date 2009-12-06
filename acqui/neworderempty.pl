#!/usr/bin/perl

#script to show display basket of orders
#written by chris@katipo.co.nz 24/2/2000

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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA


=head1 NAME

neworderempty.pl

=head1 DESCRIPTION
this script allows to create a new record to order it. This record shouldn't exist
on database.

=head1 CGI PARAMETERS

=over 4

=item booksellerid
the bookseller the librarian has to buy a new book.

=item title
the title of this new record.

=item author
the author of this new record.

=item publication year
the publication year of this new record.

=item ordernumber
the number of this order.

=item biblio

=item basketno
the basket number for this new order.

=item suggestionid
if this order comes from a suggestion.

=item breedingid
the item's id in the breeding reservoir

=item close

=back

=cut

use warnings;
use strict;
use CGI;
use C4::Context;
use C4::Input;

use C4::Auth;
use C4::Budgets;
use C4::Input;
use C4::Dates;

use C4::Bookseller;		# GetBookSellerFromId
use C4::Acquisition;
use C4::Suggestions;	# GetSuggestion
use C4::Biblio;			# GetBiblioData
use C4::Output;
use C4::Input;
use C4::Koha;
use C4::Branch;			# GetBranches
use C4::Members;
use C4::Search qw/FindDuplicate BiblioAddAuthorities/;

#needed for z3950 import:
use C4::ImportBatch qw/GetImportRecordMarc SetImportRecordStatus/;

my $input           = new CGI;
my $booksellerid    = $input->param('booksellerid');	# FIXME: else ERROR!
my $budget_id       = $input->param('budget_id');	# FIXME: else ERROR!
my $title           = $input->param('title');
my $author          = $input->param('author');
my $publicationyear = $input->param('publicationyear');
my $bookseller      = GetBookSellerFromId($booksellerid);	# FIXME: else ERROR!
my $ordernumber          = $input->param('ordernumber') || '';
my $biblionumber    = $input->param('biblionumber');
my $basketno        = $input->param('basketno');
my $suggestionid    = $input->param('suggestionid');
my $close           = $input->param('close');
my $uncertainprice  = $input->param('uncertainprice');
my $import_batch_id = $input->param('import_batch_id'); # if this is filled, we come from a staged file, and we will return here after saving the order !
my $data;
my $new = 'no';

my $budget_name;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "acqui/neworderempty.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { acquisition => 'order_manage' },
        debug           => 1,
    }
);

my $basket = GetBasket($basketno);
my $contract = &GetContract($basket->{contractnumber});

#simple parameters reading (all in one :-)
my $params = $input->Vars;
my $listprice; # the price, that can be in MARC record if we have one
if ( $ordernumber eq '' and defined $params->{'breedingid'}){
#we want to import from the breeding reservoir (from a z3950 search)
    my ($marcrecord, $encoding) = MARCfindbreeding($params->{'breedingid'});
    die("Could not find the selected record in the reservoir, bailing") unless $marcrecord;

    my $duplicatetitle;
#look for duplicates
    if (! (($biblionumber,$duplicatetitle) = FindDuplicate($marcrecord))){
        if (C4::Context->preference("BiblioAddsAuthorities")){
            my ($countlinked,$countcreated)=BiblioAddAuthorities($marcrecord, $params->{'frameworkcode'});
        }
        my $bibitemnum;
        $params->{'frameworkcode'} or $params->{'frameworkcode'} = "";
        ( $biblionumber, $bibitemnum ) = AddBiblio( $marcrecord, $params->{'frameworkcode'} );
        # get the price if there is one.
        # filter by storing only the 1st number
        # we suppose the currency is correct, as we have no possibilities to get it.
        if ($marcrecord->subfield("345","d")) {
            $listprice = $marcrecord->subfield("345","d");
            if ($listprice =~ /^([\d\.,]*)/) {
                $listprice = $1;
                $listprice =~ s/,/\./;
            } else {
                $listprice = 0;
            }
        }
        elsif ($marcrecord->subfield("010","d")) {
            $listprice = $marcrecord->subfield("010","d");
            if ($listprice =~ /^([\d\.,]*)/) {
                $listprice = $1;
                $listprice =~ s/,/\./;
            } else {
                $listprice = 0;
            }
        }
        SetImportRecordStatus($params->{'breedingid'}, 'imported');
    }
}


my $cur = GetCurrency();

if ( $ordernumber eq '' ) {    # create order
    $new = 'yes';

    # 	$ordernumber=newordernum;
    if ( $biblionumber && !$suggestionid ) {
        $data = GetBiblioData($biblionumber);
    }

# get suggestion fields if applicable. If it's a subscription renewal, then the biblio already exists
# otherwise, retrieve suggestion information.
    if ($suggestionid) {
        $data = ($biblionumber) ? GetBiblioData($biblionumber) : GetSuggestion($suggestionid);
    }
}
else {    #modify order
    $data   = GetOrder($ordernumber);
    $biblionumber = $data->{'biblionumber'};
    $budget_id = $data->{'budget_id'};

    #get basketno and supplierno. too!
    my $data2 = GetBasket( $data->{'basketno'} );
    $basketno     = $data2->{'basketno'};
    $booksellerid = $data2->{'booksellerid'};
}

# get currencies (for change rates calcs if needed)
my @rates = GetCurrencies();
my $count = scalar @rates;

# ## @rates

my @loop_currency = ();
for ( my $i = 0 ; $i < $count ; $i++ ) {
    my %line;
    $line{currency} = $rates[$i]->{'currency'};
    $line{rate}     = $rates[$i]->{'rate'};
    push @loop_currency, \%line;
}

# build branches list
my $onlymine=C4::Context->preference('IndependantBranches') && 
            C4::Context->userenv && 
            C4::Context->userenv->{flags}!=1 && 
            C4::Context->userenv->{branch};
my $branches = GetBranches($onlymine);
my @branchloop;
foreach my $thisbranch ( sort {$branches->{$a}->{'branchname'} cmp $branches->{$b}->{'branchname'}} keys %$branches ) {
    my %row = (
        value      => $thisbranch,
        branchname => $branches->{$thisbranch}->{'branchname'},
    );
    $row{'selected'} = 1 if( $thisbranch eq $data->{branchcode}) ;
    push @branchloop, \%row;
}
$template->param( branchloop => \@branchloop );

# build bookfund list
my $borrower= GetMember('borrowernumber' => $loggedinuser);
my ( $flags, $homebranch )= ($borrower->{'flags'},$borrower->{'branchcode'});

my $budget =  GetBudget($budget_id);
# build budget list
my %labels;
my @values;
my $budgets = GetBudgetHierarchy('','',$borrower->{'borrowernumber'});
foreach my $r (@$budgets) {
    $labels{"$r->{budget_id}"} = $r->{budget_name};
    next if  sprintf ("%00d",  $r->{budget_amount})  ==   0;
    push @values, $r->{budget_id};
}
# if no budget_id is passed then its an add
my $budget_dropbox = CGI::scrolling_list(
    -name    => 'budget_id',
    -id      => 'budget_id',
    -values  => \@values,
    -size    => 1,
    -labels  => \%labels,
    -onChange   => "fetchSortDropbox(this.form)",
);

if ($close) {
    $budget_id      =  $data->{'budget_id'};
    $budget_name    =   $budget->{'budget_name'};

}

my $CGIsort1;
if ($budget) {    # its a mod ..
    if ( defined $budget->{'sort1_authcat'} ) {    # with custom  Asort* planning values
        $CGIsort1 = GetAuthvalueDropbox( 'sort1', $budget->{'sort1_authcat'}, $data->{'sort1'} );
    }
} elsif(scalar(@$budgets)){
    $CGIsort1 = GetAuthvalueDropbox( 'sort1', @$budgets[0]->{'sort1_authcat'}, '' );
}else{
    $CGIsort1 = GetAuthvalueDropbox( 'sort1','', '' );
}

# if CGIsort is successfully fetched, the use it
# else - failback to plain input-field
if ($CGIsort1) {
    $template->param( CGIsort1 => $CGIsort1 );
} else {
    $template->param( sort1 => $data->{'sort1'} );
}

my $CGIsort2;
if ($budget) {
    if ( defined $budget->{'sort2_authcat'} ) {
        $CGIsort2 = GetAuthvalueDropbox( 'sort2', $budget->{'sort2_authcat'}, $data->{'sort2'} );
    }
} elsif(scalar(@$budgets)) {
    $CGIsort2 = GetAuthvalueDropbox( 'sort2', @$budgets[0]->{sort2_authcat}, '' );
}else{
    $CGIsort2 = GetAuthvalueDropbox( 'sort2','', '' );
}

if ($CGIsort2) {
    $template->param( CGIsort2 => $CGIsort2 );
} else {
    $template->param( sort2 => $data->{'sort2'} );
}

if (C4::Context->preference('AcqCreateItem') eq 'ordering' && !$ordernumber) {
    # prepare empty item form
    my $cell = PrepareItemrecordDisplay('','','','ACQ');
#     warn "==> ".Data::Dumper::Dumper($cell);
    unless ($cell) {
        $cell = PrepareItemrecordDisplay('','','','');
        $template->param('NoACQframework' => 1);
    }
    my @itemloop;
    push @itemloop,$cell;
    
    $template->param(items => \@itemloop);
}

# fill template
$template->param(
    close        => $close,
    budget_id    => $budget_id,
    budget_name  => $budget_name
) if ($close);

$template->param(
    existing         => $biblionumber,
    ordernumber           => $ordernumber,
    # basket informations
    basketno             => $basketno,
    basketname           => $basket->{'basketname'},
    basketnote           => $basket->{'note'},
    booksellerid         => $basket->{'booksellerid'},
    basketbooksellernote => $basket->{booksellernote},
    basketcontractno     => $basket->{contractnumber},
    basketcontractname   => $contract->{contractname},
    creationdate         => C4::Dates->new($basket->{creationdate},'iso')->output,
    authorisedby         => $basket->{'authorisedby'},
    authorisedbyname     => $basket->{'authorisedbyname'},
    closedate            => C4::Dates->new($basket->{'closedate'},'iso')->output,
    # order details
    suggestionid     => $suggestionid,
    biblionumber     => $biblionumber,
    uncertainprice   => $data->{'uncertainprice'},
    authorisedbyname => $borrower->{'firstname'} . " " . $borrower->{'surname'},
    biblioitemnumber => $data->{'biblioitemnumber'},
    discount_2dp     => sprintf( "%.2f",  $bookseller->{'discount'}) ,   # for display
    discount         => $bookseller->{'discount'},
    listincgst       => $bookseller->{'listincgst'},
    invoiceincgst    => $bookseller->{'invoiceincgst'},
    name             => $bookseller->{'name'},
    cur_active_sym   => $cur->{'symbol'},
    cur_active       => $cur->{'currency'},
    currency         => $bookseller->{'listprice'}, # eg: 'EUR'
    loop_currencies  => \@loop_currency,
    orderexists      => ( $new eq 'yes' ) ? 0 : 1,
    title            => $data->{'title'},
    author           => $data->{'author'},
    publicationyear  => $data->{'publicationyear'},
    budget_dropbox   => $budget_dropbox,
    isbn             => $data->{'isbn'},
    seriestitle      => $data->{'seriestitle'},
    quantity         => $data->{'quantity'},
    quantityrec      => $data->{'quantity'},
    rrp              => $data->{'rrp'},
    listprice        => sprintf("%.2f", $data->{'listprice'}||$listprice),
    total            => sprintf("%.2f", $data->{'ecost'}*$data->{'quantity'} ),
    ecost            => $data->{'ecost'},
    notes            => $data->{'notes'},
    publishercode    => $data->{'publishercode'},
    
    import_batch_id  => $import_batch_id,

# CHECKME: gst-stuff needs verifing, mason.
    gstrate          => $bookseller->{'gstrate'} || C4::Context->preference("gist"),
    gstreg           => $bookseller->{'gstreg'},
);

output_html_with_http_headers $input, $cookie, $template->output;


=item MARCfindbreeding

    $record = MARCfindbreeding($breedingid);

Look up the import record repository for the record with
record with id $breedingid.  If found, returns the decoded
MARC::Record; otherwise, -1 is returned (FIXME).
Returns as second parameter the character encoding.

=cut

sub MARCfindbreeding {
    my ( $id ) = @_;
    my ($marc, $encoding) = GetImportRecordMarc($id);
    # remove the - in isbn, koha store isbn without any -
    if ($marc) {
        my $record = MARC::Record->new_from_usmarc($marc);
        my ($isbnfield,$isbnsubfield) = GetMarcFromKohaField('biblioitems.isbn','');
        if ( $record->field($isbnfield) ) {
            foreach my $field ( $record->field($isbnfield) ) {
                foreach my $subfield ( $field->subfield($isbnsubfield) ) {
                    my $newisbn = $field->subfield($isbnsubfield);
                    $newisbn =~ s/-//g;
                    $field->update( $isbnsubfield => $newisbn );
                }
            }
        }
        # fix the unimarc 100 coded field (with unicode information)
        if (C4::Context->preference('marcflavour') eq 'UNIMARC' && $record->subfield(100,'a')) {
            my $f100a=$record->subfield(100,'a');
            my $f100 = $record->field(100);
            my $f100temp = $f100->as_string;
            $record->delete_field($f100);
            if ( length($f100temp) > 28 ) {
                substr( $f100temp, 26, 2, "50" );
                $f100->update( 'a' => $f100temp );
                my $f100 = MARC::Field->new( '100', '', '', 'a' => $f100temp );
                $record->insert_fields_ordered($f100);
            }
        }
        
        if ( !defined(ref($record)) ) {
            return -1;
        }
        else {
            # normalize author : probably UNIMARC specific...
            if (    C4::Context->preference("z3950NormalizeAuthor")
                and C4::Context->preference("z3950AuthorAuthFields") )
            {
                my ( $tag, $subfield ) = GetMarcFromKohaField("biblio.author");

#                 my $summary = C4::Context->preference("z3950authortemplate");
                my $auth_fields =
                C4::Context->preference("z3950AuthorAuthFields");
                my @auth_fields = split /,/, $auth_fields;
                my $field;

                if ( $record->field($tag) ) {
                    foreach my $tmpfield ( $record->field($tag)->subfields ) {

    #                        foreach my $subfieldcode ($tmpfield->subfields){
                        my $subfieldcode  = shift @$tmpfield;
                        my $subfieldvalue = shift @$tmpfield;
                        if ($field) {
                            $field->add_subfields(
                                "$subfieldcode" => $subfieldvalue )
                            if ( $subfieldcode ne $subfield );
                        }
                        else {
                            $field =
                            MARC::Field->new( $tag, "", "",
                                $subfieldcode => $subfieldvalue )
                            if ( $subfieldcode ne $subfield );
                        }
                    }
                }
                $record->delete_field( $record->field($tag) );
                foreach my $fieldtag (@auth_fields) {
                    next unless ( $record->field($fieldtag) );
                    my $lastname  = $record->field($fieldtag)->subfield('a');
                    my $firstname = $record->field($fieldtag)->subfield('b');
                    my $title     = $record->field($fieldtag)->subfield('c');
                    my $number    = $record->field($fieldtag)->subfield('d');
                    if ($title) {

#                         $field->add_subfields("$subfield"=>"[ ".ucfirst($title).ucfirst($firstname)." ".$number." ]");
                        $field->add_subfields(
                                "$subfield" => ucfirst($title) . " "
                            . ucfirst($firstname) . " "
                            . $number );
                    }
                    else {

#                       $field->add_subfields("$subfield"=>"[ ".ucfirst($firstname).", ".ucfirst($lastname)." ]");
                        $field->add_subfields(
                            "$subfield" => ucfirst($firstname) . ", "
                            . ucfirst($lastname) );
                    }
                }
                $record->insert_fields_ordered($field);
            }
            return $record, $encoding;
        }
    }
    return -1;
}

