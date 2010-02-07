#!/usr/bin/perl

#script to administer the aqbudget table
#written 20/02/2002 by paul.poulain@free.fr
# This software is placed under the gnu General Public License, v2 (http://www.gnu.org/licenses/gpl.html)

# ALGO :
# this script use an $op to know what to do.
# if $op is empty or none of the above values,
#	- the default screen is build (with all records, or filtered datas).
#	- the   user can clic on add, modify or delete record.
# if $op=add_form
#	- if primkey exists, this is a modification,so we read the $primkey record
#	- builds the add/modify form
# if $op=add_validate
#	- the user has just send datas, so we create/modify the record
# if $op=delete_form
#	- we show the record having primkey=$primkey and ask for deletion validation form
# if $op=delete_confirm
#	- we delete the record having primkey=$primkey


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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA

use strict;
# use warnings; # FIXME
use CGI;
use C4::Context;
use C4::Auth;
use C4::Dates qw(format_date);
use C4::Output;

sub StringSearch  {
    my $query = "SELECT * FROM currency WHERE (currency LIKE ?) ORDER BY currency";
    my $sth = C4::Context->dbh->prepare($query);
    $sth->execute((shift || '') . '%');
    return $sth->fetchall_arrayref({});
}

my $input = new CGI;
my $searchfield = $input->param('searchfield') || $input->param('description') || '';
my $offset      = $input->param('offset') || 0;
my $op          = $input->param('op')     || '';
my $script_name = "/cgi-bin/koha/admin/currency.pl";
my $pagesize = 20;

my ($template, $loggedinuser, $cookie) = get_template_and_user({
    template_name => "admin/currency.tmpl",
    query => $input,
    type => "intranet",
    flagsrequired => {parameters => 1},
    authnotrequired => 0,
    debug => 1,
});

$searchfield=~ s/\,//g;


$template->param(searchfield => $searchfield,
        script_name => $script_name);

my $dbh = C4::Context->dbh;

################## ADD_FORM ##################################
# called by default. Used to create form to add or  modify a record
if ($op eq 'add_form') {
    $template->param(add_form => 1);
    #---- if primkey exists, it's a modify action, so read values to modify...
    my $data;
    if ($searchfield) {
        my $sth=$dbh->prepare("select * from currency where currency=?");
        $sth->execute($searchfield);
        $data=$sth->fetchrow_hashref;
    }
    foreach (keys %$data) {
        $template->param($_ => $data->{$_});
    }

    my $date = $template->param('timestamp');
    ($date) and $template->param('timestamp' => format_date($date));
                                                    # END $OP eq ADD_FORM
################## ADD_VALIDATE ##################################
# called by add_form, used to insert/modify data in DB
} elsif ($op eq 'add_validate') {
    $template->param(add_validate => 1);
    my $dbh = C4::Context->dbh;
    my $check = $dbh->prepare("select count(*) as count from currency where currency = ?");

    $dbh->do("UPDATE currency SET active = 0") if (    $input->param('active')  == 1);

    $check->execute($input->param('currency'));
    my $count =   $check->fetchrow ;
    if ( $count > 0  )
    {
        my $sth = $dbh->prepare(qq|
                UPDATE currency
                    SET rate = ?,
                    symbol = ?,
                    active = ?
            WHERE currency = ?  |  );

        $sth->execute(  $input->param('rate'),
                        $input->param('symbol')||'',
                        $input->param('active')||0,
                        $input->param('currency'),
                        );
    }
    else
    {
        my $sth = $dbh->prepare(qq|
                    INSERT INTO currency (currency, rate, symbol, active) VALUES (?,?,?,?)   |);

        $sth->execute(  $input->param('currency'),
                        $input->param('rate'),
                        $input->param('symbol')||'',
                        $input->param('active')||0,
                        );
    }
                                                    # END $OP eq ADD_VALIDATE
################## DELETE_CONFIRM ##################################
# called by default form, used to confirm deletion of data in DB
} elsif ($op eq 'delete_confirm') {
    $template->param(delete_confirm => 1);
    my $sth=$dbh->prepare("select count(*) as total from aqbooksellers where currency=?");
    $sth->execute($searchfield);
    my $total = $sth->fetchrow_hashref;
    my $sth2=$dbh->prepare("select currency,rate from currency where currency=?");
    $sth2->execute($searchfield);
    my $data=$sth2->fetchrow_hashref;

    if ($total->{'total'} >0) {
        $template->param(totalgtzero => 1);
    }

    $template->param(rate => $data->{'rate'},
            total => $total);
                                                    # END $OP eq DELETE_CONFIRM
################## DELETE_CONFIRMED ##################################
# called by delete_confirm, used to effectively confirm deletion of data in DB
} elsif ($op eq 'delete_confirmed') {
    $template->param(delete_confirmed => 1);
    my $sth=$dbh->prepare("delete from currency where currency=?");
    $sth->execute($searchfield);
                                                    # END $OP eq DELETE_CONFIRMED
################## DEFAULT ##################################
} else { # DEFAULT
    $template->param(else => 1);

    my $results = StringSearch($searchfield);
    my $count = scalar(@$results);
    my @loop;
    my $activecurrency;
    for (my $i=$offset; $i < ($offset+$pagesize<$count?$offset+$pagesize:$count); $i++){
        # warn Data::Dumper::Dumper($results->[$i]);
        if($results->[$i]{'active'} == 1){ $activecurrency = 1; }
        push @loop, {
            currency  => $results->[$i]{'currency'},
            rate      => $results->[$i]{'rate'},
            symbol    => $results->[$i]{'symbol'},
            timestamp => format_date($results->[$i]{'timestamp'}),
            active    => $results->[$i]{'active'},
        };
    }
    $template->param(
        loop => \@loop,
        activecurrency => $activecurrency,
    );

    if ($offset>0) {
        $template->param(offsetgtzero => 1,
                prevpage => $offset-$pagesize);
    }

    if ($offset+$pagesize < scalar @$results) {
        $template->param(ltcount => 1,
                nextpage => $offset+$pagesize);
    }
} #---- END $OP eq DEFAULT
output_html_with_http_headers $input, $cookie, $template->output;

