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
#use warnings; FIXME - Bug 2505
use C4::Auth;
use CGI;
use C4::Context;

use C4::Search;
use C4::Output;

=head1 FUNCTIONS

=head2 plugin_parameters

Other parameters added when the plugin is called by the dopop function

=cut

sub plugin_parameters {
    my ( $dbh, $record, $tagslib, $i, $tabloop ) = @_;
    return "";
}

sub plugin_javascript {
    my ( $dbh, $record, $tagslib, $field_number, $tabloop ) = @_;
    my $res = "
    <script type=\"text/javascript\">
    function Focus$field_number() {
        return 1;
    }

    function Blur$field_number() {
        return 1;
    }

    function Clic$field_number(i) {
        var defaultvalue;
        try {
            defaultvalue = document.getElementById(i).value;
        } catch(e) {
            alert('error when getting '+i);
            return;
        }
    	window.open(\"../cataloguing/plugin_launcher.pl?plugin_name=unimarc_field_115a.pl&index=$field_number&result=\"+defaultvalue,\"unimarc_field_115a\",'width=1200,height=600,toolbar=false,scrollbars=yes');
    }

    </script>
    ";

    return ( $field_number, $res );
}

sub plugin {
    my ($input) = @_;
    my $index   = $input->param('index');
    my $result  = $input->param('result');

    my $dbh = C4::Context->dbh;
    my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
        {
            template_name =>
              "cataloguing/value_builder/unimarc_field_115a.tmpl",
            query           => $input,
            type            => "intranet",
            authnotrequired => 0,
            flagsrequired   => { editcatalogue => '*' },
            debug           => 1,
        }
    );
    my $f1  = substr( $result, 0,  1 );
    my $f2  = substr( $result, 1,  3 );
    my $f3  = substr( $result, 4,  1 );
    my $f4  = substr( $result, 5,  1 );
    my $f5  = substr( $result, 6,  1 );
    my $f6  = substr( $result, 7,  1 );
    my $f7  = substr( $result, 8,  1 );
    my $f8  = substr( $result, 9,  1 );
    my $f9  = substr( $result, 10, 1 );
    my $f10 = substr( $result, 11, 1 );
    my $f11 = substr( $result, 12, 1 );
    my $f12 = substr( $result, 13, 1 );
    my $f13 = substr( $result, 14, 1 );
    my $f14 = substr( $result, 15, 1 );
    my $f15 = substr( $result, 16, 1 );
    my $f16 = substr( $result, 17, 1 );
    my $f17 = substr( $result, 18, 1 );
    my $f18 = substr( $result, 19, 1 );

    $template->param(
        index     => $index,
        "f1$f1"   => 1,
        "f2"      => $f2,
        "f3$f3"   => 1,
        "f4$f4"   => 1,
        "f5$f5"   => 1,
        "f6$f6"   => 1,
        "f7$f7"   => 1,
        "f8$f8"   => 1,
        "f9$f9"   => 1,
        "f10$f10" => 1,
        "f11$f11" => 1,
        "f12$f12" => 1,
        "f13$f13" => 1,
        "f14$f14" => 1,
        "f15$f15" => 1,
        "f16$f16" => 1,
        "f17$f17" => 1,
        "f18$f18" => 1
    );

    output_html_with_http_headers $input, $cookie, $template->output;
}

1;
