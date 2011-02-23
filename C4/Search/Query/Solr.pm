package C4::Search::Query::Solr;

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

use C4::Search::Query;

=head1 NAME

C4::Search::Query::Solr

=head1 SYNOPSIS

Generate new Solr query from indexes, operands and operators

=head1 DESCRIPTION

return a Solr query

=head1 FUNCTIONS

=cut

sub buildQuery {

    my ($class, $indexes, $operands, $operators) = @_;

    my $q = '';
    my $i = 0;
    my $index_name;

    @$operands or return "*:*"; #push @$operands, "[* TO *]";

    # Foreach operands
    for my $kw (@$operands){
        # First element
        if ($i == 0){
            if ( (my @x = eval {@$indexes} ) == 0 ){
                # There is no index, then query is in first operand
                $q = @$operands[0];
                last;
            }

            # Catch index name if it's not 'all_fields'
            if ( @$indexes[$i] ne 'all_fields' ) {
                $index_name = @$indexes[$i];
            }else{
                $index_name = '';
            }

            # Generate index:operand
            if ($index_name ne 'all_fields' && $index_name ne ''){
                $q .= $index_name . ':' . $kw;
            }else{
                $q .= $kw;
            }
            $i = $i + 1;
            next;
        }
        # And others
        $index_name = @$indexes[$i] if @$indexes[$i];
        given (uc(@$operators[$i-1])) {
            when ('AND'){
                if ($index_name ne 'all_fields'){
                    $q .= ' AND ' . $index_name . ':'.$kw;
                }else{
                    $q .= ' AND ' . $kw;
                }
            }
            when ('NOT'){
                if ($index_name ne 'all_fields'){
                    $q .= ' NOT ' . $index_name . ':'.$kw;
                }else{
                    $q .= ' NOT ' . $kw;
                }
            }
            default {
                if ($index_name ne 'all_fields'){
                    $q .= ' OR ' . $index_name . ':' . $kw;
                }else{
                    $q .= ' OR ' . $kw;
                }
            }
        }
        $i = $i + 1;
    }

    return $q;

}

sub normalSearch {
    my ($class, $query) = @_;

    # Particular *:* query
    if ($query  eq '*:*'){
        return $query;
    }

    my $new_query = C4::Search::Query::splitToken($query);

    $new_query =~ s/all_fields://g;

    # Upper case for operators
    $new_query =~ s/ or / OR /g;
    $new_query =~ s/ and / AND /g;
    $new_query =~ s/ not / NOT /g;

    return $new_query;
}

1;
