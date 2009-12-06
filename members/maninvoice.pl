#!/usr/bin/perl

#written 11/1/2000 by chris@katipo.oc.nz
#script to display borrowers account details


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

use strict;
use warnings;

use C4::Auth;
use C4::Output;
use CGI;
use C4::Members;
use C4::Accounts;
use C4::Items;
use C4::Branch;

my $input=new CGI;

my $borrowernumber=$input->param('borrowernumber');


# get borrower details
my $data=GetMember('borrowernumber'=>$borrowernumber);
my $add=$input->param('add');
if ($add){
#  print $input->header;
    my $barcode=$input->param('barcode');
    my $itemnum = GetItemnumberFromBarcode($barcode) if $barcode;
    my $desc=$input->param('desc');
    my $amount=$input->param('amount');
    my $type=$input->param('type');
    my $error=manualinvoice($borrowernumber,$itemnum,$desc,$type,$amount);
	if ($error){
		my ($template, $loggedinuser, $cookie)
		  = get_template_and_user({template_name => "members/maninvoice.tmpl",
					query => $input,
					type => "intranet",
					authnotrequired => 0,
					flagsrequired => {borrowers => 1},
					debug => 1,
					});
		if ($error =~ /FOREIGN KEY/ && $error =~ /itemnumber/){
			$template->param('ITEMNUMBER' => 1);
		}
		$template->param('ERROR' => $error);
        output_html_with_http_headers $input, $cookie, $template->output;
	}
	else {
		print $input->redirect("/cgi-bin/koha/members/boraccount.pl?borrowernumber=$borrowernumber");
		exit;
	}
} else {

	my ($template, $loggedinuser, $cookie)
	= get_template_and_user({template_name => "members/maninvoice.tmpl",
					query => $input,
					type => "intranet",
					authnotrequired => 0,
					flagsrequired => {borrowers => 1, updatecharges => 1},
					debug => 1,
					});
					
  # get authorised values with type of MANUAL_INV
  my @invoice_types;
  my $dbh = C4::Context->dbh;
  my $sth = $dbh->prepare('SELECT * FROM authorised_values WHERE category = "MANUAL_INV"');
  $sth->execute();
  while ( my $row = $sth->fetchrow_hashref() ) {
    push @invoice_types, $row;
  }
  $template->param( invoice_types_loop => \@invoice_types );

    if ( $data->{'category_type'} eq 'C') {
        my  ( $catcodes, $labels ) =  GetborCatFromCatType( 'A', 'WHERE category_type = ?' );
        my $cnt = scalar(@$catcodes);
        $template->param( 'CATCODE_MULTI' => 1) if $cnt > 1;
        $template->param( 'catcode' =>    $catcodes->[0])  if $cnt == 1;
    }

    $template->param( adultborrower => 1 ) if ( $data->{'category_type'} eq 'A' );
    my ($picture, $dberror) = GetPatronImage($data->{'cardnumber'});
    $template->param( picture => 1 ) if $picture;

	$template->param(
                borrowernumber => $borrowernumber,
		firstname => $data->{'firstname'},
                surname  => $data->{'surname'},
		cardnumber => $data->{'cardnumber'},
		categorycode => $data->{'categorycode'},
		category_type => $data->{'category_type'},
		categoryname  => $data->{'description'},
		address => $data->{'address'},
		address2 => $data->{'address2'},
		city => $data->{'city'},
		zipcode => $data->{'zipcode'},
		country => $data->{'country'},
		phone => $data->{'phone'},
		email => $data->{'email'},
		branchcode => $data->{'branchcode'},
		branchname => GetBranchName($data->{'branchcode'}),
		is_child        => ($data->{'category_type'} eq 'C'),
    );
    output_html_with_http_headers $input, $cookie, $template->output;
}
