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

use Modern::Perl; 
use C4::Search::Query::Solr;
use C4::Search::Query::Zebra;
use C4::Context;

=head1 NAME

C4::Search::Query

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut


# hash of indexes (contains zebra and solr indexes)
my %indexes_mapper;

=head2 initIndexesMapper
Initialize indexes hash from database (indexes table)

=cut
sub initIndexesMapper {

    return if %indexes_mapper;
    my $dbh = C4::Context->dbh or return 1;

    my $sth = $dbh->prepare("SELECT * FROM indexes WHERE ressource_type='biblio'");
    $sth->execute;

    my $datas = $sth->fetchall_hashref( qw(code) );

    %indexes_mapper =
    ( all_fields =>
    { Zebra =>
        { rpn_index => 0
        , ccl_index_name => 'kw'
        }
	, Solr =>
	    { name     => 'all_fields'
        , sortable => 0
	    }
	}

    , map {
	$$_{code} =>
	    { Zebra =>
		{ rpn_index      => $$_{rpn_index}
		, ccl_index_name => $$_{ccl_index_name}
		}
	    , Solr =>
		{ name           => $$_{type} . '_' . $$_{code}
		, sortable       => $$_{sortable}
		}
	    }
    } values %$datas);

}

=head2 getSolrIndexFromZebra
Return Solr index from zebra index
=cut
sub getSolrIndexFromZebra {
    my ( $name ) = @_;
    for ( values %indexes_mapper ) {
        return $$_{Solr}{name} if $$_{Zebra}{ccl_index_name} ~~ $name ;
    }
}

=head2 getSolrIndex
Return Solr index name
=cut
sub getSolrIndex {

    my $index = shift;

    # init mapper if it's not already done
    %indexes_mapper or initIndexesMapper;

    #warn Data::Dumper::Dumper %indexes_mapper;
    $indexes_mapper{$index}->{Solr}->{name} 
    || getSolrIndexFromZebra ($index)
    || $index

}

=head2 getZebraIndex
return Zebra index name
=cut
sub getZebraIndex {
    my $index = shift;
    my $search_engine;

    # init mapper if it's not already done
    initIndexesMapper;

    # finding good index
    foreach my $code ( keys %indexes_mapper ) {
        if ( $indexes_mapper{$code}->{Solr}->{name} && $indexes_mapper{$code}->{Solr}->{name} eq $index || $code eq $index) {
            return $indexes_mapper{$code}->{Zebra}->{ccl_index_name};
        }
    }

    # not find, we return argument
    return $index;
}


=head2
Return the corresponding index functions of search engine used
=cut
sub getIndexName {

    my $code = shift;

    my $search_engine = C4::Context->preference("SearchEngine");

    given ( $search_engine ) {
        when ( 'Solr' ) {
            return getSolrIndex($code);
        }

        when ( 'Zebra' ) {
            return getZebraIndex($code);
        }
    }

}

=head2
Return token with correct index name
=cut
sub splitToken {
    my $token = shift;

    my $idx;
    my $operand;

    my @values;
    my $attr;
    my $string = $token;
    # Foreach couple of index:operand
    while ( $token =~ m/[^ ]*:[^ ]*/g ) {
        @values = split ':', $&;
        $idx = (@values)[0];
        my $old_operand = (@values)[1];
        my $old_idx = $idx;
        $operand = $old_operand;

        # split on ',' for potential attr zebra
        @values = split ',', $idx;
        $idx = (@values)[0];
        $attr = (@values)[1];
        $idx = getIndexName $idx;

        given ( $attr ) {
            when ( 'phr' ) {
                # If phr on attr, we add ""
                if ( !$old_operand =~ /^"/ ) {
                    $operand = "$old_operand";
                }
                $operand =~ s/'(.*)'/"$1"/;
            }

            when ( 'wrdl' ) {
                # nothing to do, it's default Solr's configuration
            }
        }
        # Replace new index in string
        $string =~ s/(^| )$old_idx:/ $idx:/;
        $string =~ s/:$old_operand/:$operand/;
    }

    # Delete first space causing by previous replacement
    $string =~ s/^ //;

    return $string;
}

=head2
build query functions of search engine used
=cut
sub buildQuery {

    my ($class, $indexes, $operands, $operators) = @_;

    my $search_engine = C4::Context->preference("SearchEngine");

    given( $search_engine ) {
        when( 'Zebra' ) {
            return C4::Search::Query::Zebra->buildQuery($indexes, $operands, $operators);
        }

        when( 'Solr' ) {
            my $new_indexes;
            my $new_operands;
            my $idx;

            # 'Normal' search
            if ( not @$indexes ) {
                return C4::Search::Query->normalSearch(@$operands[0]);
            }else{
                # Advanced search
                for $idx (@$indexes){
                    push @$new_indexes, getIndexName $idx;
                }
                $new_operands = $operands;
            }

            return C4::Search::Query::Solr->buildQuery($new_indexes, $new_operands, $operators);
        }
    }
}

sub normalSearch {
    my ($class, $query) = @_;

    # Particular *:* query
    if ($query  eq '*:*'){
        return $query;
    }

    my $new_query = splitToken($query);

    # Upper case for operators
    $new_query =~ s/ or / OR /g;
    $new_query =~ s/ and / AND /g;
    $new_query =~ s/ not / NOT /g;

    return $new_query;

}

1;
