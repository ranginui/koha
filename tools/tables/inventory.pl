#!/usr/bin/perl
#

use Modern::Perl;

use CGI;
use JSON;

use C4::Auth;
use C4::Circulation qw/CanBookBeRenewed/;
use C4::Context;
use C4::Koha qw/getitemtypeimagelocation/;
use C4::Reserves qw/CheckReserves/;
use C4::Utils::DataTables;
use C4::Output;
use C4::Biblio;
use C4::Items;
use C4::Dates qw/format_date format_date_in_iso/;
use C4::Koha;
use C4::Branch;    # GetBranches
use C4::Reports::Guided;    #_get_column_defs
use C4::Charset;
use List::MoreUtils qw /none/;


my $input = new CGI;
my $vars = $input->Vars;
my $barcodelist    = $input->param('barcodelist');
my $notforloanlist = $input->param('notforloanlist');
my $minlocation    = $input->param('minlocation') || '';
my $maxlocation    = $input->param('maxlocation');
$maxlocation       = $minlocation . 'Z' unless ( $maxlocation || !$minlocation );
my $location       = $input->param('location');
my $itemtype       = $input->param('itemtype');       # FIXME note, template does not currently supply this
my $ignoreissued   = $input->param('ignoreissued');
my $datelastseen   = $input->param('datelastseen');
my $markseen       = $input->param('markseen');
my $branchcode     = $input->param('branchcode');
my $branch         = $input->param('branch');
my $op             = $input->param('op') || "do_it";
my $res;                                            #contains the results loop



# Fetch DataTables parameters
my %dtparam = dt_get_params( $input );

my $dbh = C4::Context->dbh;

my @aaData = ();

my ($template, $loggedinuser, $cookie, $flags) = get_template_and_user({
    template_name   => 'tools/tables/inventory.tmpl',
    query           => $input,
    type            => 'intranet',
    authnotrequired => 0,
    flagsrequired   => { circulate => 'circulate_remaining_permission' },
});

my $iTotalRecords;
my $iTotalDisplayRecords = $dtparam{'iDisplayLength'};

# ===============================

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
        if ( $input->param( 'status-' . $authvfield->{fieldname} . '-' . $authval->{authorised_value} ) && $input->param( 'status-' . $authvfield->{fieldname} . '-' . $authval->{authorised_value} ) eq 'on' ) {
            push @{ $staton->{ $authvfield->{fieldname} } }, $authval->{authorised_value};
        }
    }
}

my @notforloans;
if (defined $notforloanlist) {
    @notforloans = split(/,/, $notforloanlist);
}

my @brcditems;
if ( $barcodelist ) {
    my @barcodes = split(/\|/, $barcodelist);
    my $dbh = C4::Context->dbh;
    my $date = format_date_in_iso( $input->param('setdate') ) || C4::Dates->today('iso');

    # 	warn "$date";
    my $strsth  = "select * from issues, items where items.itemnumber=issues.itemnumber and items.barcode =?";
    my $qonloan = $dbh->prepare($strsth);
    $strsth = "select * from items where items.barcode =? and items.wthdrawn = 1";
    my $qwthdrawn = $dbh->prepare($strsth);
    my @errorloop;
    my $count = 0;
    foreach my $barcode (@barcodes) {
        $barcode =~ s/\r?\n$//;
        if ( $qwthdrawn->execute($barcode) && $qwthdrawn->rows ) {
            push @errorloop, { 'barcode' => $barcode, 'ERR_WTHDRAWN' => 1 };
        } else {
            my $item = GetItem( '', $barcode );
            if ( defined $item && $item->{'itemnumber'} ) {
                push @brcditems, $item;
                $count++;
                $qonloan->execute($barcode);
                if ( $qonloan->rows ) {
                    my $data = $qonloan->fetchrow_hashref;
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

# now build the result list: inventoried items if requested, and mis-placed items -always-
my $inventorylist;
if ( $markseen or $op ) {
    # retrieve all items in this range.
    ($inventorylist, $iTotalRecords) = GetItemsForInventory($minlocation, $maxlocation, $location, $itemtype, $ignoreissued, '', $branchcode, $branch, $dtparam{'iDisplayStart'}, $dtparam{'iDisplayLength'}, $staton);
    # if comparison is requested, then display all the result (otherwise, we'll use the inventorylist to find missplaced items, later
    $res = $inventorylist;
}

# set "missing" flags for all items with a datelastseen before the choosen datelastseen
foreach (@$res) {$_->{missingitem}=1 if C4::Dates->new($_->{datelastseen})->output('iso') lt C4::Dates->new($datelastseen)->output('iso')}

# removing missing items from loop if "Compare barcodes list to results" has not been checked
@$res = grep {!$_->{missingitem} == 1 } @$res if (!$input->param('compareinv2barcd')); 


# insert "wrongplace" to all scanned items that are not supposed to be in this range
# note this list is always displayed, whatever the librarian has choosen for comparison
foreach my $temp (@brcditems) {
    next if $temp->{onloan}; # skip checked out items

    # If we have scanned items with a non-matching notforloan value
    if (none { $temp->{'notforloan'} eq $_ } @notforloans) {
        $temp->{'changestatus'} = 1;
        my $biblio = C4::Biblio::GetBiblioData($temp->{biblionumber});
        $temp->{title} = $biblio->{title};
        $temp->{author} = $biblio->{author};
        $temp->{datelastseen} = format_date($temp->{datelastseen});
        push @$res, $temp;

    }

    if (none { $temp->{barcode} eq $_->{barcode} && !$_->{onloan} } @$inventorylist) {
        $temp->{wrongplace}=1;
        my $biblio = C4::Biblio::GetBiblioData($temp->{biblionumber});
        $temp->{title} = $biblio->{title};
        $temp->{author} = $biblio->{author};
        $temp->{datelastseen} = format_date($temp->{datelastseen});
        push @$res, $temp;
    }
}




# Removing items that don't have any problems from loop
@$res = grep { $_->{missingitem} || $_->{wrongplace} || $_->{changestatus} } @$res;

$template->param(
    loop       => $res,
);

$iTotalRecords = scalar(@$res);
@aaData = $res;

# =================================


$template->param(
    sEcho => $dtparam{'sEcho'},
    iTotalRecords => $iTotalRecords,
    iTotalDisplayRecords => $iTotalRecords,
    aaData => @aaData,
);

print $input->header('application/json');
print $template->output();

