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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA

use strict;
use warnings;

use CGI;
use C4::Auth;    # get_template_and_user
use C4::Branch;
use C4::Koha;
use C4::Output;
use C4::Suggestions;
use C4::Koha;
use C4::Dates;

my $input           = new CGI;
my $allsuggestions  = $input->param('showall');
my $op              = $input->param('op');
my $suggestion      = $input->Vars;
delete $$suggestion{$_} foreach qw<op suggestedbyme>;
$op = 'else' unless $op;

my ( $template, $borrowernumber, $cookie );
my $deleted = $input->param('deleted');
my $submitted = $input->param('submitted');

if ( C4::Context->preference("AnonSuggestions") ) {
    ( $template, $borrowernumber, $cookie ) = get_template_and_user(
        {
            template_name   => "opac-suggestions.tmpl",
            query           => $input,
            type            => "opac",
            authnotrequired => 1,
        }
    );
    if ( !$$suggestion{suggestedby} ) {
        $$suggestion{suggestedby} = C4::Context->preference("AnonSuggestions");
    }
}
else {
    ( $template, $borrowernumber, $cookie ) = get_template_and_user(
        {
            template_name   => "opac-suggestions.tmpl",
            query           => $input,
            type            => "opac",
            authnotrequired => 0,
        }
    );
}
if ($allsuggestions){
	delete $$suggestion{suggestedby};
}
else {
	$$suggestion{suggestedby} ||= $borrowernumber unless ($allsuggestions);
}
# warn "bornum:",$borrowernumber;
use YAML;
my $suggestions_loop =
  &SearchSuggestion( $suggestion);
if ( $op eq "add_confirm" ) {
	if (@$suggestions_loop>=1){
		#some suggestion are answering the request Donot Add
	}
	else {
		$$suggestion{'suggesteddate'}=C4::Dates->today;
		$$suggestion{'branchcode'}=C4::Context->userenv->{"branch"};
		&NewSuggestion($suggestion);
		# empty fields, to avoid filter in "SearchSuggestion"
		$$suggestion{$_}='' foreach qw<title author publishercode copyrightdate place collectiontitle isbn STATUS>;
		$suggestions_loop =
		   &SearchSuggestion( $suggestion );
	}
	$op              = 'else';
    print $input->redirect("/cgi-bin/koha/opac-suggestions.pl?op=else&submitted=1");
    exit;
}

if ( $op eq "delete_confirm" ) {
    my @delete_field = $input->param("delete_field");
    foreach my $delete_field (@delete_field) {
        &DelSuggestion( $borrowernumber, $delete_field );
    }
    $op = 'else';
    print $input->redirect("/cgi-bin/koha/opac-suggestions.pl?op=else&deleted=1");
    exit;
}
map{ $_->{'branchcodesuggestedby'}=GetBranchInfo($_->{'branchcodesuggestedby'})->[0]->{'branchname'}} @$suggestions_loop;
my $supportlist=GetSupportList();
foreach my $support(@$supportlist){
	if ($$support{'imageurl'}){
		$$support{'imageurl'}= getitemtypeimagelocation( 'opac', $$support{'imageurl'} );
	}
	else {
	   delete $$support{'imageurl'}
	}
}

foreach my $suggestion(@$suggestions_loop) {
    if($suggestion->{'suggestedby'} == $borrowernumber) {
        $suggestion->{'showcheckbox'} = $borrowernumber;
    } else {
        $suggestion->{'showcheckbox'} = 0;
    }
}

$template->param(
	%$suggestion,
	itemtypeloop=> $supportlist,
    suggestions_loop => $suggestions_loop,
    showall    => $allsuggestions,
    "op_$op"         => 1,
    suggestionsview => 1,
);


output_html_with_http_headers $input, $cookie, $template->output;

