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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA


use strict;
use warnings;
use CGI;
use XML::RSS;
use C4::Items;
use C4::Auth;
use C4::Output;


my $query        = new CGI;
my @itemtype	 = $query->param('itemtype');
my @branches	 = $query->param('branch');

my @lastacq = GetLastAcquisitions( 
 { 'branches' => \@branches, 'itemtypes' => \@itemtype }
 , 20
);

my $baseurl;
if(C4::Context->preference('OPACBaseURL')){
	 $baseurl = "http://".C4::Context->preference('OPACBaseURL')."/cgi-bin/koha";
}else{
	warn "No OPACBaseURL syspref";
	die
}

my $rss = XML::RSS->new(version => '1.0');
$rss->channel(
	title => "Last acquisitions",
	link => "$baseurl/opac-main.pl",
	, descriptions => "Last acquisitions of the library"
	);

for my $item (@lastacq){
	$rss->add_item(
	   title       => $item->{title},
	   link        => "$baseurl/opac-detail.pl?biblionumber=" . $item->{biblionumber},
 	);
}

print $query->header(
        -type    => "xml/rss",
        -charset => 'UTF-8',
        -Pragma => 'no-cache',
        -'Cache-Control' => 'no-cache',

	);
print $rss->as_string();
