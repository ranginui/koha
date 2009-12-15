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
my $input = new CGI;

my $cache;

use C4::Auth;
use C4::Output;
use C4::VirtualShelves;
use C4::Branch;          # GetBranches
use C4::Members;         # GetMember
use C4::NewsChannels;    # get_opac_news
use C4::Acquisition;     # GetRecentAcqui
use C4::Languages qw(getTranslatedLanguages accept_language);

my $usecache=C4::Context->preference('usecache');

my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => "opac-main.tmpl",
        type            => "opac",
        query           => $input,
        authnotrequired => 1,
        flagsrequired   => { borrow => 1 },
    }
);

if ($usecache){
    require C4::Cache;                                                                                                                     
    C4::Cache->import();                                                                                                                   
    $cache = C4::Cache->new ( {'cache_type' => C4::Context->config("cache_type"),                                                          
				  'cache_servers' => C4::Context->config("cache_servers")                                                       
			      });   
    my $page = $cache->get("koha:opacmain:$borrowernumber:$cookie");
    if ($page){
	output_html_with_http_headers $input, $cookie, $page;
        exit;
    }
}    


my $dbh   = C4::Context->dbh;
my $borrower = GetMember( $borrowernumber, 'borrowernumber' );
my $casAuthentication = C4::Context->preference('casAuthentication');
$template->param(
    casAuthentication   => $casAuthentication,
);


my $borrower = GetMember( borrowernumber=>$borrowernumber );
$template->param(
    textmessaging        => $borrower->{textmessaging},
) if (ref($borrower) eq "HASH");

# display news
# use cookie setting for language, bug default to syspref if it's not set
(my $theme) = themelanguage(C4::Context->config('opachtdocs'),'opac-main.tmpl','opac',$input);

my $translations = getTranslatedLanguages('opac',$theme);
my @languages = ();
foreach my $trans (@$translations)
{
    push(@languages, $trans->{rfc4646_subtag});
}

my $news_lang;
if($input->cookie('KohaOpacLanguage')){
    $news_lang = $input->cookie('KohaOpacLanguage');
}else{
    while( !$news_lang && ( $ENV{HTTP_ACCEPT_LANGUAGE} =~ m/([a-zA-Z]{2,}-?[a-zA-Z]*)(;|,)?/g ) ){
        if( my @lang = grep { /^$1$/i } @languages ) {
            $news_lang = $lang[0];
        }
    }
    if (not $news_lang) {
        my @languages = split ",", C4::Context->preference("opaclanguages");
        $news_lang = @languages[0];
    }
}

$news_lang = $news_lang ? $news_lang : 'en' ;

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
    $cache->set("koha:opacmain:$borrowernumber", $page, 300);
}

# If GoogleIndicTransliteration system preference is On Set paramter to load Google's javascript in OPAC search screens 
if (C4::Context->preference('GoogleIndicTransliteration')) {
        $template->param('GoogleIndicTransliteration' => 1);
}

output_html_with_http_headers $input, $cookie, $template->output;

