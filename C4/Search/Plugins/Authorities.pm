package C4::Search::Plugins::Authorities;

# Copyright (C) 2010 BibLibre
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
use C4::AuthoritiesMarc;
use base 'Exporter';

our @EXPORT = qw/
       &ComputeValue
    /;
our $VERSION = 3.0.1;

=head2 fonction
    return rejected forms
=cut

sub ComputeValue {
    my $brecord = shift;
    
    my @bfieldstoindex = ( '6..', '7..' );
    my @afieldstoindex = ( '2..', '4..', '7..' );

    my @values;
    #for each 6..$9 and 7..$9 take authority linked
    for my $bfieldtoindex ( @bfieldstoindex ) {
        for my $bfield ( $brecord->field( $bfieldtoindex ) ) {
            for my $bsubfield ( $bfield->subfield( '9' ) ) {
                my $arecord = GetAuthority( $bsubfield );

                next unless $arecord;
                #for each 2.. and 4.. and 7.. (wich contains vedette, rejected and parralleles forms) of the authority return all subfields
                for my $afieldtoindex ( @afieldstoindex ) {
                    for my $afield ( $arecord->field( $afieldtoindex ) ) {
                        my @asubfields = $afield->subfields;
                        push @values, $_->[1] for @asubfields;
                    }
                }
            }
        }
    }

    return @values;
}

1;
