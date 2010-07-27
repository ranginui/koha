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
use C4::IssuingRules;

my $cgi = CGI->new;

# get the status of the user, this will check his credentials and rights
my ($status, $cookie, $sessionId) = C4::Auth::check_api_auth($cgi, undef);

my $result;

if ($status eq 'ok') { # if authentication is ok

    # Get the POST data
    my $branchcode   = $cgi->param('branchcode');
    my $categorycode = $cgi->param('categorycode');
    my $itemtype     = $cgi->param('itemtype');
    my $varname      = $cgi->param('varname');
    my $inputvalue   = $cgi->param('inputvalue') eq '' ? undef : $cgi->param('inputvalue');
    
    # Modify the existing rule
    ModIssuingRule({
        branchcode   => $branchcode,
        categorycode => $categorycode,
        itemtype     => $itemtype,
        $varname     => $inputvalue,
    });
    
    # Compute inheritance, and return the new value;
    my $rule = GetIssuingRule($categorycode, $itemtype, $branchcode);
    
    $result = $rule->{$varname};
} else {
    $result = 'Fail';
}

print CGI::header('-type'=>'text/plain', '-charset'=>'utf-8');
print $result;

