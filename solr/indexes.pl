#!/usr/bin/perl

# Copyright 2009 BibLibre SARL
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
use warnings;
use CGI;
use C4::Koha;
use C4::Output;
use C4::Auth;
use C4::Search::Engine::Solr;

my $input = new CGI;
my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => "solr/indexes.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { reserveforothers => "place_holds" }, #TODO
    }
);

my $ressource_type = $input->param('ressource_type') || 'biblio';

if ( $input->param('op') and $input->param('op') eq 'edit' ) {
    my @code            = $input->param('code');
    my @label           = $input->param('label');
    my @type            = $input->param('type');
    my @faceted         = $input->param('faceted');
    my @sortable        = $input->param('sortable');
    my @plugin          = $input->param('plugin');
    my @avlists         = $input->param('avlists');
    my @mandatory       = $input->param('mandatory');
    my @rpn_index       = $input->param('rpn_index');
    my @ccl_index_name  = $input->param('ccl_index_name');

    my @indexes;
    for ( 0..@code-1 ) {
        my $icode = $code[$_];
        push @indexes, {
            'code'           => $icode,
            'label'          => $label[$_],
            'type'           => $type[$_],
            'faceted'        => scalar(grep(/^$icode$/, @faceted)),
            'sortable'       => scalar(grep(/^$icode$/, @sortable)),
            'plugin'         => $plugin[$_],
            'avlist'        => $avlists[$_],
            'mandatory'      => $mandatory[$_] eq '1' ? '1' : '0',
            'rpn_index'      => $rpn_index[$_],
            'ccl_index_name' => $ccl_index_name[$_],
        }
    }
    C4::Search::Engine::Solr::SetIndexes($ressource_type, \@indexes);
}

my $ressourcetypes = C4::Search::Engine::Solr::GetRessourceTypes;
my $indexloop      = C4::Search::Engine::Solr::GetIndexes($ressource_type);

# This block would be useless with template toolkit
my $pluginloop = [ map { {
    'name'  => ( m/([^\:]+)$/ )[0],
    'value' => $_,
} } C4::Search::Engine::Solr::GetSearchPlugins ];

my $categories = GetAuthorisedValueCategories;
my @avlists = ();
map {push @avlists, $_} @$categories;

my $avlistsloop = [ map { {
    'name' => $_,
    'value' => $_,
} } @avlists ];

# This block would be useless with template toolkit
my @ressourcetypeloop = map { {
    name     => $_->{'ressource_type'},
    selected => $ressource_type eq $_->{'ressource_type'},
} } @$ressourcetypes;

# This block would be useless with template toolkit
for my $i ( @$indexloop ) {    
    $i->{'pluginloop'} = [ map { { 
        'name'     => ( m/([^\:]+)$/ )[0],
        'value'    => $_,
        'selected' => $_ eq $i->{'plugin'},
    } } C4::Search::Engine::Solr::GetSearchPlugins ];

    $i->{'avlistsloop'} = [ map { {
        'name'     => ( m/([^\:]+)$/ )[0],
        'value'    => $_,
        'selected' => $_ eq $i->{'avlist'},
    } } @avlists ];
}
warn Data::Dumper::Dumper($indexloop);

$template->param(
    ressource_type    => $ressource_type,
    ressourcetypeloop => \@ressourcetypeloop,
    indexloop         => $indexloop,
    pluginloop        => $pluginloop,
    avlistsloop       => $avlistsloop,
);

output_html_with_http_headers $input, $cookie, $template->output;
