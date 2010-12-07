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

use Net::Z3950::SimpleServer;
use C4::Biblio;
use C4::Search;
use C4::AuthoritiesMarc;
use Data::Dumper ("Dumper");

my $u = qw< 
       1 txt_name
       4 txt_title
       7 str_isbn
       8 str_issn
      30 date_date
      62 str_subject
    1003 txt_author
    1016 all_fields
>;

sub my_search_handler {
      my $args = shift;

      my $set_id = $$args{SETNAME};
      my @database_list = @{ $$args{DATABASES} };

      my $res = SimpleSearch( RPN2Solr( $$args{QUERY} ) );

      $$args{HITS} = $$res{pager}{total_entries};
      $$args{HANDLE} = $res;
}

sub my_fetch_handler {
      my $args = shift;

      my $set_id = $$args{SETNAME};
      my $offset = $$args{OFFSET};
      
      my $item = @{ $$args{HANDLE}{items} }[$offset - 1];
      my $recordid = $$item{values}{recordid};
      my $recordtype = $$item{values}{recordtype};
      
      my $record;
      if ( $recordtype eq 'biblio' ) {
          $record = GetMarcBiblio( $recordid );
      } elsif ( $recordtype eq 'authority' ) {
          $record = GetAuthority( $recordid );
      }

      $$args{RECORD} = $record->as_usmarc if $record;
      $$args{LAST} = number_of_hits == $$args{OFFSET};
}

sub RPN2Solr {
    use Regexp::Grammars;

    my $query = shift;

    # @attrset Bib-1 @attr 1=4 @attr 4=1 foo
    my $parser = qr{
        (?:<query>)

        <rule: query>
            <topset> <querystruct>
        
        <rule: topset>
            (?:\@attrset [a-zA-Z0-9\-]+)?
        
        <rule: querystruct>
            <[attrspec]>+ <term>
        
        <rule: attrspec>
            \@attr <bib1attr>=<bib1val>

        <token: bib1attr>
            [1-6]

        <token: bib1val>
            \d{1,4}

        <token: term>
            .+
    }x;

    if ( $query =~ $parser ) {
        my %tree = %/;
        my $qs = $tree{query}{querystruct};
        
        my $index;
        for ( @{ $$qs{attrspec} } ) {
            if ( $$_{bib1attr} == 1 ) {
                $index = $$u{ $$_{bib1val} };
            }
        }
        my $term  = $$qs{term};

        warn "$index:$term"; 
        return "$index:$term"; 
    }
}

my $z = new Net::Z3950::SimpleServer(
    SEARCH => \&my_search_handler,
    FETCH  => \&my_fetch_handler
);

$z->launch_server("testz3950.pl", @ARGV);
