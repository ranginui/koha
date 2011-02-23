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

package RPN2Solr;

use Modern::Perl;
use Net::Z3950::SimpleServer;
use Net::Z3950::OID;
use C4::Biblio;
use C4::Search;
use C4::AuthoritiesMarc;
use Regexp::Grammars::Z3950::RPN;
use Modern::Perl;
use C4::Search::Query;
use base 'Exporter';
our @EXPORT_OK = qw/ construct_string_from_node RPN2Solr /;

=head1 NAME

RPN2Solr - If use as script, launch a z3950 server on port 9999

=head1 DESCRIPTION

Launch a z3950 server. It can receive rpn query and return Solr results as usmarc and xml formats.

=head1 FUNCTIONS

=cut

my %parse_rpn = do {
    use Regexp::Grammars;
    ( operator => qr{ <nocontext:> <extends: Z3950::RPN> <operator>  }x
    , string   => qr{ <nocontext:> <extends: Z3950::RPN> <rpnstring> }x
    , query    => qr{ <nocontext:> <extends: Z3950::RPN> <query> }x
    );
};

=head2
search_handler function for SimpleServer
=cut
sub search_handler {
    my $args = shift;

    my $set_id = $$args{SETNAME};

    # Compatibily with plurals 'biblios' and 'authorities'
    for ( @{$$args{DATABASES}} ) {
        if ( $_ eq 'biblios' ) {
            $_ = 'biblio';
        }
        if ( $_ eq 'authorities' ) {
            $_ = 'authority';
        }
    }

    $$args{DATABASES} = ['biblio'] if $$args{DATABASES}[0] ~~ 'Default';
    my @database_list = @{ $$args{DATABASES} };

    my $query = RPN2Solr( $$args{QUERY} );
    $query = C4::Search::Query->normalSearch($query);
    my $results = SimpleSearch( $query, {recordtype => join ' OR ', @database_list} );

    $$args{HITS} = $$results{pager}{total_entries};
    $$args{HANDLE} = $results;
}

=head2
fetch_handler function for SimpleServer
=cut
sub fetch_handler {
    my $args = shift;

    my $set_id = $$args{SETNAME};
    my $offset = $$args{OFFSET};
    
    my $number_of_hits = $$args{HANDLE}{pager}{total_entries};

    my $item = @{ $$args{HANDLE}{items} }[$offset - 1];
    my $recordid = $$item{values}{recordid};
    my $recordtype = $$item{values}{recordtype};

    # "1.2.840.10003.5.109.10" == XML
    # "1.2.840.10003.5.10" == USmarc
    my $format_output = $$args{REQ_FORM} eq "1.2.840.10003.5.109.10"
        ? "xml"
        : "usmarc";

    my $record;
    given ( $format_output ) {
        # We must return an usmarc format
        when ( 'usmarc' ) {
            if ( $recordtype && $recordtype eq 'biblio' ) {
                $record = GetMarcBiblio( $recordid )->as_usmarc;
            }elsif ( $recordtype && $recordtype eq 'authority' ) {
                $record = GetAuthority ( $recordid )->as_usmarc;
            }
        }
        when ( 'xml' ) {
            # We must return a xml format
            my $parser = XML::LibXML->new();
            if ( $recordtype && $recordtype eq 'biblio' ) {
                $record = GetXmlBiblio ( $recordid );
            }elsif ( $recordtype && $recordtype eq 'authority' ) {
                $record = GetAuthorityXML ( $recordid );
            }
        }
        default {}
    }
    
    $$args{RECORD} = $record if $record;
    if ($number_of_hits == $args->{OFFSET}) {
        $$args{LAST} = 1;
    } else {
        $$args{LAST} = 0;
    }

    $$args{BASENAME} = $recordtype;

}

=head2
get correct operator
=cut
sub get_operator {
    my $operator = shift;
    given ( $operator ) {
        when ( 'prox' ) {
            # Not yet implemented
        }
        # Return uppercase operator
        default { return uc($operator) }
    }
}

=head2

=cut
sub construct_string_from_node {
    my $node = shift;
    
    my @string;
    my $value = $$node{term};
    my $index = C4::Search::Query::getIndexName(1016);
    my $bib1attr = 3; # default attribute relation type
    my $structure = 1; # default structure attribute
    my $truncate = 100; # default truncation attribute
    for my $key (keys %$node) {
        # Bib-1 only compliant. @attrset keyword happily ignored :)
        given ( $key ) {
            when ( 'operands' ) {
                # Construct operands node
                push @string, "(";
                push @string,  construct_string_from_node($$node{operands}[0]);
                push @string,  get_operator($$node{operator});
                push @string,  construct_string_from_node($$node{operands}[1]);
                push @string, ")";
            }
            when ( 'attrspec' ) {
                # Construct attrspec node
                for my $attrspec_node (@{$$node{attrspec}}) {
                    my %attr; 
                    @attr{qw/ key value /} = split /=/, $$attrspec_node{attr};
                    given ( $attr{key} ) {
                        when ( 1 ) {
                            $index = C4::Search::Query::getIndexName( $attr{value} );
                        }
                        when ( 2 ) { $bib1attr = $attr{value} }
                        when ( 4 ) { $structure = $attr{value} }
                        when ( 5 ) { $truncate = $attr{value} }
                    }
                }
            }
        }
    }

    if (defined $value) {
        # "" is not match by grammar TODO
        #$value = "[* TO *]" if $value eq "";

        given ( $truncate ) {
            when ( 1 ) { $value = "$value*"; } # Right
            when ( 2 ) { $value = "*$value"; } # Left
            when ( 3 ) { $value = "*$value*"; } # R & L
            when ( 100 ) {
                # Nothing todo
            }
        }

        given ( $structure ) {
            when ( 1 ) { $value = "'$value'"; }
            when ( 2 ) { }
            when ( 3 ) { }
            when ( 4 ) { }
            when ( 5 ) { 
                # Call C4::Search::Engine::Solr::NormalizeDate ?
            }
            when ( 6 ) { 
                for my $v (split ' ', $value) {
                    # TODO
                }
            }
            when ( 109 ) { }
        }

        given ( $bib1attr ) {
            # <
            when ( 1 ) { push @string, "$index:[* TO $value]"; }
            when ( 2 ) { push @string, "$index:[* TO $value]"; }
            
            # =
            when ( 3 ) { push @string, "$index:$value";        }
            
            # >
            when ( 4 ) { push @string, "$index:[$value TO *]"; }
            when ( 5 ) { push @string, "$index:[$value TO *]"; }
            when ( 6 ) { push @string, "!$index:$value";        }
        }
    }

    return "@string";
}

sub RPN2Solr {
    use Regexp::Grammars;

    my $query = shift;

    chomp $query;

    if ( $query =~ /$parse_rpn{query}/ ) {

        my %root = %/;

        my $subquery_node = $root{query}{subquery}; # Get the subquery node
        
        # Contruct node and return Solr query
        my $solr_query = construct_string_from_node($subquery_node);

        return $solr_query;

    }
}

sub init_handler {
        my $args = shift;

        $args->{IMP_NAME} = "Z3950-server";
        $args->{IMP_VER} = "0.1";
        $args->{ERR_CODE} = 0;

}

my $z = new Net::Z3950::SimpleServer(
    SEARCH => \&search_handler,
    FETCH  => \&fetch_handler,
    INIT => \&init_handler
);

$z->launch_server("z3950-server", @ARGV) unless caller;

