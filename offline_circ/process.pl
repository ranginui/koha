#!/usr/bin/perl

# 2009 BibLibre <jeanandre.santoni@biblibre.com>

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
#

use CGI;
use C4::Auth;
use C4::Circulation;

my $query = CGI->new;

my ($template, $loggedinuser, $cookie) = get_template_and_user({ 
    template_name => "offline_circ/list.tmpl",
    query => $query,
    type => "intranet",
    authnotrequired => 0,
    flagsrequired   => { circulate => "circulate_remaining_permissions" },
});

my $operationid = $query->param('operationid');
my $action = $query->param('action');
my $result;

if ( $action eq 'process' ) {
    my $operation = GetOfflineOperation( $operationid );
    $operation->{'cardnumber'} = 0 . $operation->{'cardnumber'} if length($operation->{'cardnumber'}) == 15;
    $operation->{'cardnumber'} = 00 . $operation->{'cardnumber'} if length($operation->{'cardnumber'}) == 14;
    $operation->{'cardnumber'} =~ s/00000000([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/00000000$4$3$2$1/i;

    $result = ProcessOfflineOperation( $operation );
} elsif ( $action eq 'delete' ) {
    $result = DeleteOfflineOperation( $operationid );
}

print CGI::header('-type'=>'text/plain', '-charset'=>'utf-8');
print $result;

