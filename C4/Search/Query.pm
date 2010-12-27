package C4::Search::Query;

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

use 5.10.0;

use C4::Search::Query::Solr;
use C4::Search::Query::Zebra;

sub new {

    my ($class, $indexes, $operands, $operators) = @_;

    my $search_engine = C4::Context->preference("SearchEngine");

    given( $search_engine ) {
        when( 'Zebra' ) {
            return C4::Search::Query::Zebra->new($indexes, $operands, $operators);
        }

        when( 'Solr' ) {
            return C4::Search::Query::Solr->new($indexes, $operands, $operators);
        }
    }
}

my %indexes_names;
sub getIndexName {
    my $code = shift;
    if ( exists $indexes_names{$code} ) {
        return $indexes_names{$code};
    }

    my $dbh = C4::Context->dbh or return 0;

    my $search_engine = C4::Context->preference("SearchEngine");

    given( $search_engine ) {
        when( 'Zebra' ) {
            my $sth = $dbh->prepare("SELECT code, rpn_index, ccl_index_name FROM indexes");
            $sth->execute;
            while ( my $line = $sth->fetchrow_hashref ) {
                $indexes_names{$sth->{code}}->{rpn_index} = $sth->{rpn_index};
                $indexes_names{$sth ->{code}}->{ccl_index_name} = $sth->{ccl_index_name};
            }
        }

        when( 'Solr' ) {
            my $sth = $dbh->prepare("SELECT code, type, sortable FROM indexes");
            $sth->execute;
            while ( my $line = $sth->fetchrow_hashref ) {
                $indexes_names{$line->{code}}->{name} = $line->{type}.'_'.$line->{code};
                $indexes_names{$line ->{code}}->{sortable} = $line->{sortable};
            }
            $indexes_names{all_fields}->{name} = 'all_fields';
            $indexes_names{all_fields}->{sortable} = 0;
        }
    }

    return $indexes_names{$code};

}

1;
