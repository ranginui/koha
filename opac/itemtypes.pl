#!/usr/bin/perl

use strict;
require Exporter;
use CGI;
use C4::Auth;    # get_template_and_user
use C4::Output;
use C4::Koha;

my $input = new CGI;
# get currently used itemtypes
my $itemtypes = &GetItemTypes();

print $input->header;
if($itemtypes){
    print '<form name="searchform" method="get" action="/cgi-bin/koha/opac-search.pl">';
    print '<input type="hidden" name="idx" value="kw">';
    print '<input type="hidden" name="sort_by" value="acqdate_dsc">';
    print '<input type="hidden" name="do" value="OK">';
    if($input->param('just_arrived')){
	print '<input type="hidden" name="limit" value="available">';	
    }
    print '<select name="limit" onChange="this.form.submit()">';
    foreach my $thisitemtype (sort keys %$itemtypes) {
	print '<option value="mc-itype:'.$thisitemtype.'">'.$itemtypes->{$thisitemtype}->{'description'}.'</option>';
    }
    print '</select>';
    print '</form>';    
}
1;