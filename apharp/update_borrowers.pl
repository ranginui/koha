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
use Mail::Sendmail;

my $new;   # option variable with default value (false)
my @list;
GetOptions ('new' => \$new, 
            'list=s' => \@list );
@list = split(/,/,join(',',@list));
die "Can't use 'new' and 'list' options" if $new && @list;

print "Retrieving the list of borrowers ...\n";
my $opt = { 'new' => $new, 'list' => \@list };
my $borrowers = getBorrowers($opt);
print "Number of borrowers found : " . scalar(@$borrowers) . "\n";

my @errors_update;
my $success_update = 0;
my $errors_by_sites = { U1 => { pers => 0, etud => 0 }, U2 => { pers => 0, etud => 0 }, U3 => { pers => 0, etud => 0 } };
my $errors_by_types = { nodata => 0, nonumber => 0, nosave => 0, appligest => 0 };

if (@$borrowers) {
    foreach (@$borrowers) {
	if ($_->{'categorycode'} eq "P") {
	    $_->{'categorycode'} = "pers";
	} else {
	    $_->{'categorycode'} = "etud";
	}
	if ($_->{APPLIGEST} !~ /^\d*$/) {
            push @errors_update, "Invalid APPLIGEST number: " . $_->{APPLIGEST} . " from " . $_->{ETABLISSEM} . "/" . $_->{'categorycode'} ."\n";
            $errors_by_sites->{ $_->{ETABLISSEM} }->{ $_->{'categorycode'} }++;
            $errors_by_types->{appligest}++;
        }
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
		$_->{"categorycode"} ||= '';
		if ($_->{"categorycode"} eq $category->{"borrower_type"} && $_->{"ETABLISSEM"} eq $category->{"univ"}) {
		    push @{ $category->{"borrowers"} }, $_->{"APPLIGEST"};
		}
	    }    
	}
	$min = $max;
	$max += $elemperpage;

	my $data = get_borrowers_attr(\@borrowers_category);
	my $result = data_to_koha($data, $new);

	$success_update += $result->{success};
	foreach ( @{ $result->{errors} } ) {
	    push @errors_update, $_;
	}

	foreach my $site ( keys %{ $result->{bysites} } ) {
	    foreach ( keys %{ $result->{bysites}->{$site} } ) {
		$errors_by_sites->{$site}->{$_} += $result->{bysites}->{$site}->{$_};
	    } 
	}

	foreach my $errortype ( keys %{ $result->{bytypes} } ) {
	    $errors_by_types->{$errortype} += $result->{bytypes}->{$errortype};
	}
    }
    my $message = make_message( { errors => \@errors_update,
			       success => $success_update,
			       bysites => $errors_by_sites,
			       bytypes => $errors_by_types});
    print $message;

    my %mail = (
        smtp    => 'smtp.nerim.net',
        To      => 'alex.arnaud@biblibre.com',
        From    => 'alex.arnaud@biblibre.com',
        Subject => 'Borrowers update result',
        Message =>  $message );
    sendmail(%mail) or print $Mail::Sendmail::error; 

    print "UPDATING BORROWERS : End update. Success : " . $success_update . ", Failure(s) : " . scalar(@errors_update) . "\n";

} else { print "no borrowers to update ...\n"; }
