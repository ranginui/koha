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

# my $usecache=C4::Context->preference('usecache');
use CGI;
my $input = new CGI;

my $memd;


    require C4::Auth;
    C4::Auth->import();
    require C4::Output;
    C4::Output->import();
    require C4::VirtualShelves;
    C4::VirtualShelves->import();
    require C4::Branch;
    C4::Branch->import();
    require C4::Members;
    C4::Members->import();
    require C4::NewsChannels;
    C4::NewsChannels->import();
    require C4::Acquisition;
    C4::Acquisition->import();



my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => "opac-main.tmpl",
        type            => "opac",
        query           => $input,
        authnotrequired => 1,
        flagsrequired   => { borrow => 1 },
    }
);

my $usecache=1;
if ($usecache){
    require Cache::Memcached;
    Cache::Memcached->import();
    $memd = new Cache::Memcached(
	'servers'=>['127.0.0.1:11211'],
    );
    my $page = $memd->get("koha:opacmain:$borrowernumber");
    if ($page){
	output_html_with_http_headers $input, $cookie, $page;
        exit;
    }
}    






my $dbh   = C4::Context->dbh;
my $borrower = GetMember( $borrowernumber, 'borrowernumber' );
$template->param(
    textmessaging        => $borrower->{textmessaging},
);

# display news
# use cookie setting for language, bug default to syspref if it's not set
my $news_lang = $input->cookie('KohaOpacLanguage') || 'en';
my $all_koha_news   = &GetNewsToDisplay($news_lang);
my $koha_news_count = scalar @$all_koha_news;

$template->param(
    koha_news       => $all_koha_news,
    koha_news_count => $koha_news_count
);

$template->param(
    'Disable_Dictionary' => C4::Context->preference("Disable_Dictionary") )
  if ( C4::Context->preference("Disable_Dictionary") );

if ($usecache){
    my $page = $template->output();
    $memd->set("koha:opacmain:$borrowernumber", $page, 300);
}
C4::Output::output_html_with_http_headers $input, $cookie, $template->output;
