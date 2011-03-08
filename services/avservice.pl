#!/usr/bin/perl

use strict;
use warnings;
use C4::Koha;
use C4::Service;

my ( $query, $response ) = C4::Service->init( );
my ($op) = C4::Service->require_params('op');

if ( $op eq 'get_av' ) {
    &LoadAVFromCode;
} else {
    print $query->header( status => '404 unknown operator' );
}

sub LoadAVFromCode {
    my ($index) = C4::Service->require_params('index');
    warn "index:$index";
    my $avlist = C4::Search::Engine::Solr::GetAvlistFromCode ($index); 
    if (!$avlist) {
        C4::Service->return_error('not_found', 'do not have an authorized value list' );
    }
    my @authorised_values = GetAuthorisedValues ($avlist); 
    $response->param( av => @authorised_values );
    C4::Service->return_success($response);
} 
