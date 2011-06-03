#!/usr/bin/perl

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
use CGI;
use MIME::Base64;
use C4::External::Electre;
use 5.10.0;

my $query = new CGI;
my $biblionumber = $query->param('biblionumber') || $query->param('bib');
my $scaled = $query->param('scaled') || "";
my $ElectreImage=GetElectreImage($biblionumber,$scaled);
if(defined($ElectreImage) and $ElectreImage ne '' and $ElectreImage ne '0'){
	print "Content-type: image/jpeg\n\n";
	print decode_base64($ElectreImage);
}
else
{
	print "Content-type: image/gif\n\n";
	print "GIF89a\x01\x00\x01\x00\xA1\x01\x00\x00\x00\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x21\xF9\x04\x01\x0A\x00\x01\x00\x2C\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02\x4C\x01\x00;";
}
__END__

=head1 AUTHOR

Stephane Delaune delaune.stephane@gmail.com

=cut
