package Koha::DateUtils;

# Copyright (c) 2011 PTFS-Europe Ltd.
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
use 5.010;
use DateTime;
use DateTime::Format::DateParse;
use C4::Context;

use base 'Exporter';
use version; our $VERSION = qv('1.0.0');

our @EXPORT = (
    qw( dt_from_string output_pref format_sqldatetime output_pref_due format_sqlduedatetime)
);

=head1 DateUtils

Koha::DateUtils - Transitional wrappers to ease use of DateTime

=head1 DESCRIPTION

Koha has historically only used dates not datetimes and been content to
handle these as strings. It also has confused formatting with actual dates
this is a temporary module for wrappers to hide the complexity of switch to DateTime

=cut

=head2 dt_ftom_string

$dt = dt_from_string($date_string, [$format, $timezone ]);

Passed a date string returns a DateTime object format and timezone default
to the system preferences. If the date string is empty DateTime->now is returned

=cut

sub dt_from_string {
    my ( $date_string, $date_format, $tz ) = @_;
    if ( !$tz ) {
        $tz = C4::Context->tz;
    }
    if ( !$date_format ) {
        $date_format = C4::Context->preference('dateformat');
    }
    if ($date_string) {
        if ( ref($date_string) eq 'DateTime' ) {    # already a dt return it
            return $date_string;
        }

        if ( $date_format eq 'metric' ) {
            $date_string =~ s#-#/#g;
            $date_string =~ s/^00/01/;    # system allows the 0th of the month
            $date_string =~ s#^(\d{1,2})/(\d{1,2})#$2/$1#;
        } else {
            if ( $date_format eq 'iso' ) {
                $date_string =~ s/-00/-01/;
                if ( $date_string =~ m/^0000-0/ ) {
                    return;               # invalid date in db
                }
            } elsif ( $date_format eq 'us' ) {
                $date_string =~ s#-#/#g;
                $date_string =~ s[/00/][/01/];
            } elsif ( $date_format eq 'sql' ) {
                $date_string =~
s/(\d{4})(\d{2})(\d{2})\s+(\d{2})(\d{2})(\d{2})/$1-$2-$3T$4:$5:$6/;
                return if ($date_string =~ /^0000-00-00/);
                $date_string =~ s/00T/01T/;
            }
        }
        return DateTime::Format::DateParse->parse_datetime( $date_string,
            $tz->name() );
    }
    return DateTime->now( time_zone => $tz );

}

=head2 output_pref

$date_string = output_pref($dt, [$format] );

Returns a string containing the time & date formatted as per the C4::Context setting,
or C<undef> if C<undef> was provided.

A second parameter allows overriding of the syspref value. This is for testing only
In usage use the DateTime objects own methods for non standard formatting

=cut

sub output_pref {
    my $dt         = shift;
    my $force_pref = shift;    # if testing we want to override Context
    my $pref =
      defined $force_pref ? $force_pref : C4::Context->preference('dateformat');
    return undef unless defined($dt);
    given ($pref) {
        when (/^iso/) {
            return $dt->strftime('%Y-%m-%d %H:%M');
        }
        when (/^metric/) {
            return $dt->strftime('%d/%m/%Y %H:%M');
        }
        when (/^us/) {
            return $dt->strftime('%m/%d/%Y %H:%M');
        }
        default {
            return $dt->strftime('%Y-%m-%d %H:%M');
        }

    }
    return;
}

=head2 output_pref_due

$date_string = output_pref_due($dt, [$format] );

Returns a string containing the time & date formatted as per the C4::Context setting

A second parameter allows overriding of the syspref value. This is for testing only
In usage use the DateTime objects own methods for non standard formatting

This is effectivelyt a wrapper around output_pref for due dates
the time portion is stripped if it is '23:59'

=cut

sub output_pref_due {
    my $disp_str = output_pref(@_);
    $disp_str =~ s/ 23:59//;
    return $disp_str;
}

=head2 format_sqldatetime

$string = format_sqldatetime( $string_as_returned_from_db );

a convenience routine for calling dt_from_string and formatting the result
with output_pref as it is a frequent activity in scripts

=cut

sub format_sqldatetime {
    my $str        = shift;
    my $force_pref = shift;    # if testing we want to override Context
    if ( defined $str && $str =~ m/^\d{4}-\d{2}-\d{2}/ ) {
        my $dt = dt_from_string( $str, 'sql' );
        return q{} unless $dt;
        $dt->truncate( to => 'minutes' );
        return output_pref( $dt, $force_pref );
    }
    return q{};
}

=head2 format_sqlduedatetime

$string = format_sqldatetime( $string_as_returned_from_db );

a convenience routine for calling dt_from_string and formatting the result
with output_pref_due as it is a frequent activity in scripts

=cut

sub format_sqlduedatetime {
    my $str        = shift;
    my $force_pref = shift;    # if testing we want to override Context
    if ( defined $str && $str =~ m/^\d{4}-\d{2}-\d{2}/ ) {
        my $dt = dt_from_string( $str, 'sql' );
        $dt->truncate( to => 'minutes' );
        return output_pref_due( $dt, $force_pref );
    }
    return q{};
}

1;
