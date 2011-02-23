package C4::Search::Plugins::Availability;

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
use base 'Exporter';

our @EXPORT = qw/
       &ComputeValue
    /;
our $VERSION = 3.0.1;

=head2 fonction
    return 1 if an item is available
    seems wrong: 
       - dispo en rayon? = pas mis de côté + pas retiré + pas en cours de prêt + pas en transit
       - dispo au pret?
=cut

sub ComputeValue {
    my ( $record ) = @_;
    my $availability = 1;

    for ( $record->field('995') ) {
        $availability = 0 if $_->subfield('n');
    }

    return ( $availability );
}

1;
