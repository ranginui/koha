#!/usr/bin/perl

# This software is placed under the gnu General Public License, v2 (http://www.gnu.org/licenses/gpl.html)

# Copyright 2007 Tamil s.a.r.l.
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

=head1 ysearch.pl


=cut

use strict;

#use warnings; FIXME - Bug 2505
use CGI;
use C4::Context;
use C4::Auth qw/check_cookie_auth/;

my $input = new CGI;
my $query = $input->param('query');
my $table = $input->param('table');
my $field = $input->param('field');

# Prevent from disclosing data
die() unless ($table eq "biblioitems"); 

binmode STDOUT, ":encoding(UTF-8)";
print $input->header( -type => 'text/plain', -charset => 'UTF-8' );

my ( $auth_status, $sessionID ) = check_cookie_auth( $input->cookie('CGISESSID'), { cataloguing => '*' } );
if ( $auth_status ne "ok" ) {
    exit 0;
}

my $dbh = C4::Context->dbh;
my $sql = qq(SELECT distinct $field 
             FROM $table 
             WHERE $field LIKE ? OR $field LIKE ? or $field LIKE ?);
$sql .= qq( ORDER BY $field);
my $sth = $dbh->prepare($sql);
$sth->execute("$query%", "% $query%", "%-$query%");

while ( my $rec = $sth->fetchrow_hashref ) {
    print nsb_clean($rec->{$field}) . "\n";
}

sub nsb_clean {
    my $NSB = '\x88' ;        # NSB : begin Non Sorting Block
    my $NSE = '\x89' ;        # NSE : Non Sorting Block end
    my $NSB2 = '\x98' ;        # NSB : begin Non Sorting Block
    my $NSE2 = '\x9C' ;        # NSE : Non Sorting Block end
    # handles non sorting blocks
    my ($string) = @_ ;
    $_ = $string ;
    s/$NSB//g ;
    s/$NSE//g ;
    s/$NSB2//g ;
    s/$NSE2//g ;
    $string = $_ ;

    return($string) ;
}

