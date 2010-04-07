#!/usr/bin/perl


# Copyright 2009 Kyle Hall <kyle.m.hall@gmail.com>
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
use C4::Context;

=head1

plugin_parameters : other parameters added when the plugin is called by the dopop function

=cut

sub plugin_parameters {
    return "";
}

=head1

plugin_javascript : the javascript function called when the user enters the subfield.
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
    my $function_name = $field_number;

    my $res  = "
<script type=\"text/javascript\">
//<![CDATA[

function Blur$function_name(index) {
    var fieldValue = document.getElementById(\"$field_number\").value;
    if (  fieldValue.substring(0,1) != '[' 
          &&
          fieldValue.substring(fieldValue.length-1) != '[' 
        ) {
      document.getElementById(\"$field_number\").value = '[' + fieldValue + ']';
    }
    return 0;
}

function Focus$function_name(subfield_managed) {
  // Do Nothing
}

function Clic$function_name(subfield_managed) {
  // Do Nothing
}
//]]>
</script>
";
return ($function_name,$res);
}

=head1

plugin : the true value_builded. The screen that is open in the popup window.

=cut

sub plugin {
    return "";
}

1;
