#!/usr/bin/perl

# Copyright Chris Cormack and the Koha Dev Team 2009
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
use Koha::Templates;
use C4::NewsChannels;    # get_opac_news

my $input = new CGI;
my $dbh   = C4::Context->dbh;

my $template = Koha::Templates->new('opac','modules/opac-main.tt');

# my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
#    {
#        template_name   => "opac-main.tmpl",
#        type            => "opac",
#        query           => $input,
#        authnotrequired => 1,
#        flagsrequired   => { borrow => 1 },
#    }
# );

# my $borrower = GetMember( $borrowernumber, 'borrowernumber' );
my %template_variables;
# $template_variables{'textmessaging'} = $borrower->{textmessaging};

# display news
# use cookie setting for language, bug default to syspref if it's not set
my $news_lang = $input->cookie('KohaOpacLanguage') || 'en';
my $all_koha_news   = &GetNewsToDisplay($news_lang);
my $koha_news_count = scalar @$all_koha_news;

$template_variables{'koha_news'} = $all_koha_news;
$template_variables{'koha_news_count'} = $koha_news_count;

print $input->header;
$template->output(\%template_variables);
# output_html_with_http_headers $input, $cookie, $template->output;
