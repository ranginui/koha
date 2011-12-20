package C4::Items;

# Copyright 2007 LibLime, Inc.
# Parts Copyright Biblibre 2010
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

use Carp;
use C4::Context;
use C4::Koha;
use C4::Biblio;
use C4::Dates qw/format_date format_date_in_iso/;
use MARC::Record;
use C4::ClassSource;
use C4::Log;
use C4::Branch;
require C4::Reserves;
use C4::Charset;
use C4::Acquisition;
use List::MoreUtils qw/any/;
use Data::Dumper; # used as part of logging item record changes, not just for
                  # debugging; so please don't remove this

use vars qw($VERSION @ISA @EXPORT);

BEGIN {
    $VERSION = 3.01;

	require Exporter;
    @ISA = qw( Exporter );

    # function exports
    @EXPORT = qw(
        GetItem
        AddItemFromMarc
        AddItem
        AddItemBatchFromMarc
        ModItemFromMarc
		Item2Marc
        ModItem
        ModDateLastSeen
        ModItemTransfer
        DelItem
    
        CheckItemPreSave
    
        GetItemStatus
        GetItemLocation
        GetLostItems
        GetItemsForInventory
        GetItemsCount
        GetItemInfosOf
        GetItemsByBiblioitemnumber
        GetItemsInfo
	GetItemsLocationInfo
	GetHostItemsInfo
        get_itemnumbers_of
	get_hostitemnumbers_of
        GetItemnumberFromBarcode
        GetBarcodeFromItemnumber
        GetHiddenItemnumbers
		DelItemCheck
		MoveItemFromBiblio 
		GetLatestAcquisitions
        CartToShelf

	GetAnalyticsCount
        GetItemHolds
    );
}

=head1 NAME

C4::Items - item management functions

=head1 DESCRIPTION

This module contains an API for manipulating item 
records in Koha, and is used by cataloguing, circulation,
acquisitions, and serials management.

A Koha item record is stored in two places: the
items table and embedded in a MARC tag in the XML
version of the associated bib record in C<biblioitems.marcxml>.
This is done to allow the item information to be readily
indexed (e.g., by Zebra), but means that each item
modification transaction must keep the items table
and the MARC XML in sync at all times.

Consequently, all code that creates, modifies, or deletes
item records B<must> use an appropriate function from 
C<C4::Items>.  If no existing function is suitable, it is
better to add one to C<C4::Items> than to use add
one-off SQL statements to add or modify items.

The items table will be considered authoritative.  In other
words, if there is ever a discrepancy between the items
table and the MARC XML, the items table should be considered
accurate.

=head1 HISTORICAL NOTE

Most of the functions in C<C4::Items> were originally in
the C<C4::Biblio> module.

=head1 CORE EXPORTED FUNCTIONS

The following functions are meant for use by users
of C<C4::Items>

=cut

=head2 GetItem

  $item = GetItem($itemnumber,$barcode,$serial);

Return item information, for a given itemnumber or barcode.
The return value is a hashref mapping item column
names to values.  If C<$serial> is true, include serial publication data.

=cut

sub GetItem {
    my ($itemnumber,$barcode, $serial) = @_;
    my $dbh = C4::Context->dbh;
	my $data;
    if ($itemnumber) {
        my $sth = $dbh->prepare("
            SELECT * FROM items 
            WHERE itemnumber = ?");
        $sth->execute($itemnumber);
        $data = $sth->fetchrow_hashref;
    } else {
        my $sth = $dbh->prepare("
            SELECT * FROM items 
            WHERE barcode = ?"
            );
        $sth->execute($barcode);		
        $data = $sth->fetchrow_hashref;
    }
    if ( $serial) {      
    my $ssth = $dbh->prepare("SELECT serialseq,publisheddate from serialitems left join serial on serialitems.serialid=serial.serialid where serialitems.itemnumber=?");
        $ssth->execute($data->{'itemnumber'}) ;
        ($data->{'serialseq'} , $data->{'publisheddate'}) = $ssth->fetchrow_array();
    }
	#if we don't have an items.itype, use biblioitems.itemtype.
	if( ! $data->{'itype'} ) {
		my $sth = $dbh->prepare("SELECT itemtype FROM biblioitems  WHERE biblionumber = ?");
		$sth->execute($data->{'biblionumber'});
		($data->{'itype'}) = $sth->fetchrow_array;
	}
    return $data;
}    # sub GetItem

=head2 CartToShelf

  CartToShelf($itemnumber);

Set the current shelving location of the item record
to its stored permanent shelving location.  This is
primarily used to indicate when an item whose current
location is a special processing ('PROC') or shelving cart
('CART') location is back in the stacks.

=cut

sub CartToShelf {
    my ( $itemnumber ) = @_;

    unless ( $itemnumber ) {
        croak "FAILED CartToShelf() - no itemnumber supplied";
    }

    my $item = GetItem($itemnumber);
    $item->{location} = $item->{permanent_location};
    ModItem($item, undef, $itemnumber);
}

=head2 AddItemFromMarc

  my ($biblionumber, $biblioitemnumber, $itemnumber) 
      = AddItemFromMarc($source_item_marc, $biblionumber);

Given a MARC::Record object containing an embedded item
record and a biblionumber, create a new item record.

=cut

sub AddItemFromMarc {
    my ( $source_item_marc, $biblionumber ) = @_;
    my $dbh = C4::Context->dbh;

    # parse item hash from MARC
    my $frameworkcode = GetFrameworkCode( $biblionumber );
	my ($itemtag,$itemsubfield)=GetMarcFromKohaField("items.itemnumber",$frameworkcode);
	
	my $localitemmarc=MARC::Record->new;
	$localitemmarc->append_fields($source_item_marc->field($itemtag));
    my $item = &TransformMarcToKoha( $dbh, $localitemmarc, $frameworkcode ,'items');
    my $unlinked_item_subfields = _get_unlinked_item_subfields($localitemmarc, $frameworkcode);
    return AddItem($item, $biblionumber, $dbh, $frameworkcode, $unlinked_item_subfields);
}

=head2 AddItem

  my ($biblionumber, $biblioitemnumber, $itemnumber) 
      = AddItem($item, $biblionumber[, $dbh, $frameworkcode, $unlinked_item_subfields]);

Given a hash containing item column names as keys,
create a new Koha item record.

The first two optional parameters (C<$dbh> and C<$frameworkcode>)
do not need to be supplied for general use; they exist
simply to allow them to be picked up from AddItemFromMarc.

The final optional parameter, C<$unlinked_item_subfields>, contains
an arrayref containing subfields present in the original MARC
representation of the item (e.g., from the item editor) that are
not mapped to C<items> columns directly but should instead
be stored in C<items.more_subfields_xml> and included in 
the biblio items tag for display and indexing.

=cut

sub AddItem {
    my $item = shift;
    my $biblionumber = shift;

    my $dbh           = @_ ? shift : C4::Context->dbh;
    my $frameworkcode = @_ ? shift : GetFrameworkCode( $biblionumber );
    my $unlinked_item_subfields;  
    if (@_) {
        $unlinked_item_subfields = shift
    };

    # needs old biblionumber and biblioitemnumber
    $item->{'biblionumber'} = $biblionumber;
    my $sth = $dbh->prepare("SELECT biblioitemnumber FROM biblioitems WHERE biblionumber=?");
    $sth->execute( $item->{'biblionumber'} );
    ($item->{'biblioitemnumber'}) = $sth->fetchrow;

    _set_defaults_for_add($item);
    _set_derived_columns_for_add($item);
    $item->{'more_subfields_xml'} = _get_unlinked_subfields_xml($unlinked_item_subfields);
    # FIXME - checks here
    unless ( $item->{itype} ) {  # default to biblioitem.itemtype if no itype
        my $itype_sth = $dbh->prepare("SELECT itemtype FROM biblioitems WHERE biblionumber = ?");
        $itype_sth->execute( $item->{'biblionumber'} );
        ( $item->{'itype'} ) = $itype_sth->fetchrow_array;
    }

	my ( $itemnumber, $error ) = _koha_new_item( $item, $item->{barcode} );
    $item->{'itemnumber'} = $itemnumber;

    ModZebra( $item->{biblionumber}, "specialUpdate", "biblioserver", undef, undef );
   
    logaction("CATALOGUING", "ADD", $itemnumber, "item") if C4::Context->preference("CataloguingLog");
    
    return ($item->{biblionumber}, $item->{biblioitemnumber}, $itemnumber);
}

=head2 AddItemBatchFromMarc

  ($itemnumber_ref, $error_ref) = AddItemBatchFromMarc($record, 
             $biblionumber, $biblioitemnumber, $frameworkcode);

Efficiently create item records from a MARC biblio record with
embedded item fields.  This routine is suitable for batch jobs.

This API assumes that the bib record has already been
saved to the C<biblio> and C<biblioitems> tables.  It does
not expect that C<biblioitems.marc> and C<biblioitems.marcxml>
are populated, but it will do so via a call to ModBibiloMarc.

The goal of this API is to have a similar effect to using AddBiblio
and AddItems in succession, but without inefficient repeated
parsing of the MARC XML bib record.

This function returns an arrayref of new itemsnumbers and an arrayref of item
errors encountered during the processing.  Each entry in the errors
list is a hashref containing the following keys:

=over

=item item_sequence

Sequence number of original item tag in the MARC record.

=item item_barcode

Item barcode, provide to assist in the construction of
useful error messages.

=item error_condition

Code representing the error condition.  Can be 'duplicate_barcode',
'invalid_homebranch', or 'invalid_holdingbranch'.

=item error_information

Additional information appropriate to the error condition.

=back

=cut

sub AddItemBatchFromMarc {
    my ($record, $biblionumber, $biblioitemnumber, $frameworkcode) = @_;
    my $error;
    my @itemnumbers = ();
    my @errors = ();
    my $dbh = C4::Context->dbh;

    # loop through the item tags and start creating items
    my @bad_item_fields = ();
    my ($itemtag, $itemsubfield) = &GetMarcFromKohaField("items.itemnumber",'');
    my $item_sequence_num = 0;
    ITEMFIELD: foreach my $item_field ($record->field($itemtag)) {
        $item_sequence_num++;
        # we take the item field and stick it into a new
        # MARC record -- this is required so far because (FIXME)
        # TransformMarcToKoha requires a MARC::Record, not a MARC::Field
        # and there is no TransformMarcFieldToKoha
        my $temp_item_marc = MARC::Record->new();
        $temp_item_marc->append_fields($item_field);
    
        # add biblionumber and biblioitemnumber
        my $item = TransformMarcToKoha( $dbh, $temp_item_marc, $frameworkcode, 'items' );
        my $unlinked_item_subfields = _get_unlinked_item_subfields($temp_item_marc, $frameworkcode);
        $item->{'more_subfields_xml'} = _get_unlinked_subfields_xml($unlinked_item_subfields);
        $item->{'biblionumber'} = $biblionumber;
        $item->{'biblioitemnumber'} = $biblioitemnumber;

        # check for duplicate barcode
        my %item_errors = CheckItemPreSave($item);
        if (%item_errors) {
            push @errors, _repack_item_errors($item_sequence_num, $item, \%item_errors);
            push @bad_item_fields, $item_field;
            next ITEMFIELD;
        }

        _set_defaults_for_add($item);
        _set_derived_columns_for_add($item);
        my ( $itemnumber, $error ) = _koha_new_item( $item, $item->{barcode} );
        warn $error if $error;
        push @itemnumbers, $itemnumber; # FIXME not checking error
        $item->{'itemnumber'} = $itemnumber;

        logaction("CATALOGUING", "ADD", $itemnumber, "item") if C4::Context->preference("CataloguingLog"); 

        my $new_item_marc = _marc_from_item_hash($item, $frameworkcode, $unlinked_item_subfields);
        $item_field->replace_with($new_item_marc->field($itemtag));
    }

    # remove any MARC item fields for rejected items
    foreach my $item_field (@bad_item_fields) {
        $record->delete_field($item_field);
    }

    # update the MARC biblio
 #   $biblionumber = ModBiblioMarc( $record, $biblionumber, $frameworkcode );

    return (\@itemnumbers, \@errors);
}

=head2 ModItemFromMarc

  ModItemFromMarc($item_marc, $biblionumber, $itemnumber);

This function updates an item record based on a supplied
C<MARC::Record> object containing an embedded item field.
This API is meant for the use of C<additem.pl>; for 
other purposes, C<ModItem> should be used.

This function uses the hash %default_values_for_mod_from_marc,
which contains default values for item fields to
apply when modifying an item.  This is needed beccause
if an item field's value is cleared, TransformMarcToKoha
does not include the column in the
hash that's passed to ModItem, which without
use of this hash makes it impossible to clear
an item field's value.  See bug 2466.

Note that only columns that can be directly
changed from the cataloging and serials
item editors are included in this hash.

Returns item record

=cut

my %default_values_for_mod_from_marc = (
    barcode              => undef, 
    booksellerid         => undef, 
    ccode                => undef, 
    'items.cn_source'    => undef, 
    copynumber           => undef, 
    damaged              => 0,
#    dateaccessioned      => undef,
    enumchron            => undef, 
    holdingbranch        => undef, 
    homebranch           => undef, 
    itemcallnumber       => undef, 
    itemlost             => 0,
    itemnotes            => undef, 
    itype                => undef, 
    location             => undef, 
    permanent_location   => undef,
    materials            => undef, 
    notforloan           => 0,
    paidfor              => undef, 
    price                => undef, 
    replacementprice     => undef, 
    replacementpricedate => undef, 
    restricted           => undef, 
    stack                => undef, 
    stocknumber          => undef, 
    uri                  => undef, 
    wthdrawn             => 0,
);

sub ModItemFromMarc {
    my $item_marc = shift;
    my $biblionumber = shift;
    my $itemnumber = shift;

    my $dbh           = C4::Context->dbh;
    my $frameworkcode = GetFrameworkCode($biblionumber);
    my ( $itemtag, $itemsubfield ) = GetMarcFromKohaField( "items.itemnumber", $frameworkcode );

    my $localitemmarc = MARC::Record->new;
    $localitemmarc->append_fields( $item_marc->field($itemtag) );
    my $item = &TransformMarcToKoha( $dbh, $localitemmarc, $frameworkcode, 'items' );
    foreach my $item_field ( keys %default_values_for_mod_from_marc ) {
        $item->{$item_field} = $default_values_for_mod_from_marc{$item_field} unless (exists $item->{$item_field});
    }
    my $unlinked_item_subfields = _get_unlinked_item_subfields( $localitemmarc, $frameworkcode );

    ModItem($item, $biblionumber, $itemnumber, $dbh, $frameworkcode, $unlinked_item_subfields); 
    return $item;
}

=head2 ModItem

  ModItem({ column => $newvalue }, $biblionumber, 
                  $itemnumber[, $original_item_marc]);

Change one or more columns in an item record and update
the MARC representation of the item.

The first argument is a hashref mapping from item column
names to the new values.  The second and third arguments
are the biblionumber and itemnumber, respectively.

The fourth, optional parameter, C<$unlinked_item_subfields>, contains
an arrayref containing subfields present in the original MARC
representation of the item (e.g., from the item editor) that are
not mapped to C<items> columns directly but should instead
be stored in C<items.more_subfields_xml> and included in 
the biblio items tag for display and indexing.

If one of the changed columns is used to calculate
the derived value of a column such as C<items.cn_sort>, 
this routine will perform the necessary calculation
and set the value.

=cut

sub ModItem {
    my $item = shift;
    my $biblionumber = shift;
    my $itemnumber = shift;

    # if $biblionumber is undefined, get it from the current item
    unless (defined $biblionumber) {
        $biblionumber = _get_single_item_column('biblionumber', $itemnumber);
    }

    my $dbh           = @_ ? shift : C4::Context->dbh;
    my $frameworkcode = @_ ? shift : GetFrameworkCode( $biblionumber );
    
    my $unlinked_item_subfields;  
    if (@_) {
        $unlinked_item_subfields = shift;
        $item->{'more_subfields_xml'} = _get_unlinked_subfields_xml($unlinked_item_subfields);
    };

    $item->{'itemnumber'} = $itemnumber or return undef;

    $item->{onloan} = undef if $item->{itemlost};

    _set_derived_columns_for_mod($item);
    _do_column_fixes_for_mod($item);
    # FIXME add checks
    # duplicate barcode
    # attempt to change itemnumber
    # attempt to change biblionumber (if we want
    # an API to relink an item to a different bib,
    # it should be a separate function)

    # update items table
    _koha_modify_item($item);

    # request that bib be reindexed so that searching on current
    # item status is possible
    ModZebra( $biblionumber, "specialUpdate", "biblioserver", undef, undef );

    logaction("CATALOGUING", "MODIFY", $itemnumber, Dumper($item)) if C4::Context->preference("CataloguingLog");
}

=head2 ModItemTransfer

  ModItemTransfer($itenumber, $frombranch, $tobranch);

Marks an item as being transferred from one branch
to another.

=cut

sub ModItemTransfer {
    my ( $itemnumber, $frombranch, $tobranch ) = @_;

    my $dbh = C4::Context->dbh;

    #new entry in branchtransfers....
    my $sth = $dbh->prepare(
        "INSERT INTO branchtransfers (itemnumber, frombranch, datesent, tobranch)
        VALUES (?, ?, NOW(), ?)");
    $sth->execute($itemnumber, $frombranch, $tobranch);

    ModItem({ holdingbranch => $tobranch }, undef, $itemnumber);
    ModDateLastSeen($itemnumber);
    return;
}

=head2 ModDateLastSeen

  ModDateLastSeen($itemnum);

Mark item as seen. Is called when an item is issued, returned or manually marked during inventory/stocktaking.
C<$itemnum> is the item number

=cut

sub ModDateLastSeen {
    my ($itemnumber) = @_;
    
    my $today = C4::Dates->new();    
    ModItem({ itemlost => 0, datelastseen => $today->output("iso") }, undef, $itemnumber);
}

=head2 DelItem

  DelItem($dbh, $biblionumber, $itemnumber);

Exported function (core API) for deleting an item record in Koha.

=cut

sub DelItem {
    my ( $dbh, $biblionumber, $itemnumber ) = @_;
    
    # FIXME check the item has no current issues
    
    _koha_delete_item( $dbh, $itemnumber );

    # get the MARC record
    my $record = GetMarcBiblio($biblionumber);
    ModZebra( $biblionumber, "specialUpdate", "biblioserver", undef, undef );

    # backup the record
    my $copy2deleted = $dbh->prepare("UPDATE deleteditems SET marc=? WHERE itemnumber=?");
    $copy2deleted->execute( $record->as_usmarc(), $itemnumber );
    # This last update statement makes that the timestamp column in deleteditems is updated too. If you remove these lines, please add a line to update the timestamp separately. See Bugzilla report 7146 and Biblio.pm (DelBiblio).

    #search item field code
    logaction("CATALOGUING", "DELETE", $itemnumber, "item") if C4::Context->preference("CataloguingLog");
}

=head2 CheckItemPreSave

    my $item_ref = TransformMarcToKoha($marc, 'items');
    # do stuff
    my %errors = CheckItemPreSave($item_ref);
    if (exists $errors{'duplicate_barcode'}) {
        print "item has duplicate barcode: ", $errors{'duplicate_barcode'}, "\n";
    } elsif (exists $errors{'invalid_homebranch'}) {
        print "item has invalid home branch: ", $errors{'invalid_homebranch'}, "\n";
    } elsif (exists $errors{'invalid_holdingbranch'}) {
        print "item has invalid holding branch: ", $errors{'invalid_holdingbranch'}, "\n";
    } else {
        print "item is OK";
    }

Given a hashref containing item fields, determine if it can be
inserted or updated in the database.  Specifically, checks for
database integrity issues, and returns a hash containing any
of the following keys, if applicable.

=over 2

=item duplicate_barcode

Barcode, if it duplicates one already found in the database.

=item invalid_homebranch

Home branch, if not defined in branches table.

=item invalid_holdingbranch

Holding branch, if not defined in branches table.

=back

This function does NOT implement any policy-related checks,
e.g., whether current operator is allowed to save an
item that has a given branch code.

=cut

sub CheckItemPreSave {
    my $item_ref = shift;

    my %errors = ();

    # check for duplicate barcode
    if (exists $item_ref->{'barcode'} and defined $item_ref->{'barcode'}) {
        my $existing_itemnumber = GetItemnumberFromBarcode($item_ref->{'barcode'});
        if ($existing_itemnumber) {
            if (!exists $item_ref->{'itemnumber'}                       # new item
                or $item_ref->{'itemnumber'} != $existing_itemnumber) { # existing item
                $errors{'duplicate_barcode'} = $item_ref->{'barcode'};
            }
        }
    }

    # check for valid home branch
    if (exists $item_ref->{'homebranch'} and defined $item_ref->{'homebranch'}) {
        my $branch_name = GetBranchName($item_ref->{'homebranch'});
        unless (defined $branch_name) {
            # relies on fact that branches.branchname is a non-NULL column,
            # so GetBranchName returns undef only if branch does not exist
            $errors{'invalid_homebranch'} = $item_ref->{'homebranch'};
        }
    }

    # check for valid holding branch
    if (exists $item_ref->{'holdingbranch'} and defined $item_ref->{'holdingbranch'}) {
        my $branch_name = GetBranchName($item_ref->{'holdingbranch'});
        unless (defined $branch_name) {
            # relies on fact that branches.branchname is a non-NULL column,
            # so GetBranchName returns undef only if branch does not exist
            $errors{'invalid_holdingbranch'} = $item_ref->{'holdingbranch'};
        }
    }

    return %errors;

}

=head1 EXPORTED SPECIAL ACCESSOR FUNCTIONS

The following functions provide various ways of 
getting an item record, a set of item records, or
lists of authorized values for certain item fields.

Some of the functions in this group are candidates
for refactoring -- for example, some of the code
in C<GetItemsByBiblioitemnumber> and C<GetItemsInfo>
has copy-and-paste work.

=cut

=head2 GetItemStatus

  $itemstatushash = GetItemStatus($fwkcode);

Returns a list of valid values for the
C<items.notforloan> field.

NOTE: does B<not> return an individual item's
status.

Can be MARC dependant.
fwkcode is optional.
But basically could be can be loan or not
Create a status selector with the following code

=head3 in PERL SCRIPT

 my $itemstatushash = getitemstatus;
 my @itemstatusloop;
 foreach my $thisstatus (keys %$itemstatushash) {
     my %row =(value => $thisstatus,
                 statusname => $itemstatushash->{$thisstatus}->{'statusname'},
             );
     push @itemstatusloop, \%row;
 }
 $template->param(statusloop=>\@itemstatusloop);

=head3 in TEMPLATE

 <select name="statusloop">
     <option value="">Default</option>
 <!-- TMPL_LOOP name="statusloop" -->
     <option value="<!-- TMPL_VAR name="value" -->" <!-- TMPL_IF name="selected" -->selected<!-- /TMPL_IF -->><!-- TMPL_VAR name="statusname" --></option>
 <!-- /TMPL_LOOP -->
 </select>

=cut

sub GetItemStatus {

    # returns a reference to a hash of references to status...
    my ($fwk) = @_;
    my %itemstatus;
    my $dbh = C4::Context->dbh;
    my $sth;
    $fwk = '' unless ($fwk);
    my ( $tag, $subfield ) =
      GetMarcFromKohaField( "items.notforloan", $fwk );
    if ( $tag and $subfield ) {
        my $sth =
          $dbh->prepare(
            "SELECT authorised_value
            FROM marc_subfield_structure
            WHERE tagfield=?
                AND tagsubfield=?
                AND frameworkcode=?
            "
          );
        $sth->execute( $tag, $subfield, $fwk );
        if ( my ($authorisedvaluecat) = $sth->fetchrow ) {
            my $authvalsth =
              $dbh->prepare(
                "SELECT authorised_value,lib
                FROM authorised_values 
                WHERE category=? 
                ORDER BY lib
                "
              );
            $authvalsth->execute($authorisedvaluecat);
            while ( my ( $authorisedvalue, $lib ) = $authvalsth->fetchrow ) {
                $itemstatus{$authorisedvalue} = $lib;
            }
            return \%itemstatus;
            exit 1;
        }
        else {

            #No authvalue list
            # build default
        }
    }

    #No authvalue list
    #build default
    $itemstatus{"1"} = "Not For Loan";
    return \%itemstatus;
}

=head2 GetItemLocation

  $itemlochash = GetItemLocation($fwk);

Returns a list of valid values for the
C<items.location> field.

NOTE: does B<not> return an individual item's
location.

where fwk stands for an optional framework code.
Create a location selector with the following code

=head3 in PERL SCRIPT

  my $itemlochash = getitemlocation;
  my @itemlocloop;
  foreach my $thisloc (keys %$itemlochash) {
      my $selected = 1 if $thisbranch eq $branch;
      my %row =(locval => $thisloc,
                  selected => $selected,
                  locname => $itemlochash->{$thisloc},
               );
      push @itemlocloop, \%row;
  }
  $template->param(itemlocationloop => \@itemlocloop);

=head3 in TEMPLATE

  <select name="location">
      <option value="">Default</option>
  <!-- TMPL_LOOP name="itemlocationloop" -->
      <option value="<!-- TMPL_VAR name="locval" -->" <!-- TMPL_IF name="selected" -->selected<!-- /TMPL_IF -->><!-- TMPL_VAR name="locname" --></option>
  <!-- /TMPL_LOOP -->
  </select>

=cut

sub GetItemLocation {

    # returns a reference to a hash of references to location...
    my ($fwk) = @_;
    my %itemlocation;
    my $dbh = C4::Context->dbh;
    my $sth;
    $fwk = '' unless ($fwk);
    my ( $tag, $subfield ) =
      GetMarcFromKohaField( "items.location", $fwk );
    if ( $tag and $subfield ) {
        my $sth =
          $dbh->prepare(
            "SELECT authorised_value
            FROM marc_subfield_structure 
            WHERE tagfield=? 
                AND tagsubfield=? 
                AND frameworkcode=?"
          );
        $sth->execute( $tag, $subfield, $fwk );
        if ( my ($authorisedvaluecat) = $sth->fetchrow ) {
            my $authvalsth =
              $dbh->prepare(
                "SELECT authorised_value,lib
                FROM authorised_values
                WHERE category=?
                ORDER BY lib"
              );
            $authvalsth->execute($authorisedvaluecat);
            while ( my ( $authorisedvalue, $lib ) = $authvalsth->fetchrow ) {
                $itemlocation{$authorisedvalue} = $lib;
            }
            return \%itemlocation;
            exit 1;
        }
        else {

            #No authvalue list
            # build default
        }
    }

    #No authvalue list
    #build default
    $itemlocation{"1"} = "Not For Loan";
    return \%itemlocation;
}

=head2 GetLostItems

  $items = GetLostItems( $where, $orderby );

This function gets a list of lost items.

=over 2

=item input:

C<$where> is a hashref. it containts a field of the items table as key
and the value to match as value. For example:

{ barcode    => 'abc123',
  homebranch => 'CPL',    }

C<$orderby> is a field of the items table by which the resultset
should be orderd.

=item return:

C<$items> is a reference to an array full of hashrefs with columns
from the "items" table as keys.

=item usage in the perl script:

  my $where = { barcode => '0001548' };
  my $items = GetLostItems( $where, "homebranch" );
  $template->param( itemsloop => $items );

=back

=cut

sub GetLostItems {
    # Getting input args.
    my $where   = shift;
    my $orderby = shift;
    my $dbh     = C4::Context->dbh;

    my $query   = "
        SELECT *
        FROM   items
            LEFT JOIN biblio ON (items.biblionumber = biblio.biblionumber)
            LEFT JOIN biblioitems ON (items.biblionumber = biblioitems.biblionumber)
            LEFT JOIN authorised_values ON (items.itemlost = authorised_values.authorised_value)
        WHERE
        	authorised_values.category = 'LOST'
          	AND itemlost IS NOT NULL
         	AND itemlost <> 0
    ";
    my @query_parameters;
    foreach my $key (keys %$where) {
        $query .= " AND $key LIKE ?";
        push @query_parameters, "%$where->{$key}%";
    }
    my @ordervalues = qw/title author homebranch itype barcode price replacementprice lib datelastseen location/;
    
    if ( defined $orderby && grep($orderby, @ordervalues)) {
        $query .= ' ORDER BY '.$orderby;
    }

    my $sth = $dbh->prepare($query);
    $sth->execute( @query_parameters );
    my $items = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$items, $row;
    }
    return $items;
}

=head2 GetItemsForInventory

  $itemlist = GetItemsForInventory($minlocation, $maxlocation, 
                 $location, $itemtype $datelastseen, $branch, 
                 $offset, $size, $statushash);

Retrieve a list of title/authors/barcode/callnumber, for biblio inventory.

The sub returns a reference to a list of hashes, each containing
itemnumber, author, title, barcode, item callnumber, and date last
seen. It is ordered by callnumber then title.

The required minlocation & maxlocation parameters are used to specify a range of item callnumbers
the datelastseen can be used to specify that you want to see items not seen since a past date only.
offset & size can be used to retrieve only a part of the whole listing (defaut behaviour)
$statushash requires a hashref that has the authorized values fieldname (intems.notforloan, etc...) as keys, and an arrayref of statuscodes we are searching for as values.

=cut

sub GetItemsForInventory {
    my ( $minlocation, $maxlocation,$location, $itemtype, $ignoreissued, $datelastseen, $branchcode, $branch, $offset, $size, $statushash ) = @_;
    my $dbh = C4::Context->dbh;
    my ( @bind_params, @where_strings );

    my $query = <<'END_SQL';
SELECT items.itemnumber, barcode, itemcallnumber, title, author, biblio.biblionumber, datelastseen
FROM items
  LEFT JOIN biblio ON items.biblionumber = biblio.biblionumber
  LEFT JOIN biblioitems on items.biblionumber = biblioitems.biblionumber
END_SQL
    if ($statushash){
        for my $authvfield (keys %$statushash){
            if ( scalar @{$statushash->{$authvfield}} > 0 ){
                my $joinedvals = join ',', @{$statushash->{$authvfield}};
                push @where_strings, "$authvfield in (" . $joinedvals . ")";
            }
        }
    }

    if ($minlocation) {
        push @where_strings, 'itemcallnumber >= ?';
        push @bind_params, $minlocation;
    }

    if ($maxlocation) {
        push @where_strings, 'itemcallnumber <= ?';
        push @bind_params, $maxlocation;
    }

    if ($datelastseen) {
        $datelastseen = format_date_in_iso($datelastseen);  
        push @where_strings, '(datelastseen < ? OR datelastseen IS NULL)';
        push @bind_params, $datelastseen;
    }

    if ( $location ) {
        push @where_strings, 'items.location = ?';
        push @bind_params, $location;
    }

    if ( $branchcode ) {
        if($branch eq "homebranch"){
        push @where_strings, 'items.homebranch = ?';
        }else{
            push @where_strings, 'items.holdingbranch = ?';
        }
        push @bind_params, $branchcode;
    }
    
    if ( $itemtype ) {
        push @where_strings, 'biblioitems.itemtype = ?';
        push @bind_params, $itemtype;
    }

    if ( $ignoreissued) {
        $query .= "LEFT JOIN issues ON items.itemnumber = issues.itemnumber ";
        push @where_strings, 'issues.date_due IS NULL';
    }

    if ( @where_strings ) {
        $query .= 'WHERE ';
        $query .= join ' AND ', @where_strings;
    }
    $query .= ' ORDER BY items.cn_sort, itemcallnumber, title';
    my $sth = $dbh->prepare($query);
    $sth->execute( @bind_params );

    my @results;
    $size--;
    while ( my $row = $sth->fetchrow_hashref ) {
        $offset-- if ($offset);
        $row->{datelastseen}=format_date($row->{datelastseen});
        if ( ( !$offset ) && $size ) {
            push @results, $row;
            $size--;
        }
    }
    return \@results;
}

=head2 GetItemsCount

  $count = &GetItemsCount( $biblionumber);

This function return count of item with $biblionumber

=cut

sub GetItemsCount {
    my ( $biblionumber ) = @_;
    my $dbh = C4::Context->dbh;
    my $query = "SELECT count(*)
          FROM  items 
          WHERE biblionumber=?";
    my $sth = $dbh->prepare($query);
    $sth->execute($biblionumber);
    my $count = $sth->fetchrow;  
    return ($count);
}

=head2 GetItemInfosOf

  GetItemInfosOf(@itemnumbers);

=cut

sub GetItemInfosOf {
    my @itemnumbers = @_;

    my $query = '
        SELECT *
        FROM items
        WHERE itemnumber IN (' . join( ',', @itemnumbers ) . ')
    ';
    return get_infos_of( $query, 'itemnumber' );
}

=head2 GetItemsByBiblioitemnumber

  GetItemsByBiblioitemnumber($biblioitemnumber);

Returns an arrayref of hashrefs suitable for use in a TMPL_LOOP
Called by C<C4::XISBN>

=cut

sub GetItemsByBiblioitemnumber {
    my ( $bibitem ) = @_;
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT * FROM items WHERE items.biblioitemnumber = ?") || die $dbh->errstr;
    # Get all items attached to a biblioitem
    my $i = 0;
    my @results; 
    $sth->execute($bibitem) || die $sth->errstr;
    while ( my $data = $sth->fetchrow_hashref ) {  
        # Foreach item, get circulation information
        my $sth2 = $dbh->prepare( "SELECT * FROM issues,borrowers
                                   WHERE itemnumber = ?
                                   AND issues.borrowernumber = borrowers.borrowernumber"
        );
        $sth2->execute( $data->{'itemnumber'} );
        if ( my $data2 = $sth2->fetchrow_hashref ) {
            # if item is out, set the due date and who it is out too
            $data->{'date_due'}   = $data2->{'date_due'};
            $data->{'cardnumber'} = $data2->{'cardnumber'};
            $data->{'borrowernumber'}   = $data2->{'borrowernumber'};
        }
        else {
            # set date_due to blank, so in the template we check itemlost, and wthdrawn 
            $data->{'date_due'} = '';                                                                                                         
        }    # else         
        # Find the last 3 people who borrowed this item.                  
        my $query2 = "SELECT * FROM old_issues, borrowers WHERE itemnumber = ?
                      AND old_issues.borrowernumber = borrowers.borrowernumber
                      ORDER BY returndate desc,timestamp desc LIMIT 3";
        $sth2 = $dbh->prepare($query2) || die $dbh->errstr;
        $sth2->execute( $data->{'itemnumber'} ) || die $sth2->errstr;
        my $i2 = 0;
        while ( my $data2 = $sth2->fetchrow_hashref ) {
            $data->{"timestamp$i2"} = $data2->{'timestamp'};
            $data->{"card$i2"}      = $data2->{'cardnumber'};
            $data->{"borrower$i2"}  = $data2->{'borrowernumber'};
            $i2++;
        }
        push(@results,$data);
    } 
    return (\@results); 
}

=head2 GetItemsInfo

  @results = GetItemsInfo($biblionumber);

Returns information about items with the given biblionumber.

C<GetItemsInfo> returns a list of references-to-hash. Each element
contains a number of keys. Most of them are attributes from the
C<biblio>, C<biblioitems>, C<items>, and C<itemtypes> tables in the
Koha database. Other keys include:

=over 2

=item C<$data-E<gt>{branchname}>

The name (not the code) of the branch to which the book belongs.

=item C<$data-E<gt>{datelastseen}>

This is simply C<items.datelastseen>, except that while the date is
stored in YYYY-MM-DD format in the database, here it is converted to
DD/MM/YYYY format. A NULL date is returned as C<//>.

=item C<$data-E<gt>{datedue}>

=item C<$data-E<gt>{class}>

This is the concatenation of C<biblioitems.classification>, the book's
Dewey code, and C<biblioitems.subclass>.

=item C<$data-E<gt>{ocount}>

I think this is the number of copies of the book available.

=item C<$data-E<gt>{order}>

If this is set, it is set to C<One Order>.

=back

=cut

sub GetItemsInfo {
    my ( $biblionumber ) = @_;
    my $dbh   = C4::Context->dbh;
    # note biblioitems.* must be avoided to prevent large marc and marcxml fields from killing performance.
    my $query = "
    SELECT items.*,
           biblio.*,
           biblioitems.volume,
           biblioitems.number,
           biblioitems.itemtype,
           biblioitems.isbn,
           biblioitems.issn,
           biblioitems.publicationyear,
           biblioitems.publishercode,
           biblioitems.volumedate,
           biblioitems.volumedesc,
           biblioitems.lccn,
           biblioitems.url,
           items.notforloan as itemnotforloan,
           itemtypes.description,
           itemtypes.notforloan as notforloan_per_itemtype,
           branchurl
     FROM items
     LEFT JOIN branches ON items.holdingbranch = branches.branchcode
     LEFT JOIN biblio      ON      biblio.biblionumber     = items.biblionumber
     LEFT JOIN biblioitems ON biblioitems.biblioitemnumber = items.biblioitemnumber
     LEFT JOIN itemtypes   ON   itemtypes.itemtype         = "
     . (C4::Context->preference('item-level_itypes') ? 'items.itype' : 'biblioitems.itemtype');
    $query .= " WHERE items.biblionumber = ? ORDER BY branches.branchname,items.dateaccessioned desc" ;
    my $sth = $dbh->prepare($query);
    $sth->execute($biblionumber);
    my $i = 0;
    my @results;
    my $serial;

    my $isth    = $dbh->prepare(
        "SELECT issues.*,borrowers.cardnumber,borrowers.surname,borrowers.firstname,borrowers.branchcode as bcode
        FROM   issues LEFT JOIN borrowers ON issues.borrowernumber=borrowers.borrowernumber
        WHERE  itemnumber = ?"
       );
	my $ssth = $dbh->prepare("SELECT serialseq,publisheddate from serialitems left join serial on serialitems.serialid=serial.serialid where serialitems.itemnumber=? "); 
	while ( my $data = $sth->fetchrow_hashref ) {
        my $datedue = '';
        my $count_reserves;
        $isth->execute( $data->{'itemnumber'} );
        if ( my $idata = $isth->fetchrow_hashref ) {
            $data->{borrowernumber} = $idata->{borrowernumber};
            $data->{cardnumber}     = $idata->{cardnumber};
            $data->{surname}     = $idata->{surname};
            $data->{firstname}     = $idata->{firstname};
            $data->{lastreneweddate} = $idata->{lastreneweddate};
            $datedue                = $idata->{'date_due'};
        if (C4::Context->preference("IndependantBranches")){
        my $userenv = C4::Context->userenv;
        if ( ($userenv) && ( $userenv->{flags} % 2 != 1 ) ) { 
            $data->{'NOTSAMEBRANCH'} = 1 if ($idata->{'bcode'} ne $userenv->{branch});
        }
        }
        }
		if ( $data->{'serial'}) {	
			$ssth->execute($data->{'itemnumber'}) ;
			($data->{'serialseq'} , $data->{'publisheddate'}) = $ssth->fetchrow_array();
			$serial = 1;
        }
		if ( $datedue eq '' ) {
            my ( $restype, $reserves ) =
              C4::Reserves::CheckReserves( $data->{'itemnumber'} );
# Previous conditional check with if ($restype) is not needed because a true
# result for one item will result in subsequent items defaulting to this true
# value.
            $count_reserves = $restype;
        }
        #get branch information.....
        my $bsth = $dbh->prepare(
            "SELECT * FROM branches WHERE branchcode = ?
        "
        );
        $bsth->execute( $data->{'holdingbranch'} );
        if ( my $bdata = $bsth->fetchrow_hashref ) {
            $data->{'branchname'} = $bdata->{'branchname'};
        }
        $data->{'datedue'}        = $datedue;
        $data->{'count_reserves'} = $count_reserves;

        # get notforloan complete status if applicable
        my $sthnflstatus = $dbh->prepare(
            'SELECT authorised_value
            FROM   marc_subfield_structure
            WHERE  kohafield="items.notforloan"
        '
        );

        $sthnflstatus->execute;
        my ($authorised_valuecode) = $sthnflstatus->fetchrow;
        if ($authorised_valuecode) {
            $sthnflstatus = $dbh->prepare(
                "SELECT lib FROM authorised_values
                 WHERE  category=?
                 AND authorised_value=?"
            );
            $sthnflstatus->execute( $authorised_valuecode,
                $data->{itemnotforloan} );
            my ($lib) = $sthnflstatus->fetchrow;
            $data->{notforloanvalue} = $lib;
        }

        # get restricted status and description if applicable
        my $restrictedstatus = $dbh->prepare(
            'SELECT authorised_value
            FROM   marc_subfield_structure
            WHERE  kohafield="items.restricted"
        '
        );

        $restrictedstatus->execute;
        ($authorised_valuecode) = $restrictedstatus->fetchrow;
        if ($authorised_valuecode) {
            $restrictedstatus = $dbh->prepare(
                "SELECT lib,lib_opac FROM authorised_values
                 WHERE  category=?
                 AND authorised_value=?"
            );
            $restrictedstatus->execute( $authorised_valuecode,
                $data->{restricted} );

            if ( my $rstdata = $restrictedstatus->fetchrow_hashref ) {
                $data->{restricted} = $rstdata->{'lib'};
                $data->{restrictedopac} = $rstdata->{'lib_opac'};
            }
        }

        # my stack procedures
        my $stackstatus = $dbh->prepare(
            'SELECT authorised_value
             FROM   marc_subfield_structure
             WHERE  kohafield="items.stack"
        '
        );
        $stackstatus->execute;

        ($authorised_valuecode) = $stackstatus->fetchrow;
        if ($authorised_valuecode) {
            $stackstatus = $dbh->prepare(
                "SELECT lib
                 FROM   authorised_values
                 WHERE  category=?
                 AND    authorised_value=?
            "
            );
            $stackstatus->execute( $authorised_valuecode, $data->{stack} );
            my ($lib) = $stackstatus->fetchrow;
            $data->{stack} = $lib;
        }
        # Find the last 3 people who borrowed this item.
        my $sth2 = $dbh->prepare("SELECT * FROM old_issues,borrowers
                                    WHERE itemnumber = ?
                                    AND old_issues.borrowernumber = borrowers.borrowernumber
                                    ORDER BY returndate DESC
                                    LIMIT 3");
        $sth2->execute($data->{'itemnumber'});
        my $ii = 0;
        while (my $data2 = $sth2->fetchrow_hashref()) {
            $data->{"timestamp$ii"} = $data2->{'timestamp'} if $data2->{'timestamp'};
            $data->{"card$ii"}      = $data2->{'cardnumber'} if $data2->{'cardnumber'};
            $data->{"borrower$ii"}  = $data2->{'borrowernumber'} if $data2->{'borrowernumber'};
            $ii++;
        }

        $results[$i] = $data;
        $i++;
    }
	if($serial) {
		return( sort { ($b->{'publisheddate'} || $b->{'enumchron'}) cmp ($a->{'publisheddate'} || $a->{'enumchron'}) } @results );
	} else {
    	return (@results);
	}
}

=head2 GetItemsLocationInfo

  my @itemlocinfo = GetItemsLocationInfo($biblionumber);

Returns the branch names, shelving location and itemcallnumber for each item attached to the biblio in question

C<GetItemsInfo> returns a list of references-to-hash. Data returned:

=over 2

=item C<$data-E<gt>{homebranch}>

Branch Name of the item's homebranch

=item C<$data-E<gt>{holdingbranch}>

Branch Name of the item's holdingbranch

=item C<$data-E<gt>{location}>

Item's shelving location code

=item C<$data-E<gt>{location_intranet}>

The intranet description for the Shelving Location as set in authorised_values 'LOC'

=item C<$data-E<gt>{location_opac}>

The OPAC description for the Shelving Location as set in authorised_values 'LOC'.  Falls back to intranet description if no OPAC 
description is set.

=item C<$data-E<gt>{itemcallnumber}>

Item's itemcallnumber

=item C<$data-E<gt>{cn_sort}>

Item's call number normalized for sorting

=back
  
=cut

sub GetItemsLocationInfo {
        my $biblionumber = shift;
        my @results;

	my $dbh = C4::Context->dbh;
	my $query = "SELECT a.branchname as homebranch, b.branchname as holdingbranch, 
			    location, itemcallnumber, cn_sort
		     FROM items, branches as a, branches as b
		     WHERE homebranch = a.branchcode AND holdingbranch = b.branchcode 
		     AND biblionumber = ?
		     ORDER BY cn_sort ASC";
	my $sth = $dbh->prepare($query);
        $sth->execute($biblionumber);

        while ( my $data = $sth->fetchrow_hashref ) {
             $data->{location_intranet} = GetKohaAuthorisedValueLib('LOC', $data->{location});
             $data->{location_opac}= GetKohaAuthorisedValueLib('LOC', $data->{location}, 1);
	     push @results, $data;
	}
	return @results;
}

=head2 GetHostItemsInfo

	$hostiteminfo = GetHostItemsInfo($hostfield);
	Returns the iteminfo for items linked to records via a host field

=cut

sub GetHostItemsInfo {
	my ($record) = @_;
	my @returnitemsInfo;

	if (C4::Context->preference('marcflavour') eq 'MARC21' ||
        C4::Context->preference('marcflavour') eq 'NORMARC'){
	    foreach my $hostfield ( $record->field('773') ) {
        	my $hostbiblionumber = $hostfield->subfield("0");
	        my $linkeditemnumber = $hostfield->subfield("9");
        	my @hostitemInfos = GetItemsInfo($hostbiblionumber);
	        foreach my $hostitemInfo (@hostitemInfos){
        	        if ($hostitemInfo->{itemnumber} eq $linkeditemnumber){
                	        push (@returnitemsInfo,$hostitemInfo);
				last;
                	}
        	}
	    }
	} elsif ( C4::Context->preference('marcflavour') eq 'UNIMARC'){
	    foreach my $hostfield ( $record->field('461') ) {
        	my $hostbiblionumber = $hostfield->subfield("0");
	        my $linkeditemnumber = $hostfield->subfield("9");
        	my @hostitemInfos = GetItemsInfo($hostbiblionumber);
	        foreach my $hostitemInfo (@hostitemInfos){
        	        if ($hostitemInfo->{itemnumber} eq $linkeditemnumber){
                	        push (@returnitemsInfo,$hostitemInfo);
				last;
                	}
        	}
	    }
	}
	return @returnitemsInfo;
}


=head2 GetLastAcquisitions

  my $lastacq = GetLastAcquisitions({'branches' => ('branch1','branch2'), 
                                    'itemtypes' => ('BK','BD')}, 10);

=cut

sub  GetLastAcquisitions {
	my ($data,$max) = @_;

	my $itemtype = C4::Context->preference('item-level_itypes') ? 'itype' : 'itemtype';
	
	my $number_of_branches = @{$data->{branches}};
	my $number_of_itemtypes   = @{$data->{itemtypes}};
	
	
	my @where = ('WHERE 1 '); 
	$number_of_branches and push @where
	   , 'AND holdingbranch IN (' 
	   , join(',', ('?') x $number_of_branches )
	   , ')'
	 ;
	
	$number_of_itemtypes and push @where
	   , "AND $itemtype IN (" 
	   , join(',', ('?') x $number_of_itemtypes )
	   , ')'
	 ;

	my $query = "SELECT biblio.biblionumber as biblionumber, title, dateaccessioned
				 FROM items RIGHT JOIN biblio ON (items.biblionumber=biblio.biblionumber) 
			            RIGHT JOIN biblioitems ON (items.biblioitemnumber=biblioitems.biblioitemnumber)
			            @where
			            GROUP BY biblio.biblionumber 
			            ORDER BY dateaccessioned DESC LIMIT $max";

	my $dbh = C4::Context->dbh;
	my $sth = $dbh->prepare($query);
    
    $sth->execute((@{$data->{branches}}, @{$data->{itemtypes}}));
	
	my @results;
	while( my $row = $sth->fetchrow_hashref){
		push @results, {date => $row->{dateaccessioned} 
						, biblionumber => $row->{biblionumber}
						, title => $row->{title}};
	}
	
	return @results;
}

=head2 get_itemnumbers_of

  my @itemnumbers_of = get_itemnumbers_of(@biblionumbers);

Given a list of biblionumbers, return the list of corresponding itemnumbers
for each biblionumber.

Return a reference on a hash where keys are biblionumbers and values are
references on array of itemnumbers.

=cut

sub get_itemnumbers_of {
    my @biblionumbers = @_;

    my $dbh = C4::Context->dbh;

    my $query = '
        SELECT itemnumber,
            biblionumber
        FROM items
        WHERE biblionumber IN (?' . ( ',?' x scalar @biblionumbers - 1 ) . ')
    ';
    my $sth = $dbh->prepare($query);
    $sth->execute(@biblionumbers);

    my %itemnumbers_of;

    while ( my ( $itemnumber, $biblionumber ) = $sth->fetchrow_array ) {
        push @{ $itemnumbers_of{$biblionumber} }, $itemnumber;
    }

    return \%itemnumbers_of;
}

=head2 get_hostitemnumbers_of

  my @itemnumbers_of = get_hostitemnumbers_of($biblionumber);

Given a biblionumber, return the list of corresponding itemnumbers that are linked to it via host fields

Return a reference on a hash where key is a biblionumber and values are
references on array of itemnumbers.

=cut


sub get_hostitemnumbers_of {
	my ($biblionumber) = @_;
	my $marcrecord = GetMarcBiblio($biblionumber);
        my (@returnhostitemnumbers,$tag, $biblio_s, $item_s);
	
	my $marcflavor = C4::Context->preference('marcflavour');
	if ($marcflavor eq 'MARC21' || $marcflavor eq 'NORMARC') {
        $tag='773';
        $biblio_s='0';
        $item_s='9';
    } elsif ($marcflavor eq 'UNIMARC') {
        $tag='461';
        $biblio_s='0';
        $item_s='9';
    }

    foreach my $hostfield ( $marcrecord->field($tag) ) {
        my $hostbiblionumber = $hostfield->subfield($biblio_s);
        my $linkeditemnumber = $hostfield->subfield($item_s);
        my @itemnumbers;
        if (my $itemnumbers = get_itemnumbers_of($hostbiblionumber)->{$hostbiblionumber})
        {
            @itemnumbers = @$itemnumbers;
        }
        foreach my $itemnumber (@itemnumbers){
            if ($itemnumber eq $linkeditemnumber){
                push (@returnhostitemnumbers,$itemnumber);
                last;
            }
        }
    }
    return @returnhostitemnumbers;
}


=head2 GetItemnumberFromBarcode

  $result = GetItemnumberFromBarcode($barcode);

=cut

sub GetItemnumberFromBarcode {
    my ($barcode) = @_;
    my $dbh = C4::Context->dbh;

    my $rq =
      $dbh->prepare("SELECT itemnumber FROM items WHERE items.barcode=?");
    $rq->execute($barcode);
    my ($result) = $rq->fetchrow;
    return ($result);
}

=head2 GetBarcodeFromItemnumber

  $result = GetBarcodeFromItemnumber($itemnumber);

=cut

sub GetBarcodeFromItemnumber {
    my ($itemnumber) = @_;
    my $dbh = C4::Context->dbh;

    my $rq =
      $dbh->prepare("SELECT barcode FROM items WHERE items.itemnumber=?");
    $rq->execute($itemnumber);
    my ($result) = $rq->fetchrow;
    return ($result);
}

=head2 GetHiddenItemnumbers

=over 4

$result = GetHiddenItemnumbers(@items);

=back

=cut

sub GetHiddenItemnumbers {
    my (@items) = @_;
    my @resultitems;

    my $yaml = C4::Context->preference('OpacHiddenItems');
    my $hidingrules;
    eval {
    	$hidingrules = YAML::Load($yaml);
    };
    if ($@) {
    	warn "Unable to parse OpacHiddenItems syspref : $@";
    	return ();
    } else {
    my $dbh = C4::Context->dbh;

	# For each item
	foreach my $item (@items) {

	    # We check each rule
	    foreach my $field (keys %$hidingrules) {
		my $query = "SELECT $field from items where itemnumber = ?";
		my $sth = $dbh->prepare($query);	
		$sth->execute($item->{'itemnumber'});
		my ($result) = $sth->fetchrow;

		# If the results matches the values in the yaml file
		if (any { $result eq $_ } @{$hidingrules->{$field}}) {

		    # We add the itemnumber to the list
		    push @resultitems, $item->{'itemnumber'};	    

		    # If at least one rule matched for an item, no need to test the others
		    last;
		}
	    }
	}
	return @resultitems;
    }

 }

=head3 get_item_authorised_values

find the types and values for all authorised values assigned to this item.

parameters: itemnumber

returns: a hashref malling the authorised value to the value set for this itemnumber

    $authorised_values = {
             'CCODE'      => undef,
             'DAMAGED'    => '0',
             'LOC'        => '3',
             'LOST'       => '0'
             'NOT_LOAN'   => '0',
             'RESTRICTED' => undef,
             'STACK'      => undef,
             'WITHDRAWN'  => '0',
             'branches'   => 'CPL',
             'cn_source'  => undef,
             'itemtypes'  => 'SER',
           };

Notes: see C4::Biblio::get_biblio_authorised_values for a similar method at the biblio level.

=cut

sub get_item_authorised_values {
    my $itemnumber = shift;

    # assume that these entries in the authorised_value table are item level.
    my $query = q(SELECT distinct authorised_value, kohafield
                    FROM marc_subfield_structure
                    WHERE kohafield like 'item%'
                      AND authorised_value != '' );

    my $itemlevel_authorised_values = C4::Context->dbh->selectall_hashref( $query, 'authorised_value' );
    my $iteminfo = GetItem( $itemnumber );
    # warn( Data::Dumper->Dump( [ $itemlevel_authorised_values ], [ 'itemlevel_authorised_values' ] ) );
    my $return;
    foreach my $this_authorised_value ( keys %$itemlevel_authorised_values ) {
        my $field = $itemlevel_authorised_values->{ $this_authorised_value }->{'kohafield'};
        $field =~ s/^items\.//;
        if ( exists $iteminfo->{ $field } ) {
            $return->{ $this_authorised_value } = $iteminfo->{ $field };
        }
    }
    # warn( Data::Dumper->Dump( [ $return ], [ 'return' ] ) );
    return $return;
}

=head3 get_authorised_value_images

find a list of icons that are appropriate for display based on the
authorised values for a biblio.

parameters: listref of authorised values, such as comes from
get_item_authorised_values or
from C4::Biblio::get_biblio_authorised_values

returns: listref of hashrefs for each image. Each hashref looks like this:

      { imageurl => '/intranet-tmpl/prog/img/itemtypeimg/npl/WEB.gif',
        label    => '',
        category => '',
        value    => '', }

Notes: Currently, I put on the full path to the images on the staff
side. This should either be configurable or not done at all. Since I
have to deal with 'intranet' or 'opac' in
get_biblio_authorised_values, perhaps I should be passing it in.

=cut

sub get_authorised_value_images {
    my $authorised_values = shift;

    my @imagelist;

    my $authorised_value_list = GetAuthorisedValues();
    # warn ( Data::Dumper->Dump( [ $authorised_value_list ], [ 'authorised_value_list' ] ) );
    foreach my $this_authorised_value ( @$authorised_value_list ) {
        if ( exists $authorised_values->{ $this_authorised_value->{'category'} }
             && $authorised_values->{ $this_authorised_value->{'category'} } eq $this_authorised_value->{'authorised_value'} ) {
            # warn ( Data::Dumper->Dump( [ $this_authorised_value ], [ 'this_authorised_value' ] ) );
            if ( defined $this_authorised_value->{'imageurl'} ) {
                push @imagelist, { imageurl => C4::Koha::getitemtypeimagelocation( 'intranet', $this_authorised_value->{'imageurl'} ),
                                   label    => $this_authorised_value->{'lib'},
                                   category => $this_authorised_value->{'category'},
                                   value    => $this_authorised_value->{'authorised_value'}, };
            }
        }
    }

    # warn ( Data::Dumper->Dump( [ \@imagelist ], [ 'imagelist' ] ) );
    return \@imagelist;

}

=head1 LIMITED USE FUNCTIONS

The following functions, while part of the public API,
are not exported.  This is generally because they are
meant to be used by only one script for a specific
purpose, and should not be used in any other context
without careful thought.

=cut

=head2 GetMarcItem

  my $item_marc = GetMarcItem($biblionumber, $itemnumber);

Returns MARC::Record of the item passed in parameter.
This function is meant for use only in C<cataloguing/additem.pl>,
where it is needed to support that script's MARC-like
editor.

=cut

sub GetMarcItem {
    my ( $biblionumber, $itemnumber ) = @_;

    # GetMarcItem has been revised so that it does the following:
    #  1. Gets the item information from the items table.
    #  2. Converts it to a MARC field for storage in the bib record.
    #
    # The previous behavior was:
    #  1. Get the bib record.
    #  2. Return the MARC tag corresponding to the item record.
    #
    # The difference is that one treats the items row as authoritative,
    # while the other treats the MARC representation as authoritative
    # under certain circumstances.

    my $itemrecord = GetItem($itemnumber);

    # Tack on 'items.' prefix to column names so that TransformKohaToMarc will work.
    # Also, don't emit a subfield if the underlying field is blank.

    
    return Item2Marc($itemrecord,$biblionumber);

}
sub Item2Marc {
	my ($itemrecord,$biblionumber)=@_;
    my $mungeditem = { 
        map {  
            defined($itemrecord->{$_}) && $itemrecord->{$_} ne '' ? ("items.$_" => $itemrecord->{$_}) : ()  
        } keys %{ $itemrecord } 
    };
    my $itemmarc = TransformKohaToMarc($mungeditem);
    my ( $itemtag, $itemsubfield ) = GetMarcFromKohaField("items.itemnumber",GetFrameworkCode($biblionumber)||'');

    my $unlinked_item_subfields = _parse_unlinked_item_subfields_from_xml($mungeditem->{'items.more_subfields_xml'});
    if (defined $unlinked_item_subfields and $#$unlinked_item_subfields > -1) {
		foreach my $field ($itemmarc->field($itemtag)){
            $field->add_subfields(@$unlinked_item_subfields);
        }
    }
	return $itemmarc;
}

=head1 PRIVATE FUNCTIONS AND VARIABLES

The following functions are not meant to be called
directly, but are documented in order to explain
the inner workings of C<C4::Items>.

=cut

=head2 %derived_columns

This hash keeps track of item columns that
are strictly derived from other columns in
the item record and are not meant to be set
independently.

Each key in the hash should be the name of a
column (as named by TransformMarcToKoha).  Each
value should be hashref whose keys are the
columns on which the derived column depends.  The
hashref should also contain a 'BUILDER' key
that is a reference to a sub that calculates
the derived value.

=cut

my %derived_columns = (
    'items.cn_sort' => {
        'itemcallnumber' => 1,
        'items.cn_source' => 1,
        'BUILDER' => \&_calc_items_cn_sort,
    }
);

=head2 _set_derived_columns_for_add 

  _set_derived_column_for_add($item);

Given an item hash representing a new item to be added,
calculate any derived columns.  Currently the only
such column is C<items.cn_sort>.

=cut

sub _set_derived_columns_for_add {
    my $item = shift;

    foreach my $column (keys %derived_columns) {
        my $builder = $derived_columns{$column}->{'BUILDER'};
        my $source_values = {};
        foreach my $source_column (keys %{ $derived_columns{$column} }) {
            next if $source_column eq 'BUILDER';
            $source_values->{$source_column} = $item->{$source_column};
        }
        $builder->($item, $source_values);
    }
}

=head2 _set_derived_columns_for_mod 

  _set_derived_column_for_mod($item);

Given an item hash representing a new item to be modified.
calculate any derived columns.  Currently the only
such column is C<items.cn_sort>.

This routine differs from C<_set_derived_columns_for_add>
in that it needs to handle partial item records.  In other
words, the caller of C<ModItem> may have supplied only one
or two columns to be changed, so this function needs to
determine whether any of the columns to be changed affect
any of the derived columns.  Also, if a derived column
depends on more than one column, but the caller is not
changing all of then, this routine retrieves the unchanged
values from the database in order to ensure a correct
calculation.

=cut

sub _set_derived_columns_for_mod {
    my $item = shift;

    foreach my $column (keys %derived_columns) {
        my $builder = $derived_columns{$column}->{'BUILDER'};
        my $source_values = {};
        my %missing_sources = ();
        my $must_recalc = 0;
        foreach my $source_column (keys %{ $derived_columns{$column} }) {
            next if $source_column eq 'BUILDER';
            if (exists $item->{$source_column}) {
                $must_recalc = 1;
                $source_values->{$source_column} = $item->{$source_column};
            } else {
                $missing_sources{$source_column} = 1;
            }
        }
        if ($must_recalc) {
            foreach my $source_column (keys %missing_sources) {
                $source_values->{$source_column} = _get_single_item_column($source_column, $item->{'itemnumber'});
            }
            $builder->($item, $source_values);
        }
    }
}

=head2 _do_column_fixes_for_mod

  _do_column_fixes_for_mod($item);

Given an item hashref containing one or more
columns to modify, fix up certain values.
Specifically, set to 0 any passed value
of C<notforloan>, C<damaged>, C<itemlost>, or
C<wthdrawn> that is either undefined or
contains the empty string.

=cut

sub _do_column_fixes_for_mod {
    my $item = shift;

    if (exists $item->{'notforloan'} and
        (not defined $item->{'notforloan'} or $item->{'notforloan'} eq '')) {
        $item->{'notforloan'} = 0;
    }
    if (exists $item->{'damaged'} and
        (not defined $item->{'damaged'} or $item->{'damaged'} eq '')) {
        $item->{'damaged'} = 0;
    }
    if (exists $item->{'itemlost'} and
        (not defined $item->{'itemlost'} or $item->{'itemlost'} eq '')) {
        $item->{'itemlost'} = 0;
    }
    if (exists $item->{'wthdrawn'} and
        (not defined $item->{'wthdrawn'} or $item->{'wthdrawn'} eq '')) {
        $item->{'wthdrawn'} = 0;
    }
    if (exists $item->{'location'} && !exists $item->{'permanent_location'}) {
        $item->{'permanent_location'} = $item->{'location'};
    }
    if (exists $item->{'timestamp'}) {
        delete $item->{'timestamp'};
    }
}

=head2 _get_single_item_column

  _get_single_item_column($column, $itemnumber);

Retrieves the value of a single column from an C<items>
row specified by C<$itemnumber>.

=cut

sub _get_single_item_column {
    my $column = shift;
    my $itemnumber = shift;
    
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT $column FROM items WHERE itemnumber = ?");
    $sth->execute($itemnumber);
    my ($value) = $sth->fetchrow();
    return $value; 
}

=head2 _calc_items_cn_sort

  _calc_items_cn_sort($item, $source_values);

Helper routine to calculate C<items.cn_sort>.

=cut

sub _calc_items_cn_sort {
    my $item = shift;
    my $source_values = shift;

    $item->{'items.cn_sort'} = GetClassSort($source_values->{'items.cn_source'}, $source_values->{'itemcallnumber'}, "");
}

=head2 _set_defaults_for_add 

  _set_defaults_for_add($item_hash);

Given an item hash representing an item to be added, set
correct default values for columns whose default value
is not handled by the DBMS.  This includes the following
columns:

=over 2

=item * 

C<items.dateaccessioned>

=item *

C<items.notforloan>

=item *

C<items.damaged>

=item *

C<items.itemlost>

=item *

C<items.wthdrawn>

=back

=cut

sub _set_defaults_for_add {
    my $item = shift;
    $item->{dateaccessioned} ||= C4::Dates->new->output('iso');
    $item->{$_} ||= 0 for (qw( notforloan damaged itemlost wthdrawn));
}

=head2 _koha_new_item

  my ($itemnumber,$error) = _koha_new_item( $item, $barcode );

Perform the actual insert into the C<items> table.

=cut

sub _koha_new_item {
    my ( $item, $barcode ) = @_;
    my $dbh=C4::Context->dbh;  
    my $error;
    my $query =
           "INSERT INTO items SET
            biblionumber        = ?,
            biblioitemnumber    = ?,
            barcode             = ?,
            dateaccessioned     = ?,
            booksellerid        = ?,
            homebranch          = ?,
            price               = ?,
            replacementprice    = ?,
            replacementpricedate = ?,
            datelastborrowed    = ?,
            datelastseen        = ?,
            stack               = ?,
            notforloan          = ?,
            damaged             = ?,
            itemlost            = ?,
            wthdrawn            = ?,
            itemcallnumber      = ?,
            restricted          = ?,
            itemnotes           = ?,
            holdingbranch       = ?,
            paidfor             = ?,
            location            = ?,
            permanent_location            = ?,
            onloan              = ?,
            issues              = ?,
            renewals            = ?,
            reserves            = ?,
            cn_source           = ?,
            cn_sort             = ?,
            ccode               = ?,
            itype               = ?,
            materials           = ?,
            uri = ?,
            enumchron           = ?,
            more_subfields_xml  = ?,
            copynumber          = ?,
            stocknumber         = ?
          ";
    my $sth = $dbh->prepare($query);
    my $today = C4::Dates->today('iso');
   $sth->execute(
            $item->{'biblionumber'},
            $item->{'biblioitemnumber'},
            $barcode,
            $item->{'dateaccessioned'},
            $item->{'booksellerid'},
            $item->{'homebranch'},
            $item->{'price'},
            $item->{'replacementprice'},
            $item->{'replacementpricedate'} || $today,
            $item->{datelastborrowed},
            $item->{datelastseen} || $today,
            $item->{stack},
            $item->{'notforloan'},
            $item->{'damaged'},
            $item->{'itemlost'},
            $item->{'wthdrawn'},
            $item->{'itemcallnumber'},
            $item->{'restricted'},
            $item->{'itemnotes'},
            $item->{'holdingbranch'},
            $item->{'paidfor'},
            $item->{'location'},
            $item->{'permanent_location'},
            $item->{'onloan'},
            $item->{'issues'},
            $item->{'renewals'},
            $item->{'reserves'},
            $item->{'items.cn_source'},
            $item->{'items.cn_sort'},
            $item->{'ccode'},
            $item->{'itype'},
            $item->{'materials'},
            $item->{'uri'},
            $item->{'enumchron'},
            $item->{'more_subfields_xml'},
            $item->{'copynumber'},
            $item->{'stocknumber'},
    );

    my $itemnumber;
    if ( defined $sth->errstr ) {
        $error.="ERROR in _koha_new_item $query".$sth->errstr;
    }
    else {
        $itemnumber = $dbh->{'mysql_insertid'};
    }

    return ( $itemnumber, $error );
}

=head2 MoveItemFromBiblio

  MoveItemFromBiblio($itenumber, $frombiblio, $tobiblio);

Moves an item from a biblio to another

Returns undef if the move failed or the biblionumber of the destination record otherwise

=cut

sub MoveItemFromBiblio {
    my ($itemnumber, $frombiblio, $tobiblio) = @_;
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT biblioitemnumber FROM biblioitems WHERE biblionumber = ?");
    $sth->execute( $tobiblio );
    my ( $tobiblioitem ) = $sth->fetchrow();
    $sth = $dbh->prepare("UPDATE items SET biblioitemnumber = ?, biblionumber = ? WHERE itemnumber = ? AND biblionumber = ?");
    my $return = $sth->execute($tobiblioitem, $tobiblio, $itemnumber, $frombiblio);
    if ($return == 1) {
        ModZebra( $tobiblio, "specialUpdate", "biblioserver", undef, undef );
        ModZebra( $frombiblio, "specialUpdate", "biblioserver", undef, undef );
	    # Checking if the item we want to move is in an order 
        my $order = GetOrderFromItemnumber($itemnumber);
	    if ($order) {
		    # Replacing the biblionumber within the order if necessary
		    $order->{'biblionumber'} = $tobiblio;
	        ModOrder($order);
	    }
        return $tobiblio;
	}
    return;
}

=head2 DelItemCheck

   DelItemCheck($dbh, $biblionumber, $itemnumber);

Exported function (core API) for deleting an item record in Koha if there no current issue.

=cut

sub DelItemCheck {
    my ( $dbh, $biblionumber, $itemnumber ) = @_;
    my $error;

        my $countanalytics=GetAnalyticsCount($itemnumber);


    # check that there is no issue on this item before deletion.
    my $sth=$dbh->prepare("select * from issues i where i.itemnumber=?");
    $sth->execute($itemnumber);

    my $item = GetItem($itemnumber);
    my $onloan=$sth->fetchrow;

    if ($onloan){
        $error = "book_on_loan" 
    }
    elsif ( C4::Context->userenv->{flags} & 1 and
            C4::Context->preference("IndependantBranches") and
           (C4::Context->userenv->{branch} ne
             $item->{C4::Context->preference("HomeOrHoldingBranch")||'homebranch'}) )
    {
        $error = "not_same_branch";
    }
	else{
        # check it doesnt have a waiting reserve
        $sth=$dbh->prepare("SELECT * FROM reserves WHERE (found = 'W' or found = 'T') AND itemnumber = ?");
        $sth->execute($itemnumber);
        my $reserve=$sth->fetchrow;
        if ($reserve){
            $error = "book_reserved";
        } elsif ($countanalytics > 0){
		$error = "linked_analytics";
	} else {
            DelItem($dbh, $biblionumber, $itemnumber);
            return 1;
        }
    }
    return $error;
}

=head2 _koha_modify_item

  my ($itemnumber,$error) =_koha_modify_item( $item );

Perform the actual update of the C<items> row.  Note that this
routine accepts a hashref specifying the columns to update.

=cut

sub _koha_modify_item {
    my ( $item ) = @_;
    my $dbh=C4::Context->dbh;  
    my $error;

    my $query = "UPDATE items SET ";
    my @bind;
    for my $key ( keys %$item ) {
        $query.="$key=?,";
        push @bind, $item->{$key};
    }
    $query =~ s/,$//;
    $query .= " WHERE itemnumber=?";
    push @bind, $item->{'itemnumber'};
    my $sth = C4::Context->dbh->prepare($query);
    $sth->execute(@bind);
    if ( C4::Context->dbh->errstr ) {
        $error.="ERROR in _koha_modify_item $query".$dbh->errstr;
        warn $error;
    }
    return ($item->{'itemnumber'},$error);
}

=head2 _koha_delete_item

  _koha_delete_item( $dbh, $itemnum );

Internal function to delete an item record from the koha tables

=cut

sub _koha_delete_item {
    my ( $dbh, $itemnum ) = @_;

    # save the deleted item to deleteditems table
    my $sth = $dbh->prepare("SELECT * FROM items WHERE itemnumber=?");
    $sth->execute($itemnum);
    my $data = $sth->fetchrow_hashref();
    my $query = "INSERT INTO deleteditems SET ";
    my @bind  = ();
    foreach my $key ( keys %$data ) {
        $query .= "$key = ?,";
        push( @bind, $data->{$key} );
    }
    $query =~ s/\,$//;
    $sth = $dbh->prepare($query);
    $sth->execute(@bind);

    # delete from items table
    $sth = $dbh->prepare("DELETE FROM items WHERE itemnumber=?");
    $sth->execute($itemnum);
    return undef;
}

=head2 _marc_from_item_hash

  my $item_marc = _marc_from_item_hash($item, $frameworkcode[, $unlinked_item_subfields]);

Given an item hash representing a complete item record,
create a C<MARC::Record> object containing an embedded
tag representing that item.

The third, optional parameter C<$unlinked_item_subfields> is
an arrayref of subfields (not mapped to C<items> fields per the
framework) to be added to the MARC representation
of the item.

=cut

sub _marc_from_item_hash {
    my $item = shift;
    my $frameworkcode = shift;
    my $unlinked_item_subfields;
    if (@_) {
        $unlinked_item_subfields = shift;
    }
   
    # Tack on 'items.' prefix to column names so lookup from MARC frameworks will work
    # Also, don't emit a subfield if the underlying field is blank.
    my $mungeditem = { map {  (defined($item->{$_}) and $item->{$_} ne '') ? 
                                (/^items\./ ? ($_ => $item->{$_}) : ("items.$_" => $item->{$_})) 
                                : ()  } keys %{ $item } }; 

    my $item_marc = MARC::Record->new();
    foreach my $item_field ( keys %{$mungeditem} ) {
        my ( $tag, $subfield ) = GetMarcFromKohaField( $item_field, $frameworkcode );
        next unless defined $tag and defined $subfield;    # skip if not mapped to MARC field
        my @values = split(/\s?\|\s?/, $mungeditem->{$item_field}, -1);
        foreach my $value (@values){
            if ( my $field = $item_marc->field($tag) ) {
                    $field->add_subfields( $subfield => $value );
            } else {
                my $add_subfields = [];
                if (defined $unlinked_item_subfields and ref($unlinked_item_subfields) eq 'ARRAY' and $#$unlinked_item_subfields > -1) {
                    $add_subfields = $unlinked_item_subfields;
            }
            $item_marc->add_fields( $tag, " ", " ", $subfield => $value, @$add_subfields );
            }
        }
    }

    return $item_marc;
}

=head2 _repack_item_errors

Add an error message hash generated by C<CheckItemPreSave>
to a list of errors.

=cut

sub _repack_item_errors {
    my $item_sequence_num = shift;
    my $item_ref = shift;
    my $error_ref = shift;

    my @repacked_errors = ();

    foreach my $error_code (sort keys %{ $error_ref }) {
        my $repacked_error = {};
        $repacked_error->{'item_sequence'} = $item_sequence_num;
        $repacked_error->{'item_barcode'} = exists($item_ref->{'barcode'}) ? $item_ref->{'barcode'} : '';
        $repacked_error->{'error_code'} = $error_code;
        $repacked_error->{'error_information'} = $error_ref->{$error_code};
        push @repacked_errors, $repacked_error;
    } 

    return @repacked_errors;
}

=head2 _get_unlinked_item_subfields

  my $unlinked_item_subfields = _get_unlinked_item_subfields($original_item_marc, $frameworkcode);

=cut

sub _get_unlinked_item_subfields {
    my $original_item_marc = shift;
    my $frameworkcode = shift;

    my $marcstructure = GetMarcStructure(1, $frameworkcode);

    # assume that this record has only one field, and that that
    # field contains only the item information
    my $subfields = [];
    my @fields = $original_item_marc->fields();
    if ($#fields > -1) {
        my $field = $fields[0];
	    my $tag = $field->tag();
        foreach my $subfield ($field->subfields()) {
            if (defined $subfield->[1] and
                $subfield->[1] ne '' and
                !$marcstructure->{$tag}->{$subfield->[0]}->{'kohafield'}) {
                push @$subfields, $subfield->[0] => $subfield->[1];
            }
        }
    }
    return $subfields;
}

=head2 _get_unlinked_subfields_xml

  my $unlinked_subfields_xml = _get_unlinked_subfields_xml($unlinked_item_subfields);

=cut

sub _get_unlinked_subfields_xml {
    my $unlinked_item_subfields = shift;

    my $xml;
    if (defined $unlinked_item_subfields and ref($unlinked_item_subfields) eq 'ARRAY' and $#$unlinked_item_subfields > -1) {
        my $marc = MARC::Record->new();
        # use of tag 999 is arbitrary, and doesn't need to match the item tag
        # used in the framework
        $marc->append_fields(MARC::Field->new('999', ' ', ' ', @$unlinked_item_subfields));
        $marc->encoding("UTF-8");    
        $xml = $marc->as_xml("USMARC");
    }

    return $xml;
}

=head2 _parse_unlinked_item_subfields_from_xml

  my $unlinked_item_subfields = _parse_unlinked_item_subfields_from_xml($whole_item->{'more_subfields_xml'}):

=cut

sub  _parse_unlinked_item_subfields_from_xml {
    my $xml = shift;

    return unless defined $xml and $xml ne "";
    my $marc = MARC::Record->new_from_xml(StripNonXmlChars($xml),'UTF-8');
    my $unlinked_subfields = [];
    my @fields = $marc->fields();
    if ($#fields > -1) {
        foreach my $subfield ($fields[0]->subfields()) {
            push @$unlinked_subfields, $subfield->[0] => $subfield->[1];
        }
    }
    return $unlinked_subfields;
}

=head2 GetAnalyticsCount

  $count= &GetAnalyticsCount($itemnumber)

counts Usage of itemnumber in Analytical bibliorecords. 

=cut

sub GetAnalyticsCount {
    my ($itemnumber) = @_;
    if (C4::Context->preference('NoZebra')) {
        # Read the index Koha-Auth-Number for this authid and count the lines
        my $result = C4::Search::NZanalyse("hi=$itemnumber");
        my @tab = split /;/,$result;
        return scalar @tab;
    } else {
        ### ZOOM search here
        my $query;
        $query= "hi=".$itemnumber;
                my ($err,$res,$result) = C4::Search::SimpleSearch($query,0,10);
        return ($result);
    }
}

=head2 GetItemHolds

=over 4
$holds = &GetItemHolds($biblionumber, $itemnumber);

=back

This function return the count of holds with $biblionumber and $itemnumber

=cut

sub GetItemHolds {
    my ($biblionumber, $itemnumber) = @_;
    my $holds;
    my $dbh            = C4::Context->dbh;
    my $query          = "SELECT count(*)
        FROM  reserves
        WHERE biblionumber=? AND itemnumber=?";
    my $sth = $dbh->prepare($query);
    $sth->execute($biblionumber, $itemnumber);
    $holds = $sth->fetchrow;
    return $holds;
}
1;
