package C4::Labels::Template;

# Copyright 2009 Foundations Bible College.
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
use Sys::Syslog qw(syslog);
use Data::Dumper;
use PDF::Reuse;

use C4::Context;
use C4::Debug;
use C4::Labels::Profile 1.000000;
use C4::Labels::PDF 1.000000;

BEGIN {
    use version; our $VERSION = qv('1.0.0_1');
}

my $unit_values = { 
    POINT       => 1,
    INCH        => 72,
    MM          => 2.83464567,
    CM          => 28.3464567,
};

sub _check_params {
    my $given_params = {};
    my $exit_code = 0;
    my @valid_template_params = (
        'tmpl_code',
        'tmpl_desc',
        'page_width',
        'page_height',
        'label_width',
        'label_height',
        'top_text_margin',
        'left_text_margin',
        'top_margin',
        'left_margin',
        'cols',
        'rows',
        'col_gap',
        'row_gap',
        'units',
        'font_size',
        'font',
    );
    if (scalar(@_) >1) {
        $given_params = {@_};
        foreach my $key (keys %{$given_params}) {
            if (!(grep m/$key/, @valid_template_params)) {
                syslog("LOG_ERR", "C4::Labels::Template : Unrecognized parameter type of \"%s\".", $key);
                $exit_code = 1;
            }
        }
    }
    else {
        if (!(grep m/$_/, @valid_template_params)) {
            syslog("LOG_ERR", "C4::Labels::Template : Unrecognized parameter type of \"%s\".", $_);
            $exit_code = 1;
        }
    }
    return $exit_code;
}

sub _conv_points {
    my $self = shift;
    $self->{page_width}         = $self->{page_width} * $unit_values->{$self->{units}};
    $self->{page_height}        = $self->{page_height} * $unit_values->{$self->{units}};
    $self->{label_width}        = $self->{label_width} * $unit_values->{$self->{units}};
    $self->{label_height}       = $self->{label_height} * $unit_values->{$self->{units}};
    $self->{top_text_margin}    = $self->{top_text_margin} * $unit_values->{$self->{units}};
    $self->{left_text_margin}   = $self->{left_text_margin} * $unit_values->{$self->{units}};
    $self->{top_margin}         = $self->{top_margin} * $unit_values->{$self->{units}};
    $self->{left_margin}        = $self->{left_margin} * $unit_values->{$self->{units}};
    $self->{col_gap}            = $self->{col_gap} * $unit_values->{$self->{units}};
    $self->{row_gap}            = $self->{row_gap} * $unit_values->{$self->{units}};
    return $self;
}

sub _apply_profile {
    my $self = shift;
    my $profile_id = shift;
    my $profile = C4::Labels::Profile->retrieve(profile_id => $profile_id, convert => 1);
    $self->{top_margin} = $self->{top_margin} + $profile->get_attr('offset_vert');      # controls vertical offset
    $self->{left_margin} = $self->{left_margin} + $profile->get_attr('offset_horz');    # controls horizontal offset
    $self->{label_height} = $self->{label_height} + $profile->get_attr('creep_vert');   # controls vertical creep
    $self->{label_width} = $self->{label_width} + $profile->get_attr('creep_horz');     # controls horizontal creep
    return $self;
}

=head1 NAME

C4::Labels::Template - A class for creating and manipulating template objects in Koha

=cut

=head1 METHODS

=head2 C4::Labels::Template->new()

    Invoking the I<new> method constructs a new template object containing the default values for a template.

    example:
        my $template = Template->new(); # Creates and returns a new template object

    B<NOTE:> This template is I<not> written to the database untill $template->save() is invoked. You have been warned!

=cut

sub new {
    my $invocant = shift;
    if (_check_params(@_) eq 1) {
        return 1;
    }
    my $type = ref($invocant) || $invocant;
    my $self = {
        tmpl_code       =>      '',
        tmpl_desc       =>      '',
        page_width      =>      0,
        page_height     =>      0,
        label_width     =>      0,
        label_height    =>      0,
        top_text_margin =>      0,
        left_text_margin =>      0,
        top_margin      =>      0,
        left_margin     =>      0,
        cols            =>      0,
        rows            =>      0,
        col_gap         =>      0,
        row_gap         =>      0,
        units           =>      'POINT',
        font_size       =>      3,
        font            =>      'TR',
        tmpl_stat       =>      0,      # false if any data has changed and the db has not been updated
        @_,
    };
    bless ($self, $type);
    return $self;
}

=head2 C4::Labels::Template->retrieve(template_id)

    Invoking the I<retrieve> method constructs a new template object containing the current values for template_id. The method returns
    a new object upon success and 1 upon failure. Errors are logged to the syslog. Two further options may be accessed. See the example
    below for further description.

    examples:

        my $template = C4::Labels::Template->retrieve(template_id => 1); # Retrieves template record 1 and returns an object containing the record

        my $template = C4::Labels::Template->retrieve(template_id => 1, convert => 1); # Retrieves template record 1, converts the units to points,
            and returns an object containing the record

        my $template = C4::Labels::Template->retrieve(template_id => 1, profile_id => profile_id); # Retrieves template record 1, converts the units
            to points, applies the given profile id, and returns an object containing the record

=cut

sub retrieve {
    my $invocant = shift;
    my %opts = @_;
    my $type = ref($invocant) || $invocant;
    my $query = "SELECT * FROM labels_templates WHERE tmpl_id = ?";  
    my $sth = C4::Context->dbh->prepare($query);
    $sth->execute($opts{template_id});
    if ($sth->err) {
        syslog("LOG_ERR", "Database returned the following error: %s", $sth->errstr);
        return 1;
    }
    my $self = $sth->fetchrow_hashref;
    $self = _conv_points($self) if (($opts{convert} && $opts{convert} == 1) || $opts{profile_id});
    $self = _apply_profile($self, $opts{profile_id}) if $opts{profile_id};
    $self->{tmpl_stat} = 1;
    bless ($self, $type);
    return $self;
}

=head2 C4::Labels::Template->delete(tmpl_id => template_id) |  $template->delete()

    Invoking the delete method attempts to delete the template from the database. The method returns 0 upon success
    and 1 upon failure. Errors are logged to the syslog.

    examples:
        my $exitstat = $template->delete(); # to delete the record behind the $template object
        my $exitstat = C4::Labels::Template->delete(tmpl_id => 1); # to delete template record 1

=cut

sub delete {
    my $self = shift;
    if (!$self->{tmpl_id}) {   # If there is no template tmpl_id then we cannot delete it
        syslog("LOG_ERR", "Cannot delete template as it has not been saved.");
        return 1;
    }
    my $query = "DELETE FROM labels_templates WHERE tmpl_id = ?";  
    my $sth = C4::Context->dbh->prepare($query);
    $sth->execute($self->{tmpl_id});
    $self->{tmpl_stat} = 0;
    return 0;
}

=head2 $template->save()

    Invoking the I<save> method attempts to insert the template into the database if the template is new and
    update the existing template record if the template exists. The method returns the new record tmpl_id upon
    success and -1 upon failure (This avotmpl_ids conflicting with a record tmpl_id of 1). Errors are logged to the syslog.

    example:
        my $exitstat = $template->save(); # to save the record behind the $template object

=cut

sub save {
    my $self = shift;
    if ($self->{'tmpl_id'}) {        # if we have an tmpl_id, the record exists and needs UPDATE
        my @params;
        my $query = "UPDATE labels_templates SET ";
        foreach my $key (keys %{$self}) {
            next if ($key eq 'tmpl_id') || ($key eq 'tmpl_stat');
            push (@params, $self->{$key});
            $query .= "$key=?, ";
        }
        $query = substr($query, 0, (length($query)-2));
        push (@params, $self->{'tmpl_id'});
        $query .= " WHERE tmpl_id=?;";
        warn "DEBUG: Updating: $query\n" if $debug;
        my $sth = C4::Context->dbh->prepare($query);
        $sth->execute(@params);
        if ($sth->err) {
            syslog("LOG_ERR", "Database returned the following error: %s", $sth->errstr);
            return -1;
        }
        $self->{tmpl_stat} = 1;
        return $self->{'tmpl_id'};
    }
    else {                      # otherwise create a new record
        my @params;
        my $query = "INSERT INTO labels_templates (";
        foreach my $key (keys %{$self}) {
            next if $key eq 'tmpl_stat';
            push (@params, $self->{$key});
            $query .= "$key, ";
        }
        $query = substr($query, 0, (length($query)-2));
        $query .= ") VALUES (";
        for (my $i=1; $i<=((scalar keys %$self) - 1); $i++) {   # key count less keys not db related...
            $query .= "?,";
        }
        $query = substr($query, 0, (length($query)-1));
        $query .= ");";
        warn "DEBUG: Saving: $query\n" if $debug;
        my $sth = C4::Context->dbh->prepare($query);
        $sth->execute(@params);
        if ($sth->err) {
            syslog("LOG_ERR", "Database returned the following error: %s", $sth->errstr);
            return -1;
        }
        my $sth1 = C4::Context->dbh->prepare("SELECT MAX(tmpl_id) FROM labels_templates;");
        $sth1->execute();
        my $tmpl_id = $sth1->fetchrow_array;
        $self->{tmpl_id} = $tmpl_id;
        $self->{tmpl_stat} = 1;
        return $tmpl_id;
    }
}

=head2 $template->get_attr("attr")

    Invoking the I<get_attr> method will return the value of the requested attribute or 1 on errors.

    example:
        my $value = $template->get_attr("attr");

=cut

sub get_attr {
    my $self = shift;
    if (_check_params(@_) eq 1) {
        return 1;
    }
    my ($attr) = @_;
    if (exists($self->{$attr})) {
        return $self->{$attr};
    }
    else {
        return 1;
    }
}

=head2 $template->set_attr(attr, value)

    Invoking the I<set_attr> method will set the value of the supplied attribute to the supplied value.

    example:
        $template->set_attr(attr => value);

=cut

sub set_attr {
    my $self = shift;
    if (_check_params(@_) eq 1) {
        return 1;
    }
    my ($attr, $value) = @_;
    $self->{$attr} = $value;
}

=head2 $template->get_text_wrap_cols()

    Invoking the I<get_text_wrap_cols> method will return the number of columns that can be printed on the
    label before wrapping to the next line.

    examples:
        my $text_wrap_cols = $template->get_text_wrap_cols();

=cut

sub get_text_wrap_cols {
    my $self = shift;
    my $string = '';
    my $strwidth = 0;
    my $col_count = 0;
    my $textlimit = $self->{label_width} - ( 3 * $self->{left_text_margin});

    while ($strwidth < $textlimit) {
        $string .= '0';
        $col_count++;
        $strwidth = C4::Labels::PDF->StrWidth( $string, $self->{font}, $self->{font_size} );
    }
    return $col_count;
}

=head2 $template->get_label_position($start_label)

    Invoking the I<get_label_position> method will return the row, column coordinates on the starting page
    and the lower left x,y coordinates on the starting label for the template object.

    examples:
        my ($row_count, $col_count, $llx, $lly) = $template->get_label_position($start_label);

=cut

sub get_label_position {
    my ($self, $start_label) = @_;
    my ($row_count, $col_count, $llx, $lly) = 0,0,0,0;
    if ($start_label eq 1) {
        $row_count = 1;
        $col_count = 1;
        $llx = $self->{left_margin};
        $lly = ($self->{page_height} - $self->{top_margin} - $self->{label_height});
        return ($row_count, $col_count, $llx, $lly);
    }
    else {
        $row_count = ceil($start_label / $self->{cols});
        $col_count = ($start_label - (($row_count - 1) * $self->{cols}));
        $llx = $self->{left_margin} + ($self->{label_width} * ($col_count - 1)) + ($self->{col_gap} * ($col_count - 1));
        $lly = $self->{page_height} - $self->{top_margin} - ($self->{label_height} * $row_count) - ($self->{row_gap} * ($row_count - 1));
        return ($row_count, $col_count, $llx, $lly);
    }
}

1;
__END__

=head1 AUTHOR

Chris Nighswonger <cnighswonger AT foundations DOT edu>

=cut
