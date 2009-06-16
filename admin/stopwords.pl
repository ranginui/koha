#!/usr/bin/perl

#script to administer the stopwords table
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
use CGI;
use C4::Context;
use C4::Output;
use C4::Search;
use C4::Auth;

sub StringSearch  {
	my ($env,$searchstring,$type)=@_;
	$searchstring=~ s/\'/\\\'/g;
	my @data=split(' ',$searchstring);
	my $count=@data;
	my $sth = C4::Context->dbh->prepare("
		SELECT word from stopwords WHERE (word like ?) order by word
	");
	$sth->execute("$data[0]%");
	my @results;
	my $cnt=0;
	while (my $data=$sth->fetchrow_hashref){
			push(@results,$data);
			$cnt ++;
	}
	$sth->finish;
	return ($cnt,\@results);
}

my $input = new CGI;
my $searchfield=$input->param('searchfield');
my $offset=$input->param('offset');
my $script_name="/cgi-bin/koha/admin/stopwords.pl";

my $pagesize=20;
my $op = $input->param('op');
$searchfield=~ s/\,//g;

my ($template, $loggedinuser, $cookie) 
    = get_template_and_user({template_name => "admin/stopwords.tmpl",
    query => $input,
    type => "intranet",
    flagsrequired => {parameters => 1, management => 1},
    authnotrequired => 0,
    debug => 1,
    });

$template->param(script_name => $script_name,
		 searchfield => $searchfield);


################## ADD_FORM ##################################
# called by default. Used to create form to add or  modify a record
if ($op eq 'add_form') {
	$template->param(add_form => 1);
	#---- if primkey exists, it's a modify action, so read values to modify...
	if ($searchfield) {
		my $dbh = C4::Context->dbh;
		my $sth=$dbh->prepare("SELECT word from stopwords where word=?");
		$sth->execute($searchfield);
		my $data=$sth->fetchrow_hashref;	# why bother ??
		$sth->finish;
	}
													# END $OP eq ADD_FORM
################## ADD_VALIDATE ##################################
# called by add_form, used to insert/modify data in DB
} elsif ($op eq 'add_validate') {
	$template->param(add_validate => 1);
	my $dbh = C4::Context->dbh;
	my @tab = split / |,/, $input->param('word');
	my $sth=$dbh->prepare("INSERT INTO stopwords (word) VALUES (?)");
	foreach my $insert_value (@tab) {
		$sth->execute($insert_value);
	}
	$sth->finish;
													# END $OP eq ADD_VALIDATE
################## DELETE_CONFIRM ##################################
# called by default form, used to confirm deletion of data in DB
} elsif ($op eq 'delete_confirm') {
	$template->param(delete_confirm => 1);
	my $dbh = C4::Context->dbh;
	my $sth=$dbh->prepare("SELECT word from stopwords where word=?");
	$sth->execute($searchfield);
	my $data=$sth->fetchrow_hashref;		# why bother ?
	$sth->finish;
													# END $OP eq DELETE_CONFIRM
################## DELETE_CONFIRMED ##################################
# called by delete_confirm, used to effectively confirm deletion of data in DB
} elsif ($op eq 'delete_confirmed') {
	$template->param(delete_confirmed => 1);
	my $dbh = C4::Context->dbh;
	my $sth=$dbh->prepare("delete from stopwords where word=?");
	$sth->execute($searchfield);
	$sth->finish;
													# END $OP eq DELETE_CONFIRMED
################## DEFAULT ##################################
} else { # DEFAULT
	$template->param(else => 1);

	my $env;
	my ($count,$results)=StringSearch($env,$searchfield,'web');
	my @loop;
	for (my $i=$offset; $i < ($offset+$pagesize<$count?$offset+$pagesize:$count); $i++){
		my %row = (word => $results->[$i]{'word'});
		push @loop, \%row;
	}
	$template->param(loop => \@loop);

	if ($offset>0) {
		$template->param(offsetgtzero => 1,
				 prevpage => $offset-$pagesize);
	}
	if ($offset+$pagesize<$count) {
		$template->param(ltcount => 1,
				 nextpage => $offset+$pagesize);
	}
}

output_html_with_http_headers $input, $cookie, $template->output;

