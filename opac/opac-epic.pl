#!/usr/bin/perl

# Script to display epic links, for hlt
# behind auth

use strict;
require Exporter;
use CGI;

use C4::Search;
use C4::Auth;         # checkauth, getborrowernumber.
use C4::Koha;
use C4::Interface::CGI::Output;


my $query = new CGI;
my $type = $query->param('type');
my $template;
my $borrowernumber;
my $cookie;

warn $type;

if ($type eq 'subject'){
    
($template, $borrowernumber, $cookie)
    = get_template_and_user({template_name => "epic_horowhenua_subject.tmpl",
			     query => $query,
			     type => "opac",
			     authnotrequired => 0,
			     flagsrequired => {borrow => 1},
			     debug => 1,
			     });
    }
else {
    ($template, $borrowernumber, $cookie)
    = get_template_and_user({template_name => "epic_horowhenua.tmpl",
			     query => $query,
			     type => "opac",
			     authnotrequired => 0,
			     flagsrequired => {borrow => 1},
			     debug => 1,
			     });
    }


output_html_with_http_headers $query, $cookie, $template->output;

