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

#use strict;
#use warnings; FIXME - Bug 2505
use C4::Context;

=head1 plugin_parameters

other parameters added when the plugin is called by the dopop function

=cut

sub plugin_parameters {
#   my ($dbh,$record,$tagslib,$i,$tabloop) = @_;
    return "";
}

=head1 plugin_javascript

The javascript function called when the user enters the subfield.
contain 3 javascript functions :
* one called when the field is entered (OnFocus). Named FocusXXX
* one called when the field is leaved (onBlur). Named BlurXXX
* one called when the ... link is clicked (<a href="javascript:function">) named ClicXXX

returns :
* XXX
* a variable containing the 3 scripts.
the 3 scripts are inserted after the <input> in the html code

=cut

sub plugin_javascript {
	my ($dbh,$record,$tagslib,$field_number,$tabloop) = @_;
	my $function_name= "inventory".(int(rand(100000))+1);

	my $branchcode = C4::Context->userenv->{'branch'};

	$query = "SELECT MAX(CAST(SUBSTRING_INDEX(stocknumber,'_',-1) AS SIGNED)) FROM items WHERE homebranch = ?";
	my $sth=$dbh->prepare($query);
	$sth->execute($branchcode);
	while (my ($count)= $sth->fetchrow_array) {
		$nextnum = $count;
	}
	$nextnum++;

	my $nextnum = $branchcode.'_'.$nextnum;

    my $scr = <<END_OF_JS;
if (\$('#' + id).val() == '' || force) {
    \$('#' + id).val('$nextnum');
}
END_OF_JS

    my $js  = <<END_OF_JS;
<script type="text/javascript">
//<![CDATA[

function Blur$function_name(index) {
    //barcode validation might go here
}

function Focus$function_name(subfield_managed, id, force) {
$scr
    return 0;
}

function Clic$function_name(id) {
    return Focus$function_name('not_relavent', id, 1);
}
//]]>
</script>
END_OF_JS
    return ($function_name, $js);
}

=head1

plugin: useless here

=cut

sub plugin {
    # my ($input) = @_;
    return "";
}

1;
