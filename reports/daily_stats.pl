#!/usr/bin/perl

# Copyright 2012 Catalyst IT
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

use CGI;
use C4::Context;
use C4::Output;
use C4::Auth;
use DateTime;

=head1 NAME

Script to build a breakdown of user stats

=head1 DESCRIPTION

=over 2

=cut

my $input = new CGI;
my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => 'reports/daily_stats.tt',
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { reports => '*' },
        debug           => 0,
    }
);

my $dbh       = C4::Context->dbh();
my $startdate = $input->param('startdate') || DateTime->now->ymd;
my $enddate   = $input->param('enddate') || DateTime->now->ymd;
$template->{VARS}->{'startdate'} = $startdate;
$template->{VARS}->{'enddate'}   = $enddate;

$template = circ_stats( $dbh, $template, $startdate, $enddate );
$template = filled_reserves( $dbh, $template, $startdate, $enddate );
$template = waiting( $dbh, $template, $startdate, $enddate );
$template = cancelled_reserves( $dbh, $template, $startdate, $enddate );
$template = new_reserves( $dbh, $template, $startdate, $enddate );
$template = photocopy( $dbh, $template, $startdate, $enddate );
$template = allcharges( $dbh, $template, $startdate, $enddate );

output_html_with_http_headers $input, $cookie, $template->output;

sub photocopy {
    my ( $dbh, $template, $startdate, $enddate ) = @_;
    my $query =
"SELECT SUM(amount) AS paid ,description FROM accountlines WHERE (description LIKE 'Photo%' or description LIKE '  Photo%') AND
  amountoutstanding = 0 AND date(timestamp) >= ? AND date(timestamp) <= ? GROUP BY description;";
    my $sth = $dbh->prepare($query);
    $sth->execute( $startdate, $enddate );
    $template->{VARS}->{'photocopies'} = $sth->fetchall_arrayref;
    return $template;
}

sub allcharges {
    my ( $dbh, $template, $startdate, $enddate ) = @_;
    my $query =
"SELECT SUM(offsetamount) AS paid,accounttype,description,itype FROM statistics LEFT JOIN accountoffsets ON (statistics.borrowernumber = accountoffsets.borrowernumber AND statistics.proccode = accountoffsets.offsetaccount) LEFT JOIN accountlines ON (accountlines.accountno = accountoffsets.accountno AND accountlines.borrowernumber = accountoffsets.borrowernumber) LEFT JOIN items ON (accountlines.itemnumber = items.itemnumber) WHERE type='payment' AND date(datetime) >= ? AND  date(accountoffsets.timestamp) >= ? AND date(datetime) <= ? AND date(accountoffsets.timestamp) <= ? group by accounttype,itype";
     my $sth = $dbh->prepare($query);
    $sth->execute( $startdate, $startdate, $enddate, $enddate  );
    $template->{VARS}->{'allcharges'} = $sth->fetchall_arrayref;
    return $template;
}

sub filled_reserves {
    my ( $dbh, $template, $startdate, $enddate ) = @_;
    my $query =
"SELECT count(*) as filled FROM old_reserves WHERE found = 'F' AND date(timestamp) >= ? AND date(timestamp) <= ?";
    my $sth = $dbh->prepare($query);
    $sth->execute( $startdate, $enddate );
    if ( my $data = $sth->fetchrow_hashref() ) {
        $template->{VARS}->{'filled'} = $data->{'filled'};
    }
    return $template;
}

sub cancelled_reserves {
    my ( $dbh, $template, $startdate, $enddate ) = @_;
    my $query =
"SELECT count(*) AS cancelled FROM old_reserves WHERE cancellationdate >= ? AND cancellationdate <= ?";
    my $sth = $dbh->prepare($query);
    $sth->execute( $startdate, $enddate );
    if ( my $data = $sth->fetchrow_hashref() ) {
        $template->{VARS}->{'cancelled'} = $data->{'cancelled'};
    }
    return $template;
}

sub waiting {
    my $dbh      = shift;
    my $template = shift;
    my $startdate = shift;
    my $enddate = shift;
    my $query    = "SELECT count(*) AS waiting FROM reserves WHERE  waitingdate >= ? and waitingdate <=?";
    my $sth      = $dbh->prepare($query);
    $sth->execute($startdate,$enddate);

    if ( my $data = $sth->fetchrow_hashref() ) {
        $template->{VARS}->{'waiting'} = $data->{'waiting'};
    }
 $query =~ s/reserves/old_reserves/;

    $sth=$dbh->prepare($query);
     $sth->execute($startdate,$enddate);
             if ( my $data = $sth->fetchrow_hashref() ) {
                      $template->{VARS}->{'waiting'} += $data->{'waiting'};
                          }

    return $template;
}

sub new_reserves {
    my ( $dbh, $template, $startdate, $enddate ) = @_;
    my $query =
"SELECT count(*) AS new FROM reserves WHERE reservedate >= ? AND reservedate <= ?";
    my $sth = $dbh->prepare($query);
    $sth->execute( $startdate, $enddate );
    if ( my $data = $sth->fetchrow_hashref() ) {
        $template->{VARS}->{'new'} = $data->{'new'};
    }
     $query =~ s/reserves/old_reserves/;
     $sth = $dbh->prepare($query);
         $sth->execute( $startdate, $enddate );
             if ( my $data = $sth->fetchrow_hashref() ) {
                      $template->{VARS}->{'new'} += $data->{'new'};
                          }

    return $template;
}

sub circ_stats {
    my ( $dbh, $template, $startdate, $enddate ) = @_;
    my $query =
"SELECT type,count(*) AS counter FROM statistics WHERE type in ('issue','renew','return','localuse') AND date(datetime) >= date(?) AND date(datetime) <= date(?) GROUP by type;";
    my $sth = $dbh->prepare($query);
    $sth->execute( $startdate, $enddate );
    $template->{VARS}->{'circ_stats'} = $sth->fetchall_arrayref;
    return $template;
}

