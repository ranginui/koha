package C4::AuthoritiesMarc::MARC21;

# Copyright (C) 2007 LibLime
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
use MARC::Record;
our $VERSION = 3.00;

=head1 NAME

C4::AuthoritiesMarc::MARC21

=head1 SYNOPSIS

use C4::AuthoritiesMarc::MARC21;

=head1 DESCRIPTION

This is a helper module providing functions used by
C<C4::AuthoritiesMarc> to deal with behavior specific
to MARC21 authority records (as opposed to other
MARC formats).

Functions from this module generally should not be used
directly; instead, use the appropriate function from
C<C4::Authorities> that will dispatch the appropriate
function based on the marcflavour system preference.

=head1 FUNCTIONS

=cut

=head2 get_heading_type_from_marc

=over 4

my $auth_type = get_auth_type_from_marc($marc);

=back

Given a MARC::Record object containing an authority record,
determine its heading type (e.g., personal name, topical term,
etc.).

=cut

=head2 default_auth_type_location

=over 4

my ($tag, $subfield) = default_auth_type_location();

=back

Get the tag and subfield used to store the heading type
if not specified in the MARC framework.  For MARC21,
this defaults to 942$a.

=cut

sub default_auth_type_location {
    return ('942', 'a');
}

=head2 fix_marc21_auth_type_location 

=over 4

fix_marc21_auth_type_location($auth_marc, $auth_type_tag, $auth_type_subfield);

=back

If the incoming C<MARC::Record> object has a 152$b, remove it.  If no
field already exists that contains the specified C<$auth_type_tag>
and C<$auth_type_subfield>, create a new field whose contents
are the original contents of the 152$b.

This routine exists to deal with a historical problem: MARC21
authority records in previous versions of Koha kept the
authority type in the 152$b.  While the 152 may be OK for UNIMARC,
a 9XX should have been used for MARC21.

This function is meant to be called from GetAuthority, GetAuthorityXML,
and AddAuthority.

FIXME: This function should be removed once it's determined
       that no MARC21 users of Koha are using the 152$b
       to store the authority type.

=cut

sub fix_marc21_auth_type_location {
    my ($auth_marc, $auth_type_tag, $auth_type_subfield) = @_;

    my $auth_type_code;
    return unless $auth_type_code = $auth_marc->subfield('152', 'b');
    $auth_marc->delete_field($auth_marc->field('152'));
    unless ($auth_marc->field($auth_type_tag) && $auth_marc->subfield($auth_type_tag, $auth_type_subfield)) {
        $auth_marc->add_fields($auth_type_tag,'','', $auth_type_subfield=>$auth_type_code); 
    }
    
}

=head1 AUTHOR

Koha Developement team <info@koha.org>

Galen Charlton <galen.charlton@liblime.com>

=cut

1;
