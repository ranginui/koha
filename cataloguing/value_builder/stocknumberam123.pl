#!/usr/bin/perl

# Copyright 2010 BibLibre SARL
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
use C4::Auth;
use CGI;
use C4::Context;

=head1

This plugin is specific to AM123 but could be used as a base for similar operations.
It is used for stocknumber computation.

If the user send an empty string, we return a simple incremented stocknumber.
If a prefix is submited, we look for the highest stocknumber with this prefix, and return it incremented.
In this case, a stocknumber has this form : "PREFIX 0009678570".
 - PREFIX is an upercase word
 - a space separator
 - 10 digits, with leading 0s if needed

=cut

sub plugin_parameters {
}

sub plugin_javascript {
    my ($dbh,$record,$tagslib,$field_number,$tabloop) = @_;
    my $res="
    <script type='text/javascript'>
        function Focus$field_number() {
            return 1;
        }

        function Blur$field_number() {
                var code = document.getElementById('$field_number');
                var url = '../cataloguing/plugin_launcher.pl?plugin_name=stocknumberam123.pl&code=' + code.value;
                var blurcallbackstocknumber = {
                    success: function(o) {
                        var field = document.getElementById('$field_number');
                        field.value = o.responseText;
                        return 1;
                    }
                }
                var transaction = YAHOO.util.Connect.asyncRequest('GET',url, blurcallbackstocknumber, null);
                return 1;
        }

        function Clic$field_number() {
            return 1;
        }
    </script>
    ";

    return ($field_number,$res);
}

sub plugin {
    my ($input) = @_;
    my $code = $input->param('code');

    my ($template, $loggedinuser, $cookie) = get_template_and_user({
        template_name   => "cataloguing/value_builder/ajax.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => {editcatalogue => '*'},
        debug           => 1,
    });

    my $dbh = C4::Context->dbh;
    # If the textbox is empty, we return a simple incremented stocknumber
    if ( $code eq "" ) {
        my $sth = $dbh->prepare("SELECT MAX(CAST(stocknumber AS SIGNED)) FROM items");
        $sth->execute;
    
        if ( my $max = $sth->fetchrow ) {
            $template->param(
                return => $max+1,
            );
        }
    # If a prefix is submited, we look for the highest stocknumber with this prefix, and return it incremented
    } elsif ( $code =~ m/^[A-Z]+$/ ) {
        my $sth = $dbh->prepare("SELECT MAX(CAST(SUBSTRING_INDEX(stocknumber,' ',-1) AS SIGNED)) FROM items WHERE stocknumber LIKE ?");
        $sth->execute($code.' %');
        
        if ( my $max = $sth->fetchrow ) {
            $template->param(
                return => $code.' '.sprintf('%010s',($max+1)),
            );
        }
    # The user entered a custom value, we don't touch it, this could be handled in js
    } else {
        $template->param(
            return => $code,
        );
    }
    warn $code;
    output_html_with_http_headers $input, $cookie, $template->output;
}

1;
