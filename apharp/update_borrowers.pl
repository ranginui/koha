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
use POSIX qw/ceil/;

my $new;   # option variable with default value (false)
GetOptions ('new' => \$new);

print "Récupération de la liste des lecteurs ...\n";
my $borrowers = getBorrowers($new);
print "Nombre de lecteurs trouvé : " . scalar(@$borrowers) . "\n";

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

    my $elemperpage = 1000;
    my $npages = ceil(scalar(@$borrowers) / $elemperpage );

    my $min = 0;
    my $max = $elemperpage;
    for ( my $i=1; $i<=$npages; $i++) {

	my @borrowers_category;

	foreach my $type (@borrower_types){
	    foreach (@univ) {
		push @borrowers_category, { borrower_type => $type,
					    univ          => $_,
		};
	    }
	}

	foreach my $category (@borrowers_category) {
	    foreach (@$borrowers[$min..$max-1]) {
		if ($_->{"categorycode"} eq $category->{"borrower_type"} && $_->{"ETABLISSEM"} eq $category->{"univ"}) {
		    push @{ $category->{"borrowers"} }, $_->{"APPLIGEST"};
		}
	    }    
	}
	$min = $max;
	$max += $elemperpage;

	my $data = get_borrowers_attr(\@borrowers_category);
	data_to_koha($data, $new);
    }

} else { print "no borrowers to update in database ..."; }




