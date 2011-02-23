package C4::Search::Engine;

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

use utf8;
use Modern::Perl;
use Moose;

use C4::Context;
use C4::Search::Engine::Solr;

=head1 NAME

C4::Search::Engine - Functions for switching betweend differents search engines.

=head1 DESCRIPTION

The "SearchEngine" syspref provide wich search engine must be used and the good call is done.

=head1 FUNCTIONS

=cut

has 'searchengine' => ( 
    isa => 'Str', 
    is => 'rw'
);

sub find_searchengine {

    my ($self) = @_; 

    if (C4::Context->preference("SearchEngine") eq "Solr") {
        $self->searchengine("Solr");
    } elsif (C4::Context->preference("SearchEngine") eq "Zebra") {
        $self->searchengine("Zebra");
    } else {
        $self->searchengine("undef");
    }
 
}

sub search {

    my $self = shift(@_);

    if ($self->searchengine eq "Solr") {
        # SimpleSearch( $q, $filters, $page, $max_results, $sort)
        return C4::Search::Engine::Solr::SimpleSearch(@_);
    } elsif ($self->searchengine eq "Zebra") {
        # SimpleSearch( $query, $offset, $max_results, $servers ) 
        warn "Unsupported yet";
        #return C4::Search::Engine::Zebra->SimpleSearch(@_);
    }
}

sub index {

    my $self = shift(@_);

    if ($self->searchengine eq "Solr") {
        # SimpleSearch( $q, $filters, $page, $max_results, $sort)
        return C4::Search::Engine::Solr::IndexRecord(@_);
    } elsif ($self->searchengine eq "Zebra") {
        # SimpleSearch( $query, $offset, $max_results, $servers ) 
        warn "Unsupported yet";
        #return C4::Search::Engine::Zebra->IndexRecord(@_);
    }
}

1;
