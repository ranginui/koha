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

    # if indexes_mapper already populate
    if ( (my @x = eval {%indexes_mapper} ) != 0) {
        return;
    }

    my $dbh = C4::Context->dbh or return 1;

    my $sth = $dbh->prepare("SELECT * FROM indexes");
    $sth->execute;

    # Populate hash
    while ( my $line = $sth->fetchrow_hashref ) {
        $indexes_mapper{ $line->{code} } = {
            Zebra => {
                rpn_index => $line->{rpn_index},
                ccl_index_name => $line->{ccl_index_name}
            },
            Solr => {
                name => $line->{type}.'_'.$line->{code},
                sortable => $line->{sortable}
            }
        };
    }

    # Add member for all fields
    $indexes_mapper{all_fields}->{Solr}->{name} = 'all_fields';
    $indexes_mapper{all_fields}->{Solr}->{sortable} = 0;
    $indexes_mapper{all_fields}->{Zebra}->{ccl_index_name} = 'kw';
}

=head2 getSolrIndex
Return Solr index name
=cut
sub getSolrIndex {
    my $index = shift;
    my $search_engine;

    # init mapper if it's not already done
    initIndexesMapper;

    # finding good index
    foreach my $code ( keys %indexes_mapper ) {
        if ( $indexes_mapper{$code}->{Zebra}->{ccl_index_name} && $indexes_mapper{$code}->{Zebra}->{ccl_index_name} eq $index ) {
            return $indexes_mapper{$code}->{Solr}->{name};
        }
    }

    # not find, it's a Solr index
    return $indexes_mapper{$index}->{Solr}->{name} if $indexes_mapper{$index};

    # else we return argument
    return $index;
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
Generate new Query functions of search engine used
=cut
sub new {

    my ($class, $indexes, $operands, $operators) = @_;

    my $search_engine = C4::Context->preference("SearchEngine");

    given( $search_engine ) {
        when( 'Zebra' ) {
            return C4::Search::Query::Zebra->new($indexes, $operands, $operators);
        }

        when( 'Solr' ) {
            warn Data::Dumper::Dumper $indexes;
            my $new_indexes;
            my $new_operands;
            my $idx;

            # 'Normal' search
            if ( (my @x = eval {@$indexes} ) == 0 ) {
                # Particular *:* query
                if (@$operands[0] eq '*:*'){
                    return C4::Search::Query::Solr->new($indexes, $operands, $operators);
                }

                my @values;
                my $attr;
                my $operand;
                push @$new_operands, @$operands[0];

                # Foreach couple of index:operand
                while ( @$operands[0] =~ m/[^ ]*:[^ ]*/g ) {
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
                    @$new_operands[0] =~ s/(^| )$old_idx:/ $idx:/;
                    @$new_operands[0] =~ s/:$old_operand/:$operand/;
                }
                # Delete first space causing by previous replacement
                @$new_operands[0] =~ s/^ //;

                # Upper case for operators
                @$new_operands[0] =~ s/ or / OR /g;
                @$new_operands[0] =~ s/ and / AND /g;
                @$new_operands[0] =~ s/ not / NOT /g;
            }else{
                # Advanced search
                for $idx (@$indexes){
                    push @$new_indexes, getIndexName $idx;
                }
                $new_operands = $operands;
            }

            return C4::Search::Query::Solr->new($new_indexes, $new_operands, $operators);
        }
    }
}

1;
