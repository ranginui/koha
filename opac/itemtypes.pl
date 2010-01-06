#!/usr/bin/perl

# Written by bob@katipo.co.nz
# Modified by chrisc@catalyst.net.nz 6/7/2009

use strict;
use warnings;
use CGI;
use C4::Koha;
use C4::Context;

my $input = new CGI;

# get currently used itemtypes
my $advanced_search_types = C4::Context->preference("AdvancedSearchTypes");
my $itemtypes;
my $cnt=1;
if ($advanced_search_types) {
    my $advsearchtypes = GetAuthorisedValues($advanced_search_types);
    my @itemtypesloop;
    for my $thisitemtype (@$advsearchtypes) {
        my %row = (
            number      => $cnt++,
            ccl         => $advanced_search_types,
            code        => $thisitemtype->{authorised_value},
   #         selected    => $selected,
            description => $thisitemtype->{'lib'},
            count5      => $cnt % 4,
            imageurl =>
              getitemtypeimagelocation( 'opac', $thisitemtype->{'imageurl'} ),
        );
        push @itemtypesloop, \%row;
    }
    $itemtypes = \@itemtypesloop;
}
print $input->header;
if ($itemtypes) {
    print
'<form name="searchform" method="get" action="/cgi-bin/koha/opac-search.pl">';
    print '<input type="hidden" name="idx" value="kw">';
    print '<input type="hidden" name="sort_by" value="acqdate_dsc">';
    print '<input type="hidden" name="do" value="OK">';
    if ( $input->param('just_arrived') ) {
        print '<input type="hidden" name="limit" value="available">';
    }
    print '<select name="limit" onChange="this.form.submit()">';
    print '<option>-- Please choose --</option>';
    foreach my $thisitemtype ( sort {$a->{description} cmp $b->{description}} @$itemtypes ) {
        print '<option value="mc-ccode:'
          . $thisitemtype->{code} . '">'
          . $thisitemtype->{'description'}
          . '</option>';
    }
    print '</select>';
    print '</form>';
}
1;
