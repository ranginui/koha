#!/usr/bin/perl

use Modern::Perl;

use CGI;
use JSON;

use C4::Auth;
use C4::Context;
use C4::Utils::DataTables;

my $input = new CGI;
my $vars = $input->Vars;

# Fetch DataTables parameters
my %dtparam = dt_get_params( $input );

my $booksellerid = $input->param('booksellerid');
my $isbn_author_title = $input->param('isbn_author_title');
my $basketno = $input->param('basketno');
my $ordernumber = $input->param('ordernumber');
my $basketgroupname = $input->param('basketgroupname');
my $invoicedatereceived = $input->param('invoicedatereceived');
my $invoice = $input->param('invoice');

my $dbh = C4::Context->dbh;

# Build the query
my $select = qq{
    SELECT SQL_CALC_FOUND_ROWS
        aqorders.*, aqbasket.booksellerid, biblio.author, biblio.title,
        biblioitems.isbn, biblioitems.publishercode,
        aqorders.quantity * aqorders.ecost AS ordertotal
};
my $from = qq{
    FROM aqorders
        LEFT JOIN aqbasket ON aqbasket.basketno = aqorders.basketno
        LEFT JOIN aqbasketgroups ON aqbasket.basketgroupid = aqbasketgroups.id
        LEFT JOIN biblio ON biblio.biblionumber = aqorders.biblionumber
        LEFT JOIN biblioitems ON biblioitems.biblionumber = aqorders.biblionumber
};

my @where_params;
my $where = qq{
    WHERE aqorders.datereceived IS NULL
      AND aqbasket.booksellerid = ?
};
push @where_params, $booksellerid;

my $where_filters;
my @where_filters_params;
if($isbn_author_title) {
    $where_filters .= qq{
        AND (
            biblioitems.isbn LIKE ?
            OR biblio.author LIKE ?
            OR biblio.title LIKE ?
        )
    };
    push @where_filters_params,
            "%$isbn_author_title%",
            "%$isbn_author_title%",
            "%$isbn_author_title%";
}
if($basketno) {
    $where_filters .= qq{
        AND aqorders.basketno = ?
    };
    push @where_filters_params, $basketno;
}
if($ordernumber) {
    $where_filters .= qq{
        AND aqorders.ordernumber = ?
    };
    push @where_filters_params, $ordernumber;
}
if($basketgroupname) {
    $where_filters .= qq{
        AND aqbasketgroups.name LIKE ?
    };
    push @where_filters_params, "%$basketgroupname%";
}

my ($filters, $filter_params) = dt_build_having(\%dtparam);

my $having = " HAVING " . join(" AND ", @$filters) if (@$filters);
my $order_by = dt_build_orderby(\%dtparam);

my $limit .= $dtparam{'iDisplayLength'} ne '-1' ? ' LIMIT ?,? ' : '';

my $query = $select . $from . $where . ( $where_filters || '' ) . ( $having || '' ) . $order_by . $limit;
my @bind_params;
push @bind_params,
    @where_params,
    @where_filters_params,
    @$filter_params,
    $dtparam{'iDisplayLength'} ne '-1' ? ($dtparam{'iDisplayStart'}, $dtparam{'iDisplayLength'}) : ();
my $sth = $dbh->prepare($query);
$sth->execute(@bind_params);
my $results = $sth->fetchall_arrayref({});

$sth = $dbh->prepare("SELECT FOUND_ROWS()");
$sth->execute;
my ($iTotalDisplayRecords) = $sth->fetchrow_array;

# This is mandatory for DataTables to show the total number of results
my $select_total_count = "SELECT COUNT(*) ";
$sth = $dbh->prepare($select_total_count.$from.$where);
$sth->execute(@where_params);
my ($iTotalRecords) = $sth->fetchrow_array;

my @aaData = ();
foreach(@$results) {
    my %row = %{$_};

    $row{'invoicedatereceived'} = $invoicedatereceived;
    $row{'invoice'} = $invoice;

    push @aaData, \%row;
}

my ($template, $loggedinuser, $cookie, $flags) = get_template_and_user({
    template_name   => 'acqui/tables/pendingorders.tmpl',
    query           => $input,
    type            => 'intranet',
    authnotrequired => 0,
    flagsrequired   => { acqui => '*' },
});

$template->param(
    sEcho => $dtparam{'sEcho'},
    iTotalRecords => $iTotalRecords,
    iTotalDisplayRecords => $iTotalDisplayRecords,
    aaData => \@aaData,
);

print $input->header('application/json');
print $template->output();
