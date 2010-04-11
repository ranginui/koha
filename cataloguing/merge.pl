#!/usr/bin/perl 


# Copyright 2009 BibLibre
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
use CGI;
use C4::Output;
use C4::Auth;
use C4::Items;
use C4::Biblio;
use C4::Serials;
use YAML;

my $input = new CGI;
my @biblionumber = $input->param('biblionumber');
my $merge = $input->param('merge');

my @errors;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "cataloguing/merge.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { editcatalogue => 'edit_catalogue' },
    }
);

#------------------------
# Merging
#------------------------
if ($merge) {

    my @params = $input->param();
    my $dbh = C4::Context->dbh;
    my $sth;

    # Creating a new record from the html code
    my $record       = TransformHtmlToMarc( \@params , $input );
    my $tobiblio     =  $input->param('biblio1');
    my $frombiblio   =  $input->param('biblio2');

    # Rewriting the leader
    $record->leader(GetMarcBiblio($tobiblio)->leader());

    my $frameworkcode = &GetFrameworkCode($tobiblio);
    my @notmoveditems;

    # Modifying the reference record
    ModBiblio($record, $tobiblio, $frameworkcode);

    # Moving items from the other record to the reference record
    my $itemnumbers = get_itemnumbers_of($frombiblio);
    use Data::Dumper;
    foreach my $itloop ($itemnumbers->{$frombiblio}) {
	foreach my $itemnumber (@$itloop) {
	    my $res = MoveItemFromBiblio($itemnumber, $frombiblio, $tobiblio);
	    if (not defined $res) {
		push @notmoveditems, $itemnumber;
	    }
	}
    }
    # If some items could not be moved :
    if (scalar(@notmoveditems) > 0) {
		my $itemlist = join(' ',@notmoveditems);
		push @errors, "The following items could not be moved from the old record to the new one: $itemlist";
    }

    # Moving subscriptions from the other record to the reference record
    my $subcount = CountSubscriptionFromBiblionumber($frombiblio);
    if ($subcount > 0) {
	$sth = $dbh->prepare("UPDATE subscription SET biblionumber = ? WHERE biblionumber = ?");
	$sth->execute($tobiblio, $frombiblio);

	$sth = $dbh->prepare("UPDATE subscriptionhistory SET biblionumber = ? WHERE biblionumber = ?");
	$sth->execute($tobiblio, $frombiblio);

    }

    # Moving serials
    $sth = $dbh->prepare("UPDATE serial SET biblionumber = ? WHERE biblionumber = ?");
    $sth->execute($tobiblio, $frombiblio);

    # TODO : Moving reserves

    # Deleting the other record
    if (scalar(@errors) == 0) {
	my $error = DelBiblio($frombiblio);
	push @errors, $error if ($error); 
    }

    # Errors
    my @errors_loop  = map{{error => $_}}@errors;

    # Parameters
    $template->param({
	errors  => \@errors_loop,
	result => 1,
	biblio1 => $input->param('biblio1')
    });


#-------------------------
# Show records to merge
#-------------------------
} else {

    my $mergereference = $input->param('mergereference');
    my $biblionumber = $input->param('biblionumber');

    my $data1 = GetBiblioData($biblionumber[0]);
    my $data2 = GetBiblioData($biblionumber[1]);

    # Ask the user to choose which record will be the kept
    if (not $mergereference) {
	$template->param({
	    choosereference => 1,	
	    biblio1 => $biblionumber[0],
	    biblio2 => $biblionumber[1],
	    title1 => $data1->{'title'},
	    title2 => $data2->{'title'}
	    });
    } else {

	if (scalar(@biblionumber) != 2) {
	    push @errors, "An unexpected number of records was provided for merging. Currently only two records at a time can be merged.";
	}

	# Checks if both records use the same framework
	my $frameworkcode1 = &GetFrameworkCode($biblionumber[0]);
	my $frameworkcode2 = &GetFrameworkCode($biblionumber[1]);
	my $framework;
	if ($frameworkcode1 ne $frameworkcode2) {
	    push @errors, "The records selected for merging are using different frameworks. Currently merging is only available for records using the same framework.";
	} else {
	    $framework = $frameworkcode1;	
	}

	# Getting MARC Structure
	my $tagslib = GetMarcStructure(1, $framework);

	my $notreference = ($biblionumber[0] == $mergereference) ? $biblionumber[1] : $biblionumber[0];

	# Creating a loop for display
	my @record1 = _createMarcHash(GetMarcBiblio($mergereference), $tagslib);
	my @record2 = _createMarcHash(GetMarcBiblio($notreference), $tagslib);

	# Errors
	my @errors_loop  = map{{error => $_}}@errors;

	# Parameters
	$template->param({
	    errors  => \@errors_loop,
	    biblio1 => $mergereference,
	    biblio2 => $notreference,
	    mergereference => $mergereference,
	    record1 => @record1,
	    record2 => @record2,
	    framework => $framework
	    });
    }
}
output_html_with_http_headers $input, $cookie, $template->output;
exit;


# ------------------------
# Functions
# ------------------------
sub _createMarcHash {
     my $record = shift;
    my $tagslib = shift;
    my @array;
    my @fields = $record->fields();


    foreach my $field (@fields) {
	my $fieldtag = $field->tag();
	if ($fieldtag < 10) {
	    if ($tagslib->{$fieldtag}->{'@'}->{'tab'} >= 0) {
		push @array, { 
			field => [ 
				    {
					tag => $fieldtag, 
					key => createKey(), 
					value => $field->data(),
				    }
				]
			    };    
	    }
	} else {
	    my @subfields = $field->subfields();
	    my @subfield_array;
	    foreach my $subfield (@subfields) {
		if ($tagslib->{$fieldtag}->{@$subfield[0]}->{'tab'} >= 0) {
		    push @subfield_array, {  
                                        subtag => @$subfield[0],
					subkey => createKey(), 
                                        value => @$subfield[1],
                                      };
		}

	    }

	    if ($tagslib->{$fieldtag}->{'tab'} >= 0 && $fieldtag ne '995') {
		push @array, {
			field => [  
				    {
					tag => $fieldtag, 
					key => createKey(), 
					indicator1 => $field->indicator(1), 
					indicator2 => $field->indicator(2), 
					subfield   => [@subfield_array], 
				    }
				]
			    }; 	
	    }

	}
    }
    return [@array];

}

=item CreateKey

    Create a random value to set it into the input name

=cut

sub createKey(){
    return int(rand(1000000));
}


