#!/usr/bin/perl
# Copyright Chris Cormack chris@bigballofwax.co.nz 2010
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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA


use strict;
use warnings;
use CGI;
use C4::Context;
use LWP::Simple;
my $input = new CGI;
my $subject = $input->param('subject');
$subject=~ s/\.$//;
$subject=~ s/^ //;
$subject=~ s/ /_/g;
$subject = lc $subject;
my $count = $input->param('count');
my $base_url = "http://openlibrary.org/subjects/$subject" . '.json?details=true';
warn $base_url;
print $input->header;

my $content = get($base_url);
print $content;
