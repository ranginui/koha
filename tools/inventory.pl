#!/usr/bin/perl

# Copyright 2000-2009 Biblibre S.A
#                                         John Soros <john.soros@biblibre.com>
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

#need to open cgi and get the fh before anything else opens a new cgi context (see C4::Auth)
use CGI;
my $input          = CGI->new;
my $uploadbarcodes = $input->param('uploadbarcodes');

use List::MoreUtils qw /none/;
use C4::Auth;
use C4::Context;
use C4::Output;
use C4::Biblio;
use C4::Items;
use C4::Dates qw/format_date format_date_in_iso/;
use C4::Koha;
use C4::Branch;    # GetBranches
use C4::Circulation;

my $minlocation = $input->param('minlocation') || '';
my $maxlocation = $input->param('maxlocation');
$maxlocation = $minlocation . 'Z' unless ( $maxlocation || !$minlocation );
my $location     = $input->param('location');
my $itemtype     = $input->param('itemtype');       # FIXME note, template does not currently supply this
my $ignoreissued = $input->param('ignoreissued');
my $datelastseen = $input->param('datelastseen');
my $offset       = $input->param('offset');
my $markseen     = $input->param('markseen');
$offset = 0 unless $offset;
my $pagesize = $input->param('pagesize');
$pagesize = 50 unless $pagesize;
my $branchcode = $input->param('branchcode');
my $branch     = $input->param('branch');
my $op         = $input->param('op');
my $res;                                            #contains the results loop

# warn "uploadbarcodes : ".$uploadbarcodes;
# use Data::Dumper; warn Dumper($input);

my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {   template_name   => "tools/inventory.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { tools => 'inventory' },
        debug           => 1,
    }
);

my $branches = GetBranches();
my @branch_loop;
for my $branch_hash ( keys %$branches ) {
    push @branch_loop,
      { value      => "$branch_hash",
        branchname => $branches->{$branch_hash}->{'branchname'},
        selected   => ( $branch_hash eq $branchcode ? 1 : 0 )
      };
}

@branch_loop = sort { $a->{branchname} cmp $b->{branchname} } @branch_loop;
my @authorised_value_list;
my $authorisedvalue_categories;

my $frameworks = getframeworks();
for my $fwk ( keys %$frameworks ) {
    my $fwkcode = $frameworks->{$fwk}->{'frameworkcode'};
    my $authcode = GetAuthValCode( 'items.location', $fwkcode );
    if ( $authcode && $authorisedvalue_categories !~ /\b$authcode\W/ ) {
        $authorisedvalue_categories .= "$authcode ";
        my $data = GetAuthorisedValues($authcode);
        foreach my $value (@$data) {
            $value->{selected} = 1 if ( $value->{authorised_value} eq ($location) );
        }
        push @authorised_value_list, @$data;
    }
}

my $statuses = [];
for my $statfield (qw/items.notforloan items.itemlost items.wthdrawn items.damaged/) {
    my $hash = {};
    $hash->{fieldname} = $statfield;
    $hash->{authcode}  = GetAuthValCode($statfield);
    if ( $hash->{authcode} ) {
        my $arr = GetAuthorisedValues( $hash->{authcode} );
        $hash->{values} = $arr;
        push @$statuses, $hash;
    }
}
$template->param( statuses => $statuses );
my $staton = {};    #authorized values that are ticked
for my $authvfield (@$statuses) {
    $staton->{ $authvfield->{fieldname} } = [];
    for my $authval ( @{ $authvfield->{values} } ) {
        if ( $input->param( 'status-' . $authvfield->{fieldname} . '-' . $authval->{id} ) && $input->param( 'status-' . $authvfield->{fieldname} . '-' . $authval->{id} ) eq 'on' ) {
            push @{ $staton->{ $authvfield->{fieldname} } }, $authval->{id};
        }
    }
}

my $statussth = '';
for my $authvfield (@$statuses) {
    if ( scalar @{ $staton->{ $authvfield->{fieldname} } } > 0 ) {
        my $joinedvals = join ',', @{ $staton->{ $authvfield->{fieldname} } };
        $statussth .= "$authvfield->{fieldname} in ($joinedvals) and ";
    }
}
$statussth =~ s, and $,,g;

$template->param(
    branchloop               => \@branch_loop,
    authorised_values        => \@authorised_value_list,
    DHTMLcalendar_dateformat => C4::Dates->DHTMLcalendar(),
    today                    => C4::Dates->today(),
    minlocation              => $minlocation,
    maxlocation              => $maxlocation,
    location                 => $location,
    ignoreissued             => $ignoreissued,
    branchcode               => $branchcode,
    branch                   => $branch,
    offset                   => $offset,
    pagesize                 => $pagesize,
    datelastseen             => $datelastseen,
);
my @brcditems;
if ( $uploadbarcodes && length($uploadbarcodes) > 0 ) {
    my $dbh = C4::Context->dbh;
    my $date = format_date_in_iso( $input->param('setdate') ) || C4::Dates->today('iso');

    # 	warn "$date";
    my $strsth  = "select * from issues, items where items.itemnumber=issues.itemnumber and items.barcode =?";
    my $qonloan = $dbh->prepare($strsth);
    $strsth = "select * from items where items.barcode =? and items.wthdrawn = 1";
    my $qwthdrawn = $dbh->prepare($strsth);
    my @errorloop;
    my $count = 0;
    while ( my $barcode = <$uploadbarcodes> ) {
        $barcode =~ s/\r?\n$//;
        if ( $qwthdrawn->execute($barcode) && $qwthdrawn->rows ) {
            push @errorloop, { 'barcode' => $barcode, 'ERR_WTHDRAWN' => 1 };
        } else {
            my $item = GetItem( '', $barcode );
            if ( defined $item && $item->{'itemnumber'} ) {
                ModItem( { datelastseen => $date }, undef, $item->{'itemnumber'} );
                push @brcditems, $item;
                $count++;
                $qonloan->execute($barcode);
                if ( $qonloan->rows ) {
                    my $data = $qonloan->fetchrow_hashref;
                    my ( $doreturn, $messages, $iteminformation, $borrower ) = AddReturn( $barcode, $data->{homebranch} );
                    if ($doreturn) {
                        push @errorloop, { 'barcode' => $barcode, 'ERR_ONLOAN_RET' => 1 };
                    } else {
                        push @errorloop, { 'barcode' => $barcode, 'ERR_ONLOAN_NOT_RET' => 1 };
                    }
                }
            } else {
                push @errorloop, { 'barcode' => $barcode, 'ERR_BARCODE' => 1 };
            }
        }
    }
    $qonloan->finish;
    $qwthdrawn->finish;
    $template->param( date => format_date($date), Number => $count );

    # 	$template->param(errorfile=>$errorfile) if ($errorfile);
    $template->param( errorloop => \@errorloop ) if (@errorloop);
}

# mark seen if applicable (ie: coming form mark seen checkboxes)
if ($markseen) {
    foreach ( $input->param ) {
        /SEEN-(.+)/ and &ModDateLastSeen($1);
    }
}
# now build the result list: inventoried items if requested, and mis-placed items -always-
my $inventorylist;
if ( $markseen or $op ) {
    # retrieve all items in this range.
    $inventorylist = GetItemsForInventory($minlocation, $maxlocation, $location, $itemtype, $ignoreissued, '', $branchcode, $branch, $offset, $pagesize, $staton);
    # if comparison is requested, then display all the result (otherwise, we'll use the inventorylist to find missplaced items, later
    $res = $inventorylist if $input->param('compareinv2barcd');
}
# set "missing" flags for all items with a datelastseen before the choosen datelastseen
foreach (@$res) {$_->{missingitem}=1 if C4::Dates->new($_->{datelastseen})->output('iso') lt C4::Dates->new($datelastseen)->output('iso')}
# insert "wrongplace" to all scanned items that are not supposed to be in this range
# note this list is always displayed, whatever the librarian has choosen for comparison
foreach my $temp (@brcditems) {
    next if $temp->{onloan}; # skip checked out items
    if (none { $temp->{barcode} eq $_->{barcode} && !$_->{onloan} } @$inventorylist) {
        $temp->{wrongplace}=1;
        my $biblio = C4::Biblio::GetBiblioData($temp->{biblionumber});
        $temp->{title} = $biblio->{title};
        $temp->{author} = $biblio->{author};
        push @$res, $temp;
    }
}
$template->param(
    loop       => $res,
    nextoffset => ( $offset + $pagesize ),
    prevoffset => ( $offset ? $offset - $pagesize : 0 ),
);

if ( $input->param('CSVexport') eq 'on' ) {
    eval { use Text::CSV };
    my $csv = Text::CSV->new
      or die Text::CSV->error_diag();
    print $input->header(
        -type       => 'text/csv',
        -attachment => 'inventory.csv',
    );
    $csv->combine(qw / title author barcode itemnumber homebranch location itemcallnumber notforloan lost damaged/);
    print $csv->string, "\n";
    for my $re (@$res) {
        my @line;
        for my $key ( qw / title author barcode itemnumber homebranch location itemcallnumber notforloan lost damaged / ) {
            push @line, $re->{$key};
        }
        push @line, "wrong place" if $re->{wrongplace};
        push @line, "missing item" if $re->{missingitem};
        $csv->combine(@line);
        print $csv->string, "\n";
    }
    exit;
}

output_html_with_http_headers $input, $cookie, $template->output;
