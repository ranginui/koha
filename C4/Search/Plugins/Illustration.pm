package C4::Search::Plugins::Illustration;

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

use utf8;
use Modern::Perl;
use base 'Exporter';
use MARC::Record;

our @EXPORT = qw/
       &ComputeValue
    /;
our $VERSION = 3.0.1;

=head2 fonction
  take 4 first chars of 105a field and translate and return it.
=cut

sub ComputeValue {
    my ( $record ) = @_;

    my %h = (
	   'a' => 'illustrations',
	   'b' => 'cartes',
	   'c' => 'portraits',
	   'd' => 'cartes maritimes',
	   'e' => 'plans',
	   'f' => 'planches hors texte',
	   'g' => 'musique notée',
	   'h' => 'fac-similés',
	   'i' => 'armoiries',
	   'j' => 'tableaux généalogiques',
	   'k' => 'formulaires',
	   'l' => 'échantillons',
	   'm' => 'enregistrements sonores',
	   'n' => 'transparents',
	   'o' => 'enluminures',
	   'y' => 'sans illustration',
	   '#' => 'valeur non requise',
    );
    
    my @illustration;
    if ( my $f105a = $record->subfield('105', 'a') ) {
        my $p03 = substr $f105a, 0, 4;
	    @illustration = map { $h{ $_ } ? $h{ $_ } : () } split //, $p03;
    }

    return @illustration;
}

1;
