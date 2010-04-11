#!/usr/bin/perl

# Copyright 2000-2003 Katipo Communications
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
use C4::Koha;
use CGI;
use C4::Biblio;
use C4::Items;
use C4::Branch;
use C4::Acquisition;
use C4::Output;             # contains gettemplate
use C4::Auth;
use C4::Serials;
use C4::Dates qw/format_date/;
use C4::Circulation;  # to use itemissues
use C4::Search;		# enabled_staff_search_views

my $query=new CGI;

# FIXME  subject is not exported to the template?
my $subject=$query->param('subject');

# if its a subject we need to use the subject.tmpl
my ($template, $loggedinuser, $cookie) = get_template_and_user({
    template_name   => ($subject? 'catalogue/subject.tmpl':
                      'catalogue/moredetail.tmpl'),
    query           => $query,
    type            => "intranet",
    authnotrequired => 0,
    flagsrequired   => {catalogue => 1},
    });

# get variables

my $biblionumber=$query->param('biblionumber');
my $title=$query->param('title');
my $bi=$query->param('bi');
$bi = $biblionumber unless $bi;
my $data=GetBiblioData($biblionumber);
my $dewey = $data->{'dewey'};

#coping with subscriptions
my $subscriptionsnumber = CountSubscriptionFromBiblionumber($biblionumber);

# FIXME Dewey is a string, not a number, & we should use a function
# $dewey =~ s/0+$//;
# if ($dewey eq "000.") { $dewey = "";};
# if ($dewey < 10){$dewey='00'.$dewey;}
# if ($dewey < 100 && $dewey > 10){$dewey='0'.$dewey;}
# if ($dewey <= 0){
#      $dewey='';
# }
# $dewey=~ s/\.$//;
# $data->{'dewey'}=$dewey;

my @results;
my $fw = GetFrameworkCode($biblionumber);
my @items= GetItemsInfo($biblionumber);
my $count=@items;
$data->{'count'}=$count;

my $ccodes= GetKohaAuthorisedValues('items.ccode',$fw);
my $itemtypes = GetItemTypes;

$data->{'itemtypename'} = $itemtypes->{$data->{'itemtype'}}->{'description'};
$results[0]=$data;
my $itemnumber;
($itemnumber) and @items = (grep {$_->{'itemnumber'} == $itemnumber} @items);
foreach my $item (@items){
    $item->{itemlostloop}= GetAuthorisedValues(GetAuthValCode('items.itemlost',$fw),$item->{itemlost}) if GetAuthValCode('items.itemlost',$fw);
    $item->{itemdamagedloop}= GetAuthorisedValues(GetAuthValCode('items.damaged',$fw),$item->{damaged}) if GetAuthValCode('items.damaged',$fw);
    $item->{'collection'}              = $ccodes->{ $item->{ccode} };
    $item->{'itype'}                   = $itemtypes->{ $item->{'itype'} }->{'description'};
    $item->{'replacementprice'}        = sprintf( "%.2f", $item->{'replacementprice'} );
    $item->{'datelastborrowed'}        = format_date( $item->{'datelastborrowed'} );
    $item->{'dateaccessioned'}         = format_date( $item->{'dateaccessioned'} );
    $item->{'datelastseen'}            = format_date( $item->{'datelastseen'} );
    $item->{'copyvol'}                 = $item->{'copynumber'};

    my $order = GetOrderFromItemnumber( $item->{'itemnumber'} );
    $item->{'ordernumber'}             = $order->{'ordernumber'};
    $item->{'basketno'}                = $order->{'basketno'};
    $item->{'booksellerinvoicenumber'} = $order->{'booksellerinvoicenumber'};

    if ($item->{notforloantext} or $item->{itemlost} or $item->{damaged} or $item->{wthdrawn}) {
        $item->{status_advisory} = 1;
    }

    if (C4::Context->preference("IndependantBranches")) {
        #verifying rights
        my $userenv = C4::Context->userenv();
        unless (($userenv->{'flags'} == 1) or ($userenv->{'branch'} eq $item->{'homebranch'})) {
                $item->{'nomod'}=1;
        }
    }
    $item->{'homebranchname'} = GetBranchName($item->{'homebranch'});
    $item->{'holdingbranchname'} = GetBranchName($item->{'holdingbranch'});
    if ($item->{'datedue'}) {
        $item->{'datedue'} = format_date($item->{'datedue'});
        $item->{'issue'}= 1;
    } else {
        $item->{'issue'}= 0;
    }
}
$template->param(count => $data->{'count'},
	subscriptionsnumber => $subscriptionsnumber,
    subscriptiontitle   => $data->{title},
	C4::Search::enabled_staff_search_views,
);
$template->param(BIBITEM_DATA => \@results);
$template->param(ITEM_DATA => \@items);
$template->param(moredetailview => 1);
$template->param(loggedinuser => $loggedinuser);
$template->param(biblionumber => $biblionumber);
$template->param(biblioitemnumber => $bi);
$template->param(itemnumber => $itemnumber);
$template->param(ONLY_ONE => 1) if ( $itemnumber && $count != @items );
$template->param(z3950_search_params => C4::Search::z3950_search_args(GetBiblioData($biblionumber)));

output_html_with_http_headers $query, $cookie, $template->output;

