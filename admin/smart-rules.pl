#!/usr/bin/perl
# Copyright 2000-2002 Katipo Communications
# copyright 2010 BibLibre
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
#use warnings; FIXME - Bug 2505
use CGI;
use C4::Context;
use C4::Output;
use C4::Auth;
use C4::Koha;
use C4::Debug;
use C4::Branch; # GetBranches
use C4::Dates qw/format_date format_date_in_iso/;

my $input = new CGI;
my $dbh = C4::Context->dbh;

# my $flagsrequired;
# $flagsrequired->{circulation}=1;
my ($template, $loggedinuser, $cookie)
    = get_template_and_user({template_name => "admin/smart-rules.tmpl",
                            query => $input,
                            type => "intranet",
                            authnotrequired => 0,
                            flagsrequired => {parameters => 1},
                            debug => 1,
                            });

my $type=$input->param('type');
my $branch = $input->param('branch') || ( C4::Branch::onlymine() ? ( C4::Branch::mybranch() || '*' ) : '*' );
my $op = $input->param('op');

if ($op eq 'delete') {
    my $itemtype     = $input->param('itemtype');
    my $categorycode = $input->param('categorycode');
    $debug and warn "deleting $1 $2 $branch";

    my $sth_Idelete = $dbh->prepare("delete from issuingrules where branchcode=? and categorycode=? and itemtype=?");
    $sth_Idelete->execute($branch, $categorycode, $itemtype);
}
elsif ($op eq 'delete-branch-cat') {
    my $categorycode  = $input->param('categorycode');
    if ($branch eq "*") {
        if ($categorycode eq "*") {
            my $sth_delete = $dbh->prepare("DELETE FROM default_circ_rules");
            $sth_delete->execute();
        } else {
            my $sth_delete = $dbh->prepare("DELETE FROM default_borrower_circ_rules
                                            WHERE categorycode = ?");
            $sth_delete->execute($categorycode);
        }
    } elsif ($categorycode eq "*") {
        my $sth_delete = $dbh->prepare("DELETE FROM default_branch_circ_rules
                                        WHERE branchcode = ?");
        $sth_delete->execute($branch);
    } else {
        my $sth_delete = $dbh->prepare("DELETE FROM branch_borrower_circ_rules
                                        WHERE branchcode = ?
                                        AND categorycode = ?");
        $sth_delete->execute($branch, $categorycode);
    }
}
elsif ($op eq 'delete-branch-item') {
    my $itemtype  = $input->param('itemtype');
    if ($branch eq "*") {
        if ($itemtype eq "*") {
            my $sth_delete = $dbh->prepare("DELETE FROM default_circ_rules");
            $sth_delete->execute();
        } else {
            my $sth_delete = $dbh->prepare("DELETE FROM default_branch_item_rules
                                            WHERE itemtype = ?");
            $sth_delete->execute($itemtype);
        }
    } elsif ($itemtype eq "*") {
        my $sth_delete = $dbh->prepare("DELETE FROM default_branch_circ_rules
                                        WHERE branchcode = ?");
        $sth_delete->execute($branch);
    } else {
        my $sth_delete = $dbh->prepare("DELETE FROM branch_item_rules
                                        WHERE branchcode = ?
                                        AND itemtype = ?");
        $sth_delete->execute($branch, $itemtype);
    }
}
# save the values entered
elsif ($op eq 'add') {
    my $sth_search = $dbh->prepare("SELECT COUNT(*) AS total FROM issuingrules WHERE branchcode=? AND categorycode=? AND itemtype=?");
    my $sth_insert = $dbh->prepare("INSERT INTO issuingrules (branchcode, categorycode, itemtype, maxissueqty, renewalsallowed, reservesallowed, issuelength, hardduedate, hardduedatecompare, fine, finedays, firstremind, chargeperiod,rentaldiscount) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    my $sth_update=$dbh->prepare("UPDATE issuingrules SET fine=?, finedays=?, firstremind=?, chargeperiod=?, maxissueqty=?, renewalsallowed=?, reservesallowed=?, issuelength=?, hardduedate=?, hardduedatecompare=?, rentaldiscount=?  WHERE branchcode=? AND categorycode=? AND itemtype=?");
    
    my $br = $branch; # branch
    my $bor  = $input->param('categorycode'); # borrower category
    my $cat  = $input->param('itemtype');     # item type
    my $fine = $input->param('fine');
    my $finedays     = $input->param('finedays');
    my $firstremind  = $input->param('firstremind');
    my $chargeperiod = $input->param('chargeperiod');
    my $maxissueqty  = $input->param('maxissueqty');
    my $renewalsallowed  = $input->param('renewalsallowed');
    my $reservesallowed  = $input->param('reservesallowed');
    $maxissueqty =~ s/\s//g;
    $maxissueqty = undef if $maxissueqty !~ /^\d+/;
    my $issuelength  = $input->param('issuelength');
    my $hardduedate = $input->param('hardduedate');
    $hardduedate = format_date_in_iso($hardduedate);
    my $hardduedatecompare = $input->param('hardduedatecompare');
    my $rentaldiscount = $input->param('rentaldiscount');
    $debug and warn "Adding $br, $bor, $cat, $fine, $maxissueqty";

    $sth_search->execute($br,$bor,$cat);
    my $res = $sth_search->fetchrow_hashref();
    if ($res->{total}) {
        $sth_update->execute($fine, $finedays,$firstremind, $chargeperiod, $maxissueqty, $renewalsallowed,$reservesallowed, $issuelength,$hardduedate,$hardduedatecompare,$rentaldiscount, $br,$bor,$cat);
    } else {
        $sth_insert->execute($br,$bor,$cat,$maxissueqty,$renewalsallowed,$reservesallowed,$issuelength,$hardduedate,$hardduedatecompare,$fine,$finedays,$firstremind,$chargeperiod,$rentaldiscount);
    }
} 
elsif ($op eq "set-branch-defaults") {
    my $categorycode  = $input->param('categorycode');
    my $maxissueqty   = $input->param('maxissueqty');
    my $holdallowed   = $input->param('holdallowed');
    $maxissueqty =~ s/\s//g;
    $maxissueqty = undef if $maxissueqty !~ /^\d+/;
    $holdallowed =~ s/\s//g;
    $holdallowed = undef if $holdallowed !~ /^\d+/;

    if ($branch eq "*") {
        my $sth_search = $dbh->prepare("SELECT count(*) AS total
                                        FROM default_circ_rules");
        my $sth_insert = $dbh->prepare("INSERT INTO default_circ_rules
                                        (maxissueqty, holdallowed)
                                        VALUES (?, ?)");
        my $sth_update = $dbh->prepare("UPDATE default_circ_rules
                                        SET maxissueqty = ?, holdallowed = ?");

        $sth_search->execute();
        my $res = $sth_search->fetchrow_hashref();
        if ($res->{total}) {
            $sth_update->execute($maxissueqty, $holdallowed);
        } else {
            $sth_insert->execute($maxissueqty, $holdallowed);
        }
    } else {
        my $sth_search = $dbh->prepare("SELECT count(*) AS total
                                        FROM default_branch_circ_rules
                                        WHERE branchcode = ?");
        my $sth_insert = $dbh->prepare("INSERT INTO default_branch_circ_rules
                                        (branchcode, maxissueqty, holdallowed)
                                        VALUES (?, ?, ?)");
        my $sth_update = $dbh->prepare("UPDATE default_branch_circ_rules
                                        SET maxissueqty = ?, holdallowed = ?
                                        WHERE branchcode = ?");
        $sth_search->execute($branch);
        my $res = $sth_search->fetchrow_hashref();
        if ($res->{total}) {
            $sth_update->execute($maxissueqty, $holdallowed, $branch);
        } else {
            $sth_insert->execute($branch, $maxissueqty, $holdallowed);
        }
    }
}
elsif ($op eq "add-branch-cat") {
    my $categorycode  = $input->param('categorycode');
    my $maxissueqty   = $input->param('maxissueqty');
    $maxissueqty =~ s/\s//g;
    $maxissueqty = undef if $maxissueqty !~ /^\d+/;

    if ($branch eq "*") {
        if ($categorycode eq "*") {
            my $sth_search = $dbh->prepare("SELECT count(*) AS total
                                            FROM default_circ_rules");
            my $sth_insert = $dbh->prepare("INSERT INTO default_circ_rules
                                            (maxissueqty)
                                            VALUES (?)");
            my $sth_update = $dbh->prepare("UPDATE default_circ_rules
                                            SET maxissueqty = ?");

            $sth_search->execute();
            my $res = $sth_search->fetchrow_hashref();
            if ($res->{total}) {
                $sth_update->execute($maxissueqty);
            } else {
                $sth_insert->execute($maxissueqty);
            }
        } else {
            my $sth_search = $dbh->prepare("SELECT count(*) AS total
                                            FROM default_borrower_circ_rules
                                            WHERE categorycode = ?");
            my $sth_insert = $dbh->prepare("INSERT INTO default_borrower_circ_rules
                                            (categorycode, maxissueqty)
                                            VALUES (?, ?)");
            my $sth_update = $dbh->prepare("UPDATE default_borrower_circ_rules
                                            SET maxissueqty = ?
                                            WHERE categorycode = ?");
            $sth_search->execute($branch);
            my $res = $sth_search->fetchrow_hashref();
            if ($res->{total}) {
                $sth_update->execute($maxissueqty, $categorycode);
            } else {
                $sth_insert->execute($categorycode, $maxissueqty);
            }
        }
    } elsif ($categorycode eq "*") {
        my $sth_search = $dbh->prepare("SELECT count(*) AS total
                                        FROM default_branch_circ_rules
                                        WHERE branchcode = ?");
        my $sth_insert = $dbh->prepare("INSERT INTO default_branch_circ_rules
                                        (branchcode, maxissueqty)
                                        VALUES (?, ?)");
        my $sth_update = $dbh->prepare("UPDATE default_branch_circ_rules
                                        SET maxissueqty = ?
                                        WHERE branchcode = ?");
        $sth_search->execute($branch);
        my $res = $sth_search->fetchrow_hashref();
        if ($res->{total}) {
            $sth_update->execute($maxissueqty, $branch);
        } else {
            $sth_insert->execute($branch, $maxissueqty);
        }
    } else {
        my $sth_search = $dbh->prepare("SELECT count(*) AS total
                                        FROM branch_borrower_circ_rules
                                        WHERE branchcode = ?
                                        AND   categorycode = ?");
        my $sth_insert = $dbh->prepare("INSERT INTO branch_borrower_circ_rules
                                        (branchcode, categorycode, maxissueqty)
                                        VALUES (?, ?, ?)");
        my $sth_update = $dbh->prepare("UPDATE branch_borrower_circ_rules
                                        SET maxissueqty = ?
                                        WHERE branchcode = ?
                                        AND categorycode = ?");

        $sth_search->execute($branch, $categorycode);
        my $res = $sth_search->fetchrow_hashref();
        if ($res->{total}) {
            $sth_update->execute($maxissueqty, $branch, $categorycode);
        } else {
            $sth_insert->execute($branch, $categorycode, $maxissueqty);
        }
    }
}
elsif ($op eq "add-branch-item") {
    my $itemtype  = $input->param('itemtype');
    my $holdallowed   = $input->param('holdallowed');
    $holdallowed =~ s/\s//g;
    $holdallowed = undef if $holdallowed !~ /^\d+/;

    if ($branch eq "*") {
        if ($itemtype eq "*") {
            my $sth_search = $dbh->prepare("SELECT count(*) AS total
                                            FROM default_circ_rules");
            my $sth_insert = $dbh->prepare("INSERT INTO default_circ_rules
                                            (holdallowed)
                                            VALUES (?)");
            my $sth_update = $dbh->prepare("UPDATE default_circ_rules
                                            SET holdallowed = ?");

            $sth_search->execute();
            my $res = $sth_search->fetchrow_hashref();
            if ($res->{total}) {
                $sth_update->execute($holdallowed);
            } else {
                $sth_insert->execute($holdallowed);
            }
        } else {
            my $sth_search = $dbh->prepare("SELECT count(*) AS total
                                            FROM default_branch_item_rules
                                            WHERE itemtype = ?");
            my $sth_insert = $dbh->prepare("INSERT INTO default_branch_item_rules
                                            (itemtype, holdallowed)
                                            VALUES (?, ?)");
            my $sth_update = $dbh->prepare("UPDATE default_branch_item_rules
                                            SET holdallowed = ?
                                            WHERE itemtype = ?");
            $sth_search->execute($itemtype);
            my $res = $sth_search->fetchrow_hashref();
            if ($res->{total}) {
                $sth_update->execute($holdallowed, $itemtype);
            } else {
                $sth_insert->execute($itemtype, $holdallowed);
            }
        }
    } elsif ($itemtype eq "*") {
        my $sth_search = $dbh->prepare("SELECT count(*) AS total
                                        FROM default_branch_circ_rules
                                        WHERE branchcode = ?");
        my $sth_insert = $dbh->prepare("INSERT INTO default_branch_circ_rules
                                        (branchcode, holdallowed)
                                        VALUES (?, ?)");
        my $sth_update = $dbh->prepare("UPDATE default_branch_circ_rules
                                        SET holdallowed = ?
                                        WHERE branchcode = ?");
        $sth_search->execute($branch);
        my $res = $sth_search->fetchrow_hashref();
        if ($res->{total}) {
            $sth_update->execute($holdallowed, $branch);
        } else {
            $sth_insert->execute($branch, $holdallowed);
        }
    } else {
        my $sth_search = $dbh->prepare("SELECT count(*) AS total
                                        FROM branch_item_rules
                                        WHERE branchcode = ?
                                        AND   itemtype = ?");
        my $sth_insert = $dbh->prepare("INSERT INTO branch_item_rules
                                        (branchcode, itemtype, holdallowed)
                                        VALUES (?, ?, ?)");
        my $sth_update = $dbh->prepare("UPDATE branch_item_rules
                                        SET holdallowed = ?
                                        WHERE branchcode = ?
                                        AND itemtype = ?");

        $sth_search->execute($branch, $itemtype);
        my $res = $sth_search->fetchrow_hashref();
        if ($res->{total}) {
            $sth_update->execute($holdallowed, $branch, $itemtype);
        } else {
            $sth_insert->execute($branch, $itemtype, $holdallowed);
        }
    }
}

my $branches = GetBranches();
my @branchloop;
for my $thisbranch (sort { $branches->{$a}->{branchname} cmp $branches->{$b}->{branchname} } keys %$branches) {
    my $selected = 1 if $thisbranch eq $branch;
    my %row =(value => $thisbranch,
                selected => $selected,
                branchname => $branches->{$thisbranch}->{'branchname'},
            );
    push @branchloop, \%row;
}

my $sth=$dbh->prepare("SELECT description,categorycode FROM categories ORDER BY description");
$sth->execute;
my @category_loop;
while (my $data=$sth->fetchrow_hashref){
    push @category_loop,$data;
}

$sth->finish;
$sth=$dbh->prepare("SELECT description,itemtype FROM itemtypes ORDER BY description");
$sth->execute;
# $i=0;
my @row_loop;
my @itemtypes;
while (my $row=$sth->fetchrow_hashref){
    push @itemtypes,$row;
}

my $sth2 = $dbh->prepare("
    SELECT issuingrules.*, itemtypes.description AS humanitemtype, categories.description AS humancategorycode
    FROM issuingrules
    LEFT JOIN itemtypes
        ON (itemtypes.itemtype = issuingrules.itemtype)
    LEFT JOIN categories
        ON (categories.categorycode = issuingrules.categorycode)
    WHERE issuingrules.branchcode = ?
");
$sth2->execute($branch);

while (my $row = $sth2->fetchrow_hashref) {
    $row->{'current_branch'} ||= $row->{'branchcode'};
    $row->{'humanitemtype'} ||= $row->{'itemtype'};
    $row->{'default_humanitemtype'} = 1 if $row->{'humanitemtype'} eq '*';
    $row->{'humancategorycode'} ||= $row->{'categorycode'};
    $row->{'default_humancategorycode'} = 1 if $row->{'humancategorycode'} eq '*';
    $row->{'fine'} = sprintf('%.2f', $row->{'fine'});
    if ($row->{'hardduedate'} ne '0000-00-00') {
       $row->{'hardduedate'} = format_date( $row->{'hardduedate'});
       $row->{'hardduedatebefore'} = 1 if ($row->{'hardduedatecompare'} == -1);
       $row->{'hardduedateexact'} = 1 if ($row->{'hardduedatecompare'} ==  0);
       $row->{'hardduedateafter'} = 1 if ($row->{'hardduedatecompare'} ==  1);
    } else {
       $row->{'hardduedate'} = 0;
    }
    push @row_loop, $row;
}
$sth->finish;

my @sorted_row_loop = sort by_category_and_itemtype @row_loop;

my $sth_branch_cat;
if ($branch eq "*") {
    $sth_branch_cat = $dbh->prepare("
        SELECT default_borrower_circ_rules.*, categories.description AS humancategorycode
        FROM default_borrower_circ_rules
        JOIN categories USING (categorycode)
        
    ");
    $sth_branch_cat->execute();
} else {
    $sth_branch_cat = $dbh->prepare("
        SELECT branch_borrower_circ_rules.*, categories.description AS humancategorycode
        FROM branch_borrower_circ_rules
        JOIN categories USING (categorycode)
        WHERE branch_borrower_circ_rules.branchcode = ?
    ");
    $sth_branch_cat->execute($branch);
}

my @branch_cat_rules = ();
while (my $row = $sth_branch_cat->fetchrow_hashref) {
    push @branch_cat_rules, $row;
}
my @sorted_branch_cat_rules = sort { $a->{'humancategorycode'} cmp $b->{'humancategorycode'} } @branch_cat_rules;

# note undef maxissueqty so that template can deal with them
foreach my $entry (@sorted_branch_cat_rules, @sorted_row_loop) {
    $entry->{unlimited_maxissueqty} = 1 unless defined($entry->{maxissueqty});
}

my @sorted_row_loop = sort by_category_and_itemtype @row_loop;

my $sth_branch_item;
if ($branch eq "*") {
    $sth_branch_item = $dbh->prepare("
        SELECT default_branch_item_rules.*, itemtypes.description AS humanitemtype
        FROM default_branch_item_rules
        JOIN itemtypes USING (itemtype)
    ");
    $sth_branch_item->execute();
} else {
    $sth_branch_item = $dbh->prepare("
        SELECT branch_item_rules.*, itemtypes.description AS humanitemtype
        FROM branch_item_rules
        JOIN itemtypes USING (itemtype)
        WHERE branch_item_rules.branchcode = ?
    ");
    $sth_branch_item->execute($branch);
}

my @branch_item_rules = ();
while (my $row = $sth_branch_item->fetchrow_hashref) {
    push @branch_item_rules, $row;
}
my @sorted_branch_item_rules = sort { $a->{'humanitemtype'} cmp $b->{'humanitemtype'} } @branch_item_rules;

# note undef holdallowed so that template can deal with them
foreach my $entry (@sorted_branch_item_rules) {
    $entry->{holdallowed_any} = 1 if($entry->{holdallowed} == 2);
    $entry->{holdallowed_same} = 1 if($entry->{holdallowed} == 1);
}

$template->param(show_branch_cat_rule_form => 1);
$template->param(branch_item_rule_loop => \@sorted_branch_item_rules);
$template->param(branch_cat_rule_loop => \@sorted_branch_cat_rules);

my $sth_defaults;
if ($branch eq "*") {
    $sth_defaults = $dbh->prepare("
        SELECT *
        FROM default_circ_rules
    ");
    $sth_defaults->execute();
} else {
    $sth_defaults = $dbh->prepare("
        SELECT *
        FROM default_branch_circ_rules
        WHERE branchcode = ?
    ");
    $sth_defaults->execute($branch);
}

my $defaults = $sth_defaults->fetchrow_hashref;

if ($defaults) {
    $template->param(default_holdallowed_none => 1) if($defaults->{holdallowed} == 0);
    $template->param(default_holdallowed_same => 1) if($defaults->{holdallowed} == 1);
    $template->param(default_holdallowed_any => 1) if($defaults->{holdallowed} == 2);
    $template->param(default_maxissueqty => $defaults->{maxissueqty});
}

$template->param(default_rules => ($defaults ? 1 : 0));

$template->param(categoryloop => \@category_loop,
                        itemtypeloop => \@itemtypes,
                        rules => \@sorted_row_loop,
                        branchloop => \@branchloop,
                        humanbranch => ($branch ne '*' ? $branches->{$branch}->{branchname} : ''),
                        current_branch => $branch,
                        definedbranch => scalar(@sorted_row_loop)>0 
                        );
output_html_with_http_headers $input, $cookie, $template->output;

exit 0;

# sort by patron category, then item type, putting
# default entries at the bottom
sub by_category_and_itemtype {
    unless (by_category($a, $b)) {
        return by_itemtype($a, $b);
    }
}

sub by_category {
    my ($a, $b) = @_;
    if ($a->{'default_humancategorycode'}) {
        return ($b->{'default_humancategorycode'} ? 0 : 1);
    } elsif ($b->{'default_humancategorycode'}) {
        return -1;
    } else {
        return $a->{'humancategorycode'} cmp $b->{'humancategorycode'};
    }
}

sub by_itemtype {
    my ($a, $b) = @_;
    if ($a->{'default_humanitemtype'}) {
        return ($b->{'default_humanitemtype'} ? 0 : 1);
    } elsif ($b->{'default_humanitemtype'}) {
        return -1;
    } else {
        return $a->{'humanitemtype'} cmp $b->{'humanitemtype'};
    }
}
