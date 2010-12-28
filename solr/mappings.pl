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
        template_name   => "solr/mappings.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { reserveforothers => "place_holds" }, #TODO
    }
);

my $ressource_type = $input->param('ressource_type') || 'biblio';

if ( $input->param('op') and $input->param('op') eq 'edit' ) {
    my @field    = $input->param('field');
    my @subfield = $input->param('subfield');
    my @index    = $input->param('index');
    #warn Data::Dumper::Dumper(\@field, \@subfield, \@index);
    my @indexes;
    for ( 0..@field-1 ) {
        push @indexes, {
            'field'    => $field[$_],
            'subfield' => $subfield[$_],
            'index'    => $index[$_],
        }
    }
    #warn Data::Dumper::Dumper(\@indexes);
    C4::Search::Engine::Solr::SetMappings($ressource_type, \@indexes);
}

my $ressourcetypes = C4::Search::Engine::Solr::GetRessourceTypes;
my $mappingloop    = C4::Search::Engine::Solr::GetMappings($ressource_type);

# This block would be useless with template toolkit
my @ressourcetypeloop = map { {
    name     => $_->{'ressource_type'},
    selected => $ressource_type eq $_->{'ressource_type'},
} } @$ressourcetypes;

# This block would be useless with template toolkit
for my $m ( @$mappingloop ) {
    my $indexloop     = C4::Search::Engine::Solr::GetIndexes($ressource_type);
    $_->{'selected'}  = $_->{'code'} eq $m->{'index'} for @$indexloop;
    $m->{'indexloop'} = $indexloop;
}

$template->param(
    ressource_type    => $ressource_type,
    ressourcetypeloop => \@ressourcetypeloop,
    indexloop         => C4::Search::Engine::Solr::GetIndexes($ressource_type),
    mappingloop       => $mappingloop,
);

output_html_with_http_headers $input, $cookie, $template->output;

