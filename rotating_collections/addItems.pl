#!/usr/bin/perl
use strict;
#use warnings; FIXME - Bug 2505
require Exporter;

use C4::Output;
use C4::Auth;
use C4::Context;
use C4::RotatingCollections;
use C4::Items;

use CGI;

my $query = new CGI;
my ($template, $loggedinuser, $cookie)
    = get_template_and_user({template_name => "rotating_collections/addItems.tmpl",
			     query => $query,
			     type => "intranet",
			     authnotrequired => 1,
			     flagsrequired => {parameters => 1},
			     debug => 1,
			     });

if ( $query->param('action') eq 'addItem' ) {
  ## Add the given item to the collection
  my $colId = $query->param('colId');
  my $barcode = $query->param('barcode');
  my $removeItem = $query->param('removeItem');
  my $itemnumber = GetItemnumberFromBarcode( $barcode );

  my ( $success, $errorCode, $errorMessage );
  
  if ( ! $removeItem ) {
    ( $success, $errorCode, $errorMessage ) = AddItemToCollection( $colId, $itemnumber );

    $template->param(
      previousActionAdd => 1,
      addedBarcode => $barcode,
    );

    if ( $success ) {
      $template->param( addSuccess => 1 );
    } else {
      $template->param( addFailure => 1 );
      $template->param( failureMessage => $errorMessage );
    }
  } else {
    ## Remove the given item from the collection
    ( $success, $errorCode, $errorMessage ) = RemoveItemFromCollection( $colId, $itemnumber );

    $template->param(
      previousActionRemove => 1,
      removedBarcode => $barcode,
      removeChecked => 1,
    );

    if ( $success ) {
      $template->param( removeSuccess => 1 );
    } else {
      $template->param( removeFailure => 1 );
      $template->param( failureMessage => $errorMessage );
    }

  }  
}

my ( $colId, $colTitle, $colDescription, $colBranchcode ) = GetCollection( $query->param('colId') );
my $collectionItems = GetItemsInCollection( $colId );
if ( $collectionItems ) {
  $template->param( collectionItemsLoop => $collectionItems );
}

$template->param(
                intranetcolorstylesheet => C4::Context->preference("intranetcolorstylesheet"),
                intranetstylesheet => C4::Context->preference("intranetstylesheet"),
                IntranetNav => C4::Context->preference("IntranetNav"),
                                  
                colId => $colId,
                colTitle => $colTitle,
                colDescription => $colDescription,
                colBranchcode => $colBranchcode,
                );

output_html_with_http_headers $query, $cookie, $template->output;
