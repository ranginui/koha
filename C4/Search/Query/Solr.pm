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

sub new {

    my ($class, $indexes, $operands, $operators) = @_;

    my $q = '';
    my $i = 0;
    for my $kw (@$operands){
        # First element
        if ($i == 0){
            if ( (my @x = eval {@$indexes} ) == 0 ){
                $q = @$operands[0];
                last;
            }
            if (@$indexes[$i] ne 'all_fields' && @$indexes[$i] ne ''){
                $q .= @$indexes[$i] . ':' . $kw;
            }else{
                $q .= $kw;
            }
            $i = $i + 1;
            next;
        }
        # And others
        given (@$operators[$i-1]) {
            when (undef){
                if (@$indexes[$i] ne 'all_fields'){
                    $q .= @$indexes[$i] . ':' . $kw;
                }else{
                    $q .= $kw;
                }

                $i = $i + 1;
                next;
            }
            given (@$operators[$i-1]) {
                when ('and'){
                    if (@$indexes[$i] ne 'all_fields'){
                        $q .= ' AND ' . @$indexes[$i] . ':'.$kw;
                    }else{
                        $q .= ' AND ' . $kw;
                    }
                }
                when ('or'){
                    if (@$indexes[$i] ne 'all_fields'){
                        $q .= ' OR ' . @$indexes[$i] . ':'.$kw;
                    }else{
                        $q .= ' OR ' . $kw;
                    }
                }
                when ('not'){
                    if (@$indexes[$i] ne 'all_fields'){
                        $q .= ' -' . @$indexes[$i] . ':'.$kw;
                    }else{
                        $q .= ' -' . $kw;
                    }
                }
            }
            $i = $i + 1;
        }
    }

    return $q;

}

1;
