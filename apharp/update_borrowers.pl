#!/usr/bin/perl

# Copyright 2000-2002 Katipo Communications
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

use Apharp;
use Getopt::Long;

my $new;   # option variable with default value (false)
GetOptions ('new' => \$new);

my $borrowers = getBorrowers($new);

if ($borrowers) {
    foreach (@$borrowers) {
	if ($_->{'categorycode'} eq "P") {
	    $_->{'categorycode'} = "pers";
	    next;
	}
	$_->{'categorycode'} = "etud";
    }

    #builds an array for each branch with staff and one for each branch with students
    my @borrower_types = ("pers", "etud");
    my @univ = ("U1", "U2", "U3");
    my @borrowers_category;

    foreach my $type (@borrower_types){
	foreach (@univ) {
	    push @borrowers_category, { borrower_type => $type,
                                    univ          => $_,
	    };
	}
    }

    foreach my $category (@borrowers_category) {
	foreach (@$borrowers) {
	    if ($_->{"categorycode"} eq $category->{"borrower_type"} && $_->{"ETABLISSEM"} eq $category->{"univ"}) {
		push @{ $category->{"borrowers"} }, $_->{"APPLIGEST"};
	    }
	}    
    }

    my $data = get_borrowers_attr(\@borrowers_category);

    data_to_koha($data, $new);
} else { print "no borrowers to update in database ..."; }




