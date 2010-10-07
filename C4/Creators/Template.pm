package C4::Creators::Template;

use strict;
use warnings;
use POSIX qw(ceil);
use autouse 'Data::Dumper' => qw(Dumper);

use C4::Context;
use C4::Debug;
use C4::Creators::Profile 1.000000;
use C4::Creators::Lib 1.000000 qw(get_unit_values);

BEGIN {
    use version; our $VERSION = qv('1.0.0_1');
}

sub _check_params {
    shift if $_[0] =~ m/::/; # this seems a bit hackish
    my $given_params = {};
    my $exit_code = 0;
    my @valid_template_params = (
        'profile_id',
        'template_code',
        'template_desc',
        'page_width',
        'page_height',
        'label_width',
        'label_height',
        'card_width',
        'card_height',
        'top_text_margin',
        'left_text_margin',
        'top_margin',
        'left_margin',
        'cols',
        'rows',
        'col_gap',
        'row_gap',
        'units',
        'creator',
        'current_label',
    );
    if (scalar(@_) >1) {
        $given_params = {@_};
        foreach my $key (keys %{$given_params}) {
            if (!(grep m/$key/, @valid_template_params)) {
                warn sprintf('Unrecognized parameter type of "%s".', $key);
                $exit_code = 1;
            }
        }
    }
    else {
        if (!(grep m/$_/, @valid_template_params)) {
            warn sprintf('Unrecognized parameter type of "%s".', $_);
            $exit_code = 1;
        }
    }
    return $exit_code;
}

sub _conv_points {
    my $self = shift;
    my @unit_value = grep {$_->{'type'} eq $self->{'units'}} @{get_unit_values()};
    $self->{'page_width'}         = $self->{'page_width'} * $unit_value[0]->{'value'};
    $self->{'page_height'}        = $self->{'page_height'} * $unit_value[0]->{'value'};
    $self->{'label_width'}        = $self->{'label_width'} * $unit_value[0]->{'value'};
    $self->{'label_height'}       = $self->{'label_height'} * $unit_value[0]->{'value'};
    $self->{'top_text_margin'}    = $self->{'top_text_margin'} * $unit_value[0]->{'value'};
    $self->{'left_text_margin'}   = $self->{'left_text_margin'} * $unit_value[0]->{'value'};
    $self->{'top_margin'}         = $self->{'top_margin'} * $unit_value[0]->{'value'};
    $self->{'left_margin'}        = $self->{'left_margin'} * $unit_value[0]->{'value'};
    $self->{'col_gap'}            = $self->{'col_gap'} * $unit_value[0]->{'value'};
    $self->{'row_gap'}            = $self->{'row_gap'} * $unit_value[0]->{'value'};
    return $self;
}

sub _apply_profile {
    my $self = shift;
    my $creator = shift;
    my $profile = C4::Creators::Profile->retrieve(profile_id => $self->{'profile_id'}, creator => $creator, convert => 1);
    $self->{'top_margin'} = $self->{'top_margin'} + $profile->get_attr('offset_vert');      # controls vertical offset
    $self->{'left_margin'} = $self->{'left_margin'} + $profile->get_attr('offset_horz');    # controls horizontal offset
    $self->{'label_height'} = $self->{'label_height'} + $profile->get_attr('creep_vert');   # controls vertical creep
    $self->{'label_width'} = $self->{'label_width'} + $profile->get_attr('creep_horz');     # controls horizontal creep
    return $self;
}

sub new {
    my $invocant = shift;
    my $type = ref($invocant) || $invocant;
    if (_check_params(@_) eq 1) {
        return -1;
    }
    my $self = {
        profile_id      =>      0,
        template_code   =>      'DEFAULT TEMPLATE',
        template_desc   =>      'Default description',
        page_width      =>      0,
        page_height     =>      0,
        label_width     =>      0,
        label_height    =>      0,
        top_text_margin =>      0,
        left_text_margin =>     0,
        top_margin      =>      0,
        left_margin     =>      0,
        cols            =>      0,
        rows            =>      0,
        col_gap         =>      0,
        row_gap         =>      0,
        units           =>      'POINT',
        template_stat   =>      0,      # false if any data has changed and the db has not been updated
        @_,
    };
    bless ($self, $type);
    return $self;
}

sub retrieve {
    my $invocant = shift;
    my %opts = @_;
    my $type = ref($invocant) || $invocant;
    my $query = "SELECT * FROM " . $opts{'table_name'} . " WHERE template_id = ? AND creator = ?";
    my $sth = C4::Context->dbh->prepare($query);
    $sth->execute($opts{'template_id'}, $opts{'creator'});
    if ($sth->err) {
        warn sprintf('Database returned the following error: %s', $sth->errstr);
        return -1;
    }
    my $self = $sth->fetchrow_hashref;
    $self = _conv_points($self) if (($opts{convert} && $opts{convert} == 1) || $opts{profile_id});
    $self = _apply_profile($self, $opts{'creator'}) if $opts{profile_id} && $self->{'profile_id'};        # don't bother if there is no profile_id
    $self->{'template_stat'} = 1;
    bless ($self, $type);
    return $self;
}

sub delete {
    my $self = {};
    my %opts = ();
    my $call_type = '';
    my @query_params = ();
    if (ref($_[0])) {
        $self = shift;  # check to see if this is a method call
        $call_type = 'C4::Labels::Template->delete';
        push @query_params, $self->{'template_id'}, $self->{'creator'};
    }
    else {
        %opts = @_;
        $call_type = 'C4::Labels::Template::delete';
        push @query_params, $opts{'template_id'}, $opts{'creator'};
    }
    if (scalar(@query_params) < 2) {   # If there is no template id or creator type then we cannot delete it
        warn sprintf('%s : Cannot delete template as the template id is invalid or non-existant.', $call_type) if !$query_params[0];
        warn sprintf('%s : Cannot delete template as the creator type is invalid or non-existant.', $call_type) if !$query_params[1];
        return -1;
    }
    my $query = "DELETE FROM creator_templates WHERE template_id = ? AND creator = ?";
    my $sth = C4::Context->dbh->prepare($query);
    $sth->execute(@query_params);
    $self->{'template_stat'} = 0;
}

sub save {
    my $self = shift;
    my %opts = @_;
    if ($self->{'template_id'}) {        # if we have an template_id, the record exists and needs UPDATE
        my @params;
        my $query = "UPDATE " . $opts{'table_name'} . " SET ";
        foreach my $key (keys %{$self}) {
            next if ($key eq 'template_id') || ($key eq 'template_stat') || ($key eq 'creator');
            push (@params, $self->{$key});
            $query .= "$key=?, ";
        }
        $query = substr($query, 0, (length($query)-2));
        push (@params, $self->{'template_id'}, $self->{'creator'});
        $query .= " WHERE template_id=? AND creator=?;";
        my $sth = C4::Context->dbh->prepare($query);
        $sth->execute(@params);
        if ($sth->err) {
            warn sprintf('Database returned the following error: %s', $sth->errstr);
            return -1;
        }
        $self->{'template_stat'} = 1;
        return $self->{'template_id'};
    }
    else {                      # otherwise create a new record
        my @params;
        my $query = "INSERT INTO " . $opts{'table_name'} ." (";
        foreach my $key (keys %{$self}) {
            next if $key eq 'template_stat';
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
        my $sth = C4::Context->dbh->prepare($query);
        $sth->execute(@params);
        if ($sth->err) {
            warn sprintf('Database returned the following error: %s', $sth->errstr);
            return -1;
        }
        my $sth1 = C4::Context->dbh->prepare("SELECT MAX(template_id) FROM " . $opts{'table_name'} . ";");
        $sth1->execute();
        my $template_id = $sth1->fetchrow_array;
        $self->{'template_id'} = $template_id;
        $self->{'template_stat'} = 1;
        return $template_id;
    }
}

sub get_attr {
    my $self = shift;
    if (_check_params(@_) eq 1) {
        return -1;
    }
    my ($attr) = @_;
    if (exists($self->{$attr})) {
        return $self->{$attr};
    }
    else {
        return -1;
    }
}

sub set_attr {
    my $self = shift;
    if (_check_params(@_) eq 1) {
        return -1;
    }
    my %attrs = @_;
    foreach my $attrib (keys(%attrs)) {
        $self->{$attrib} = $attrs{$attrib};
    };
}

sub get_label_position {
    my ($self, $start_label) = @_;
    my $current_label = $self->{'current_label'};
    if ($start_label eq 1) {
        $current_label->{'row_count'} = 1;
        $current_label->{'col_count'} = 1;
        $current_label->{'llx'} = $self->{'left_margin'};
        $current_label->{'lly'} = ($self->{'page_height'} - $self->{'top_margin'} - $self->{'label_height'});
        $self->{'current_label'} = $current_label;
        return ($current_label->{'row_count'}, $current_label->{'col_count'}, $current_label->{'llx'}, $current_label->{'lly'});
    }
    else {
        $current_label->{'row_count'} = ceil($start_label / $self->{'cols'});
        $current_label->{'col_count'} = ($start_label - (($current_label->{'row_count'} - 1) * $self->{'cols'}));
        $current_label->{'llx'} = $self->{'left_margin'} + ($self->{'label_width'} * ($current_label->{'col_count'} - 1)) + ($self->{'col_gap'} * ($current_label->{'col_count'} - 1));
        $current_label->{'lly'} = $self->{'page_height'} - $self->{'top_margin'} - ($self->{'label_height'} * $current_label->{'row_count'}) - ($self->{'row_gap'} * ($current_label->{'row_count'} - 1));
        $self->{'current_label'} = $current_label;
        return ($current_label->{'row_count'}, $current_label->{'col_count'}, $current_label->{'llx'}, $current_label->{'lly'});
    }
}

sub get_next_label_pos {
    my $self = shift;
    my $current_label = $self->{'current_label'};
    my $new_page = 0;
    if ($current_label->{'col_count'} lt $self->get_attr('cols')) {
        $current_label->{'llx'} = ($current_label->{'llx'} + $self->get_attr('label_width') + $self->get_attr('col_gap'));
        $current_label->{'col_count'}++;
    }
    else {
        $current_label->{'llx'} = $self->get_attr('left_margin');
        if ($current_label->{'row_count'} eq $self->get_attr('rows')) {
            $new_page = 1;
            $current_label->{'lly'} = ($self->get_attr('page_height') - $self->get_attr('top_margin') - $self->get_attr('label_height'));
            $current_label->{'row_count'} = 1;
        }
        else {
            $current_label->{'lly'} = ($current_label->{'lly'} - $self->get_attr('row_gap') - $self->get_attr('label_height'));
            $current_label->{'row_count'}++;
        }
        $current_label->{'col_count'} = 1;
    }
    return ($current_label->{'llx'}, $current_label->{'lly'}, $new_page);
}

1;
__END__

=head1 NAME

C4::Creators::Template - A class for creating and manipulating template objects in Koha

=head1 ABSTRACT

This module provides methods for creating, retrieving, and otherwise manipulating label template objects used by Koha.

=head1 METHODS

=head2 new()

    Invoking the I<new> method constructs a new template object containing the default values for a template.
    The following parameters are optionally accepted as key => value pairs:

        C<profile_id>           A valid profile id to be assciated with this template. NOTE: The profile must exist in the database and B<not> be assigned to another template.
        C<template_code>        A template code. ie. 'Avery 5160 | 1 x 2-5/8'
        C<template_desc>        A readable description of the template. ie. '3 columns, 10 rows of labels'
        C<page_width>           The width of the page measured in the units supplied by the units parameter in this template.
        C<page_height>          The height of the page measured in the same units.
        C<label_width>          The width of a single label on the page this template applies to.
        C<label_height>         The height of a single label on the page.
        C<top_text_margin>      The measure of the top margin on a single label on the page.
        C<left_text_margin>     The measure of the left margin on a single label on the page.
        C<top_margin>           The measure of the top margin of the page.
        C<left_margin>          The measure of the left margin of the page.
        C<cols>                 The number of columns of labels on the page.
        C<rows>                 The number of rows of labels on the page.
        C<col_gap>              The measure of the gap between the columns of labels on the page.
        C<row_gap>              The measure of the gap between the rows of labels on the page.
        C<units>                The units of measure used for this template. These B<must> match the measures you supply above or
                                bad things will happen to your document. NOTE: The only supported units at present are:

=over 9

=item .
POINT   = Postscript Points (This is the base unit in the Koha label creator.)

=item .
AGATE   = Adobe Agates (5.1428571 points per)

=item .
INCH    = US Inches (72 points per)

=item .
MM      = SI Millimeters (2.83464567 points per)

=item .
CM      = SI Centimeters (28.3464567 points per)

=back

    example:
        my $template = Template->new(); # Creates and returns a new template object with the defaults

        my $template = C4::Labels::Template->new(profile_id => 1, page_width => 8.5, page_height => 11.0, units => 'INCH'); # Creates and returns a new template object using
            the supplied values to override the defaults

    B<NOTE:> This template is I<not> written to the database untill save() is invoked. You have been warned!

=head2 retrieve(template_id => $template_id)

    Invoking the I<retrieve> method constructs a new template object containing the current values for template_id. The method returns
    a new object upon success and -1 upon failure. Errors are logged to the Apache log. Two further options may be accessed. See the example
    below for further description.

    examples:

        C<my $template = C4::Labels::Template->retrieve(template_id => 1); # Retrieves template record 1 and returns an object containing the record>

        C<my $template = C4::Labels::Template->retrieve(template_id => 1, convert => 1); # Retrieves template record 1, converts the units to points,
            and returns an object containing the record>

        C<my $template = C4::Labels::Template->retrieve(template_id => 1, profile_id => 1); # Retrieves template record 1, converts the units
            to points, applies the currently associated profile id, and returns an object containing the record.>

=head2 delete()

    Invoking the delete method attempts to delete the template from the database. The method returns -1 upon failure. Errors are logged to the Apache log.
    NOTE: This method may also be called as a function and passed a key/value pair simply deleteing that template from the database. See the example below.

    examples:
        C<my $exitstat = $template->delete(); # to delete the record behind the $template object>
        C<my $exitstat = C4::Labels::Template::delete(template_id => 1); # to delete template record 1>

=head2 save()

    Invoking the I<save> method attempts to insert the template into the database if the template is new and update the existing template record if
    the template exists. The method returns the new record template_id upon success and -1 upon failure (This avoids template_ids conflicting with a
    record template_id of 1). Errors are logged to the Apache log.

    example:
        C<my $template_id = $template->save(); # to save the record behind the $template object>

=head2 get_attr($attribute)

    Invoking the I<get_attr> method will return the value of the requested attribute or -1 on errors.

    example:
        C<my $value = $template->get_attr($attribute);>

=head2 set_attr(attribute => value, attribute_2 => value)

    Invoking the I<set_attr> method will set the value of the supplied attributes to the supplied values. The method accepts key/value pairs separated by
    commas.

    example:
        C<$template->set_attr(attribute => value);>

=head2 get_label_position($start_label)

    Invoking the I<get_label_position> method will return the row, column coordinates on the starting page and the lower left x,y coordinates on the starting
    label for the template object.

    examples:
        C<my ($row_count, $col_count, $llx, $lly) = $template->get_label_position($start_label);>

=head1 AUTHOR

Chris Nighswonger <cnighswonger AT foundations DOT edu>

=head1 COPYRIGHT

Copyright 2009 Foundations Bible College.

=head1 LICENSE

This file is part of Koha.

Koha is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later version.

You should have received a copy of the GNU General Public License along with Koha; if not, write to the Free Software Foundation, Inc., 51 Franklin Street,
Fifth Floor, Boston, MA 02110-1301 USA.

=head1 DISCLAIMER OF WARRANTY

Koha is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

=cut
